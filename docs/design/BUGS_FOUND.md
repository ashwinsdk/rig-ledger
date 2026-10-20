# Bugs Found (B6)

> RECONCILED 2026-10-13. Scope is Android only; macOS is frozen. Entries that exist only in the macOS shell are OUT OF SCOPE (not fixed, not deleted): B-01 (desktop rig switch race), B-05 (Cmd+F), B-06 (New Entry on inert tabs), B-07 (Cmd 1-4 hint), B-08 (sidebar keyboard access), B-16 (Cmd+2 refresh), D-07 (`PlatformHelper.isDesktop`), G2-B20 (desktop hub navigation). A later decision on macOS (DESIGN_DIRECTION_APPLE.md Q-O9, new entry D-08 "macOS fate") decides them. Approved by the developer on 2026-10-13 for Phase 1: G3-B01 (CSV import zeroing depth, rates, extra charges, LR-31), B-G1-01 (double-tap Save duplicates, LR-32, six forms), B-03 (calendar totals mixing months, LR-33). The data-touching list (section 4) has 18 entries (an earlier summary said 21); each needs plan mode and an explicit yes, never batched. Other bug fixes follow MIGRATION_PLAN.md Phase 4 in the order crash, wrong number, data loss by UI guard, UI only, cosmetic.


Found by reading the code, `flutter analyze` output (210 infos, 0 errors, 0 warnings on 2026-10-12: 140 deprecated_member_use, 53 prefer_const_constructors, 2 use_build_context_synchronously, others minor), the known gaps in `.claude/tasks/BACKLOG.md` and `docs/v2.0.0-review.md`, and the visual audit on the Android emulator. NOTHING WAS FIXED. Nothing was run on macOS (missing `GoogleService-Info.plist`), so macOS-only items are marked UNVERIFIED. Items marked UNVERIFIED come from reading, not from reproducing.

ID prefixes: `B-` lead audit (shells, Ledger, Portfolio, core), `D-` known data, sync and platform items from BACKLOG.md, `B-G1-` forms and side ledger, `G2-B` Account Ledger, `G3-B` agents, settings, exports, stats and theme. Each entry keeps its original fields: severity, where, how to reproduce, expected versus actual, proposed fix, risk, and whether it touches data, sync or models.

## 1. Summary

| Severity | Safe to schedule (UI only, no data, sync or model change) | Needs explicit approval (touches data, sync or models) |
|---|---|---|
| Crash | 4 | 1 |
| Wrong number | 12 | 6 |
| Data loss | 6 | 7 |
| UI only | 52 | 1 |
| Cosmetic | 12 | 3 |
| Total | 86 | 18 |

Severity meaning: crash = exception or assertion; wrong number = a figure the user reads or a stored figure is wrong or misleading; data loss = records can be lost, duplicated, overwritten or exposed; UI only = layout, accessibility, feedback; cosmetic = polish, copy, maintenance.

## 2. Proposed fix order

Order is by risk to the user first, then by cost and risk of the fix. Only section 3 items are proposed for the migration plan (T-U80 and later) without further approval of the data section; section 4 waits for explicit approval.

1. Crash (section 3.1): date picker range assertions, setState after await, empty-list guards. Smallest fixes, highest value.
2. Wrong number, UI side (3.2): calendar day totals across months (hide Calendar for non-Month periods), preview total, NaN percent, feet format rule, stale rig switch (shared `switchRig`, LR-01), CSV import mapping display. Each is verified against the parity lines before and after.
3. Data loss that is fixed with a UI guard only (3.3): double-tap guards on every Save, Transfer and Add buttons (a `_saving` flag), discard-changes prompt (behavior change, needs a yes), destructive defaults (agent delete default option), restore and clear-all wording (copy only).
4. UI only (3.4): tap targets, overflow at 200 percent, contrast, focus and keyboard access, feedback after actions, empty and filtered states. Most are resolved by the shared components in MIGRATION_PLAN.md, so they are fixed in the screen tasks rather than as separate commits.
5. Cosmetic (3.5): copy, pluralization, dead code, deprecated API sweep.
6. Section 4 (data, sync, models) only after the developer approves each item, one commit each, each with its own test and a restore-from-backup rehearsal.

## 3. Bugs that can be fixed without touching data, sync or models

### 3.1 Crash (4)

| ID | Title |
|---|---|
| B-G1-02 | Date picker assertion for dates outside 2020..now+365 (side bore and side ledger forms and filters) |
| G2-B13 | Account Summary and Calendar crash when there are no books |
| G3-B11 | setState after await without mounted check (Drive card) |
| G3-B24 | Export: zero columns allowed in PDF ledger export |

#### B-G1-02 Date picker assertion for dates outside 2020..now+365 (side bore and side ledger forms and filters)

- Severity: crash (debug assertion; in release the picker misbehaves). UNVERIFIED (not reproduced)
- Where: `side_bore_form_screen.dart:213-218`, `diesel_form_screen.dart:100-105` and `:113-118`, same in `pvc/bit/hammer_form_screen.dart` (`_selectDate`), `diesel_list_screen.dart:525-530` and the three other filter sheets.
- Repro: edit an entry dated before 1 Jan 2020 (imported or backdated) or dated more than a year ahead, tap the Date field.
- Expected: picker opens at the entry date. Actual: `initialDate` is outside `[firstDate, lastDate]`, `showDatePicker` asserts. The main form uses 2000..2100 (`ledger_form_screen.dart:318-319`) so it is not affected.
- Proposed fix: clamp `initialDate` into the range inside a shared `pickRigDate` helper, or widen to the main form range.
- Risk: low (clamp) / low (widen). Touches data/sync/models: no.

#### G2-B13 Account Summary and Calendar crash when there are no books

- Severity: crash - UNVERIFIED (default book recreation may prevent an empty list)
- Where: cashbook_account_summary_screen.dart:31-32, cashbook_calendar_screen.dart:36-37 (`books.firstWhere(..., orElse: () => current ?? books.first)`)
- If `cashBooksProvider` is empty and `currentCashBookProvider` is null, `books.first` throws StateError. DatabaseService ensures a default book (T-CB02) so it should be unreachable; kept for completeness.
- Fix: guard with an `EmptyState`.
- Touches data: no

#### G3-B11 setState after await without mounted check (Drive card)

- Severity: crash (assertion in debug) / UI.
- Where: settings_screen.dart:754-757 (auto backup switch), 530-533 (`_signOut`: mounted checked before the await only).
- Fix: `if (!mounted) return;` before `setState`.
- Risk: none. Touches data: no.

#### G3-B24 Export: zero columns allowed in PDF ledger export

- Severity: crash or empty file (UNVERIFIED).
- Where: pdf_export_screen.dart:537 ("None"), 269 (button enabled when entries > 0), 946 (`columns = _selectedColumns`).
- Fix: disable Export when no column is selected (UI guard in the redesign).

### 3.2 Wrong number (12)

| ID | Title |
|---|---|
| B-01 | Desktop rig switch does not await the switch, so the first refresh can load the old rig |
| B-02 | Three rig-switch handlers do different things |
| B-03 | Calendar day totals add up different months when the period is not Month |
| B-09 | Feet shown in two formats: bill card raw double, summary whole feet |
| B-16 | Switching area with Cmd+2 skips the refresh that clicking Portfolio runs |
| B-G1-03 | Calculation Preview Total ignores a manually edited Total |
| B-G1-09 | Side ledger summary Pending nets overpayments against dues |
| G2-B05 | Transfer can be submitted twice |
| G2-B06 | Note form can create duplicate notes |
| G2-B11 | Items dialog silently discards a half-typed row |
| G3-B19 | Stats donut percentages show "NaN%" when the total is 0 |
| G3-B23 | Stats multi-type tally can exceed total count (UNVERIFIED semantics) |

