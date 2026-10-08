const { HttpError } = require('./response');
const crypto = require('crypto');
const { waitUntil } = require('@vercel/functions');
const { getAiProduct } = require('./productCatalog');
const {
  completeAiReport,
  createAiReportDebit,
  getAiReportForUser,
  getWallet,
  reconcileEmptyAiReportsForUser,
  refundAiReport,
} = require('./walletService');
const { buildAiReportSystemPrompt } = require('./promptLoader');
const { normalizeReportUserPrompt } = require('./aiReportInput');
const { ensureDeliveredAiReport } = require('./aiReportQuality');
const { recordServiceEventQuietly } = require('./monitoringService');
const { callDoubao, getDoubaoConfig } = require('./doubaoClient');
const { cloudPollingEnabled } = require('./aiReportMode');

function maxPromptChars() {
  return Math.max(1000, Number(process.env.AI_PROMPT_MAX_CHARS || 16000));
}

function maxSystemPromptChars() {
  return Math.max(1000, Number(process.env.AI_SYSTEM_PROMPT_MAX_CHARS || 14000));
}

function maxClientSystemPromptChars() {
  return Math.max(
    500,
    Number(process.env.AI_CLIENT_SYSTEM_PROMPT_MAX_CHARS || 3000),
  );
}

function maxInputSnapshotChars() {
  return Math.max(1000, Number(process.env.AI_INPUT_SNAPSHOT_MAX_CHARS || 50000));
}

function assertTextLimit(name, value, maxChars) {
  const text = String(value || '');
  if (text.length > maxChars) {
    throw new HttpError(413, `${name}内容过长，请精简后再试`);
  }
  return text;
}

function assertJsonSizeLimit(name, value, maxChars) {
  const text = JSON.stringify(value || {});
  if (text.length > maxChars) {
    throw new HttpError(413, `${name}内容过长，请精简后再试`);
  }
  return value || {};
}

function ensureAiAnswer(value) {
  return ensureDeliveredAiReport(value);
}

function addReportNotice(answer, product) {
  const content = ensureAiAnswer(answer);
  const natal = /^(bazi|ziwei|tieban)_/.test(product.reportType);
  const notice = natal
    ? '命理解读为传统民俗文化内容，不能当作将发生的事实，仅作娱乐参考。'
    : '解卦为传统民俗文化内容，不能当作将发生的事实，仅作娱乐参考。';
  return `${notice}\n\nAI 生成内容\n\n${content}`;
}

