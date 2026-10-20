import { chromium } from 'playwright-core';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
const here = path.dirname(fileURLToPath(import.meta.url));
const file = path.resolve(here, '..', 'rigledger_apple_mockup.html');
const browser = await chromium.launch({ channel: 'chrome' });
const page = await browser.newPage({ viewport: { width: 1000, height: 900 } });
const errs = [];
page.on('pageerror', e => errs.push('pageerror: ' + e.message));
page.on('console', m => { if (m.type() === 'error') errs.push('console: ' + m.text()); });
await page.goto('file://' + file);
await page.waitForTimeout(500);
const total = await page.evaluate(() => J.reduce((n, g) => n + g[1].length, 0));
console.log('screens in J:', total);
for (let gi = 0; ; gi++) {
  const n = await page.evaluate(g => (J[g] ? J[g][1].length : -1), gi);
  if (n < 0) break;
  for (let ii = 0; ii < n; ii++) {
    const before = errs.length;
    const name = await page.evaluate(([g, i]) => J[g][0] + ' / ' + J[g][1][i][0], [gi, ii]);
    try { await page.evaluate(([g, i]) => jump(g, i), [gi, ii]); } catch (e) { errs.push('EXC ' + name + ': ' + e.message); }
    const bad = await page.evaluate(() => /undefined|NaN|\[object/.test(document.querySelector('#screen').innerText + document.querySelector('#ov').innerText));
    if (bad) errs.push('SUSPECT TEXT in ' + name);
    if (errs.length > before) console.log('  issue in', name, '->', errs.slice(before).join(' | '));
  }
}
console.log(errs.length ? 'ISSUES: ' + errs.length : 'NO ERRORS');
await browser.close();
