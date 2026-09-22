const fs = require('fs');
const path = require('path');

const AI_REPORT_PROMPT_FILE = path.join(
  __dirname,
  'prompts',
  'ai_report_system_prompt.md',
);

const FALLBACK_AI_REPORT_SYSTEM_PROMPT = [
  '你是「国学万宝匣」的 AI 辅助解读引擎。',
  '按所给问事、每日一卦或命盘资料解读，先给明确的卦理或命理判断，再说明依据、条件和建议。',
  '传统推演不等于已证实的现实事实；缺少关键时间或资料时直说，不编造。输出中文 Markdown。',
].join('\n');

let aiReportPromptCache;

function readPromptFile(filePath) {
  return fs.readFileSync(filePath, 'utf8').trim();
}

function getAiReportSystemPrompt() {
  const envPrompt = String(process.env.AI_REPORT_SYSTEM_PROMPT || '').trim();
  if (envPrompt) return envPrompt;

  if (aiReportPromptCache !== undefined) return aiReportPromptCache;

  try {
    aiReportPromptCache = readPromptFile(AI_REPORT_PROMPT_FILE);
  } catch (_) {
    aiReportPromptCache = FALLBACK_AI_REPORT_SYSTEM_PROMPT;
  }
  return aiReportPromptCache;
}

function buildAiReportSystemPrompt() {
  // System instructions are server-owned. Older clients may still send a supplement.
  return getAiReportSystemPrompt();
}

module.exports = {
  AI_REPORT_PROMPT_FILE,
  buildAiReportSystemPrompt,
  getAiReportSystemPrompt,
};