async function generateAiReport({ userId, body, dependencies = {} }) {
  const productResolver = dependencies.getAiProduct || getAiProduct;
  const promptBuilder = dependencies.buildAiReportSystemPrompt || buildAiReportSystemPrompt;
  const debitReport = dependencies.createAiReportDebit || createAiReportDebit;
  const completeReport = dependencies.completeAiReport || completeAiReport;
  const refundReport = dependencies.refundAiReport || refundAiReport;
  const requestAi = dependencies.callDoubao || callDoubao;
  const recordMonitoringEvent =
    dependencies.recordServiceEventQuietly || recordServiceEventQuietly;
  const product = productResolver(body.productId);
  if (!product) throw new HttpError(400, 'AI 解析档位不存在或已下架');
  if (!product.enabled) {
    throw new HttpError(400, product.disabledReason || '该 AI 解析档位暂未开放');
  }
  // Cached Web pages and older APKs must not silently charge a new price.
  if (body.expectedPointsCenti !== product.priceCents) {
    throw new HttpError(409, `本次解析需 ${product.pricePoints} 积分，请刷新页面或更新应用后确认（本次未扣积分）`);
  }
  if (!body.userPrompt) {
    throw new HttpError(400, 'AI 解析缺少必要内容');
  }

  const title = assertTextLimit('标题', body.title || '', 200);
  const clientSystemPrompt = assertTextLimit(
    '页面补充提示词',
    body.systemPrompt || '',
    maxClientSystemPromptChars(),
  );
  const systemPrompt = assertTextLimit(
    '系统提示词',
    promptBuilder(clientSystemPrompt),
    maxSystemPromptChars(),
  );
  const originalUserPrompt = assertTextLimit('解析问题', body.userPrompt, maxPromptChars());
  const userPrompt = assertTextLimit('解析问题', normalizeReportUserPrompt(originalUserPrompt), maxPromptChars());
  const inputSnapshotJson = assertJsonSizeLimit(
    '输入快照',
    body.inputSnapshotJson,
    maxInputSnapshotChars(),
  );
  const baziChartJson = assertJsonSizeLimit(
    '命盘快照',
    body.baziChartJson,
    maxInputSnapshotChars(),
  );
  const questionResultJson = assertJsonSizeLimit(
    '结果快照',
    body.questionResultJson,
    maxInputSnapshotChars(),
  );

  const promptSnapshot = [title, systemPrompt, userPrompt].join('\n\n');
  const providerConfig = dependencies.callDoubao ? undefined : getDoubaoConfig();
  if (body.requestId != null &&
      !/^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(body.requestId)) {
    throw new HttpError(400, '请求标识无效');
  }
  const requestId = body.requestId || crypto.randomUUID();

  const debit = await debitReport({
    userId,
    product,
    inputSnapshotJson,
    baziChartJson,
    questionResultJson,
    promptSnapshot,
    requestId,
  });

  if (debit.alreadyPending) {
    if (debit.order.status === 'refunded' || debit.order.status === 'failed') {
      throw new HttpError(409, '这次解析已失败并退回积分，请重新提交');
    }
    return {
      pending: debit.order.status !== 'completed',
      answer: debit.order.resultText || '',
      model: providerConfig?.model || product.model,
      report: debit.order,
      wallet: debit.wallet,
      alreadyPending: true,
    };
  }

  const finish = async () => {
    let ai;
    let answer;
    try {
      ai = await requestAi({
        product,
        systemPrompt,
        userPrompt,
        config: providerConfig,
      });
      answer = addReportNotice(ai.answer, product);
    } catch (error) {
      const refunded = await refundReport({
        orderId: debit.order.id,
        errorMessage: error.message || 'AI 调用失败，积分已自动退回',
        model: product.model,
      });
      if (refunded.order.status === 'completed') {
        return {
          answer: refunded.order.resultText,
          model: product.model,
          report: refunded.order,
          wallet: refunded.wallet,
          alreadyPending: true,
        };
      }
      recordMonitoringEvent({
        category: 'ai',
        eventType: 'ai_report_refunded',
        severity: 'error',
        message: 'AI 解析失败，积分已自动退回',
        userId,
        context: {
          productId: product.id,
          orderId: debit.order.id,
          statusCode: error.statusCode || 500,
        },
      });
      const statusCode = error.statusCode && error.statusCode < 500
        ? error.statusCode
        : 500;
      throw new HttpError(
        statusCode,
        `${error.message || 'AI 调用失败'}，本次积分已自动退回`,
        {
          wallet: refunded.wallet,
          report: refunded.order,
          refunded: true,
          deliveryReason: error.details?.deliveryReason,
        },
      );
    }

    // Saving can commit even when its HTTP response is lost. Retry only the
    // idempotent settlement, never the AI request or the debit.
    let settled;
    for (let attempt = 0; attempt < 2; attempt += 1) {
      try {
        settled = await completeReport({
          orderId: debit.order.id, resultText: answer, model: ai.model, usage: ai.usage,
        });
        break;
      } catch (_) {
        try {
          const report = await (dependencies.getAiReportForUser || getAiReportForUser)({
            userId, orderId: debit.order.id,
          });
          if (report.status !== 'generating' && report.status !== 'pending') {
            let wallet = debit.wallet;
            try { wallet = await (dependencies.getWallet || getWallet)(userId); } catch (_) { /* Next wallet refresh reconciles this. */ }
            settled = { order: report, wallet };
            break;
          }
        } catch (_) { /* An unavailable database is not proof of a failed task. */ }
      }
    }
    if (!settled) {
      recordMonitoringEvent({
        category: 'ai', eventType: 'ai_report_settlement_uncertain', severity: 'error',
        message: 'AI 报告保存状态待核对，未执行盲目退款', userId,
        context: { orderId: debit.order.id, productId: product.id },
      });
      return {
        pending: true, answer: '', model: ai.model,
        report: debit.order, wallet: debit.wallet,
      };
    }
    if (settled.order.status === 'refunded' || settled.order.status === 'failed') {
      throw new HttpError(409, '本次解析已结束并退回积分，请重新提交', {
        report: settled.order, wallet: settled.wallet, refunded: true,
      });
    }
    return {
      answer: settled.order.resultText || answer,
      model: ai.model, report: settled.order, wallet: settled.wallet,
    };
  };

  if (!cloudPollingEnabled()) return finish();

  // Register before starting the model request. The promise is owned by this
  // Vercel invocation, including after its HTTP response has been sent.
  let start;
  const background = new Promise((resolve) => { start = resolve; })
    .then((registered) => registered ? finish() : undefined)
    .catch((error) => {
      recordMonitoringEvent({
        category: 'ai', eventType: 'ai_cloud_report_failed', severity: 'error',
        message: error.details?.refunded
          ? '云端解析失败，积分已自动退回'
          : '云端解析结算状态待核对',
        userId,
        context: {
          orderId: debit.order.id, productId: product.id,
          statusCode: error.statusCode || 500,
        },
      });
    });
  try {
    (dependencies.waitUntil || waitUntil)(background);
  } catch (_) {
    start(false);
    const refunded = await refundReport({
      orderId: debit.order.id, model: product.model,
      errorMessage: '云端解析任务未能启动，积分已自动退回',
    });
    throw new HttpError(503, '云端解析任务未能启动，请稍后重试', {
      report: refunded.order, wallet: refunded.wallet,
      refunded: refunded.order.status === 'refunded',
    });
  }
  start(true);
  return {
    pending: true, answer: '', model: providerConfig?.model || product.model,
    report: debit.order, wallet: debit.wallet, alreadyPending: false,
  };
}

async function getAiReportDetail({ userId, orderId }) {
  if (!orderId) throw new HttpError(400, '缺少报告 ID');
  // Recover historical records created before empty AI responses were treated
  // as failures. The wallet service only refunds completed orders with no
  // valid content or the historic empty-response placeholder.
  await reconcileEmptyAiReportsForUser(userId);
  return getAiReportForUser({ userId, orderId });
}

module.exports = {
  addReportNotice,
  ensureAiAnswer,
  generateAiReport,
  getAiReportDetail,
};
