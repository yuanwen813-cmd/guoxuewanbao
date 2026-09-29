function text(value) {
  return typeof value === 'string' || typeof value === 'number' ? String(value).trim() : '';
}

function formatReportSource(source) {
  if (!source || typeof source !== 'object' || Array.isArray(source)
      || !text(source.featureName) || !text(source.summary)) return null;
  const lines = [];
  const add = (label, value) => {
    const content = text(value);
    if (content) lines.push(`${label}：${content}`);
  };
  add('方法', source.featureName);
  add('原始问题', source.userQuestion);
  add('原始记录时间', source.castTimeUtc || source.createdAt);
  add('结果摘要', source.summary);
  const hexagram = (label, card) => {
    if (!card || typeof card !== 'object') return;
    add(label, [card.index ? `第${text(card.index)}卦` : '', text(card.name), text(card.symbol)].filter(Boolean).join(' '));
    add(`${label}上卦`, card.upperTrigram);
    add(`${label}下卦`, card.lowerTrigram);
    add(`${label}卦辞`, card.judgment);
    add(`${label}象曰`, card.image);
  };
  hexagram('本卦', source.primaryHexagram);
  if (source.movingYao && typeof source.movingYao === 'object') {
    add('动爻', source.movingYao.lineName);
    add('动爻爻位', source.movingYao.line);
    add('动爻爻辞', source.movingYao.text);
    add('本地爻义参考', source.movingYao.meaning);
  }
  hexagram('互卦', source.mutualHexagram);
  hexagram('变卦', source.changedHexagram);
  for (const section of Array.isArray(source.chartSections) ? source.chartSections : []) {
    if (!section || typeof section !== 'object') continue;
    add('资料分项', section.title);
    for (const row of Array.isArray(section.rows) ? section.rows : []) {
      if (row && text(row.label)) add(text(row.label), row.value);
    }
  }
  return lines.join('\n');
}

function normalizeReportUserPrompt(prompt) {
  const value = String(prompt || '');
  const marker = '\n原始资料：\n';
  const start = value.lastIndexOf(marker);
  const end = value.lastIndexOf('\n请解读。');
  if (start < 0 || end <= start) return value;
  try {
    const source = JSON.parse(value.slice(start + marker.length, end));
    const formatted = formatReportSource(source);
    if (!formatted) return value;
    // Preserve the user's question and supplied time verbatim. Only format
    // recognized source records; unknown formats and natal plain text survive.
    return value.slice(0, start + marker.length) + formatted + value.slice(end);
  } catch (_) {
    return value;
  }
}

module.exports = { formatReportSource, normalizeReportUserPrompt };
