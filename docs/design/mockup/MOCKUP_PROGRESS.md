# Mockup progress (checkpoints, newest last)

Resume rule: this file plus `rigledger_apple_mockup.html` are the whole state. The v1 file at `docs/design/ref/mockup-v1/rigledger_android_mockup.html` is no longer the logic baseline (since the 2.0.4 update the baseline is `qa/logic-baseline-v2.0.4.txt`; the 2.0.1, 2.0.2 and 2.0.3 copies stay for history) and must not be edited from here. Nothing under `lib/` was touched.

Authoring note: the file was assembled once from parts kept ignored by git (CSS, core, ledger, portfolio/agents/settings, accounts, dev), with the logic block copied from the baseline by line range. After the first assembly it is edited directly. `qa/logic-diff.mjs` re-proves the freeze at any time.

## Status by J group (all DONE; 128 screens after the 2.0.4 update, 121 after 2.0.3, 117 after 2.0.2, 111 after 2.0.1, 91 before: 68 from v1, 23 added for the Apple direction, 20 added for 2.0.1)

| J group | Screens | Status | Notes |
|---|---|---|---|
| Ledger tab | 9 | DONE | ring card, 2 x 2 metric cards, depth tiles, day groups with sticky headers and swipe actions, calendar, sheets |
| Bill forms | 7 | DONE | full height sheets, live total, pinned pill, payment and agent sheets, delete alert |
| Side ledger | 8 | DONE | four lists, four forms, gradient tiles on the Side Ledger home |
| Portfolio | 4 | DONE | rig pill (B1), pinned cards, insight cards with scrub chart (needs logic LR-21, LR-22), donut |
| Agents (inside Portfolio) | 6 | DONE | 2.0.1: the Agents tab was removed; section in Portfolio Overview, detail sheet, add and edit with per-type prices, delete |
| Account Ledger | 26 | DONE | all cb screens; date picker sheet (B2, LR-02); calculator as round keys |
| Settings | 10 | DONE | Drive hero card (connected, not connected, error), Appearance row (LR-23), Rigs, exports |
| Apple direction: states (new) | 14 | DONE | empty, loading, error for every list |
| Apple direction: overlays (new) | 9 | DONE | row actions, full value popover, alerts, appearance, date picker |
| Agent view (v2.0.3, new) | 4 | DONE | 3 month agent view, manual commission bill, empty state, Edit Agent dialog |
| Step Rates and entry rig (v2.0.4, new) | 7 | DONE | Step Rates (default, edited), reset dialog, feet and commission by type, entry form with Rig dropdown, linked entry (rig locked), ledger list with rig names |

## Checkpoint 2: Android platform pass (2026-10-13)

Decisions applied: gap 12; sticky day headers ship; ONE Dev toggle "Glass blur" default OFF (solid 94 percent surface plus hairline; profile on the reference Android device before turning it on); macOS dropped (CSS archived in `archive/`).

Android changes done: Inter vendored and first in the stack (OFL, `fonts/`); frame 412 x 892 dp and 360 x 800 dp, 8 px bezel, no notch; edge-to-edge 28 dp status bar with Android icons; bottom inset token (24 dp gesture pill, or 3-button bar 48 dp), tab bar and sticky buttons above it; System back button plus Escape (keyboard, popover, dialog or sheet, screen, nothing on a root tab); 48 dp targets; pressed overlay on every tappable (no scale); 300 dp keyboard simulation with scroll-into-view; theme follows the system; iOS-only copy and shortcuts removed; pinned metric cards lost their chevron icon.

## Verification (2026-10-13)

| Check | Result |
|---|---|
| `node qa/token-audit.mjs` | OK |
| `node qa/logic-diff.mjs` | logic block and J registry identical to v1 |
| `node qa/smoke.mjs` | 91 screens, no errors |
| `node qa/shoot.mjs` (412 dp, light and dark) | 0 issues |
| `--stress --ts 2` | 0 issues (Inter, overflow report empty) |
| `--stress --ts 1.3` | 0 issues |
| `--width 360` and `--width 360 --stress --ts 2` | 0 issues (after calendar cells were widened to 49 dp) |
| `--nav3` | 0 issues |
| `--blur` | 0 issues |

