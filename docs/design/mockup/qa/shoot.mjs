// Screenshots every J screen in light and dark and checks overflow, text size, touch targets and contrast.
// usage: node shoot.mjs [--out docs/design/ref/qa] [--stress] [--ts 2] [--width 412|360] [--nav3] [--blur] [--only light|dark] [--no-shots] [--no-kb] [--show 40]
import { chromium } from 'playwright-core';
import path from 'node:path';
import os from 'node:os';
import fs from 'node:fs';
import { fileURLToPath } from 'node:url';
const here = path.dirname(fileURLToPath(import.meta.url));
const file = path.resolve(here, '..', 'rigledger_apple_mockup.html');
const args = process.argv.slice(2);
const opt = (k, d) => { const i = args.indexOf('--' + k); return i < 0 ? d : (args[i + 1] && !args[i + 1].startsWith('--') ? args[i + 1] : true); };
const out = path.resolve(String(opt('out', path.resolve(here, '..', '..', 'ref', 'qa'))));
const stress = !!opt('stress', false), ts = +opt('ts', 1), width = +opt('width', 412), only = opt('only', null), noShots = !!opt('no-shots', false), nav3 = !!opt('nav3', false), blur = !!opt('blur', false), noKb = !!opt('no-kb', false);
const TAP = 48;
const tag = `${width === 360 ? 'small' : 'phone'}${nav3 ? '_nav3' : ''}${blur ? '_blur' : ''}${stress ? '_stress' : ''}${ts !== 1 ? '_ts' + ts * 100 : ''}`;
fs.mkdirSync(out, { recursive: true });

