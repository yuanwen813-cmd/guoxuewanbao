// Learning record only. All line values come from the reader; no random casting,
// network requests or analytics. The map uses bottom-to-top keys and is verified
// against assets/data/iching/hexagrams_64.json.
const hexagrams = {
  '111111': '乾为天', '000000': '坤为地', '100010': '水雷屯', '010001': '山水蒙',
  '111010': '水天需', '010111': '天水讼', '010000': '地水师', '000010': '水地比',
  '111011': '风天小畜', '110111': '天泽履', '111000': '地天泰', '000111': '天地否',
  '101111': '天火同人', '111101': '火天大有', '001000': '地山谦', '000100': '雷地豫',
  '100110': '泽雷随', '011001': '山风蛊', '110000': '地泽临', '000011': '风地观',
  '100101': '火雷噬嗑', '101001': '山火贲', '000001': '山地剥', '100000': '地雷复',
  '100111': '天雷无妄', '111001': '山天大畜', '100001': '山雷颐', '011110': '泽风大过',
  '010010': '坎为水', '101101': '离为火', '001110': '泽山咸', '011100': '雷风恒',
  '001111': '天山遁', '111100': '雷天大壮', '000101': '火地晋', '101000': '地火明夷',
  '101011': '风火家人', '110101': '火泽睽', '001010': '水山蹇', '010100': '雷水解',
  '110001': '山泽损', '100011': '风雷益', '111110': '泽天夬', '011111': '天风姤',
  '000110': '泽地萃', '011000': '地风升', '010110': '泽水困', '011010': '水风井',
  '101110': '泽火革', '011101': '火风鼎', '100100': '震为雷', '001001': '艮为山',
  '001011': '风山渐', '110100': '雷泽归妹', '101100': '雷火丰', '001101': '火山旅',
  '011011': '巽为风', '110110': '兑为泽', '010011': '风水涣', '110010': '水泽节',
  '110011': '风泽中孚', '001100': '雷山小过', '101010': '水火既济', '010101': '火水未济'
};

const positions = ['初爻', '二爻', '三爻', '四爻', '五爻', '上爻'];
const valueNames = {6: '老阴', 7: '少阳', 8: '少阴', 9: '老阳'};
const storageKey = 'guoxue-yarrow-lesson-v1';

// Preserve only the three attribution fields already supported by the product.
// This rewrites navigation links; it does not send or record analytics events.
function attributionValues(search) {
  const params = new URLSearchParams(search);
  const defaults = {utm_source: 'learn', utm_medium: 'tutorial', utm_campaign: 'yarrow_20261008'};
  return Object.fromEntries(Object.entries(defaults).map(([key, fallback]) => {
    const value = params.get(key);
    return [key, value && /^[A-Za-z0-9][A-Za-z0-9_.-]{0,63}$/.test(value) ? value : fallback];
  }));
}

function calculateRecord(values) {
  if (!Array.isArray(values) || values.length !== 6 || Array.from(values).some(v => ![6, 7, 8, 9].includes(v))) {
    return null;
  }
  const primary = values.map(value => value === 7 || value === 9 ? 1 : 0);
  const changed = values.map((value, index) => value === 6 || value === 9 ? 1 - primary[index] : primary[index]);
  const moving = values.flatMap((value, index) => value === 6 || value === 9 ? [index] : []);
  return {values: [...values], primary, changed, moving, primaryName: hexagrams[primary.join('')], changedName: hexagrams[changed.join('')]};
}

function homeworkText(record) {
  if (!record) return '';
  const moving = record.moving.length ? record.moving.map(index => `${positions[index]}（${valueNames[record.values[index]]}）`).join('、') : '无动爻';
  return [
    '国学万宝匣｜蓍草起卦学习作业',
    `六爻（初爻 → 上爻）：${record.values.join('、')}`,
    `本卦：${record.primaryName}`,
    `变卦：${record.changedName}${record.moving.length ? '' : '（与本卦相同）'}`,
    `动爻：${moving}`,
    '',
    '一爻三变记录：____ → ____ → ____ → ____；最后余策 ÷ 4 = ____',
    '《周易》原典笔记：____',
    '《高岛易断》阅读笔记（另查参考资料）：____',
    '我的事实、思考与一项可验证行动：____',
    '',
    '教材：https://guoxuewanbao.cn/learn/yarrow',
    '本记录由手工选择的爻数换算，不是自动随机起卦。'
  ].join('\n');
}