Every run includes: overflow and clipping, text under 11 px, targets under 48 dp, contrast under 4.5:1, and the keyboard check (each text field focused with the simulated keyboard, field and primary button stay visible). No form needed fixing for the keyboard. Issues fixed on the way: tab bar hidden behind the 3-button bar, completed note rows 37 dp tall, calendar cells 46 dp wide at 360 dp.

Screenshots and contact sheets: `docs/design/ref/qa/` (not in the repo).

## Decisions after the Android pass

Root-tab back leaves the app (Android default); predictive back enabled in the first Android build; reference device is a mid-range phone for blur profiling. No questions open.

## Checkpoint 3: update to app version 2.0.1 (2026-10-13)

Source of truth: `docs/v2.0.1-review.md` and the Flutter code (read only). The mockup now matches 2.0.1+6. Per item:

1. Version text is 2.0.1 (page title, dev panel title, About "Version 2.0.1 (build 6)", Settings row).
2. Ledger page: the month or year arrows (or the custom range text) and a small icon Daily/Calendar toggle share one row; the ring card and 2 x 2 metric cards became one slim sideways scrolling card (Total, Received, Balance, Commission, plus Total Depth on a side bore rig); a collapsible "Feet: Depth X | PVC Y | MS Z" bar expands to "Depth by type", "PVC by type", "MS pipe by type" chips (`7"`, `9"`, zero as `0 ft`); side bore has no drop down. A 9inch depth type and a 9 inch bill (1043, Karthik) were added.
3. Bill cards have a commission strip (marked "(manual)" for bill 1037, per-kind amounts at the right). Bill form: breakdown box under the three rate fields with an amber "manual" tag, Calculation Preview has a "Commission (not in total)" block, Type dropdowns list the user-defined types (the bill's own type is always kept).
4. Settings > Ledger Types: three sections with Add, Rename, Delete (all error texts from the code), per depth type a step rate choice (none, 7 inch table, 8 inch table). Add and rename really change the lists, bills and step rates in the page; delete is refused while bills use a size.
5. Agents tab removed (4 tabs). Portfolio Overview has the Agents section (all agents, a 4th agent "Prakash" has no bills, "Add agent" in the header), the agent detail sheet (name, phone, notes, This period, Commission per foot with per-type prices and "(other sizes)" defaults, Delete, Edit), Add/Edit agent with one price field per type plus defaults. Choosing an agent on a bill fills the rates from that agent's price for the chosen type, and changing a type re-applies it unless the rate was typed.
6. Portfolio: the rig pill (dropdown arrow, Switch Rig sheet) is no longer flagged "needs logic"; This rig / All rigs are two large pills with icons and a hint line; the agent filter lists only agents with bills in the scope and resets on a scope or rig change; expenses include Other expenses.
7. Other expenses: Side Ledger category tile (receipt icon, new token `--c-oth`), Add Entry option "Other" (5 on main bore, 4 on side bore), Other Expenses list (summary Entries/Total/Paid/Pending, date range filter, swipe rows), Add and Edit Other Expense form, Portfolio expenses insight, profit, Side Ledger mini pie "Other" and detail card "Other expenses", CSV and PDF export type "Other expenses" (the PDF summary figures are now computed from the dataset instead of fixed text).
8. Account Ledger: already in the same Apple look as the ledger pages, so only the Save behaviour changed: outlined "Save and add another" plus filled "Save" (1 second "Saved" snack), empty amount shows the inline "Enter an amount".
9. The screen jump list has 111 entries including all the above (see SCREEN_MAP.md, section v2.0.1).

### Intentional logic changes (the baseline was updated deliberately)

`qa/logic-baseline-v2.0.1.txt` is the new frozen copy of the data and derived block. Changes against the v2.0.0 block: `AG` got per-type prices (`pr`) and a 4th agent; new `TYPES`, `STEPT` (step table per depth type, 9inch has none), `rateFor`; `stepFor` follows `STEPT`; bills 1037 (manual commission 3000) and 1043 (9inch) were added and commission uses the agent price for the bill's type; `SL.other` entries; `feetTotals` and `feetBy` replace the fixed 7"/8" sums in `stats`; `expenses` includes `other`, so `pfCalc` profit includes Other expenses. Everything else (calcMain, cbCalc and so on) is unchanged. The v1 J registry check was dropped (the registry grew).

### Hand check (recomputed outside the page, `qa/logic-diff.mjs` asserts the same numbers)

- Bill 1043 commission: 260 ft x 12 (Karthik, 9 inch price) + 60 ft x 5 (PVC 7 inch) + 0 ft x 2 = 3,120 + 300 = 3,420.
- Portfolio, This rig (Main Rig), Month = October 2026: received 40,000 + 78,800 + 20,000 + 90,000 + 15,000 = 243,800; commission 4,100 + 3,960 + 3,300 + 6,100 + 3,420 = 20,880; expenses diesel 20,280 + PVC 27,500 + bit 13,000 + hammer 9,500 + other 15,900 (9,000 + 4,500 + 2,400) = 86,180; profit = 243,800 - 86,180 - 20,880 = 136,740.

### Verification (2026-10-13)

| Check | Result |
|---|---|
| `node qa/token-audit.mjs` | OK |
| `node qa/logic-diff.mjs` | identical to the 2.0.1 baseline, 11 hand checks OK |
| `node qa/smoke.mjs` | 111 screens, no errors |
| `node qa/shoot.mjs` (412 dp, light and dark) | 0 issues |
| `--stress`, `--stress --ts 2`, `--stress --ts 1.3` | 0 issues |
| `--width 360` and `--width 360 --stress --ts 2` | 0 issues |
| `--nav3`, `--blur` | 0 issues |

Fixes found by the checks on the way: agent row with no bills was 43 dp tall (now 48), PDF summary amounts overflowed at 360 dp, 200 percent text and STRESS data (now wrap). `shoot.mjs` skips the edge-overflow check inside `.hscroll` (the sideways summary strip) like it does for `.chips` and `.swp`.

### Open

Nothing blocks. Not shown: custom step brackets (not editable in 2.0.1), the Side Ledger mini stat row of the Flutter screen (tiles carry the same numbers).

## Checkpoint 4: update to app version 2.0.2 (2026-10-20)

Source of truth: `docs/v2.0.2-review.md` and the Flutter code (read only). The mockup now matches 2.0.2+7. Per item:

1. Version text is 2.0.2 (build 7): page title, dev panel title, About, Settings row.
2. Several lines per bill. Main bore form: Depth, PVC and MS pipe each show line cards (Type, feet, rate; with several lines a header "Depth line 2" and a remove X), "Add Depth line", "Add PVC line", "Add MS Pipe line" buttons, "Step Rate" or "Step Rate, all depth lines" (sum of each depth line worked out alone), Calculation Preview with one row per line and a commission block with one row per line, Commission section with one rate field per line ("Depth 1 7inch rate", helper "200 ft = ₹2,000") and the breakdown box. An agent choice (new bill) fills each line from the agent price of its type, a type change re-applies it unless the rate was typed, a new line gets the agent price. Side bore form: depth lines only ("Depth (ft)", "Rate/ft"), "Add Depth line", commission rows "Depth 1", "Depth 2".
3. Dummy data: 1044 (Karthik, depth 200 ft 7inch + 150 ft 8inch, PVC 80 ft 7inch + 60 ft 8inch), 1045 (Karthik, depth 7inch 320 ft + 9inch 150 ft, step rate on the 7inch line only) and side bill 204 (two depth lines). Karthik got 8inch prices (depth 11, PVC 6). Every screen reads the same lines.
4. Ledger page: Depth chip "200ft (7inch) + 150ft (8inch)", PVC chip "7inch + 8inch", chips wrap, commission strip from the lines; feet strip and drop down count each line under its own type; filter sheet depth and PVC filters match any line; Ledger Types counts, rename and delete use every line; CSV and PDF export screens show a sample (type cells "7inch + 8inch", feet as sums, average rate).
5. Portfolio: one pill "Agent: All agents" (tinted when an agent is chosen) opens the sheet "Filter by agent" (search, All agents row, every agent including "no bills", sorted by total then name, check mark, "No agent matches"); the choice resets on a scope or rig change. Agent Edit saves for real (price edits show in "Commission per foot"); Delete removes the agent and deletes or reassigns its bills.
6. Screen jump list: 117 entries; new: two-depth-line bill form (1044), step on one line (1045), commission section with several lines, side bore two-line form, agent filter sheet, agent filter sheet with a search typed.

### Intentional logic changes (the baseline was updated deliberately)

`qa/logic-baseline-v2.0.2.txt` is the new frozen copy. Changes against the v2.0.1 block: bills hold `L` (lines `{c,t,f,r,k}`) instead of the flat `dt, d, dr, pt, p, pr, m, mr, cr` fields; new helpers `LN`, `linesOf`, `lfeet`, `lcomm`, `typesOf`, `hasType`, `stepSum`, `calcBill`; step rate is the sum per depth line (none on side bore), total, commission, feet by type, filters and `calcMain(side)` read the lines; new bills 1044, 1045 (main) and 204 (side); Karthik prices `depth:8inch` 11 and `pvc:8inch` 6; new `pfScopeBills()` (scope and period before the agent filter) used by `pfCalc` and the agent sheet. Numbers of the older bills are unchanged.

### Hand check (recomputed outside the page, `qa/logic-diff.mjs` asserts the same numbers)

- Bill 1044: depth 200 x 90 + 150 x 95 = 18,000 + 14,250; PVC 80 x 150 + 60 x 170 = 12,000 + 10,200; both depth lines are under 300 ft so step 0; total 54,450. Commission 200 x 10 + 150 x 11 + 80 x 5 + 60 x 6 = 2,000 + 1,650 + 400 + 360 = 4,410. Received 30,000, balance 24,450.
- Bill 1045: 320 x 90 + 150 x 100 = 28,800 + 15,000, step on the 7inch line 20 ft x 10 = 200, total 44,000; commission 320 x 10 + 150 x 12 = 5,000.
- Portfolio, This rig (Main Rig), October 2026 (bills 1039, 1040, 1041, 1042, 1043, 1044, 1045): total billed 416,360; received 313,800; commission 30,290; expenses 86,180; profit 313,800 - 86,180 - 30,290 = 197,330.
- Same with the agent filter Karthik (1040, 1043, 1044, 1045): total 174,710; received 105,000; pending 69,450; commission 16,130; profit card replaced by the note.
- Feet (Oct, main): depth 7inch 1,150, 8inch 1,080, 9inch 410, total 2,640; PVC 7inch 360, 8inch 410.

### Verification (2026-10-20)

| Check | Result |
|---|---|
| `node qa/token-audit.mjs` | OK |
| `node qa/logic-diff.mjs` | identical to the 2.0.2 baseline, 37 hand checks OK |
| `node qa/smoke.mjs` | 117 screens, no errors |
| `node qa/flows.mjs` | all click-through checks OK, no script errors |
| `node qa/shoot.mjs` (412 dp, light and dark) | 0 issues |
| `--stress`, `--stress --ts 2`, `--stress --ts 1.3` | 0 issues |
| `--width 360` and `--width 360 --stress --ts 2` | 0 issues |
| `--nav3`, `--blur` | 0 issues |

Fix found on the way: typing in the agent dialog after visiting a bill form called the form recalculation with no lines (guarded).

### Open

Nothing blocks. Not shown: per-line step rate editing, import and PDF per-line columns (the app has none). The older docs `docs/v2.0.2-review.md` ("mockups show one line per category") can now be updated by the developer.

## Checkpoint 5: update to app version 2.0.3 (2026-10-22)

Source of truth: `docs/v2.0.3-review.md` and the Flutter code (`agent_view.dart`, `portfolio_view.dart`, `commission_recalc.dart`, `agent_provider.dart`, `agent_dialogs.dart`, read only). The mockup now matches 2.0.3+8. Per item:

1. Version text is 2.0.3 (build 8): page title, dev panel title, About, Settings row.
2. Agent prices update existing bills: saving the Edit Agent dialog runs `recalcAgentBills` on the page data (same rule as `CommissionRecalc.changedBills`, see MOCKUP_NOTES.md) and shows "Agent updated" or "Agent updated. Commission changed on N bills" (1 bill singular). Ledger cards, summary strip, Portfolio and the agent view change with it.
3. Portfolio agent view (`agentView()`): choosing an agent in the pill sheet or tapping an agent row replaces the profit card, metric cards, expenses card, Agents section and definitions with the gradient header (name, period "01 Aug 2026 to 13 Oct 2026" or "All time", Commission earned, "All agents" back button, tune icon), the profit card (green or red, Expected, All agents after expenses, the note), Bills / Total and Received / Pending cards, the By month table (only when the period spans more than one month), one card per bill newest first (tap opens the form) and a totals row; empty case "No bills for NAME in this period". The Agents section rows have an info icon button (tooltip "Prices and details", opens the details sheet) and no chevron. `fitAll` no longer scales a figure below 11 px (it falls to the compact form instead; the STRESS month table needed it).
4. Screen jump list: 121 entries; new group "Agent view (v2.0.3)": 3 month Karthik, manual commission bill, no bills (empty), Edit Agent dialog. "Overview (agent filter)" is now "Overview (agent view, Murugan)".

### Intentional logic changes (the baseline was updated deliberately)

`qa/logic-baseline-v2.0.3.txt` is the new frozen copy. Changes against the v2.0.2 block: new bill `b10` (1036, Karthik, 18 Aug 2026, depth 250 ft 7inch x 90, PVC 90 ft 7inch x 150 with a hand-typed commission rate 8) so Karthik has bills in Aug, Sep and Oct; `LN(c,t,f,r,hk)` takes an optional hand-typed commission rate (`hk`, used when the dummy lines get their rate); `calcBill` rounds the commission to paise; new `agentPrice` and `recalcAgentBills(oldAgent,newAgent)`; `pfCalc(ag)` takes an optional agent id ('all' gives the overall figures used by the agent view). Numbers of the older bills and the October figures are unchanged (bill 1036 is in August).

### Hand check (recomputed outside the page, `qa/logic-diff.mjs` asserts the same numbers)

- Bill 1036: depth 250 x 90 = 22,500 (under 300 ft, no step), PVC 90 x 150 = 13,500, total 36,000. Commission 250 x 10 + 90 x 8 (hand-typed) = 2,500 + 720 = 3,220.
- Karthik, 3 Mo (1 Aug to 31 Oct, main rig; 1036, 1037, 1040, 1043, 1044, 1045): total 36,000 + 50,000 + 41,260 + 35,000 + 54,450 + 44,000 = 260,710; received 20,000 + 50,000 + 20,000 + 15,000 + 30,000 + 40,000 = 175,000; less 260; pending 260,710 - 175,000 - 260 = 85,450; commission 3,220 + 3,000 (manual) + 3,300 + 3,420 + 4,410 + 5,000 = 22,350.
- Agent profit = 175,000 - 22,350 = 152,650. Expected = 260,710 - 260 - 22,350 = 238,100.
- All agents, same period: received 424,800, commission 39,390, expenses 121,505 (diesel 33,855, PVC 40,250, bit 18,800, hammer 9,500, other 19,100); profit 424,800 - 121,505 - 39,390 = 263,905.
- Price edit, one bill: Karthik PVC 8inch 6 to 7 changes only 1044 (its auto line 60 ft): 200 x 10 + 150 x 11 + 80 x 5 + 60 x 7 = 4,470 (was 4,410).
- Price edit, several bills: Karthik depth 7inch 10 to 12 and PVC 7inch 5 to 6 change 5 bills; 1037 is skipped (manual 3,000); 1036 keeps its hand-typed 8: 250 x 12 + 90 x 8 = 3,720 (was 3,220); 1040 3,960; 1043 3,480; 1044 4,950; 1045 5,640; the agent view commission becomes 24,750.
- Murugan default depth 10 to 11 changes 4 bills (1042, 1039, side 202, side 204); side 204 = 220 x 11 = 2,420.

### Verification (2026-10-22)

| Check | Result |
|---|---|
| `node qa/token-audit.mjs` | OK |
| `node qa/logic-diff.mjs` | identical to the 2.0.3 baseline, 59 hand checks OK |
| `node qa/smoke.mjs` | 121 screens, no errors |
| `node qa/flows.mjs` | all click-through checks OK (67), no script errors |
| `node qa/shoot.mjs` (412 dp, light and dark) | 0 issues |
| `--stress`, `--stress --ts 2`, `--stress --ts 1.3` | 0 issues |
| `--width 360` and `--width 360 --stress --ts 2` | 0 issues |
| `--nav3`, `--blur` | 0 issues |

Fix found on the way: in STRESS data the By month Total figure was scaled to 10.2 px (under the 11 px floor); `fitAll` now uses the compact form instead of scaling below 11 px. Gotcha: in zsh a loop variable holding several flags must be expanded with `${=a}` or the flags reach `shoot.mjs` as one argument and the run silently tests the default mode.

### Open

Nothing blocks. Not verified: the real Flutter agent view on a device (the review lists the same gap). `docs/v2.0.3-review.md` item "The mockups under docs/design do not show the agent view yet" can now be removed by the developer.

## Checkpoint 6: update to app version 2.0.4 (2026-10-22)

Source of truth: `docs/v2.0.4-review.md` and the Flutter code (`step_rates.dart`, `step_rates_screen.dart`, `agent_view.dart` `_feetByType`, `cashbook_entry_form_screen.dart` `_rigField`, `cashbook_row.dart`, `payment_link_service.dart`, `cashbook_export_service.dart`, read only). The mockup now matches 2.0.4+9. Per item:

1. Version text is 2.0.4 (build 9): page title, dev panel title, About, Settings row, logic block header.
2. Settings has a "Step Rates" row above "Ledger Types" (subtitle "Extra rate beyond 300 ft, for each rig (new bills only)"). The Step Rates screen: Rig dropdown (main bore rigs), info box, two table cards (7 inch and 8 inch: "Step rate starts after", one row per 100 ft bracket with a remove X (disabled with one row), "Add bracket" = last row + growth, "After the last bracket, extra per ft grows by", live example), "Reset to standard" with the confirm alert, "Save" with the snacks "Step rates saved. New bills use them" and "Fill every rate with a number". `stepCalc` mirrors `StepTable.calculate`. A new bill (and a saved bill whose depth lines are edited) uses the current tables of its rig, a saved bill keeps its stored step rate (`b.stp`); see MOCKUP_NOTES.md.
3. Agent view: new card "Feet and commission by type" between the Bills / Total / Received / Pending cards and By month (the mockup had no feet card before): Depth, PVC and MS pipe groups, a header "Total N ft  |  ₹C", one chip per type with feet (`7"  1,350 ft` and "Commission ₹13,500"), the manual note when a bill in the view has a hand-typed commission. Karthik 3 Mo shows three depth types, two PVC types and MS pipe, so no dummy data was added for it.
4. Account Ledger entries have an optional rig (`v`): "Rig (optional)" row between notes and Account (sheet of No rig and the rigs), disabled with "Set from the bill" for linked income; rows show the rig (icon and name) under the time line; linked income of bills 1039 and 1042 has Main Rig; three hand-typed entries have a rig; Copy keeps the rig (now adds the copy to the data); Save and Save and add another keep it. The Report sheets describe the CSV Rig column and the PDF "Rig: NAME" line. Totals and balances are unchanged.
5. Screen jump list: 128 entries, new group "Step Rates and entry rig (v2.0.4)" with the 7 screens above; `SCREEN_MAP.md`, `MOCKUP_NOTES.md` and `TOKENS.md` (section 11) updated.

### Intentional logic changes (the baseline was updated deliberately)

`qa/logic-baseline-v2.0.4.txt` is the new frozen copy. Changes against the v2.0.3 block: the fixed `STEP` table is replaced by `STDT` (standard tables), `STEPR` (tables per main bore rig, `{th, ex, bey}`), `cloneTb`, `stepCalc` (adds the growth after the last bracket, which the old function did not have; no dummy bill is that deep), `stepTab`; `stepFor(t,ft,rig)` and `stepSum(L,side,rig)` take the rig; each bill stores its step rate once at load (`b.stp`) and `calcBill` uses it (`b.step=b.stp`), so editing the tables never changes a saved bill; `calcMain` uses the stored step rate of a saved bill until a depth line is edited (`F.keepStep`, `F.depthEd`) and the rig of the form (`F.rig`); new `feetComm(bs)` (feet and commission per category and type, rounded to paise); account ledger entries 3, 6, 9, 13, 14 and 15 got a rig (`v`). Every older number is unchanged (the 59 hand checks of 2.0.3 still pass).

### Hand check (recomputed outside the page, `qa/logic-diff.mjs` asserts the same numbers)

- Step rate, default tables: 350 ft 7inch = 50 x 10 = 500; 420 ft 8inch = 100 x 10 + 20 x 20 = 1,400 (bills 1042 and 1041 keep exactly these).
- One edited bracket: 7inch first bracket 10 to 15 gives 350 ft = 50 x 15 = 750; 8inch second bracket 20 to 25 gives 420 ft = 1,000 + 20 x 25 = 1,500. After both edits the 13 main bills, the ledger cards and the Portfolio numbers are identical to before (checked in the script), a new 350 ft 7inch line costs 750.
- Beyond the last bracket (7inch, 1,050 ft): 27,000 (300 to 900 ft) + 100 x (90 + 20) + 50 x (90 + 40) = 27,000 + 11,000 + 6,500 = 44,500; with first bracket 15 and growth 30: 27,500 + 100 x 120 + 50 x 150 = 47,000; with a seventh bracket 110: 27,500 + 100 x 110 + 50 x 130 = 45,000.
- Defaults shown by the live example: 1,000 ft 7inch = 27,000 + 100 x 110 = 38,000; 8inch = 31,000 + 100 x 120 = 43,000. Example feet = start + 100 x (rows + 1).
- Karthik, 3 Mo (bills 1036, 1037, 1040, 1043, 1044, 1045), feet and commission by type: Depth 7inch 1,350 ft (250 + 300 + 280 + 200 + 320), 2,500 + 3,000 + 2,800 + 2,000 + 3,200 = 13,500; 8inch 150 ft x 11 = 1,650; 9inch 410 ft (260 + 150), 3,120 + 1,800 = 4,920; Depth total 1,910 ft, 20,070. PVC 7inch 430 ft (90 + 100 + 100 + 60 + 80), 90 x 8 (hand-typed) + 500 + 500 + 300 + 400 = 2,420; 8inch 60 ft x 6 = 360; PVC total 490 ft, 2,780. MS pipe 6inch 20 ft x 2 = 40. Sum 22,890 against the agent commission 22,350: the difference 540 is bill 1037, whose commission was typed as 3,000 while its lines give 3,540 (this is why the card carries the note).

### Verification (2026-10-22)

| Check | Result |
|---|---|
| `node qa/token-audit.mjs` | OK |
| `node qa/logic-diff.mjs` | identical to the 2.0.4 baseline, 86 hand checks OK |
| `node qa/smoke.mjs` | 128 screens, no errors |
| `node qa/flows.mjs` | all click-through checks OK (101), no script errors |
| `node qa/shoot.mjs` (412 dp, light and dark) | 0 issues |
| `--stress`, `--stress --ts 2`, `--stress --ts 1.3` | 0 issues |
| `--width 360` and `--width 360 --stress --ts 2` | 0 issues |
| `--nav3`, `--blur` | 0 issues |

Fix found on the way: the locked Income/Expense segment of a linked entry (new screen "linked entry form") had 4.42:1 contrast at 55 percent opacity; it is now 65 percent. The flows script reloads the page before its 2.0.4 part because the 2.0.3 part edits agent prices.

### Open

Nothing blocks. Not verified: the Flutter screens on a device (the review lists the same gap). `docs/v2.0.4-review.md` "Open: the mockups under docs/design do not show Step Rates, feet by type in the agent view or the entry rig yet" can now be removed by the developer (the other mockup under `docs/design/ref/mockup-v1/` is updated by another agent). Rig dropdown on Step Rates lists one rig because the dummy data has one main bore rig.
