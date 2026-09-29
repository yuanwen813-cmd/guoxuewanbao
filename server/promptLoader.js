const fs = require('node:fs');
const path = require('node:path');

function getAiReportSystemPrompt() {
  // Only the short, reviewed context is active, not the legacy long template
  // or client-supplied system rules.
  return fs.readFileSync(path.join(__dirname, 'prompts/ai_report_cultural_context.md'), 'utf8').trim();
}

function buildAiReportSystemPrompt() {
  return getAiReportSystemPrompt();
}

module.exports = { buildAiReportSystemPrompt, getAiReportSystemPrompt };
