# Mockup progress (checkpoints, newest last)

Resume rule: this file plus `rigledger_apple_mockup.html` are the whole state. The v1 file at `docs/design/ref/mockup-v1/rigledger_android_mockup.html` is no longer the logic baseline (since the 2.0.2 update the baseline is `qa/logic-baseline-v2.0.2.txt`; the 2.0.1 copy stays for history) and must not be edited from here. Nothing under `lib/` was touched.

Authoring note: the file was assembled once from parts kept ignored by git (CSS, core, ledger, portfolio/agents/settings, accounts, dev), with the logic block copied from the baseline by line range. After the first assembly it is edited directly. `qa/logic-diff.mjs` re-proves the freeze at any time.

## Status by J group (all DONE; 117 screens after the 2.0.2 update, 111 after 2.0.1, 91 before: 68 from v1, 23 added for the Apple direction, 20 added for 2.0.1)

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
