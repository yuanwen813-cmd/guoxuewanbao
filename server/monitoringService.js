const { getSupabaseServiceClient } = require('./supabaseClient');

const allowedSeverities = new Set(['info', 'warning', 'error']);
const blockedContextKeys = /(?:token|secret|password|phone|prompt|body|payload|content|code)/i;

function normalizeSeverity(value) {
  return allowedSeverities.has(value) ? value : 'error';
}

function sanitizeContext(value) {
  if (!value || typeof value !== 'object' || Array.isArray(value)) return {};
  const cleaned = {};
  for (const [key, raw] of Object.entries(value)) {
    if (blockedContextKeys.test(key)) continue;
    if (typeof raw === 'string') cleaned[key] = raw.slice(0, 160);
    if (typeof raw === 'number' || typeof raw === 'boolean') cleaned[key] = raw;
  }
  return cleaned;
}

function isMissingMonitoringTable(error) {
  const message = String(error?.message || '');
  return error?.code === '42P01' ||
    error?.code === 'PGRST205' ||
    message.includes('service_event_logs');
}

async function recordServiceEvent({
  category,
  eventType,
  severity = 'error',
  message,
  userId,
  context,
}, { supabaseClient } = {}) {
  const supabase = supabaseClient || getSupabaseServiceClient();
  const { error } = await supabase.from('service_event_logs').insert({
    category: String(category || 'api').slice(0, 40),
    event_type: String(eventType || 'unknown').slice(0, 100),
    severity: normalizeSeverity(severity),
    message: String(message || '服务运行异常').slice(0, 500),
    user_id: userId || null,
    context_json: sanitizeContext(context),
  });
  if (error) {
    if (isMissingMonitoringTable(error)) return false;
    throw error;
  }
  return true;
}

function recordServiceEventQuietly(event) {
  void recordServiceEvent(event).catch((error) => {
    // Monitoring must never interrupt payment, refund, or login recovery.
    console.error('[monitoring]', event.eventType || 'unknown', error.message);
  });
}

module.exports = {
  isMissingMonitoringTable,
  recordServiceEvent,
  recordServiceEventQuietly,
  sanitizeContext,
};
