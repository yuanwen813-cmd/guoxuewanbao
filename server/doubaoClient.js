const { HttpError } = require('./response');

const DEFAULT_ARK_BASE_URL = 'https://ark.cn-beijing.volces.com/api/v3';
const DEFAULT_ARK_MODEL = 'doubao-seed-2-1-pro-260915';

function getDoubaoModelId() {
  return String(process.env.ARK_MODEL_ID || DEFAULT_ARK_MODEL).trim();
}

function getDoubaoConfig() {
  const apiKey = String(process.env.ARK_API_KEY || '').trim();
  if (!apiKey) throw new HttpError(503, 'AI 服务尚未配置，请稍后再试（本次未扣费）');
  const baseUrl = String(process.env.ARK_BASE_URL || DEFAULT_ARK_BASE_URL)
    .trim().replace(/\/+$/, '');
  // This integration only sends credentials to the official Beijing Ark API.
  if (baseUrl !== DEFAULT_ARK_BASE_URL) {
    throw new HttpError(503, 'AI 服务地址配置有误，请联系管理员');
  }
  const model = getDoubaoModelId();
  if (!model || /\s/.test(model)) {
    throw new HttpError(503, 'AI 模型配置有误，请联系管理员');
  }
  const configuredTimeout = Number(process.env.ARK_TIMEOUT_MS || 270000);
  const timeoutMs = Number.isFinite(configuredTimeout)
    ? Math.min(270000, Math.max(1000, configuredTimeout))
    : 270000;
  return { apiKey, baseUrl, model, timeoutMs };
}

async function callDoubao({ systemPrompt, userPrompt, config = getDoubaoConfig() }) {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), config.timeoutMs);
  try {
    const response = await fetch(`${config.baseUrl}/responses`, {
      method: 'POST',
      signal: controller.signal,
      headers: {
        Authorization: `Bearer ${config.apiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: config.model,
        store: false,
        input: [
          { role: 'system', content: [{ type: 'input_text', text: systemPrompt }] },
          { role: 'user', content: [{ type: 'input_text', text: userPrompt }] },
        ],
      }),
    });
    const data = await response.json().catch(() => ({}));
    if (!response.ok || data?.error) {
      // Provider responses can contain configuration details; never forward them.
      throw new HttpError(502, '豆包服务暂时不可用，请稍后再试');
    }
    const messages = Array.isArray(data?.output)
      ? data.output.filter((item) => item?.type === 'message' && item.role === 'assistant')
      : [];
    const content = messages.flatMap((item) => Array.isArray(item.content) ? item.content : []);
    if (data?.incomplete_details?.reason === 'content_filter'
        || content.some((part) => part?.type === 'refusal')) {
      throw new HttpError(424, 'AI 暂时无法解析此内容，请调整问题后重试');
    }
    // Never deliver partial text or internal reasoning as a paid report.
    if (data?.status !== 'completed' || data?.incomplete_details
        || messages.some((item) => item.status && item.status !== 'completed')) {
      throw new HttpError(424, 'AI 报告未完整生成，请稍后重试');
    }
    const answer = content
      .filter((part) => part?.type === 'output_text' && typeof part.text === 'string')
      .map((part) => part.text).join('\n\n').trim();
    if (!answer) throw new HttpError(424, 'AI 服务未返回有效内容');
    // Preserve the wallet logging contract while using Responses token names.
    const tokenCount = (value) => Number.isSafeInteger(value) && value >= 0 ? value : null;
    const usage = {
      prompt_tokens: tokenCount(data.usage?.input_tokens),
      completion_tokens: tokenCount(data.usage?.output_tokens),
      total_tokens: tokenCount(data.usage?.total_tokens),
    };
    return { answer, usage, model: data.model || config.model };
  } catch (error) {
    if (error instanceof HttpError) throw error;
    if (controller.signal.aborted) {
      throw new HttpError(504, 'AI 解析超时，请稍后重试');
    }
    throw new HttpError(502, 'AI 服务连接失败，请稍后再试');
  } finally {
    clearTimeout(timer);
  }
}

module.exports = { callDoubao, getDoubaoConfig, getDoubaoModelId };
