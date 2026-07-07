const fs = require('fs');
const path = require('path');

const AI_REPORT_PROMPT_FILE = path.join(
  __dirname,
  'prompts',
  'ai_report_system_prompt_v2.md',
);

const FALLBACK_AI_REPORT_SYSTEM_PROMPT = [
  '你是「国学万宝匣」的 AI 辅助解读引擎。',
  '你只能基于系统提供的结构化结果进行白话解读，不得重新排盘、重新起卦或编造缺失信息。',
  '输出必须克制、清晰、有边界，不得使用绝对化、恐吓式表达，也不得替代医疗、法律、投资、婚恋、职业等现实决策建议。',
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

function buildAiReportSystemPrompt(clientSupplement) {
  const basePrompt = getAiReportSystemPrompt();
  const supplement = String(clientSupplement || '').trim();
  if (!supplement) return basePrompt;

  return [
    basePrompt,
    '',
    '---',
    '',
    '## 页面补充规则',
    '',
    supplement,
  ].join('\n');
}

module.exports = {
  AI_REPORT_PROMPT_FILE,
  buildAiReportSystemPrompt,
  getAiReportSystemPrompt,
};