// Runs inside the page. Returns a list of {type, el, extra}.
const checker = (minTouch) => {
  const phone = document.querySelector('#phone'), pr = phone.getBoundingClientRect(), bw = parseFloat(getComputedStyle(phone).borderRightWidth) || 0;
  const scope = [document.querySelector('#screen'), document.querySelector('#ov'), document.querySelector('#nav')];
  const issues = [];
  const parse = s => {
    const m = s.match(/rgba?\(([^)]+)\)/) || s.match(/color\(srgb ([^)]+)\)/);
    if (!m) return null;
    let p = m[1].replace(/\//g, ' ').split(/[ ,]+/).filter(Boolean).map(Number);
    if (/color\(srgb/.test(s)) p = [p[0] * 255, p[1] * 255, p[2] * 255, p[3]];
    return [p[0], p[1], p[2], p[3] == null ? 1 : p[3]];
  };
  const over = (f, b) => [f[0] * f[3] + b[0] * (1 - f[3]), f[1] * f[3] + b[1] * (1 - f[3]), f[2] * f[3] + b[2] * (1 - f[3]), 1];
  const lum = c => { const f = v => { v /= 255; return v <= .03928 ? v / 12.92 : Math.pow((v + .055) / 1.055, 2.4); }; return .2126 * f(c[0]) + .7152 * f(c[1]) + .0722 * f(c[2]); };
  const ratio = (a, b) => { const x = lum(a), y = lum(b); return (Math.max(x, y) + .05) / (Math.min(x, y) + .05); };
  const canvas = parse(getComputedStyle(phone).backgroundColor) || [0, 0, 0, 1];
  const gradStops = el => { const bi = getComputedStyle(el).backgroundImage; if (!bi || bi === 'none') return null; const m = bi.match(/(rgba?\([^)]*\)|color\(srgb [^)]*\))/g); return m ? m.map(parse).filter(Boolean) : null; };
  const bgOf = el => {
    const under = [];
    for (let e = el; e && e !== document.documentElement; e = e.parentElement) {
      const g = gradStops(e); if (g && g.length) return { stops: g, under };
      const c = parse(getComputedStyle(e).backgroundColor);
      if (c && c[3] > 0) { under.push(c); if (c[3] >= .999) break; }
    }
    return { stops: null, under };
  };
  const flatten = under => { let b = canvas; for (let i = under.length - 1; i >= 0; i--) b = over(under[i], b); return b; };
  const label = el => {
    let s = el.tagName.toLowerCase();
    if (el.className && typeof el.className === 'string') s += '.' + el.className.trim().split(/\s+/).slice(0, 2).join('.');
    const t = (el.innerText || el.getAttribute('aria-label') || '').trim().replace(/\s+/g, ' ').slice(0, 28);
    return s + (t ? ` "${t}"` : '');
  };
  const visible = el => { const r = el.getBoundingClientRect(), cs = getComputedStyle(el); if (!(r.width > 0 && r.height > 0 && cs.visibility !== 'hidden' && cs.display !== 'none')) return false; for (let e = el; e && e !== document.body; e = e.parentElement) if (+getComputedStyle(e).opacity < 0.05) return false; return true; };
  const seen = new Set();
  const add = (type, el, extra) => { const k = type + label(el); if (seen.has(k)) return; seen.add(k); issues.push({ type, el: label(el), extra }); };
  for (const s of scope) {
    if (!s) continue;
    s.querySelectorAll('*').forEach(el => {
      if (!visible(el)) return;
      if (el.closest('.swp') && !el.closest('.swp > .main')) return;
      const cs = getComputedStyle(el), r = el.getBoundingClientRect();
      if (!el.closest('.chips,.swp,.hscroll')) {
        if (r.right > pr.right - bw + 1.5 && r.width < pr.width) add('overflow-edge', el, `right=${Math.round(r.right - pr.right)}`);
        if ((cs.overflowX === 'hidden' || cs.overflowX === 'clip') && el.scrollWidth > el.clientWidth + 1 && !el.classList.contains('fit') && cs.textOverflow !== 'ellipsis' && !el.id) add('clipped', el, `${el.scrollWidth}>${el.clientWidth}`);
        if (el.classList.contains('fit') && el.scrollWidth > el.clientWidth + 1) add('fit-overflow', el, `${el.scrollWidth}>${el.clientWidth}`);
      }
      const hasText = [...el.childNodes].some(n => n.nodeType === 3 && n.textContent.trim());
      if (hasText && !el.classList.contains('mi')) {
        const fs = parseFloat(cs.fontSize);
        if (fs < 10.95) add('small-text', el, `${fs.toFixed(1)}px`);
        let fg = parse(cs.color);
        if (fg) {
          let eff = 1; for (let e = el; e && e !== document.body; e = e.parentElement) eff *= +getComputedStyle(e).opacity;
          fg = [fg[0], fg[1], fg[2], fg[3] * eff];
          const bg = bgOf(el), large = fs >= 24 || (fs >= 18.66 && +cs.fontWeight >= 700), need = large ? 3 : 4.5;
          let worst = 99;
          if (bg.stops) { for (const st of bg.stops) { const b = over(st, flatten(bg.under)); worst = Math.min(worst, ratio(over(fg, b), b)); } }
          else { const b = flatten(bg.under); worst = ratio(over(fg, b), b); }
          if (worst < need) add('contrast', el, `${worst.toFixed(2)}:1 need ${need}`);
        }
      }
      if (el.matches('button,a,input,select,textarea,[onclick],[role=button],[role=switch],[role=checkbox]') && !el.closest('.pop')) {
        if (r.left >= pr.right - bw || r.right <= pr.left + bw) return;
        let box = r;
        if (el.matches('input,select,textarea') && el.closest('label')) box = el.closest('label').getBoundingClientRect(); // the label row is the touch target
        if (box.width < minTouch - .5 || box.height < minTouch - .5) add('touch', el, `${Math.round(box.width)}x${Math.round(box.height)}`);
      }
    });
  }
  return issues;
};

