const { HttpError } = require('./response');
const crypto = require('crypto');
const { getAiProduct } = require('./productCatalog');
const {
  completeAiReport,
  createAiReportDebit,
  createQueuedAiReportDebit,
  getAiReportForUser,
  reconcileEmptyAiReportsForUser,
  refundAiReport,
} = require('./walletService');
const { buildAiReportSystemPrompt } = require('./promptLoader');
const { recordServiceEventQuietly } = require('./monitoringService');
const { callDoubao, getDoubaoConfig } = require('./doubaoClient');

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
  const answer = typeof value === 'string' ? value.trim() : '';
  if (!answer) {
    throw new HttpError(424, 'AI 服务未返回有效内容');
  }
  return answer;
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
  const userPrompt = assertTextLimit('解析问题', body.userPrompt, maxPromptChars());
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

  if (process.env.AI_LONG_REPORTS_ENABLED === 'true'
      && /^(bazi|ziwei|tieban)_/.test(product.reportType)) {
    const queueReport = dependencies.createQueuedAiReportDebit || createQueuedAiReportDebit;
    const queued = await queueReport({
      userId, product, inputSnapshotJson, baziChartJson, questionResultJson,
      promptSnapshot, userPrompt, systemPrompt, requestId,
    });
    if (queued.order.status === 'refunded' || queued.order.status === 'failed') {
      throw new HttpError(409, '这次解析已失败并退回积分，请重新提交');
    }
    return {
      pending: queued.order.status === 'generating',
      answer: queued.order.resultText || '',
      model: providerConfig?.model || product.model,
      report: queued.order,
      wallet: queued.wallet,
      alreadyPending: queued.alreadyPending,
    };
  }

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

  try {
    const ai = await requestAi({
      product,
      systemPrompt,
      userPrompt,
      config: providerConfig,
    });
    const answer = addReportNotice(ai.answer, product);
    const completed = await completeReport({
      orderId: debit.order.id,
      resultText: answer,
      model: ai.model,
      usage: ai.usage,
    });
    return {
      answer,
      model: ai.model,
      report: completed.order,
      wallet: completed.wallet,
    };
  } catch (error) {
    const refunded = await refundReport({
      orderId: debit.order.id,
      errorMessage: error.message || 'AI 调用失败，积分已自动退回',
      model: product.model,
    });
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
      },
    );
  }
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