#### B-01 Desktop rig switch does not await the switch, so the first refresh can load the old rig

- Severity: wrong number (stale data after switching rig on macOS) - UNVERIFIED (macOS not runnable here)
- Where: `lib/features/navigation/desktop_shell.dart:107-118`; `CurrentVehicleNotifier.setCurrentVehicle` is `async` and writes `currentVehicleId` with `await _settingsBox.put(...)` (`vehicle_provider.dart:58-61`, `database_service.dart:139`); `getAllLedgerEntries` reads `currentVehicleId` (`database_service.dart:201-203`).
- Reproduce: macOS with two rigs, open Ledger, pick the other rig in the title bar.
- Expected: Ledger, Side Ledger, Portfolio show the new rig. Actual (likely): the eight refresh calls run immediately after an un-awaited `setCurrentVehicle`, before the settings write has completed, so lists can still be filtered by the previous rig until another refresh happens. The mobile sheet awaits the call first (`combined_home_screen.dart:1160-1168`).
- Proposed fix: one shared `switchRig` that awaits first (LR-01).
- Risk: low. Touches data/sync/models: no (call order only; no data written differently)

#### B-02 Three rig-switch handlers do different things

- Severity: wrong number (stale filters after switching) / UI only
- Where: Ledger sheet `combined_home_screen.dart:1160-1176` (clears search and filter; refreshes ledger, diesel, pvc, bit, hammer, agents; not `vehiclesProvider`, not `currentVehicleProvider`), desktop title bar `desktop_shell.dart:107-118` (no clearing; refreshes ledger, agents, diesel, pvc, bit, hammer, vehicles), CONVENTIONS.md (eight providers including `currentVehicleProvider`).
- Reproduce: apply a filter on Rig A (agent X), switch rig on macOS: the filter stays active on Rig B and can show an empty list with the filter dot lit.
- Expected: same result from every entry point. Actual: differs by platform.
- Proposed fix: LR-01.
- Risk: low. Touches data/sync/models: no

#### B-03 Calendar day totals add up different months when the period is not Month

- Severity: wrong number
- Where: `calendarDayTotalsProvider` (`ledger_provider.dart:337-347`) keys totals by `entry.date.day` only, over `filteredLedgerEntriesProvider` (which for 3 Mo, 6 Mo, Year, Custom, All spans several months); `CalendarViewWidget` draws the grid for `selectedMonthProvider` and reads `dayTotals[day]`.
- Reproduce: bills on 12 Sep and 12 Oct. Period 3 Mo (or All), toggle Calendar. The cell for day 12 of the selected month shows the sum of both bills.
- Expected: a cell shows only bills of that calendar date, or the Calendar view is limited to the Month period. Actual: totals merge across months.
- Proposed fix: (UI only, no logic change) hide the Daily/Calendar toggle's Calendar option unless the period is Month, or show a note; (logic) key the provider by full date. 
- Risk: low for the UI option, medium for the provider change. Touches data/sync/models: no (provider only)

#### B-09 Feet shown in two formats: bill card raw double, summary whole feet

- Severity: wrong number (display inconsistency)
- Where: `ledger_list.dart` depth text `'${entry.depthInFeet}ft'` (no formatting, can show `500.0` or floating noise) versus `summary_row.dart` `NumberFormat('#,##0')` (rounds fractional feet, e.g. 450.5 shows as 450 or 451 by rounding rule).
- Reproduce: a bill with 450.5 ft depth: card shows `450.5ft`, summary 7" Depth shows a rounded value, so sums of the cards do not visibly add up to the tile.
- Expected: one rule (decision LR-13: whole feet with up to 1 decimal where fractional).
- Fix: `RigFormat.feet` (UI only). No calculation change.
- Risk: low. Touches data/sync/models: no

#### B-16 Switching area with Cmd+2 skips the refresh that clicking Portfolio runs

- Severity: wrong number (stale Portfolio) - UNVERIFIED
- Where: `desktop_shell.dart` sidebar `onItemSelected` refreshes five providers when index 1; the Cmd+2 binding only sets `desktopNavIndexProvider`.
- Fix: single area-switch function.
- Risk: low. Touches data/sync/models: no

#### B-G1-03 Calculation Preview Total ignores a manually edited Total

- Severity: wrong number (display)
- Where: `ledger_form_screen.dart:1131-1143`
- Repro: enter depth 100, rate 50 (Preview Total 5,000.00), type 4,500 into the Total field.
- Expected: preview and field agree or the preview says the Total is manual. Actual: the Preview "Total" row always shows the computed 5,000.00 while the Total field and the saved bill use 4,500.
- Proposed fix: relabel the row "Calculated total" and add a caption when `_isTotalManuallyEdited` and the values differ (copy only; no calculation change).
- Risk: none. Touches data/sync/models: no.

#### B-G1-09 Side ledger summary Pending nets overpayments against dues

- Severity: wrong number (UNVERIFIED: depends on intended definition of Pending)
- Where: `diesel_list_screen.dart:109-114` (`totalPending += entry.pending`), same loop in the PVC, Bit and Hammer lists
- Repro: two diesel bills, one with pending +5,000 and one overpaid with pending -2,000 (advance). Summary Pending shows 3,000.
- Expected (if "Pending" means money still owed): 5,000, with the advance shown separately. Actual: 3,000 because the negative pending reduces the sum.
- Proposed fix: logic change, not a UI change; see `logic_g1.md` L-06. Redesign keeps the number as is.
- Risk: medium. Touches data/sync/models: no (a calculation in the screen).

#### G2-B05 Transfer can be submitted twice

- Severity: wrong number (duplicate transfer pair)
- Where: lib/features/cashbook/cashbook_transfer_screen.dart:51-74, button at 149-157
- Reproduce: enter amount, double-tap Transfer quickly on a slow device or desktop double click.
- Expected: one pair of linked entries. Actual: `_transfer` awaits `transfer(...)` and only clears the fields afterward; the button has no busy flag, so two taps before the first await completes can send two calls. UNVERIFIED (provider call is local and fast, so the window is small).
- Fix: local `_busy` bool that disables the button, like `_saving` in the entry form (cashbook_entry_form_screen.dart:199-203).
- Risk: low. Touches data/sync/models: no (UI guard only)

#### G2-B06 Note form can create duplicate notes

- Severity: wrong number (duplicate note)
- Where: lib/features/cashbook/cashbook_note_form_screen.dart:40-57, button at 139-140
- Reproduce: type a note, double-tap Save.
- Expected: one note. Actual: no busy flag; `addNote` is awaited and the route is popped afterward. UNVERIFIED for the same reason as G2-B05.
- Fix: `_saving` flag disabling Save.
- Touches data: no

#### G2-B11 Items dialog silently discards a half-typed row

- Severity: wrong number (the entry amount is set from the items total, which excludes the unsaved row)
- Where: lib/features/cashbook/cashbook_items_dialog.dart:85-103, 194-196
- Reproduce: Add Items, type Item, Quantity, Rate but do not press Add, press OK. The row is dropped and the amount is set from the other rows only (cashbook_entry_form_screen.dart:129-137).
- Expected: either add the pending row or warn. Fix: on OK, if the three fields are filled, ask or add the row; (UI only, behavior change small: listed as Q2 in the final report).
- Touches data: no

#### G3-B19 Stats donut percentages show "NaN%" when the total is 0

- Severity: wrong number (display).
- Where: lib/features/stats/stats_screen.dart:622, 645 (`entry.value / total * 100`, total can be 0 when bills have total 0).
- Fix: `total > 0 ? ... : 0` display guard. Risk none. Touches data: no.

#### G3-B23 Stats multi-type tally can exceed total count (UNVERIFIED semantics)