// Focuses every text field on the screen and checks that the field and the primary button stay visible above the simulated keyboard.
async function kbCheck(page) {
  const out = [];
  await page.evaluate(() => { const s = document.querySelector('#scc'); if (s) s.scrollTop = 0; });
  const sel = '#screen input:not([type=radio]):not([type=checkbox]):not([readonly]), #screen textarea, #ov input:not([type=radio]):not([type=checkbox]):not([readonly]), #ov textarea';
  const handles = await page.$$(sel);
  for (const h of handles.slice(0, 30)) {
    if (!(await h.isVisible())) continue;
    await h.focus(); await page.waitForTimeout(140);
    const r = await h.evaluate(el => {
      const ph = document.querySelector('#phone'), kb = document.querySelector('#kb'), kbTop = getComputedStyle(kb).display === 'none' ? Infinity : kb.getBoundingClientRect().top;
      const er = el.getBoundingClientRect(); let sc = el.parentElement; while (sc && !/(auto|scroll)/.test(getComputedStyle(sc).overflowY)) sc = sc.parentElement;
      const sr = sc ? sc.getBoundingClientRect() : ph.getBoundingClientRect();
      const bot = document.querySelector('#screen .bot, #ov .shbot'), botTop = bot ? bot.getBoundingClientRect().top : Infinity;
      const nb = document.querySelector('#screen .nb'), top = Math.max(sr.top, nb && !document.querySelector('#screen .fs') ? nb.getBoundingClientRect().bottom : 0);
      const limit = Math.min(kbTop, sr.bottom, botTop);
      const btn = document.querySelector('#screen .bot .bp, #ov .shbot .bp, #screen .bot button, #ov .shbot button'), br = btn ? btn.getBoundingClientRect() : null;
      const name = (el.getAttribute('placeholder') || el.id || el.tagName) + '';
      return { fieldHidden: er.top < top - 1 || er.bottom > limit + 1, name, btnHidden: br ? (br.bottom > kbTop + 1 || br.top < 0) : false, kbOn: ph.classList.contains('kbd'), er: [Math.round(er.top), Math.round(er.bottom)], limit: Math.round(limit), top: Math.round(top) };
    });
    if (!r.kbOn) out.push({ type: 'kb-off', el: r.name });
    if (r.fieldHidden) out.push({ type: 'kb-field-hidden', el: r.name, extra: `field ${r.er} visible ${r.top}..${r.limit}` });
    if (r.btnHidden) out.push({ type: 'kb-button-hidden', el: r.name });
  }
  await page.evaluate(() => { if (document.activeElement && document.activeElement.blur) document.activeElement.blur(); });
  return out;
}
const browser = await chromium.launch({ channel: 'chrome' });
const themes = only ? [only] : ['light', 'dark'];
const report = {};
for (const theme of themes) {
  const ctx = await browser.newContext({ viewport: { width: Math.max(width + 340, 1000), height: 980 }, deviceScaleFactor: 1.5, colorScheme: theme });
  const page = await ctx.newPage();
  const errs = [];
  page.on('pageerror', e => errs.push(e.message));
  await page.goto('file://' + file);
  await page.evaluate(([t, ts, st, w, n3, bl]) => { dev('theme', t); dev('ts', ts); dev('dw', w); if (st) dev('stress', 'on'); if (n3) dev('nav', '3button'); if (bl) dev('blur', 'on'); }, [theme, ts, stress, width, nav3, blur]);
  await page.waitForTimeout(300);
  const groups = await page.evaluate(() => J.map(g => g[1].length));
  for (let gi = 0; gi < groups.length; gi++) for (let ii = 0; ii < groups[gi]; ii++) {
    const name = await page.evaluate(([g, i]) => J[g][0] + ' / ' + J[g][1][i][0], [gi, ii]);
    await page.evaluate(([g, i]) => jump(g, i), [gi, ii]);
    await page.waitForTimeout(380);
    if (!noShots) await page.locator('#phone').screenshot({ path: path.join(out, `${tag}_${theme}_${String(gi).padStart(2, '0')}_${String(ii).padStart(2, '0')}.png`) });
    const iss = await page.evaluate(checker, TAP);
    const sh = await page.evaluate(() => { const s = document.querySelector('#scc'); if (!s) return 0; s.scrollTop = s.scrollHeight; return s.scrollTop; });
    if (sh > 0) {
      await page.waitForTimeout(250);
      const more = await page.evaluate(checker, TAP), keys = new Set(iss.map(i => i.type + i.el));
      more.forEach(m => { if (!keys.has(m.type + m.el)) iss.push(m); });
    }
    if (!noKb) iss.push(...await kbCheck(page));
    if (iss.length || errs.length) report[`${theme} | ${name}`] = { issues: iss, errors: errs.splice(0) };
  }
  await ctx.close();
}
await browser.close();
const flat = Object.entries(report).flatMap(([k, v]) => v.issues.map(i => ({ screen: k, ...i })));
const byType = {};
flat.forEach(i => { byType[i.type] = (byType[i.type] || 0) + 1; });
fs.writeFileSync(path.join(out, `report_${tag}.json`), JSON.stringify(report, null, 1));
console.log(`mode ${tag}: ${flat.length} issues`, JSON.stringify(byType));
const limit = +opt('show', 40);
flat.slice(0, limit).forEach(i => console.log(` ${i.type.padEnd(13)} ${i.screen.slice(0, 58).padEnd(58)} ${i.el} ${i.extra || ''}`));
if (flat.length > limit) console.log(` ... ${flat.length - limit} more in report_${tag}.json`);
