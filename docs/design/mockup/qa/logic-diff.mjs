// Proves the data and derived-logic block is frozen, and that its numbers match hand-computed values.
// usage: node logic-diff.mjs            check against qa/logic-baseline-v2.0.2.txt
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
const basePath = path.join(here, 'logic-baseline-v2.0.2.txt');
const startMark = "(checked by qa/logic-diff.mjs against qa/logic-baseline-v2.0.2.txt) ================= */\n";
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
vm.runInContext(logic + '\nthis.__x={BILLS:BILLS,S:S,pfScopeBills:pfScopeBills,pfCalc:pfCalc,expenses:expenses,mrange:mrange,stats:stats,periodBills:periodBills,rateFor:rateFor,AG:AG,feetTotals:feetTotals};', ctx);
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
console.log(ok ? 'RESULT: logic freeze holds and hand checks pass' : 'RESULT: LOGIC BLOCK CHANGED OR HAND CHECK FAILED');
process.exit(ok ? 0 : 1);
