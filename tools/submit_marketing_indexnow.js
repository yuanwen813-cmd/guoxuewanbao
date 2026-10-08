'use strict';

const fs = require('node:fs');
const path = require('node:path');

async function main() {
  const configPath = process.argv[2];
  if (!configPath) throw new Error('Pass the local IndexNow configuration path');
  const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
  if (config.host !== 'guoxuewanbao.cn' || !/^[a-f0-9]{32}$/.test(config.key)) {
    throw new Error('Invalid domain verification configuration');
  }
  const keyLocation = `https://${config.host}/${config.key}.txt`;
  const verification = await fetch(keyLocation, { signal: AbortSignal.timeout(30000) });
  if (!verification.ok || (await verification.text()).trim() !== config.key) {
    throw new Error('Live domain verification file unavailable');
  }
  const urlList = ['https://guoxuewanbao.cn/', 'https://guoxuewanbao.cn/learn/yarrow'];
  const lesson = await fetch(urlList[1], { signal: AbortSignal.timeout(30000) });
  if (!lesson.ok || !(await lesson.text()).includes('lesson-title')) {
    throw new Error('Live tutorial unavailable; no URLs submitted');
  }
  const response = await fetch('https://api.indexnow.org/indexnow', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=utf-8' },
    body: JSON.stringify({ host: config.host, key: config.key, keyLocation, urlList }),
    signal: AbortSignal.timeout(30000),
  });
  const result = {
    submittedAt: new Date().toISOString(),
    endpoint: 'https://api.indexnow.org/indexnow',
    status: response.status,
    accepted: response.status === 200 || response.status === 202,
    verificationPending: response.status === 202,
    urls: urlList,
    note: 'Submission receipt only; indexing, ranking, visits and registrations remain unverified.',
  };
  const receiptPath = path.join(path.dirname(path.resolve(configPath)), 'indexnow-receipt.json');
  fs.writeFileSync(receiptPath, JSON.stringify(result, null, 2) + '\n');
  console.log(JSON.stringify(result, null, 2));
  if (!result.accepted) process.exitCode = 1;
}

main().catch(() => {
  console.error('IndexNow submission incomplete. Verification, network or server response failed.');
  process.exitCode = 1;
});