- Severity: wrong number (possible).
- Where: stats_screen.dart:1048-1058 (and Bit 1108-1118, Hammer 1168-1178): `typeCounts[type] += entry.count` for every type in `entry.types ?? [entry.type]` while `totalCount += entry.count` once.
- Question for developer: is `count` the per-type quantity or the entry's total pieces?
- Touches data: no (display).

### 3.3 Data loss (6)

| ID | Title |
|---|---|
| B-G1-01 | Double tap on Save creates duplicate entries |
| B-G1-06 | Legacy type not in the option list makes a PVC, Bit or Hammer entry unsaveable |
| B-G1-14 | No discard guard on any bill or side ledger form |
| G3-B09 | Clear All Data does not tell the user that Account Ledger is erased |
| G3-B15 | Agent delete: destructive option is the default |
| G3-B16 | Vehicle form: double tap on Add creates two vehicles |

#### B-G1-01 Double tap on Save creates duplicate entries

- Severity: data loss (duplicates; a second bill with a different id)
- Where: `ledger_form_screen.dart:406-476`, `side_bore_form_screen.dart:264-338`, `diesel_form_screen.dart:141-190`, `pvc_form_screen.dart:159-248`, `bit_form_screen.dart` and `hammer_form_screen.dart` (same `_saveEntry`)
- Repro: new bill, fill valid data, tap Save twice quickly (or press Enter/click twice on macOS).
- Expected: one entry. Actual: `_saveEntry` has no in-flight flag; each call builds an entry with a fresh UUID (`widget.entry?.id ?? _uuid.v4()`), awaits `addEntry`, so two entries are written before `Navigator.pop`.
- Proposed fix: local `_saving` bool set before the first await, button disabled while true, reset in `finally`.
- Risk: low. Touches data/sync/models: no (UI guard only).

#### B-G1-06 Legacy type not in the option list makes a PVC, Bit or Hammer entry unsaveable

- Severity: data loss risk (user cannot save edits). UNVERIFIED (depends on stored data)
- Where: `pvc_form_screen.dart:69-92` and `:162-186` (selection added at 76/82/89 but controllers exist only for `pvcTypes`; rows rendered only for `pvcTypes.where(...)` at 374-376); same in `bit_form_screen.dart` and `hammer_form_screen.dart`
- Repro: edit an entry whose stored type or `types` contains a string outside the current list (for example an older spelling such as "7inch" or "6 inch").
- Expected: the type is editable or removable. Actual: the type counts as selected with count 0, no input row is shown, Save fails with 'Please enter count and rate for <type>' and the user cannot fix it; the chip row also has no chip for it.
- Proposed fix: UI shows an extra disabled selected chip with a remove action (see pvc_form_screen.md 4.5). Making it removable changes what is saved only if the user removes it.
- Risk: medium (touches save semantics if the data layer decides). Touches data/sync/models: no for the UI change.

#### B-G1-14 No discard guard on any bill or side ledger form

- Severity: data loss (unsaved typing)
- Where: all 6 form screens (no `PopScope`/`WillPopScope`), for example `ledger_form_screen.dart:524`
- Repro: type into a new bill, press the system back gesture or the app bar back.
- Expected: confirm discard. Actual: the form closes and the input is lost.
- Proposed fix: `PopScope(canPop: !dirty, onPopInvokedWithResult: ...)`. Dirty = any controller differs from its initial value.
- Risk: low. Touches data/sync/models: no.

#### G3-B09 Clear All Data does not tell the user that Account Ledger is erased

- Severity: data loss (undisclosed scope).
- Where: lib/features/settings/settings_screen.dart:323-335; lib/core/database/database_service.dart:469-486 (clears cash books, cash entries, cash notes and tombstones).
- Expected: dialog lists everything that is deleted. Actual: lists only ledger entries, agents, side-ledger entries, vehicles.
- Fix: copy change (allowed in the redesign) plus typed confirmation.
- Risk: none. Touches data: no (copy).

#### G3-B15 Agent delete: destructive option is the default

- Severity: data loss (risk of accidental delete of all bills of an agent).
- Where: agents_screen.dart:311, 356-366, 413-431.
- Actual: `reassignToAgentId` starts null, so "Delete all entries" is selected and Delete is one tap.
- Fix: no default selection; Delete disabled until a choice (UI only).
- Touches data: no (UI).

#### G3-B16 Vehicle form: double tap on Add creates two vehicles

- Severity: data loss (duplication, small).
- Where: vehicle_management_screen.dart:380-406 (no saving flag, `Navigator.pop` after awaits).
- Fix: `_saving` flag. Risk low. Touches data: prevents duplicates.

### 3.4 UI only (52)

| ID | Title |
|---|---|
| B-05 | Cmd+F is registered and does nothing |
| B-06 | "New Entry" button and Cmd+N do nothing on Portfolio, Agents and Settings |
| B-08 | Sidebar items cannot be reached or activated with the keyboard |
| B-11 | Empty list says "No entries yet" even when a search or filter caused it |
| B-12 | Period chips are clipped without hint ("All" appears as "Al") |
| B-13 | Summary highlights collide or overflow with long numbers and large text |
| B-14 | Bill card info rows overflow at large text |
| B-15 | Ledger calendar day cells overflow and fail contrast |
| B-17 | Context used after an await in backup and PDF export |
| B-G1-04 | Add-agent dialog: controllers never disposed, snackbar hidden behind the dialog, setState after await |
| B-G1-05 | Side ledger lists sort the provider's list in place during build |
| B-G1-07 | Entry cards overflow on narrow widths and large text |
| B-G1-08 | Delete icon on side ledger cards is a 20 dp target |
| B-G1-10 | Filter sheets accept start date after end date and show an empty list silently |
| B-G1-11 | Filter sheets are not scrollable: overflow with the keyboard open |
| B-G1-12 | Payment removal is immediate with no confirmation |
| B-G1-13 | Payment dialog shows a book-creation error under the Amount field |
| B-G1-15 | Side bore Balance box shows overpayment in green and uses failing contrast |
| B-G1-17 | Total field in the main bill form has no label |
| B-G1-18 | Bill number duplicate check scans the whole rig box on every keystroke |
| B-G1-19 | Wrapper/controller notes (low) |
| G2-B01 | Book selector tap target about 36 dp |
| G2-B03 | Calendar cells can overflow at large text scale |
| G2-B07 | Confirm dialog paints every confirm label in error red, including "Import" |
| G2-B08 | Snackbar error text contrast |
| G2-B10 | Entry form: removed or abandoned bill files stay on disk |
| G2-B12 | Items dialog remove button tap target 18 dp, no confirm |
| G2-B14 | Account Summary builds all day rows eagerly |
| G2-B17 | Trash: permanent delete and Delete All give no feedback |
| G2-B18 | Import screen shows raw exception text, warning color fails contrast |
| G2-B19 | Report: no progress while the PDF is built |
| G2-B20 | Hub: desktop destinations are pushed on the root navigator (covers the shell sidebar) - UNVERIFIED |
| G2-B21 | CashDateField has no label or semantics |
| G2-B22 | Format Date dialog loses one option when day equals month |
| G3-B04 | Manual column mapping is lost when navigating back and forward |
| G3-B05 | Validate step is allowed with required fields unmapped |
| G3-B13 | Agent dialogs: validation snackbars are hidden behind the dialog |
| G3-B14 | Agent dialog controllers are never disposed |
| G3-B17 | Vehicle name + Active badge overflow |
| G3-B18 | Vehicle card tap switches rig and leaves the screen |
| G3-B20 | Stats: pie hover or touch rebuilds the whole screen |
| G3-B21 | Stats stat rows and legend overflow at 200 percent text scale |
| G3-B22 | Stats pie touched label is white on light slices |
| G3-B25 | Export: From date after To date is silently accepted |
| G3-B26 | PDF export screen recomputes Hive range scans on every rebuild |
| G3-B27 | PdfPreview may regenerate the PDF on unrelated rebuilds (UNVERIFIED) |
| G3-B28 | Theme: transparent AppBar default makes plugin and license pages unreadable (UNVERIFIED on device) |
| G3-B29 | Theme: selected chip label is dark on dark blue unless overridden |
| G3-B30 | Sign-in error shown to end users contains developer instructions |
| G3-B31 | Startup waits on the network and permission screen before the first frame |
| G3-B33 | Agent card row overflow at large text |
| G3-B34 | Stats mini cards: Paid and Due slices nearly identical in lightness |