function initialize() {
  const attribution = attributionValues(window.location.search);
  const productPaths = new Set(['/', '/reference/zhouyi', '/reference/takashima', '/divination/takashima', '/download', '/login']);
  document.querySelectorAll('a[href]').forEach(anchor => {
    const url = new URL(anchor.href, window.location.href);
    if (url.hostname === 'guoxuewanbao.cn' && productPaths.has(url.pathname)) {
      url.search = '';
      for (const [key, value] of Object.entries(attribution)) url.searchParams.set(key, value);
      anchor.href = url.href;
    }
  });
  const selects = positions.map((_, index) => document.getElementById(`line-${index + 1}`));
  const status = document.getElementById('record-status');
  const result = document.getElementById('record-result');
  const localChoice = document.getElementById('save-local');
  const copyButton = document.getElementById('copy-homework');
  const fallback = document.getElementById('copy-fallback');
  let record = null;

  function renderLines(container, bits, values, primary) {
    container.replaceChildren();
    for (let index = 5; index >= 0; index -= 1) {
      const row = document.createElement('div');
      row.className = 'hexagram-row';
      const label = document.createElement('span');
      label.textContent = positions[index];
      const line = document.createElement('span');
      line.className = `yao ${bits[index] ? 'yang' : 'yin'}`;
      line.setAttribute('aria-hidden', 'true');
      const mark = document.createElement('span');
      mark.className = 'mark';
      mark.textContent = primary ? (values[index] === 6 ? '×' : values[index] === 9 ? '○' : '') : '';
      const isMoving = values[index] === 6 || values[index] === 9;
      row.setAttribute('aria-label', `${positions[index]}：${bits[index] ? '阳爻' : '阴爻'}${primary && isMoving ? '，动爻' : ''}`);
      row.append(label, line, mark);
      container.append(row);
    }
  }

  function saveCurrent() {
    try {
      if (localChoice.checked) {
        localStorage.setItem(storageKey, JSON.stringify(selects.map(select => select.value)));
      } else {
        localStorage.removeItem(storageKey);
      }
      return true;
    } catch {
      localChoice.checked = false;
      status.textContent += ' 当前浏览器无法保存；爻数仍可在本页使用。';
      return false;
    }
  }

  function update(persist = true) {
    const values = selects.map(select => select.value ? Number(select.value) : null);
    record = calculateRecord(values);
    result.hidden = !record;
    copyButton.disabled = !record;
    fallback.hidden = true;
    if (record) {
      document.getElementById('primary-name').textContent = record.primaryName;
      document.getElementById('changed-name').textContent = record.changedName;
      renderLines(document.getElementById('primary-lines'), record.primary, record.values, true);
      renderLines(document.getElementById('changed-lines'), record.changed, record.values, false);
      document.getElementById('moving-lines').textContent = record.moving.length
        ? `动爻：${record.moving.map(index => `${positions[index]}（${valueNames[record.values[index]]}）`).join('、')}`
        : '无动爻，本卦与变卦相同。';
      status.textContent = `记录完成：${record.primaryName}，${record.moving.length} 个动爻。`;
    } else {
      const selected = values.filter(value => value !== null).length;
      status.textContent = selected ? `已选 ${selected} / 6 爻，请继续从下向上记录。` : '选齐六爻后，这里会显示本卦、变卦与动爻。';
    }
    return persist ? saveCurrent() : true;
  }

  // Only restore a previously opted-in, valid six-field record. Malformed
  // or unavailable storage never prevents learning or changing the controls.
  try {
    const stored = JSON.parse(localStorage.getItem(storageKey));
    if (Array.isArray(stored) && stored.length === 6 && stored.every(value => ['', '6', '7', '8', '9'].includes(value))) {
      stored.forEach((value, index) => { selects[index].value = value; });
      localChoice.checked = true;
    }
  } catch { /* Private browser or malformed local record: start empty. */ }

  selects.forEach(select => select.addEventListener('change', () => update()));
  localChoice.addEventListener('change', saveCurrent);
  document.getElementById('load-example').addEventListener('click', () => {
    [9, 7, 7, 7, 7, 7].forEach((value, index) => { selects[index].value = String(value); });
    update();
    document.getElementById('record').scrollIntoView({behavior: matchMedia('(prefers-reduced-motion: reduce)').matches ? 'auto' : 'smooth', block: 'start'});
  });
  document.getElementById('clear-record').addEventListener('click', () => {
    selects.forEach(select => { select.value = ''; });
    localChoice.checked = false;
    const cleared = update();
    status.textContent = cleared ? '已清除本页爻数与当前浏览器中的保存记录。' : '已清除本页爻数；浏览器阻止了本地存储操作，无法核验已存记录。';
  });
  copyButton.addEventListener('click', async () => {
    const text = homeworkText(record);
    if (!text) return;
    try {
      await navigator.clipboard.writeText(text);
      status.textContent = '学习作业已复制，可粘贴到自己的笔记中。';
    } catch {
      fallback.value = text;
      fallback.hidden = false;
      fallback.focus();
      fallback.select();
      status.textContent = '浏览器未允许自动复制；下方已选中作业文本，可手动复制。';
    }
  });
  document.querySelectorAll('[data-print]').forEach(button => button.addEventListener('click', () => window.print()));
  update(false);
}

if (typeof document !== 'undefined') initialize();
