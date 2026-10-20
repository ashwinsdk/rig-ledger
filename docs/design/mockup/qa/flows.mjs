// Click-through checks of the v2.0.2 behaviours (several bill lines, agent filter, agent edit). usage: node flows.mjs
import { chromium } from 'playwright-core';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
const here = path.dirname(fileURLToPath(import.meta.url));
const file = path.resolve(here, '..', 'rigledger_apple_mockup.html');
const browser = await chromium.launch({ channel: 'chrome' });
const page = await browser.newPage({ viewport: { width: 1000, height: 900 } });
const errs = [];
page.on('pageerror', e => errs.push('pageerror: ' + e.message + ' ' + (e.stack || '').split('\n').slice(0, 3).join(' <- ')));
await page.goto('file://' + file);
await page.waitForTimeout(400);
let ok = true;
const check = (name, got, want) => { const p = String(got) === String(want); ok = ok && p; console.log(`${p ? 'OK  ' : 'FAIL'}  ${name}: ${got}${p ? '' : ' (want ' + want + ')'}`); };
const J = (g, i) => page.evaluate(([g, i]) => jump(g, i), [g, i]);
const find = name => page.evaluate(n => { for (let g = 0; g < J.length; g++) for (let i = 0; i < J[g][1].length; i++) if (J[g][1][i][0] === n) return [g, i]; return null; }, name);
const txt = sel => page.evaluate(s => (document.querySelector(s) || {}).innerText || '', sel);
const jumpTo = async name => { const x = await find(name); await J(x[0], x[1]); await page.waitForTimeout(150); };

// 1. bill 1044 form: totals and commission, then add a depth line and type into it
await jumpTo('Main Bore - Edit Entry (two depth lines, two PVC lines)');
check('form total', await txt('#ltot'), '₹54,450');
check('step label with several depth lines', await page.evaluate(() => [...document.querySelectorAll('.fl')].some(e => e.textContent === 'Step Rate, all depth lines')), true);
check('commission total', await page.evaluate(() => document.querySelector('#cbk').innerText.replace(/\s+/g, ' ')), 'Depth commission ₹3,650 PVC commission ₹760 MS pipe commission ₹0 Total commission ₹4,410');
await page.evaluate(() => addLine('depth'));
check('three depth line headers', await page.evaluate(() => [...document.querySelectorAll('.lnh .fl')].filter(e => /^Depth line/.test(e.textContent)).map(e => e.textContent).join('|')), 'Depth line 1|Depth line 2|Depth line 3');
await page.fill('#i_L_depth_2_f', '100');
await page.fill('#i_L_depth_2_r', '80');
check('total after a third line of 100 ft x 80', await txt('#ltot'), '₹62,450');
await page.fill('#i_L_depth_2_k', '12');
check('commission breakdown after typing the line rate (4,410 + 100 ft x 12)', await page.evaluate(() => document.querySelector('#cbk').innerText.replace(/\s+/g, ' ')), 'Depth commission ₹4,850 PVC commission ₹760 MS pipe commission ₹0 Total commission ₹5,610');
check('commission field', await page.inputValue('#i_comm'), '5610');
await page.evaluate(() => rmLine('depth', 2));
check('total after removing the third line', await txt('#ltot'), '₹54,450');
check('Add line buttons', await page.evaluate(() => [...document.querySelectorAll('.addln')].map(e => e.lastChild.textContent.trim()).join('|')), 'Add Depth line|Add PVC line|Add MS Pipe line');

// 2. agent choice fills each line from the agent price of its type; a type change follows unless typed
await jumpTo('Main Bore - New Entry');
await page.evaluate(() => { F.ag = 'a3'; pickAgent(); });
check('Karthik fills depth 7inch rate', await page.inputValue('#i_L_depth_0_k'), '10');
await page.selectOption('#i_L_depth_0_t', '8inch');
check('type change to 8inch follows the agent price', await page.inputValue('#i_L_depth_0_k'), '11');
await page.fill('#i_L_depth_0_k', '13');
await page.selectOption('#i_L_depth_0_t', '9inch');
check('typed rate is kept on type change', await page.inputValue('#i_L_depth_0_k'), '13');
await page.evaluate(() => addLine('pvc'));
await page.selectOption('#i_L_pvc_1_t', '8inch');
check('a type change on a new PVC line follows the agent', await page.inputValue('#i_L_pvc_1_k'), '6');

// 3. side bore two lines
await jumpTo('Side Bore - Edit Entry (two depth lines)');
check('side form total', await txt('#ltot'), '₹19,200');
check('side form has no type rows', await page.evaluate(() => !!document.querySelector('select[id^=i_L_depth_0_t]')), false);
check('side commission rows', await page.evaluate(() => [...document.querySelectorAll('#scc .fl')].map(e => e.textContent).filter(t => /^Depth \d rate$/.test(t)).join('|')), 'Depth 1 rate|Depth 2 rate');

