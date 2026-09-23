function getAiReportSystemPrompt() {
  // Direct provider output: legacy files and env overrides no longer add rules.
  return '';
}

function buildAiReportSystemPrompt() {
  return getAiReportSystemPrompt();
}

module.exports = { buildAiReportSystemPrompt, getAiReportSystemPrompt };
