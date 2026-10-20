// usage: node peek.mjs <light|dark> <outDir> <gi.ii[:scrollTop]> ...
import { chromium } from 'playwright-core';
import path from 'node:path';
import fs from 'node:fs';
import { fileURLToPath } from 'node:url';
const here = path.dirname(fileURLToPath(import.meta.url));
const file = path.resolve(here, '..', 'rigledger_apple_mockup.html');
const [theme, out, ...ids] = process.argv.slice(2);
fs.mkdirSync(out, { recursive: true });
const browser = await chromium.launch({ channel: 'chrome' });
const page = await browser.newPage({ viewport: { width: 1000, height: 900 }, deviceScaleFactor: 2, colorScheme: theme });
page.on('pageerror', e => console.log('pageerror', e.message));
await page.goto('file://' + file);
await page.evaluate(t => dev('theme', t), theme);
await page.waitForTimeout(300);
for (const id of ids) {
  const [g, rest] = id.split('.'); const [i, st] = rest.split(':');
  await page.evaluate(([g, i]) => jump(+g, +i), [g, i]);
  await page.waitForTimeout(450);
  if (st) { await page.evaluate(s => { const e = document.querySelector('#scc'); e.scrollTop = +s; }, st); await page.waitForTimeout(450); }
  await page.locator('#phone').screenshot({ path: path.join(out, `${theme}_${g}_${rest.replace(':', '_')}.png`) });
}
await browser.close();
