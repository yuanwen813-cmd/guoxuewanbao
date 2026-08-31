const { HttpError } = require('./response');
const { getAiProduct } = require('./productCatalog');
const {
  completeAiReport,
  createAiReportDebit,
  getAiReportForUser,
  reconcileEmptyAiReportsForUser,
  refundAiReport,
} = require('./walletService');
const { buildAiReportSystemPrompt } = require('./promptLoader');
const { recordServiceEventQuietly } = require('./monitoringService');

const DEEPSEEK_BASE_URL =
  process.env.DEEPSEEK_BASE_URL || 'https://api.deepseek.com';

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
  const answer = String(value || '').trim();
  if (!answer) {
    throw new HttpError(424, 'AI 服务未返回有效内容');
  }
  return answer;
}

async function callDeepSeek({ product, systemPrompt, userPrompt, temperature }) {
  const apiKey = process.env.DEEPSEEK_API_KEY;
  if (!apiKey) throw new HttpError(503, '服务端未配置 DeepSeek API Key');

  const response = await fetch(`${DEEPSEEK_BASE_URL}/v1/chat/completions`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${apiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: product.model,
      messages: [
        { role: 'system', content: systemPrompt || '' },
        { role: 'user', content: userPrompt || '' },
      ],
      temperature: typeof temperature === 'number' ? temperature : 0.45,
      max_tokens: product.maxTokens,
    }),
  });

  const data = await response.json().catch(() => ({}));
  if (!response.ok) {
    const message =
      data.error?.message || data.message || `AI 服务暂时不可用：${response.status}`;
    throw new HttpError(response.status, message, data);
  }

  const answer = ensureAiAnswer(data.choices?.[0]?.message?.content);

  return {
    answer,
    usage: data.usage || {},
    model: data.model || product.model,
  };
}

async function generateAiReport({ userId, body, dependencies = {} }) {
  const productResolver = dependencies.getAiProduct || getAiProduct;
  const promptBuilder = dependencies.buildAiReportSystemPrompt || buildAiReportSystemPrompt;
  const debitReport = dependencies.createAiReportDebit || createAiReportDebit;
  const completeReport = dependencies.completeAiReport || completeAiReport;
  const refundReport = dependencies.refundAiReport || refundAiReport;
  const requestAi = dependencies.callDeepSeek || callDeepSeek;
  const recordMonitoringEvent =
    dependencies.recordServiceEventQuietly || recordServiceEventQuietly;
  const product = productResolver(body.productId);
  if (!product) throw new HttpError(400, 'AI 解析档位不存在或已下架');
  if (!product.enabled) {
    throw new HttpError(400, product.disabledReason || '该 AI 解析档位暂未开放');
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

  const debit = await debitReport({
    userId,
    product,
    inputSnapshotJson,
    baziChartJson,
    questionResultJson,
    promptSnapshot,
  });

  try {
    const ai = await requestAi({
      product,
      systemPrompt,
      userPrompt,
      temperature: body.temperature,
    });
    const completed = await completeReport({
      orderId: debit.order.id,
      resultText: ai.answer,
      model: ai.model,
      usage: ai.usage,
    });
    return {
      answer: ai.answer,
      model: ai.model,
      report: completed.order,
      wallet: completed.wallet,
    };
  } catch (error) {
    const refunded = await refundReport({
      orderId: debit.order.id,
      errorMessage: error.message || 'AI 调用失败，已自动退款',
      model: product.model,
    });
    recordMonitoringEvent({
      category: 'ai',
      eventType: 'ai_report_refunded',
      severity: 'error',
      message: 'AI 解析失败，扣费已自动退款',
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
      `${error.message || 'AI 调用失败'}，本次扣费已自动退回`,
      {
        wallet: refunded.wallet,
        report: refunded.order,
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
  ensureAiAnswer,
  generateAiReport,
  getAiReportDetail,
};