// 4. ledger cards
await page.evaluate(() => { S.rig = 'main'; S.stack = []; S.tab = 0; S.lt = 0; S.view = 0; render(); });
await page.waitForTimeout(100);
const card = await page.evaluate(() => [...document.querySelectorAll('.entry')].filter(e => e.innerText.includes('#1044'))[0].innerText.replace(/\s+/g, ' '));
check('1044 depth chip', /Depth 200ft \(7inch\) \+ 150ft \(8inch\)/.test(card), true);
check('1044 PVC chip', /PVC 7inch \+ 8inch/.test(card), true);
check('1044 commission strip', /Depth ₹3,650 PVC ₹760/.test(card), true);
// filter: a bill matches when ANY line has the type
const f = await page.evaluate(() => { S.flt = { dt: '8inch' }; const a = periodBills().map(b => b.bill).sort().join(','); S.flt = { pt: '8inch' }; const b = periodBills().map(b => b.bill).sort().join(','); S.flt = {}; return a + ' / ' + b; });
check('filters match any line (depth 8inch / PVC 8inch)', f, '1039,1041,1044 / 1039,1041,1044');
check('Ledger Types: 8inch depth used by (b2, b4, b8)', await page.evaluate(() => typeUse('depth', '8inch')), 3);
check('Ledger Types: 9inch depth used by', await page.evaluate(() => typeUse('depth', '9inch')), 2);

// 5. Portfolio agent filter
await page.evaluate(() => { S.rig = 'main'; S.stack = []; S.tab = 1; S.pr = { tab: 0, range: 'month', scope: 'this', agent: 'all' }; render(); });
check('pill text', await page.evaluate(() => document.querySelector('.afp').innerText.replace(/\s+/g, ' ').trim()), 'person_outline Agent: All agents arrow_drop_down');
check('profit without agent filter', await page.evaluate(() => document.querySelector('.hero.cin').innerText), '₹1,97,330');
await page.evaluate(() => agentFilterSheet());
check('sheet rows', await page.evaluate(() => [...document.querySelectorAll('#aflist .ri')].map(e => e.innerText.replace(/\s+/g, ' ').trim()).join(' ; ')), 'All agents 7 bills check ; Karthik 4 bills | ₹1,74,710 ; Murugan 2 bills | ₹1,62,850 ; Selvam 1 bill | ₹78,800 ; Prakash no bills');
await page.fill('#afq', 'zz');
check('no match text', await txt('#aflist'), 'No agent matches');
await page.fill('#afq', 'kar');
check('search keeps only Karthik and hides the All agents row', await page.evaluate(() => document.querySelectorAll('#aflist .ri').length), 1);
await page.click('#aflist .ri');
check('sheet closed after choosing', await page.evaluate(() => $('#ov').innerHTML === ''), true);
check('pill shows the agent and is tinted', await page.evaluate(() => { const e = document.querySelector('.afp'); return e.classList.contains('on') + ' ' + e.innerText.replace(/\s+/g, ' ').trim(); }), 'true person_outline Agent: Karthik arrow_drop_down');
check('profit card replaced by the note', await page.evaluate(() => /Expenses are not tracked per agent/.test(document.querySelector('#scc').innerText)), true);
check('Karthik total billed card', await page.evaluate(() => [...document.querySelectorAll('.mc')].filter(e => /Total billed/.test(e.innerText))[0].querySelector('.fit').dataset.full), '₹1,74,710');
check('Karthik commission card', await page.evaluate(() => [...document.querySelectorAll('.mc')].filter(e => /Commission/.test(e.innerText))[0].querySelector('.fit').dataset.full), '₹16,130');
await page.evaluate(() => setPS('all'));
check('agent filter resets on This rig / All rigs change', await page.evaluate(() => S.pr.agent), 'all');

// 6. agent sheet Edit really changes the agent, Delete really removes it
await page.evaluate(() => { S.tab = 1; render(); agentSheet('a3'); });
await page.evaluate(() => agentDlg('a3'));
await page.fill('#i_rp_depth_8inch', '15');
await page.fill('#i_an', 'Karthik S');
await page.evaluate(() => saveAgent());
check('agent renamed', await page.evaluate(() => agent('a3').name), 'Karthik S');
await page.evaluate(() => agentSheet('a3'));
check('detail sheet shows the new 8inch price', await page.evaluate(() => /Depth 8" *\n?.*15/.test(document.querySelector('#ov').innerText) || /Depth 8"/.test(document.querySelector('#ov').innerText) && /₹15/.test(document.querySelector('#ov').innerText)), true);
await page.evaluate(() => { F = {}; agentDel('a4'); });
await page.evaluate(() => agentGone('a4'));
check('agent without bills deleted', await page.evaluate(() => AG.length), 3);
console.log(errs.length ? 'ERRORS ' + errs.join(' | ') : 'no script errors');
console.log(ok && !errs.length ? 'RESULT: flows OK' : 'RESULT: FLOWS FAILED');
await browser.close();
process.exit(ok && !errs.length ? 0 : 1);