#### B-05 Cmd+F is registered and does nothing

- Severity: UI only
- Where: `desktop_shell.dart:360-368`
- Reproduce: macOS, Ledger tab, Cmd+F: no response (BACKLOG.md lists it).
- Expected: focus the search. Actual: empty handler body.
- Proposed fix: LR-14 (handler body) or remove the shortcut from the menu until implemented.
- Risk: low. Touches data/sync/models: no

#### B-06 "New Entry" button and Cmd+N do nothing on Portfolio, Agents and Settings

- Severity: UI only
- Where: `desktop_shell.dart:249-272` (`_handleAdd` has empty branches), sidebar button always enabled.
- Reproduce: macOS, open Portfolio, click New Entry.
- Expected: disabled or hidden. Actual: enabled button, no action.
- Proposed fix: disabled state with tooltip (UI only).
- Risk: none. Touches data/sync/models: no

#### B-08 Sidebar items cannot be reached or activated with the keyboard

- Severity: UI only (accessibility)
- Where: `desktop_shell.dart:660-730` (`MouseRegion` only, no `InkWell`/`Focus`/semantics)
- Reproduce: macOS, press Tab repeatedly: focus never lands on a sidebar item; use Cmd+1..5 only.
- Fix: `RigSidebar` with `InkWell`, focus ring and `Semantics(button, selected)`.
- Risk: none. Touches data/sync/models: no

#### B-11 Empty list says "No entries yet" even when a search or filter caused it

- Severity: UI only
- Where: `ledger_list.dart:20-45`
- Reproduce: search for text that matches nothing.
- Fix: two empty states.
- Risk: none. Touches data/sync/models: no

#### B-12 Period chips are clipped without hint ("All" appears as "Al")

- Severity: UI only
- Where: Side Ledger and Portfolio chip rows (screenshots 01 and 05), `combined_home_screen.dart` `_buildSideLedgerPeriodChip`, `stats_screen.dart` `_buildRangeChip`
- Fix: `RigChipRow` fade edge and scroll into view.
- Risk: none. Touches data/sync/models: no

#### B-13 Summary highlights collide or overflow with long numbers and large text

- Severity: UI only (readability) / wrong number risk (clipped digits)
- Where: `summary_row.dart:38-85` (FittedBox with no minimum), `120-160` (feet `Text` without fit), Side Ledger `_buildMiniStatDouble` row
- Reproduce: bills totalling above 99,99,999 with font size at 130 percent: money values touch; feet values wrap.
- Fix: HIGHLIGHTS_AND_COLLAPSE.md part B.
- Risk: low. Touches data/sync/models: no

#### B-14 Bill card info rows overflow at large text

- Severity: UI only
- Where: `ledger_list.dart` Depth and PVC `Row` of `_InfoChip`s, three `_ValueDisplay` columns
- Fix: `Wrap`, fitted values (screens/ledger_list.md 4.1).
- Risk: none. Touches data/sync/models: no

#### B-15 Ledger calendar day cells overflow and fail contrast

- Severity: UI only
- Where: `calendar_view.dart:104-131` (9 sp white text on gradient chip, 3.7:1, no `FittedBox`)
- Fix: T-U34.
- Risk: none. Touches data/sync/models: no

#### B-17 Context used after an await in backup and PDF export

- Severity: UI only
- Where: `settings_screen.dart:215` and `pdf_export_screen.dart:1563` (analyzer `use_build_context_synchronously`)
- Fix: capture `ScaffoldMessenger` before the await or check `mounted` first.
- Risk: none. Touches data/sync/models: no

#### B-G1-04 Add-agent dialog: controllers never disposed, snackbar hidden behind the dialog, setState after await

- Severity: UI only
- Where: `ledger_form_screen.dart:341-404` (controllers created at 342-343 outside any State; snackbar at 379-381 raised on the scaffold behind the modal barrier; `setState` after `await addAgent` at 399 without a `mounted` check), `side_bore_form_screen.dart:226-262` (controller at 227 never disposed; empty name closes the dialog with no feedback; `setState` after await at 257 without `mounted`).
- Repro: open Add agent, press Add with an empty name in the main form: the 'Agent name is required' snackbar appears under the barrier, barely visible. Side bore form: press Add with empty name, the dialog closes and nothing happens.
- Proposed fix: a dialog widget that owns its controllers (MEMORY.md gotcha), inline error text, `if (!mounted) return;` after the await.
- Risk: low. Touches data/sync/models: no.

#### B-G1-05 Side ledger lists sort the provider's list in place during build

- Severity: UI only (shared-state mutation). UNVERIFIED whether any consumer depends on the order
- Where: `diesel_list_screen.dart:30` and `:51` (`var filtered = entries; ... filtered.sort(...)`), same in `pvc_list_screen.dart`, `bit_list_screen.dart`, `hammer_list_screen.dart` (`_applyFilters`)
- Repro: open any list with no filter set; `filtered` aliases `ref.watch(...)` state and `.sort` reorders that list instance inside `build`.
- Expected: display code does not mutate provider state. Actual: provider state list is reordered silently (no notification), other consumers of the same list may observe a different order than the notifier stored.
- Proposed fix: `final filtered = [...entries];` before filtering/sorting.
- Risk: none. Touches data/sync/models: no.

#### B-G1-07 Entry cards overflow on narrow widths and large text

- Severity: UI only
- Where: `diesel_list_screen.dart:403-446` (Rate + Paid + Due row without `Flexible`), `:459` (bunk details `Text` not in `Expanded`); `pvc_list_screen.dart` payment row and storage row (about 481-545); `bit_list_screen.dart` and `hammer_list_screen.dart` ID/name chip row; highlight boxes of PVC/Bit/Hammer (three `Expanded` boxes, about 93 dp each at 360 dp)
- Repro: Android 360 dp wide, an entry with Paid Rs 1,00,000.00 and Due Rs 1,00,000.00, or a 40-character bunk name, or text scale 200 percent.
- Expected: wraps/ellipsizes. Actual: RenderFlex overflow (yellow-black stripe in debug, clipped content in release).
- Proposed fix: `Expanded`/`Flexible` + `maxLines`, `Wrap` for the status row (see `SideEntryCard`).
- Risk: none. Touches data/sync/models: no.

#### B-G1-08 Delete icon on side ledger cards is a 20 dp target

- Severity: UI only (destructive mis-tap; confirm dialog mitigates)
- Where: `diesel_list_screen.dart:371-377` (`padding: EdgeInsets.zero`, `constraints: const BoxConstraints()`), same pattern in the other three lists
- Repro: tap near the trash glyph on a card: the 20 x 20 dp target is easy to miss and the surrounding card area opens the edit form instead.
- Expected: at least 48 x 48 dp. Actual: 20 x 20 dp.
- Proposed fix: 48 dp overflow menu button (see diesel_list_screen.md 4.2).
- Risk: none. Touches data/sync/models: no.

#### B-G1-10 Filter sheets accept start date after end date and show an empty list silently

