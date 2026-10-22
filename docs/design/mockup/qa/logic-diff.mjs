// Proves the data and derived-logic block is frozen, and that its numbers match hand-computed values.
// usage: node logic-diff.mjs            check against qa/logic-baseline-v2.0.3.txt
//        node logic-diff.mjs --update   rewrite the baseline after an INTENTIONAL logic change (say so in MOCKUP_PROGRESS.md)
//
// History: until v2.0.0 the block was compared byte for byte with the v1 mockup in docs/design/ref. The v2.0.1 update changed it on
// purpose (see "Intentional logic changes" in MOCKUP_PROGRESS.md), so the baseline is now this repo file, not a file outside it.
import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';
import { fileURLToPath } from 'node:url';
const here = path.dirname(fileURLToPath(import.meta.url));
const html = fs.readFileSync(path.resolve(here, '..', 'rigledger_apple_mockup.html'), 'utf8');
const basePath = path.join(here, 'logic-baseline-v2.0.3.txt');
const startMark = "(checked by qa/logic-diff.mjs against qa/logic-baseline-v2.0.3.txt) ================= */\n";
const a = html.indexOf(startMark), b = html.indexOf('/* ================= END LOGIC BLOCK');
if (a < 0 || b < 0) { console.log('RESULT: logic block markers not found'); process.exit(1); }
const logic = html.slice(a + startMark.length, b);
if (process.argv.includes('--update')) { fs.writeFileSync(basePath, logic); console.log('baseline rewritten, ' + logic.split('\n').length + ' lines'); process.exit(0); }
let ok = true;
const base = fs.readFileSync(basePath, 'utf8');
const same = base === logic; ok = ok && same;
console.log(`${same ? 'IDENTICAL' : 'DIFFERENT'}  logic block vs baseline  (${base.split('\n').length - 1} lines baseline, ${logic.split('\n').length - 1} lines now)`);
if (!same) { const x = base.split('\n'), y = logic.split('\n'); for (let i = 0; i < Math.max(x.length, y.length); i++) if (x[i] !== y[i]) { console.log(`  first difference at line ${i + 1}:\n  - ${x[i]}\n  + ${y[i]}`); break; } }

// Evaluate the block and compare with numbers worked out by hand (see MOCKUP_PROGRESS.md, "Hand check").
const ctx = { document: { querySelector() { return null; } }, console };
vm.createContext(ctx);
vm.runInContext(logic + '\nthis.__x={recalcAgentBills:recalcAgentBills,agent:agent,BILLS:BILLS,S:S,pfScopeBills:pfScopeBills,pfCalc:pfCalc,expenses:expenses,mrange:mrange,stats:stats,periodBills:periodBills,rateFor:rateFor,AG:AG,feetTotals:feetTotals};', ctx);
const X = ctx.__x;
const check = (name, got, want) => { const g = Math.round(got * 100) / 100; const p = g === want; ok = ok && p; console.log(`${p ? 'OK  ' : 'FAIL'}  ${name}: ${g} (hand ${want})`); };
const bill = id => X.BILLS.find(b => b.id === id);
// b7, Karthik, one depth line 9inch: depth 260 ft x 12 (9 inch price) + pvc 60 ft x 5 + no ms = 3120 + 300
check('commission of bill b7', bill('b7').comm, 3420);
check('total of bill b7 (9inch has no step rate)', bill('b7').total, 35000);
check('manual commission of bill b6', bill('b6').comm, 3000);
// v2.0.2 multi-line bill b8 (Karthik): depth 200 ft 7inch x 90 + 150 ft 8inch x 95, pvc 80 ft 7inch x 150 + 60 ft 8inch x 170, each line under 300 ft so no step rate
check('step rate of bill b8 (per line, both under 300 ft)', bill('b8').step, 0);
check('total of bill b8 = 18000 + 14250 + 12000 + 10200', bill('b8').total, 54450);
check('commission of bill b8 = 200x10 + 150x11 + 80x5 + 60x6', bill('b8').comm, 4410);
check('balance of bill b8 = 54450 - 30000', bill('b8').bal, 24450);
// b9 (Karthik): 7inch 320 ft x 90 with step 20 ft x 10 = 200, 9inch 150 ft x 100 (no table, under 300 anyway)
check('step rate of bill b9 (only the 7inch line has one)', bill('b9').step, 200);
check('total of bill b9 = 28800 + 200 + 15000', bill('b9').total, 44000);
check('commission of bill b9 = 320x10 + 150x12', bill('b9').comm, 5000);
// side bore bill s4: two depth lines 120 x 85 + 100 x 90, commission 220 ft x 10 (Murugan default), no step
check('total of side bill s4 = 10200 + 9000', bill('s4').total, 19200);
check('commission of side bill s4 = 220 x 10', bill('s4').comm, 2200);
// Portfolio, This rig (Main Rig), Month = October 2026 (b1, b2, b3, b4, b7, b8, b9)
const c = X.pfCalc();
check('Portfolio bills (Oct, main)', c.bs.length, 7);
check('Portfolio total billed (Oct, main)', c.st.total, 416360);
check('Portfolio received (Oct, main)', c.st.recv, 313800);
check('Portfolio pending (Oct, main)', c.st.bal, 101800);
check('Portfolio commission (Oct, main)', c.st.comm, 30290);
check('Portfolio expenses incl. Other expenses (Oct)', c.ex.total, 86180);
check('Portfolio Other expenses (Oct)', c.ex.other, 15900);
check('Portfolio profit = received - expenses - commission', c.profit, 313800 - 86180 - 30290);
check('Portfolio profit (hand total)', c.profit, 197330);
const ft = X.stats(X.periodBills()).ft;
check('Feet, 7inch depth over all lines (Oct, main)', ft.depth['7inch'], 1150);
check('Feet, 8inch depth over all lines (Oct, main)', ft.depth['8inch'], 1080);
check('Feet, 9inch depth over all lines (Oct, main)', ft.depth['9inch'], 410);
check('Feet, depth total (Oct, main)', ft.depthTotal, 2640);
check('Feet, PVC 7inch (Oct, main)', ft.pvc['7inch'], 360);
check('Feet, PVC 8inch (Oct, main)', ft.pvc['8inch'], 410);
// agent filter = Karthik (b3, b7, b8, b9)
X.S.pr.agent = 'a3';
const k = X.pfCalc();
check('Karthik bills (Oct, main)', k.bs.length, 4);
check('Karthik total billed', k.st.total, 41260 + 35000 + 54450 + 44000);
check('Karthik received', k.st.recv, 20000 + 15000 + 30000 + 40000);
check('Karthik pending', k.st.bal, 21000 + 20000 + 24450 + 4000);
check('Karthik commission', k.st.comm, 3300 + 3420 + 4410 + 5000);
X.S.pr.agent = 'all';
// agent filter sheet: counts come from the scope before the agent filter
const sc = X.pfScopeBills();
check('Agent sheet: bills in scope', sc.length, 7);
check('Agent sheet: Murugan bills (b1, b4)', sc.filter(b => b.ag === 'a1').length, 2);
check('Agent sheet: Prakash bills (none)', sc.filter(b => b.ag === 'a4').length, 0);

