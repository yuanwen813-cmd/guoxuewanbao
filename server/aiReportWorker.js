const { getSupabaseServiceClient } = require('./supabaseClient');
const { callDoubaoStream, getDoubaoConfig } = require('./doubaoClient');
const { addReportNotice } = require('./aiReportService');
const { getAiProduct } = require('./productCatalog');

const pollMs = Math.max(1000, Number(process.env.AI_WORKER_POLL_MS || 5000));
const longTimeoutMs = Math.min(1800000,
  Math.max(270000, Number(process.env.ARK_LONG_TIMEOUT_MS || 1800000)));

async function rpc(supabase, name, args = {}) {
  const { data, error } = await supabase.rpc(name, args);
  if (error) throw new Error(`${name} failed: ${error.code || 'database error'}`);
  return data;
}

async function processJob(job, { supabase, requestAi, config }) {
  const orderId = job.order_id;
  const token = job.claim_token;
  const heartbeat = setInterval(() => {
    rpc(supabase, 'heartbeat_ai_report_job', {
      p_order_id: orderId,
      p_claim_token: token,
    }).catch((error) => console.error('AI job heartbeat failed', orderId, error.message));
  }, 60000);
  heartbeat.unref?.();

  let resultText = null;
  let errorMessage = null;
  let model = config.model;
  let usage = null;
  try {
    const product = getAiProduct(job.product_id);
    if (!product) throw new Error('AI 产品配置不存在');
    const ai = await requestAi({
      systemPrompt: job.system_prompt,
      userPrompt: job.user_prompt,
      config,
    });
    resultText = addReportNotice(ai.answer, product);
    model = ai.model;
    usage = ai.usage;
  } catch (error) {
    errorMessage = error.message || 'AI 解析失败，费用已自动退回';
    console.warn('AI job generation failed', {
      orderId, statusCode: error.statusCode || 500,
      message: errorMessage,
    });
  } finally {
    clearInterval(heartbeat);
  }

  const result = await rpc(supabase, 'settle_ai_report_job', {
    p_order_id: orderId,
    p_claim_token: token,
    p_result_text: resultText,
    p_error_message: errorMessage,
    p_model: model,
    p_request_tokens: usage?.prompt_tokens ?? null,
    p_response_tokens: usage?.completion_tokens ?? null,
  });
  if (!result?.settled) {
    console.warn('AI job lease changed before settlement', orderId);
  }
  return result;
}

async function runWorker({ supabase, requestAi = callDoubaoStream, idleMs = pollMs } = {}) {
  const client = supabase || getSupabaseServiceClient();
  const config = { ...getDoubaoConfig(), timeoutMs: longTimeoutMs };
  if (!Number.isFinite(config.timeoutMs)) throw new Error('Invalid ARK_LONG_TIMEOUT_MS');
  let stopping = false;
  process.once('SIGTERM', () => { stopping = true; });
  process.once('SIGINT', () => { stopping = true; });
  console.log('AI report worker started');
  while (!stopping) {
    try {
      const job = await rpc(client, 'claim_ai_report_job');
      if (job) {
        await processJob(job, { supabase: client, requestAi, config });
        continue;
      }
    } catch (error) {
      console.error('AI report worker cycle failed', error.message);
    }
    await new Promise((resolve) => setTimeout(resolve, idleMs));
  }
}

if (require.main === module) {
  runWorker().catch((error) => {
    console.error('AI report worker could not start', error.message);
    process.exitCode = 1;
  });
}

module.exports = { processJob, runWorker };