- Severity: UI only
- Where: `diesel_list_screen.dart:543-550` (`_applyFilters`) and the three twins
- Repro: set Start Date after End Date, Apply.
- Expected: warning. Actual: empty list with "No entries match your filters" and no explanation of the range.
- Proposed fix: inline error text (copy) in the sheet (see diesel_list_screen.md 4.3); blocking Apply is a validator change (L-04).
- Risk: none for the message. Touches data/sync/models: no.

#### B-G1-11 Filter sheets are not scrollable: overflow with the keyboard open

- Severity: UI only
- Where: `diesel_list_screen.dart:561-654` (`Column(mainAxisSize.min)` inside `Padding(viewInsets.bottom)`), PVC sheet has additional chips (about 440 dp tall)
- Repro: small phone or landscape, tap the Bunk Name or Storage Place field.
- Expected: sheet content scrolls. Actual: bottom overflow stripe, Apply hidden.
- Proposed fix: `SingleChildScrollView` + `isScrollControlled` already set; pin Apply in the footer.
- Risk: none. Touches data/sync/models: no.

#### B-G1-12 Payment removal is immediate with no confirmation

- Severity: UI only (recoverable until the bill is saved; linked receiver income is trashed on save and recoverable from Account Ledger trash for 30 days)
- Where: `payment_log_editor.dart:144-152`
- Repro: tap the trash icon on a payment row.
- Expected: undo or confirm. Actual: removed instantly.
- Proposed fix: Undo snackbar (see payment_log_editor.md 4.1).
- Risk: none. Touches data/sync/models: no.

#### B-G1-13 Payment dialog shows a book-creation error under the Amount field

- Severity: UI only
- Where: `payment_log_editor.dart:308-309` and `:358` (`_error` shared, `errorText` on the Amount `TextField`)
- Repro: Add payment, Received by > New receiver, enter a name that already exists (error path returns `error` from `addBook`).
- Expected: error near the receiver field. Actual: the message appears under Amount.
- Proposed fix: separate `_receiverError`.
- Risk: none. Touches data/sync/models: no.

#### B-G1-15 Side bore Balance box shows overpayment in green and uses failing contrast

