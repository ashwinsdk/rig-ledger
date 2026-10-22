// Click-through checks of the v2.0.2, v2.0.3 and v2.0.4 behaviours (several bill lines, agent filter, agent edit, agent view, commission recalculation, Step Rates, feet and commission by type, rig on Account Ledger entries). usage: node flows.mjs
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
check('agent view replaces the profit card, metric cards and Agents section', await page.evaluate(() => !!document.querySelector('.agh') && !document.querySelector('.hero.cin') && !document.querySelector('.plink') && /Profit from this agent/.test(document.querySelector('#scc').innerText)), true);
check('Karthik (Oct) commission earned in the header', await page.evaluate(() => document.querySelector('.agh .ahv .fit').dataset.full), '₹16,130');
check('Karthik (Oct) Total card', await page.evaluate(() => [...document.querySelectorAll('.mc')].filter(e => /Total/.test(e.innerText))[0].querySelector('.fit').dataset.full), '₹1,74,710');
await page.evaluate(() => setPS('all'));
check('agent filter resets on This rig / All rigs change', await page.evaluate(() => S.pr.agent), 'all');

// 7. agent view (v2.0.3), 3 month period
await jumpTo('Agent view (3 month, Karthik)');
const hd = await page.evaluate(() => document.querySelector('.agh').innerText.replace(/\s+/g, ' ').trim());
check('header: name, period, commission earned, back button', hd.replace(/^person /, '').replace(/ tune /, ' ').replace(/arrow_back /, ''), 'Karthik 01 Aug 2026 to 13 Oct 2026 Commission earned ₹22,350 All agents');
check('header has the tune and back icons with 48 dp targets', await page.evaluate(() => [...document.querySelectorAll('.agh button')].map(e => Math.round(e.getBoundingClientRect().height)).join(',')), '48,48');
const pc = await page.evaluate(() => document.querySelector('.agp').innerText.replace(/\s+/g, ' ').trim());
check('profit card', pc, 'Profit from this agent (received - commission) ₹1,52,650 Expected when all pending is collected: ₹2,38,100 All agents, after expenses: ₹2,63,905 Expenses are not tracked per agent, so they are not taken off this figure.');
check('profit card is green', await page.evaluate(() => !document.querySelector('.agp').classList.contains('neg')), true);
check('Bills, Total, Received, Pending cards', await page.evaluate(() => [...document.querySelectorAll('.mgrid .mc')].map(e => e.innerText.replace(/\s+/g, ' ').trim()).join(' | ')), 'Bills 6 | Total ₹2,60,710 | Received ₹1,75,000 | Pending ₹85,450');
check('By month rows (newest first)', await page.evaluate(() => [...document.querySelectorAll('.mtb .mr')].map(e => [...e.children].map(c => c.innerText.replace(/\s+/g, ' ').trim()).join(' ')).join(' ; ')), 'Month Bills Total Commission ; Oct 2026 4 ₹1,74,710 ₹16,130 ; Sep 2026 1 ₹50,000 ₹3,000 ; Aug 2026 1 ₹36,000 ₹3,220');
check('bills newest first', await page.evaluate(() => [...document.querySelectorAll('.agb b.t15')].map(e => e.textContent).join(' ')), '#1043 #1044 #1040 #1045 #1037 #1036');
check('bill 1044 card: commission strip with split', await page.evaluate(() => [...document.querySelectorAll('.agb')].filter(e => /#1044/.test(e.innerText))[0].innerText.replace(/\s+/g, ' ').trim()), '11 Oct #1044 Namakkal chevron_right Total ₹54,450 Received ₹30,000 Balance ₹24,450 handshake Commission ₹4,410 Depth ₹3,650 PVC ₹760');
check('bill 1037 card: manual, no split', await page.evaluate(() => [...document.querySelectorAll('.agb')].filter(e => /#1037/.test(e.innerText))[0].querySelector('.cmstrip').innerText.replace(/\s+/g, ' ').trim()), 'handshake Commission (manual) ₹3,000');
check('totals row', await page.evaluate(() => document.querySelector('.agt').innerText.replace(/\s+/g, ' ').trim()), '6 bills Total ₹2,60,710 Received ₹1,75,000 Pending ₹85,450 Commission ₹22,350');
// tap a bill opens its form, back returns to the agent view
await page.evaluate(() => [...document.querySelectorAll('.agb')].filter(e => /#1043/.test(e.innerText))[0].click());
await page.waitForTimeout(150);
check('tapping a bill opens its form', await txt('#ltot'), '₹35,000');
await page.evaluate(() => back());
check('back returns to the agent view', await page.evaluate(() => !!document.querySelector('.agh')), true);
// back button returns to the normal Overview
await page.evaluate(() => document.querySelector('.ahb').click());
check('All agents button returns to the Overview', await page.evaluate(() => S.pr.agent + ' ' + !document.querySelector('.agh') + ' ' + !!document.querySelector('.hero.cin')), 'all true true');
// the Agents section: tap a row opens the agent view, the info icon opens the details sheet
check('Agents section rows have an info icon button and no chevron', await page.evaluate(() => [...document.querySelectorAll('.plink')].every(e => e.querySelector('.agi[title="Prices and details"]') && !/chevron_right/.test(e.innerText))), true);
await page.evaluate(() => document.querySelector('.plink .agi').click());
check('info icon opens the details sheet', await page.evaluate(() => /commission per foot/i.test(document.querySelector("#ov").innerText)), true);
await page.evaluate(() => closeOv());
await page.evaluate(() => [...document.querySelectorAll('.plink .pm')].filter(e => /Selvam/.test(e.innerText))[0].click());
check('tapping an agent row opens that agent view and the pill shows the name', await page.evaluate(() => document.querySelector('.agh b').textContent + ' / ' + document.querySelector('.afp').innerText.replace(/\s+/g, ' ').trim()), 'Selvam / person_outline Agent: Selvam arrow_drop_down');
await page.evaluate(() => setPS('all'));
check('scope change resets the agent view', await page.evaluate(() => S.pr.agent + ' ' + !document.querySelector('.agh')), 'all true');
await page.evaluate(() => setPS('this'));
// empty state
await jumpTo('Agent view (no bills, empty state)');
check('empty state text', await page.evaluate(() => /No bills for Prakash in this period/.test(document.querySelector('#scc').innerText) && !document.querySelector('.agb') && !document.querySelector('.mtb')), true);
// no month table with a one month period
await page.evaluate(() => { S.pr = { tab: 0, range: 'month', scope: 'this', agent: 'a3' }; render(); });
check('one month period: no By month table', await page.evaluate(() => !document.querySelector('.mtb') && document.querySelectorAll('.agb').length), 4);
check('All time wording', await page.evaluate(() => agPeriod(null)), 'All time');

// 8. commission recalculation when the agent prices are saved (v2.0.3)
await page.evaluate(() => { S.pr = { tab: 0, range: '3m', scope: 'this', agent: 'a3' }; S.tab = 1; render(); });
const save = async fields => { await page.evaluate(() => agentDlg('a3')); for (const [id, v] of Object.entries(fields)) await page.fill('#i_' + id, v); await page.evaluate(() => saveAgent()); await page.waitForTimeout(100); };
await save({ rp_pvc_8inch: '7' });
check('snack for one bill (singular)', await txt('.sn'), 'Agent updated. Commission changed on 1 bill');
check('1044 follows the new PVC 8inch price (60 ft x 7)', await page.evaluate(() => BILLS.filter(b => b.bill === '1044')[0].comm), 4470);
check('agent view header follows (22,350 + 60)', await page.evaluate(() => document.querySelector('.agh .ahv .fit').dataset.full), '₹22,410');
await save({ rp_depth_7inch: '12', rp_pvc_7inch: '6' });
check('snack for five bills (plural)', await txt('.sn'), 'Agent updated. Commission changed on 5 bills');
check('manual bill 1037 skipped, hand-typed PVC line of 1036 keeps 8', await page.evaluate(() => ['1037', '1036'].map(n => BILLS.filter(b => b.bill === n)[0].comm).join(',')), '3000,3720');
check('agent view numbers follow (24,750 commission, profit 175,000 - 24,750)', await page.evaluate(() => document.querySelector('.agh .ahv .fit').dataset.full + ' ' + document.querySelector('.agp .ahv .fit').dataset.full), '₹24,750 ₹1,50,250');
check('bill card of 1040 shows the new commission (3,960)', await page.evaluate(() => [...document.querySelectorAll('.agb')].filter(e => /#1040/.test(e.innerText))[0].querySelector('.cmstrip b').innerText), '₹3,960');
await page.evaluate(() => { S.tab = 0; S.stack = []; S.lt = 0; S.view = 0; S.per = '3m'; render(); });
check('Ledger card of 1044 shows the new split (Depth 4,050 PVC 900)', await page.evaluate(() => [...document.querySelectorAll('.entry')].filter(e => /#1044/.test(e.innerText))[0].querySelector('.cmstrip').innerText.replace(/\s+/g, ' ').trim()), 'handshake Commission ₹4,950 Depth ₹4,050 PVC ₹900');
await page.evaluate(() => { S.per = 'month'; S.tab = 1; render(); });
await save({ an: 'Karthik K' });
check('saving without a price change says only Agent updated', await txt('.sn'), 'Agent updated');
// the side bore bill follows the default depth rate (Murugan 10 -> 11): s4 220 ft
await page.evaluate(() => agentDlg('a1'));
await page.fill('#i_acd', '11');
await page.evaluate(() => saveAgent());
await page.waitForTimeout(100);
check('Murugan default depth 10 -> 11 changes 4 bills', await txt('.sn'), 'Agent updated. Commission changed on 4 bills');
check('side bill 204 commission 220 x 11', await page.evaluate(() => BILLS.filter(b => b.bill === '204')[0].comm), 2420);

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

// 7. v2.0.4 Step Rates screen (fresh page: the sections above edited the agent prices)
await page.reload();
await page.waitForTimeout(400);
const norm = sel => page.evaluate(s => { const e = document.querySelector(s); return e ? e.innerText.replace(/\s+/g, ' ').trim() : ''; }, sel);
const plain = e => { const c = e.cloneNode(true); c.querySelectorAll('.mi').forEach(x => x.remove()); return c.textContent.replace(/\s+/g, ' ').trim(); };
await jumpTo('Step Rates (default tables)');
check('Settings row exists with the new subtitle', await page.evaluate(() => { S.stack = []; S.tab = 3; render(); const l = [...document.querySelectorAll('.ri .tt')].map(e => e.innerText.replace(/\s+/g, ' ').trim()); const i = l.findIndex(t => t.startsWith('Step Rates')); return i >= 0 && l[i + 1].startsWith('Ledger Types') && l[i] === 'Step Rates Extra rate beyond 300 ft, for each rig (new bills only)'; }), true);
await jumpTo('Step Rates (default tables)');
check('7 inch default example', await norm('#srx_t7'), 'Example: 1,000 ft gives a step rate of ₹38,000');
check('8 inch default example', await norm('#srx_t8'), 'Example: 1,000 ft gives a step rate of ₹43,000');
check('bracket labels', await page.evaluate(() => [...document.querySelectorAll('[id^=srl_t7_]')].map(e => e.textContent).join('|')), '300 to 400 ft, extra per ft|400 to 500 ft, extra per ft|500 to 600 ft, extra per ft|600 to 700 ft, extra per ft|700 to 800 ft, extra per ft|800 to 900 ft, extra per ft');
await page.fill('#i_st7_e0', '15');
check('typing a rate updates the example (38,000 + 100 x 5)', await norm('#srx_t7'), 'Example: 1,000 ft gives a step rate of ₹38,500');
await page.fill('#i_st7_th', '400');
check('typing the start updates labels and example feet', await page.evaluate(() => document.querySelector('#srl_t7_0').textContent + ' / ' + document.querySelector('#srx_t7').textContent.slice(0, 23)), '400 to 500 ft, extra per ft / Example: 1,100 ft gives');
await page.fill('#i_st7_th', '300');
await page.evaluate(() => srAdd('t7'));
check('Add bracket = last + growth (90 + 20)', await page.inputValue('#i_st7_e6'), '110');
check('example feet after an added row', await norm('#srx_t7'), 'Example: 1,100 ft gives a step rate of ₹51,500');
for (let i = 0; i < 6; i++) await page.evaluate(() => srRm('t7', 0));
check('one row left, remove X disabled', await page.evaluate(() => document.querySelector('#i_st7_e0').closest('.fr').querySelector('button.nbtn').disabled), true);
await page.fill('#i_st7_e0', '');
await page.evaluate(() => srSave());
check('empty field snack', await txt('.sn'), 'Fill every rate with a number');
await page.fill('#i_st7_e0', 'abc');
await page.evaluate(() => srSave());
check('non-number snack', await txt('.sn'), 'Fill every rate with a number');
await jumpTo('Step Rates (default tables)');
await page.fill('#i_st7_e0', '15');
await page.evaluate(() => srSave());
check('save snack', await txt('.sn'), 'Step rates saved. New bills use them');
check('table stored for the rig', await page.evaluate(() => STEPR.main.t7.ex.join(',')), '15,20,30,50,70,90');
// saved bills keep their step rate, a new bill uses the new table
await page.evaluate(() => { S.stack = []; S.rig = 'main'; S.tab = 0; render(); openBill('b1'); });
check('saved bill 1042 still shows step 500', await page.inputValue('#i_step'), '500');
check('saved bill 1042 total unchanged by the new table', await page.evaluate(() => BILLS.filter(b => b.bill === '1042')[0].total), 350 * 90 + 500 + 120 * 150 + 20 * 400 + 1000);
await page.fill('#i_L_depth_0_f', '360');
check('editing the depth of a saved bill recalculates with the new table (60 ft x 15)', await page.inputValue('#i_step'), '900');
await page.evaluate(() => { S.stack = []; newForm('billForm'); });
await page.fill('#i_L_depth_0_f', '350');
check('new bill 350 ft 7inch uses the new table (50 x 15)', await page.inputValue('#i_step'), '750');
await page.selectOption('#i_L_depth_0_t', '8inch');
check('8inch is untouched (50 x 10)', await page.inputValue('#i_step'), '500');
await page.evaluate(() => { S.stack = []; S.tab = 3; F = {}; push('stepRates'); });
await page.evaluate(() => srResetDlg());
check('reset dialog wording', await page.evaluate(() => /Reset step rates/.test(document.querySelector('#ov').innerText) && /Go back to the standard 7 inch and 8 inch tables for this rig\? Saved bills keep their step rate\./.test(document.querySelector('#ov').innerText)), true);
await page.evaluate(() => { closeOv(); srReset(); });
check('reset goes back to the standard table', await page.evaluate(() => STEPR.main === undefined && stepFor('7inch', 350, 'main') === 500 && document.querySelector('#i_st7_e0').value === '10'), true);

// 8. v2.0.4 agent view: Feet and commission by type
await jumpTo('Agent view, Feet and commission by type');
const fcTxt = (await norm('.fcard')).replace(/\s*\|\s*/g, ' | ');
check('card title', /^Feet and commission by type Depth Total 1,910 ft \| ₹20,070/.test(fcTxt), true);
check('depth chips (7", 8", 9") with commission', ['7" 1,350 ft Commission ₹13,500', '8" 150 ft Commission ₹1,650', '9" 410 ft Commission ₹4,920'].every(x => fcTxt.includes(x)), true);
check('PVC group and chips', ['PVC Total 490 ft | ₹2,780', '7" 430 ft Commission ₹2,420', '8" 60 ft Commission ₹360'].every(x => fcTxt.includes(x)), true);
check('MS group and manual note', fcTxt.includes('MS pipe Total 20 ft | ₹40') && fcTxt.includes('Commission by type uses the line rates. A bill whose commission was set by hand counts with its line rates here.'), true);
await page.evaluate(() => { S.pr = { tab: 0, range: 'month', scope: 'this', agent: 'a3' }; render(); });
check('October view has no manual bill, so no note', await page.evaluate(() => !/set by hand/.test(document.querySelector('.fcard').innerText)), true);
check('card sits between the metric cards and By month', await page.evaluate(() => { const c = document.querySelector('.fcard'), m = document.querySelector('.mgrid'); return !!(m.compareDocumentPosition(c) & 4); }), true);

// 9. v2.0.4 rig on Account Ledger entries
await jumpTo('Account Ledger list with rig names');
const rows = await page.evaluate(() => [...document.querySelectorAll('.entry')].map(e => e.innerText.replace(/\s+/g, ' ')).filter(t => /Labour wages|Compressor/.test(t)).join(' || '));
check('rows with a rig show its name, rows without show none', /Labour wages.*Side Rig 1/.test(rows) && /Compressor service.*Main Rig/.test(rows) && !(await page.evaluate(() => /Rig/.test([...document.querySelectorAll('.entry')].filter(e => /Spare parts/.test(e.innerText))[0].innerText))), true);
await jumpTo('Account Ledger linked entry form (rig locked)');
check('linked entry: rig disabled with helper', await page.evaluate(() => document.querySelector('#i_cv').disabled && /Set from the bill/.test(document.querySelector('#scc').innerText) && /Main Rig/.test(document.querySelector('#i_cv').innerText)), true);
await page.evaluate(() => { S.stack = []; S.tab = 2; CB.book = 'mur'; CB.period = 'all'; render(); });
check('linked income rows show the bill rig', await page.evaluate(() => [...document.querySelectorAll('.entry')].filter(e => /Bill 1042 cash/.test(e.innerText)).every(e => /Main Rig/.test(e.innerText))), true);
await jumpTo('Account Ledger entry form, Rig dropdown (open)');
check('sheet lists No rig and both rigs', await page.evaluate(() => [...document.querySelectorAll('#ov .ri .tt b')].map(e => e.textContent.trim()).join('|')), 'No rig|Main Rig|Side Rig 1');
await page.evaluate(() => [...document.querySelectorAll('#ov .ri')].filter(e => /Side Rig 1/.test(e.innerText))[0].click());
await page.waitForTimeout(100);
check('chosen rig shown on the form', await page.evaluate(() => document.querySelector('#i_cv').innerText.replace(/\s+/g, ' ').replace(/precision_manufacturing|expand_more/g, '').replace(/\s+/g, ' ').trim()), 'Rig (optional) Side Rig 1');
await page.evaluate(() => cbSave(false));
check('Save and add another keeps the rig', await page.evaluate(() => F.cv + ' ' + document.querySelector('#i_cv').innerText.includes('Side Rig 1')), 'side true');
await page.evaluate(() => { F.edit = 6; F.ca = '3500'; F.cn = 'Compressor copy'; cbCopy('cash'); });
check('Copy keeps the rig', await page.evaluate(() => CBE[CBE.length - 1].v + ' ' + CBE[CBE.length - 1].ln), 'side 0');
await page.evaluate(() => cbReportDlg(1));
check('Report sheet says what the CSV and PDF get', await page.evaluate(() => /trailing|ends with a Rig column/.test(document.querySelector('#ov').innerText) && /Rig: Side Rig 1|Rig: Main Rig/.test(document.querySelector('#ov').innerText)), true);
console.log(errs.length ? 'ERRORS ' + errs.join(' | ') : 'no script errors');
console.log(ok && !errs.length ? 'RESULT: flows OK' : 'RESULT: FLOWS FAILED');
await browser.close();
process.exit(ok && !errs.length ? 0 : 1);