// v2.0.3 agent view, 3 months (1 Aug to 31 Oct 2026), Karthik (b10 Aug, b6 Sep, b3, b7, b8, b9 Oct)
X.S.pr.range = '3m'; X.S.pr.agent = 'a3';
const v = X.pfCalc();
check('Karthik 3 mo bills', v.bs.length, 6);
check('Karthik 3 mo total = 36000 + 50000 + 41260 + 35000 + 54450 + 44000', v.st.total, 260710);
check('Karthik 3 mo received = 20000 + 50000 + 20000 + 15000 + 30000 + 40000', v.st.recv, 175000);
check('Karthik 3 mo pending = 260710 - 175000 - 260 less', v.st.bal, 85450);
check('Karthik 3 mo commission = 3220 + 3000 (manual) + 3300 + 3420 + 4410 + 5000', v.st.comm, 22350);
check('Karthik 3 mo agent profit = received - commission', v.st.recv - v.st.comm, 152650);
check('Karthik 3 mo expected = billed - less - commission', v.st.total - v.less - v.st.comm, 238100);
check('commission of b10 (depth 250 x 10 + hand-typed PVC 90 x 8)', bill('b10').comm, 3220);
X.S.pr.agent = 'all';
const o = X.pfCalc();
check('All agents 3 mo received (424,800)', o.st.recv, 424800);
check('All agents 3 mo commission (39,390)', o.st.comm, 39390);
check('All agents 3 mo expenses (121,505)', o.ex.total, 121505);
check('All agents 3 mo profit after expenses = 424800 - 121505 - 39390', o.profit, 263905);
// CommissionRecalc: PVC 8inch price of Karthik 6 -> 7 changes only b8 (its auto line 60 x 6 -> 60 x 7); b10 PVC is 7inch
const copy = a => JSON.parse(JSON.stringify(a));
let oldA = copy(X.agent('a3')), newA = copy(oldA); newA.pr['pvc:8inch'] = 7;
Object.assign(X.agent('a3'), newA);
check('recalc PVC 8inch 6 -> 7 changes 1 bill', X.recalcAgentBills(oldA, X.agent('a3')), 1);
check('b8 commission = 200x10 + 150x11 + 80x5 + 60x7', bill('b8').comm, 4470);
// depth 7inch 10 -> 12 and PVC 7inch 5 -> 6: b10 depth follows, its hand-typed PVC rate 8 stays, manual b6 is skipped
oldA = copy(X.agent('a3')); newA = copy(oldA); newA.pr['depth:7inch'] = 12; newA.pr['pvc:7inch'] = 6;
Object.assign(X.agent('a3'), newA);
check('recalc depth 7inch and PVC 7inch changes 5 bills (b10, b3, b7, b8, b9; b6 is manual)', X.recalcAgentBills(oldA, X.agent('a3')), 5);
check('b10 = 250x12 + 90x8 (hand-typed line keeps 8)', bill('b10').comm, 3720);
check('b6 manual commission stays', bill('b6').comm, 3000);
check('b3 = 280x12 + 100x6', bill('b3').comm, 3960);
check('b7 = 260x12 + 60x6', bill('b7').comm, 3480);
check('b8 = 200x12 + 150x11 + 80x6 + 60x7', bill('b8').comm, 4950);
check('b9 = 320x12 + 150x12', bill('b9').comm, 5640);
// Murugan default depth rate 10 -> 11: main bills with a depth line without a type price (b1, b4) and side bills (s2, s4) follow
oldA = copy(X.agent('a1')); newA = copy(oldA); newA.cd = 11;
Object.assign(X.agent('a1'), newA);
check('recalc Murugan default depth 10 -> 11 changes 4 bills (b1, b4, s2, s4)', X.recalcAgentBills(oldA, X.agent('a1')), 4);
check('b1 = 350x11 + 120x5', bill('b1').comm, 4450);
check('side s4 = 220 x 11', bill('s4').comm, 2420);
console.log(ok ? 'RESULT: logic freeze holds and hand checks pass' : 'RESULT: LOGIC BLOCK CHANGED OR HAND CHECK FAILED');
process.exit(ok ? 0 : 1);