- Severity: UI only
- Where: `side_bore_form_screen.dart:716-753` (condition `> 0 ? warning : success`)
- Repro: Total 1,000, received 1,500: Balance Rs -500.00 appears green, same style as 0.
- Expected: negative has its own tone. Actual: green (#10B981 on tint about 2.4:1) for 0 and negatives; positive uses amber #F59E0B text (about 2.0:1).
- Proposed fix: tone mapping outstanding > 0, moneyIn = 0, negative < 0 (see side_bore_form_screen.md).
- Risk: none. Touches data/sync/models: no.

#### B-G1-17 Total field in the main bill form has no label

- Severity: UI only (accessibility)
- Where: `ledger_form_screen.dart:932-941` (`InputDecoration` has only prefix and suffix icons; the section title above is not associated with the field)
- Repro: TalkBack/VoiceOver on the Total field announces only the value.
- Proposed fix: `labelText: 'Total'` (or `Semantics(label)`).
- Risk: none. Touches data/sync/models: no.

#### B-G1-18 Bill number duplicate check scans the whole rig box on every keystroke

- Severity: UI only (performance on large ledgers)
- Where: `ledger_form_screen.dart:230-251` and `side_bore_form_screen.dart:189-210` via `DatabaseService.getAllLedgerEntries()` (filters the full Hive box by vehicle on each call)
- Repro: bill number field on a rig with thousands of bills: each keystroke does an O(n) scan and `toList()`.
- Proposed fix: debounce 250 ms in the widget; keep the same function.
- Risk: none. Touches data/sync/models: no.

#### B-G1-19 Wrapper/controller notes (low)

- Severity: UI only. UNVERIFIED
- Where: `side_bore_form_screen.dart:614-620` calls `_recalculate()` (which calls `setState`) inside a `setState` callback; `_recalculate` and `_updateBalance` both `setState` (two rebuilds per keystroke); `payment_log_editor.dart:45-51` uses `ref.read` in a build helper so a renamed receiver is not reflected until a parent rebuild.
- Proposed fix: move the recalculation after `setState`; `ref.watch(select)` for names.
- Risk: none. Touches data/sync/models: no.

#### G2-B01 Book selector tap target about 36 dp

- Severity: UI only
- Where: lib/features/cashbook/cashbook_home_screen.dart:254-269
- Reproduce: open Accounts tab, try tapping the book name near its top or bottom edge.
- Expected: 48 dp minimum hit area. Actual: InkWell wraps a Row with 6 dp vertical padding and 24 dp text, about 36 dp.
- Fix: wrap with `ConstrainedBox(minHeight: 48)`; see cashbook_home_screen.md 4.1.
- Risk: none. Touches data/sync/models: no

#### G2-B03 Calendar cells can overflow at large text scale

- Severity: UI only
- Where: lib/features/cashbook/cashbook_calendar_screen.dart:98-153
- Reproduce: set system font size to the largest, open Calendar on a 360 dp phone, month with income and expense on the same day.
- Expected: no overflow. Actual: `childAspectRatio: 0.72` gives a cell about 50 x 69 dp; day number 12 sp plus two 10 sp lines scale with text size and exceed the cell (Column inside a fixed-ratio cell, no clip). UNVERIFIED (not run at 200 percent).
- Fix: see cashbook_calendar_screen.md (cell aspect from text scale, amounts in a dot plus sheet at large scale).
- Risk: low. Touches data/sync/models: no

#### G2-B07 Confirm dialog paints every confirm label in error red, including "Import"

- Severity: UI only (misleading destructive styling)
- Where: lib/features/cashbook/widgets/cashbook_common.dart:121-125, used with `confirmLabel: 'Import'` at cashbook_import_screen.dart:54-62
- Expected: a non-destructive action in primary color. Actual: the label is always `AppColors.error`.
- Fix: `ConfirmDialog(destructive: false)` for Import.
- Touches data: no

#### G2-B08 Snackbar error text contrast

- Severity: UI only
- Where: cashbook_common.dart:98-103 (`backgroundColor: AppColors.error`, default white text)
- White on #EF4444 is 3.76:1 (fails 4.5). No duration, no floating behavior, no icon. Fix: `showRigSnack`.
- Touches data: no

#### G2-B10 Entry form: removed or abandoned bill files stay on disk

- Severity: UI only (storage leak)
- Where: cashbook_entry_form_screen.dart:139-147 (copy into app support dir at pick time), 169, 592-593 (chip delete only removes the path from the list)
- Reproduce: Add Bills > Gallery, pick an image, delete the chip or leave the form with Back. The copied file stays in `cashbook_bills/`.
- Fix: delete the copied file when the chip is removed or the form is closed without saving (logic, L-06).
- Touches data: files only.

#### G2-B12 Items dialog remove button tap target 18 dp, no confirm

- Severity: UI only
- Where: cashbook_items_dialog.dart:178-182
- Icon size 18 with default IconButton padding is about 34 dp. Fix: 48 dp, same action, optional undo snackbar.
- Touches data: no

#### G2-B14 Account Summary builds all day rows eagerly

- Severity: UI only (performance)
- Where: cashbook_account_summary_screen.dart:107-137 (`ListView(children: [for ...])`, `days.entries.toList().reversed` each build)
- For period All on a book with years of entries, hundreds of rows are built at once on every rebuild. Fix: `ListView.builder` over a list computed once per provider value.
- Touches data: no

#### G2-B17 Trash: permanent delete and Delete All give no feedback

- Severity: UI only
- Where: cashbook_trash_screen.dart:53-57, 92-96
- After the confirm dialog the row simply disappears; Delete All is offered even when the trash is empty.
- Fix: snackbar "Deleted permanently" and disable "Delete All" when `trash.isEmpty` (UI only).
- Touches data: no

#### G2-B18 Import screen shows raw exception text, warning color fails contrast

- Severity: UI only
- Where: cashbook_import_screen.dart:47, 80 (`e.toString()` / 'Import failed: $e'), 166 (`AppColors.warning` text, #F59E0B on white is 2.15:1)
- Fix: friendly summary line plus an expandable "Details" with the raw message; use `outstanding` role for warning text.
- Touches data: no

#### G2-B19 Report: no progress while the PDF is built

- Severity: UI only
- Where: cashbook_report_dialog.dart:44-51
- Large books: `CashbookExportService.buildPdf` can take seconds; there is no indicator so users tap Report twice and may get two share sheets.
- Fix: modal progress (`RigDialogShell` with 24 dp indicator) and disable the Report icon while running.
- Touches data: no

#### G2-B20 Hub: desktop destinations are pushed on the root navigator (covers the shell sidebar) - UNVERIFIED

- Severity: UI only
- Where: cashbook_hub_screen.dart:70-76; no `Navigator(` found in lib/features/navigation
- See cashbook_hub_screen.md section 3 item 3 and logic_g2.md L-01.
- Touches data: no

#### G2-B21 CashDateField has no label or semantics

- Severity: UI only (accessibility)
- Where: widgets/cashbook_common.dart:180-185 (`InputDecorator` with only a suffix icon)
- Screen readers read only the date text; sighted users see no field name (used in Add Account, Opening Balance, Transfer, Note form, Date range dialog).
- Fix: `RigDateField(label: ...)`.
- Touches data: no

#### G2-B22 Format Date dialog loses one option when day equals month

- Severity: UI only (a setting cannot be chosen on some days)
- Where: lib/features/cashbook/cashbook_settings_screen.dart:72-77 (map keyed by today's formatted text)
- Reproduce: on a date where day equals month (for example 10 Oct), open Account Ledger Settings > Format Date. 'dd-MM-yyyy' and 'MM-dd-yyyy' both render "10-10-2026", the map keeps one entry, the dialog lists 5 formats. Chosen value for that text is the later pattern (MM-dd-yyyy), so dd-MM-yyyy cannot be selected that day.
- Fix: key the options by pattern and show an example from a fixed sample date (25 Dec) or show the pattern text.
- Risk: none. Touches data/sync/models: no

#### G3-B04 Manual column mapping is lost when navigating back and forward

- Severity: UI only.
- Where: csv_import_screen.dart:129-139 (`_autoMapColumns()` on every Continue from step 0).
- Repro: step 1 load file, Continue, change dropdowns, Back, Continue.
- Expected: mapping preserved. Actual: reset to auto mapping.
- Fix: run auto map only when the file changes (UI flag).
- Risk: low. Touches data: no.

#### G3-B05 Validate step is allowed with required fields unmapped

- Severity: UI only (every row errors).
- Where: csv_import_screen.dart:141-146.
- Fix: disable Validate until Date, Bill number, Agent name are mapped (UI guard).
- Risk: low. Touches data: no.

#### G3-B13 Agent dialogs: validation snackbars are hidden behind the dialog

- Severity: UI only.
- Where: agents_screen.dart:166-169, 177-181, 269-272.
- Actual: `ScaffoldMessenger` shows the snackbar on the page under the barrier; the user sees nothing or a dimmed bar.
- Fix: inline field errors (in redesign).
- Touches data: no.

#### G3-B14 Agent dialog controllers are never disposed

- Severity: UI only (small leak per open).
- Where: agents_screen.dart:108-113, 212-220.
- Fix: private StatefulWidget dialog owning controllers (also required by MEMORY.md gotcha).
- Touches data: no.

#### G3-B17 Vehicle name + Active badge overflow

- Severity: UI only.
- Where: vehicle_management_screen.dart:254-286 (name `Text` not Expanded/Flexible inside a Row with a badge).
- Repro: name of about 25 characters on a 360 dp screen. Fix: Wrap or Expanded.

#### G3-B18 Vehicle card tap switches rig and leaves the screen

- Severity: UI only (surprise navigation).
- Where: vehicle_management_screen.dart:222-224, 141-162 (`Navigator.pop`).
- Fix: explicit Switch button (redesign keeps behavior of the whole-card tap).

#### G3-B20 Stats: pie hover or touch rebuilds the whole screen

- Severity: UI only (performance).
- Where: stats_screen.dart:51-58 (unused record watching 5 providers), 603-614 (`setState` in `touchCallback`).
- Repro: macOS, move the mouse over the By Agent donut with a few thousand bills; profile rebuilds.
- Fix: ValueNotifier for the highlighted slice; per-tab Consumers.

#### G3-B21 Stats stat rows and legend overflow at 200 percent text scale

- Severity: UI only (RenderFlex overflow / one-char-per-line wrap).
- Where: stats_screen.dart:1320-1342 (`_StatRow` Row(spaceBetween), no Flexible), 647-690 (legend: fixed 50 dp percent box, unflexed amount).
- Repro: set system font scale to largest, open Portfolio > Side Ledger or Ledger with large amounts.
- Fix: Flexible/Wrap, stacked amount and percent. UNVERIFIED on device, certain from layout.

#### G3-B22 Stats pie touched label is white on light slices

- Severity: UI only (contrast 1.62:1 on #B7CDED).
- Where: stats_screen.dart:624-634 with `AppColors.chartColors` (app_colors.dart:50-59).

#### G3-B25 Export: From date after To date is silently accepted

- Severity: UI only. Where: pdf_export_screen.dart:870-886, csv_export_screen.dart:405-421, stats_screen.dart:376-394.
- Actual: shows "No entries found" or empty stats without a reason.

#### G3-B26 PDF export screen recomputes Hive range scans on every rebuild

- Severity: UI only (jank on large data).
- Where: pdf_export_screen.dart:206 (`_getEntriesCount()` in build), 591-593 and 709-782 (second scan per summary), each of 18 column chips and both date pickers call `setState`.
- Fix: cache aggregates in State on type/range change.

#### G3-B27 PdfPreview may regenerate the PDF on unrelated rebuilds (UNVERIFIED)

- Severity: UI only (performance).
- Where: pdf_export_screen.dart:839-852 (new `build:` closure per rebuild).

#### G3-B28 Theme: transparent AppBar default makes plugin and license pages unreadable (UNVERIFIED on device)

- Severity: UI only.
- Where: lib/core/theme/app_theme.dart:25-36; about_screen.dart:109-114 (`showLicensePage`).

#### G3-B29 Theme: selected chip label is dark on dark blue unless overridden

- Severity: UI only (about 2.5:1).
- Where: app_theme.dart:128-136 (`selectedColor: primary`, label `textPrimary`).

#### G3-B30 Sign-in error shown to end users contains developer instructions

- Severity: UI only (copy).
- Where: lib/core/services/google_drive_service.dart:93-99 shown by settings_screen.dart:499-502. Contains keytool and Firebase Console steps and a developer handle.
- Fix: redesign puts it behind a Details expander; the service string is unchanged (logic L-08 to give users a plain message).

#### G3-B31 Startup waits on the network and permission screen before the first frame

- Severity: UI only (UNVERIFIED duration).
- Where: lib/main.dart:59-71 (sequential awaits including `GoogleDriveService.initialize()` / `signInSilently()` and `_requestPermissions()` before `runApp`).
- Fix: StartupGate (needs developer approval, order preserved).

#### G3-B33 Agent card row overflow at large text

- Severity: UI only (UNVERIFIED).
- Where: agents_screen.dart:556-583 (Row with phone and bill count, no Flexible).

#### G3-B34 Stats mini cards: Paid and Due slices nearly identical in lightness

- Severity: UI only (accessibility). Where: stats_screen.dart:908-919 (`success` #10B981 vs `warning` #F59E0B, luminance ratio 1.18:1), labels 10 and 11 sp under the chart without swatches (930-962).

### 3.5 Cosmetic (12)

| ID | Title |
|---|---|
| B-04 | Portfolio resets the agent filter by assigning state inside build |
| B-07 | Sidebar shortcut hint says Cmd 1-4 but there are five areas |
| B-10 | Balance reads green when the balance is zero or negative |
| B-18 | Dead code: HomeScreen, SideLedgerScreen, GradientAppBar |
| B-21 | Deprecated `withOpacity` in 125 places |
| B-22 | Housekeeping: dependencies and unused packages |
| B-G1-16 | Diesel form: exactly paid shows "Balance (Advance)" |
| G2-B02 | Day header and period label ignore the user's date-format setting |
| G2-B04 | Calendar day amounts use 10 sp |
| G2-B15 | Time pickers ignore the 12/24 hour setting in Transfer and Note form |
| G2-B16 | Trash shows "1 days left" |
| G3-B32 | Last backup text never refreshes and has a grammar error |

#### B-04 Portfolio resets the agent filter by assigning state inside build

- Severity: cosmetic (fragile)
- Where: `portfolio_view.dart:32-34` (`_agentId = null` inside `build`).
- Reproduce: select an agent chip, switch rig to one without that agent; the reset happens during build without `setState`.
- Expected: reset through `didUpdateWidget` or a listener. Actual: works today because the same build continues, fragile.
- Proposed fix: move to a listener; same rule.
- Risk: none. Touches data/sync/models: no

#### B-07 Sidebar shortcut hint says Cmd 1-4 but there are five areas

- Severity: cosmetic
- Where: `desktop_shell.dart:648`
- Fix: text "Cmd 1-5".
- Risk: none. Touches data/sync/models: no

#### B-10 Balance reads green when the balance is zero or negative

- Severity: cosmetic (misleading signal)
- Where: `ledger_list.dart` `_LedgerEntryCard` Balance color expression (`entry.balance > 0 ? warning : success`) and `side bore` balance box (g1 B-G1-15)
- Expected: a distinct "settled" or "credit" tone. Actual: same green as Received.
- Fix: card spec in `screens/ledger_list.md` 4.1.
- Risk: none. Touches data/sync/models: no

#### B-18 Dead code: HomeScreen, SideLedgerScreen, GradientAppBar

- Severity: cosmetic (maintenance)
- Where: `home_screen.dart` (378 lines, never instantiated), `side_ledger_screen.dart` (200 lines, never instantiated), `gradient_widgets.dart` `GradientAppBar` (no users)
- Fix: delete in the cleanup task after migration.
- Risk: none (verify with grep). Touches data/sync/models: no

#### B-21 Deprecated `withOpacity` in 125 places

- Severity: cosmetic (precision loss in alpha; analyzer: 140 deprecated_member_use infos)
- Where: 26 files (`app_theme.dart:122`, summary, cards)
- Fix: color roles with alpha built into tokens (T-U13).
- Risk: none. Touches data/sync/models: no

#### B-22 Housekeeping: dependencies and unused packages

- Severity: cosmetic
- Where: `pubspec.yaml`: `flutter_launcher_icons` in dependencies, `riverpod_generator` unused (BACKLOG.md)
- Fix: move or remove.
- Risk: low (build). Touches data/sync/models: no

#### B-G1-16 Diesel form: exactly paid shows "Balance (Advance)"

- Severity: cosmetic
- Where: `diesel_form_screen.dart:375-376`
- Repro: Total 9,000, Paid 9,000.
- Expected: neutral paid-in-full wording. Actual: label "Balance (Advance)" with Rs 0.00 (and blue). The text rule is parity-pinned; only the tone is redesigned.
- Risk: none. Touches data/sync/models: no.

#### G2-B02 Day header and period label ignore the user's date-format setting

- Severity: cosmetic (inconsistent display)
- Where: lib/core/providers/cashbook_provider.dart:103 (`formatDayHeader` fixed 'EEE, MMM dd yyyy'), lib/core/utils/cashbook_calculator.dart:194-199 (`rangeLabel` fixed 'MMM-dd-yyyy' with ' -> ')
- Reproduce: Account Ledger Settings > Format Date, choose "dd-MMM-yyyy". Row dates change, the day header and the period bar label do not.
- Expected: one date style on the screen. Actual: three patterns on one screen (rows, day header, range label).
- Fix: UI builds the range label from `CashDateRange.start/lastDay` with `settings.formatDate`; day header pattern change is a provider change (logic_g2.md L-04). Export strings must not change.
- Risk: low. Touches data/sync/models: no

#### G2-B04 Calendar day amounts use 10 sp

- Severity: cosmetic
- Where: cashbook_calendar_screen.dart:137-148
- Below the 11 sp floor in DESIGN_SYSTEM.md section 4. Fix: labelSmall 11 sp minimum with the stacked layout.
- Touches data: no

#### G2-B15 Time pickers ignore the 12/24 hour setting in Transfer and Note form

- Severity: cosmetic (inconsistent)
- Where: cashbook_transfer_screen.dart:42-49, cashbook_note_form_screen.dart:31-38 (compare cashbook_entry_form_screen.dart:106-121 which applies `alwaysUseUse24HourFormat: settings.use24Hour`)
- Reproduce: Settings > Time Format 24 hour; open Add Income and tap the time (24h picker); open Transfer and tap the time (picker follows the device).
- Fix: one `RigTimeField` applying the setting.
- Touches data: no

#### G2-B16 Trash shows "1 days left"

- Severity: cosmetic
- Where: cashbook_trash_screen.dart:132
- Fix: pluralization in the widget ("1 day left").
- Touches data: no

#### G3-B32 Last backup text never refreshes and has a grammar error

- Severity: cosmetic.
- Where: settings_screen.dart:628-637 ("1 hours ago", computed once per build).

## 4. Needs your explicit approval (touches data, sync or models)

Nothing in this section is scheduled. Each item needs a yes, its own commit, a test and (for sync and restore) a rehearsal against a copy of a real backup kept outside the repo.

### 4.1 Crash (1)

#### G3-B08 Import `firstWhere` without orElse can abort mid-import

- Severity: crash (caught) / data inconsistency.
- Where: csv_import_screen.dart:665-667.
- Actual: if an agent lookup fails after agents were created, a StateError aborts; agents were already added, entries are not imported ("Import failed: Bad state: No element").
- Fix: `orElse` fallback or pre-validation. Logic L-05.
- Touches data: yes.

### 4.2 Wrong number (6)

#### B-20 Portfolio "All rigs" does not update when another rig's data changes

- Severity: wrong number - UNVERIFIED
- Where: `portfolio_provider.dart:41-52` reads Hive boxes directly and only re-evaluates when the current rig's five providers emit
- Reproduce: All rigs on; sync pulls records for another rig; Overview keeps old numbers until the current rig's lists change (sync calls refresh on all providers, so impact is small).
- Fix: LR-10.
- Risk: medium. Touches data/sync/models: yes (provider)

#### G2-B09 Entry form: edit mutates the live entry before the save result is known

- Severity: wrong number (display only, until reload) - UNVERIFIED
- Where: lib/features/cashbook/cashbook_entry_form_screen.dart:205-217
- The edit path assigns the new bookId, date, amount, type, notes, description, attachments and items directly onto `widget.entry` and then calls `updateEntry(e)`. If `updateEntry` returns an error (shown in a snackbar at 233-236), the object in the provider's list already holds the unsaved values, so the list can show values that were not saved until the next reload. Whether the object is shared with the provider list depends on `cashEntriesProvider` (HiveObject identity); not verified.
- Fix (logic, not applied): build a copy (`copyWith`) and pass the copy. Listed in logic_g2.md L-05.
- Touches data: yes (entry object); the redesign does not change it.

#### G3-B01 CSV import auto-mapping breaks on the app's own export

- Severity: wrong number (silent zeros).
- Where: lib/features/export/csv_import_screen.dart:32-49 (expectedHeaders), 498-518 (_autoMapColumns); headers in lib/core/models/ledger_entry.dart:500-522.
- Repro: export Ledger to CSV, then Import from CSV with that file, press Continue and inspect the mapping.
- Expected: Depth Type to Depth, Depth (feet) to Depth in feet, Depth Rate/ft to Depth per feet rate, PVC and MS pipe likewise, Extra Charges to Extra-chargers.
- Actual: matching is `header == expected || header.contains(expected)` with `break` on the first expected name in list order. "Depth (feet)" and "Depth Rate/ft" contain "depth" and overwrite the mapping of `Depth` with the later column index; `Depth in feet` and `Depth per feet rate` never match; same for PVC and MS pipe; "Extra Charges" never matches "Extra-chargers". Result: depth type is read from the rate column, feet and rates and extra charges are unmapped and import as 0 unless the user fixes 7 dropdowns by hand. Nothing warns that numeric fields are unmapped.
- Proposed fix: exact (case-insensitive) match first, then known aliases for the app's export headers, then `contains` only for unmatched names; warn in the UI when any non-required numeric field is unmapped.
- Risk: medium (changes what gets imported for existing users; needs a test with the export file).
- Touches data/sync/models: yes (creates ledger entries). Logic change, so listed in logic_g3.md L-01; the redesign only adds UI warnings.

#### G3-B06 Empty date silently becomes today; non-ISO dates always fail

- Severity: wrong number (dates) / UI.
- Where: csv_import_screen.dart:556-568.
- Actual: empty Date cell imports with `DateTime.now()`; `DateTime.parse` rejects `dd/MM/yyyy` so all rows fail with the same message.
- Fix (logic L-03): accept configured formats and report empty dates as errors. Redesign: show the expected format hint on step 2.
- Risk: medium. Touches data: yes.

#### G3-B07 Import ignores Step Rate, Notes, Commission (lossy round trip)

- Severity: wrong number (silent omission).
- Where: csv_import_screen.dart:593-615 versus ledger_entry.dart:500-522.
- Fix: logic L-04. Redesign shows an info line "Step Rate, Notes and Commission are not imported" (copy only).
- Touches data: yes.

#### G3-B12 Agent rename can duplicate an existing agent name

- Severity: wrong number (two agents with the same name; by-agent totals in Portfolio and Stats group by name).
- Where: lib/features/agents/agents_screen.dart:267-287 (edit has no `getAgentByName` check; add has, 172-182).
- Fix: same check on edit (excluding the agent itself). Logic L-07 (validator).
- Touches data: yes.

### 4.3 Data loss (7)

#### D-01 Google Drive scope is wider than needed

- Severity: data loss (privacy exposure, security)
- Where: `google_drive_service.dart` (full Drive scope requested; BACKLOG.md, docs/v2.0.0-review.md 3.2)
- Fix: narrow to `drive.file` or app data folder; requires re-consent.
- Risk: high (existing sign-ins break). Touches data/sync/models: yes (sync)

#### D-02 Restore is not atomic

- Severity: data loss
- Where: `DatabaseService.restoreBackup` clears all boxes before rewriting (BACKLOG.md)
- Fix: validate then swap, or write to temp boxes first.
- Risk: high. Touches data/sync/models: yes

#### D-03 UI writes during a sync merge can be lost; tombstone pruning ignores oldest device

- Severity: data loss
- Where: `SyncService._merge`, ARCHITECTURE.md danger zones (30 day tombstone pruning; a device offline longer resurrects deleted entries)
- Fix: write queue during merge; prune relative to the oldest device sync.
- Risk: high. Touches data/sync/models: yes (sync)

#### D-04 Auto backup can overwrite a remote snapshot that has a higher version

- Severity: data loss
- Where: auto backup path (BACKLOG.md; manual sync already refuses)
- Fix: same refusal as sync.
- Risk: medium. Touches data/sync/models: yes (sync)

#### G3-B02 Double import possible (duplicate bills)

- Severity: data loss (duplication).
- Where: csv_import_screen.dart:75-78 (primary button always enabled), 148 (`_importEntries()` without re-entrancy guard), 629-703.
- Repro: reach step 3, double-click Import quickly (macOS) or double-tap.
- Expected: one import. Actual: `_isImporting` is set but not checked; a second call re-imports the same `_validEntries` with new ids (`LedgerEntriesNotifier.importEntries` saves each with its uuid).
- Fix: early `if (_isImporting) return;` and disable controls while importing (UI guard only; the redesign disables Back and primary).
- Risk: low. Touches data: yes (prevents duplicates).

#### G3-B03 Importing the same CSV twice duplicates every bill

- Severity: data loss (duplication). 
- Where: csv_import_screen.dart:593 (new uuid per row), lib/core/providers/ledger_provider.dart:139-144.
- Expected: warn or skip rows whose bill number, agent and date already exist. Actual: no duplicate detection.
- Fix: duplicate check in `_validateAndParse` against existing bills (logic) or at least a UI warning (redesign adds a standing hint). Logic request L-02.
- Risk: medium. Touches data: yes.

#### G3-B10 Restore asks for confirmation before the file is chosen and never validates the file

- Severity: data loss.
- Where: settings_screen.dart:243-290; database_service.dart:373 (clear first, then restore, non-atomic: MEMORY.md open bug).
- Repro: Restore Backup, confirm, pick any .json file with a JSON object. `restoreBackup` clears all boxes then reads keys with defaults (`?? []`), so a wrong but valid JSON object wipes everything and restores nothing.
- Fix: UI order (pick, show summary, confirm) is in the redesign; atomic restore or pre-validation is logic L-06.
- Touches data: yes (L-06).

### 4.4 UI only (1)

#### B-19 Screens call DatabaseService directly

- Severity: UI only (convention breach; stale-data risk)
- Where: export screens (22 + 22 uses), settings 4, side forms 3 each, ledger forms 2 each, `portfolioSourceProvider(true)` reads boxes inside a provider
- Fix: LR-10 (providers).
- Risk: medium. Touches data/sync/models: yes (data access path)

### 4.5 Cosmetic (3)

#### D-05 MANAGE_EXTERNAL_STORAGE permission declared but not needed

- Severity: cosmetic (Play policy risk)
- Where: Android manifest (BACKLOG.md)
- Fix: remove; SAF is used.
- Risk: medium (storage behavior on API 30-32). Touches data/sync/models: no

#### D-06 MiniLedgerEntry model, box and sync path are orphaned

- Severity: cosmetic (maintenance, extra sync payload)
- Where: `mini_ledger_entry.dart`, `DatabaseService`, `SyncService`
- Fix: remove or wire (BACKLOG.md); removal touches schema and sync.
- Risk: high. Touches data/sync/models: yes

#### D-07 `PlatformHelper.isDesktop` includes Windows and Linux

- Severity: cosmetic
- Where: `platform_helper.dart`; `GoogleDriveService._isDesktop` is Windows/Linux only (placeholder credentials)
- Fix: macOS-only checks where chrome differs.
- Risk: low. Touches data/sync/models: no

#### D-08 macOS fate (decision, not a bug)
- Severity: cosmetic (maintenance)
- Where: `macos/`, `lib/features/navigation/desktop_shell.dart`, `lib/core/services/desktop_auth_service.dart`, `window_manager`, every `PlatformHelper.isDesktop` branch
- The app is Android only from 2026-10-13; this code is frozen: not edited, not deleted by the revamp. Options for a separate later decision: keep building, archive on a branch, or delete.
- Risk: none now. Touches data/sync/models: no
