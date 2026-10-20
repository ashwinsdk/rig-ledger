# Logic Requests (out of scope for the revamp)

These improvements need a change to models, providers, services, calculations, validators, field meanings, navigation outcomes or export content, so they are NOT part of the redesign. Each is listed with why it matters. Items LR-01 and LR-02 are the two approved exceptions from the brief (B1, B2) written as precise requests. The per-area audits append their own requests in the sections at the end.

| ID | Request | Why it matters | What would change | Status |
|---|---|---|---|---|
| LR-01 (B1) | One shared `switchRig(ref, vehicle)` used by the Ledger header sheet, the desktop title bar and the Portfolio header | the three copies differ today: desktop does not `await setCurrentVehicle` and does not clear search/filter (B-01, B-02); Portfolio needs a third copy | extract the existing mobile handler body into one function; await `setCurrentVehicle`, clear `searchQueryProvider` and `ledgerFilterProvider`, run the eight `refresh()` calls | APPROVED 2026-10-13 (answer 13). Verified provider list and order in DESIGN_DIRECTION_APPLE.md 8.1; also clears the four side ledger filters |
| LR-02 (B2) | `CashViewConfigNotifier.setAnchor(DateTime)` | the Daily date picker must set the anchor while keeping `period == daily` and the arrows; `setDay` switches to a custom range and `shift` moves one step | one method: `state = state.copyWith(anchor: dateOnly(d), clearCustomRange: true)` | APPROVED 2026-10-13 (answer 14) |
| LR-03 | Calendar day tap in the Ledger Calendar view opens that day's bills (or switches to Daily on that day) | the calendar shows totals but is a dead end (no `onTap`) | new tap behavior and a way to set the day in `selectedMonthProvider`/daily state | PROPOSED (the mockup shows tap on a calendar day, J "Calendar view with selected day"); not in the first pass |
| LR-04 | Account Ledger weekly, monthly and yearly pickers (tap the label to jump) | consistency with B2 | reuse `setAnchor` plus month/year picker UI | not scheduled |
| LR-05 | Search debounce (250 ms) on the Ledger search | writing the provider on every keystroke refilters the list each key; matters for 2,000+ bills | timing change in `SearchSheet` onChanged | not scheduled |
| LR-06 | Undo after delete (snackbar Undo) for bills, payments and Account Ledger entries | destructive action safety; trash exists only for Account Ledger | new restore path for bills/payments (tombstones interplay with sync) | not scheduled, high risk (sync) |
| LR-07 | Persist the collapsed or expanded header state and the last chosen period | reduces repeated taps | new settings keys | not scheduled |
| LR-08 | "Share bill as image or PDF" from the bill card | frequent field need (inferred, ask) | new export | not scheduled, needs a requirement |
| LR-09 | Unified period model for Ledger, Side Ledger, Portfolio and Account Ledger (one provider shape, one chip set) | four implementations today (I-33) | provider refactor | not scheduled |
| LR-10 | Replace direct `DatabaseService` reads in screens with providers (export screens 44 uses, settings 4, side forms 3 each, ledger forms 2 each, `portfolioSourceProvider(true)`) | convention breach, blocks memoization, can show stale data | provider additions and screen changes that touch data access | needs approval (data path) |
| LR-11 | Make backup restore atomic and queue UI writes during sync merge | data-loss risk (BACKLOG.md, v2.0.0 review) | service changes | see BUGS_FOUND.md data section |
| LR-12 | Run PDF generation off the UI isolate (`compute`) | large exports can freeze the window | service change | only if profiling shows a stall |
| LR-13 | Feet display: decide rounding for summary versus card (B-09) | wrong-looking numbers: summary `#,##0` hides decimals that the card shows | formatting rule only if the summary should show decimals; no calculation change | DECIDED 2026-10-13 (answer 16): up to one decimal, trailing .0 hidden. Caveat: inputs allow more decimals (DESIGN_DIRECTION_APPLE.md 8.2); input restriction is LR-30 (proposed) |
| LR-14 | Cmd+F handler body (focus search on the Ledger tab) | the shortcut is registered but empty (B-05) | handler body | DROPPED 2026-10-13: macOS is out of scope (answer 15) |
| LR-15 | Keyboard shortcut for "collapse header" and "go to today" in the Account Ledger | desktop efficiency | new shortcuts | DROPPED 2026-10-13: desktop shortcuts are out of scope |
| LR-16 | Currency symbol and Indian lakh grouping as a user setting | decision pending (Rs. versus the rupee sign); the Account Ledger already has number-style settings | settings key and provider | CLOSED 2026-10-13: rupee sign and en-IN grouping everywhere, not a setting (answer 3, LR-24) |
| LR-21 (Apple direction) | Daily cumulative series for received and billed, for any period, scope and agent | the Portfolio "Collection" insight card draws a line over the days of the period with a scrub marker; the app has totals only, no per-day series | one derived provider, `portfolioSeriesProvider(range, scope, agent)`, pure derivation from existing ledger entries (no model change); mockup computes it in `pfSeries()` and flags it | proposed |
| LR-22 (Apple direction) | Comparison to the average of earlier periods, and the generated sentence on each insight card ("You have collected 80 percent...", "Expenses were X, mostly on Y") | Health-style highlight cards need "this period versus average" legends | derived provider plus a definition of "average" (mean of the previous 3 equal periods is the mockup's stand-in: the previous month only); sentences are UI text from existing numbers | proposed, deferred: metric cards ship first, definition still to approve |
| LR-23 (Apple direction) | Persist the appearance choice (System, Light, Dark) and the accent | the new Appearance row in Settings; today the app is light only (CONVENTIONS.md) | one settings key (Hive settings box) and a `themeModeProvider`; accent only if a brand colour is approved (Q-Brand) | APPROVED 2026-10-13, System by default; overrides the "light only" convention |
| LR-24 (Apple direction) | Account Ledger display defaults: rupee sign instead of `Rs.`, date format `d MMM yyyy` | the mockup shows one money format everywhere (TOKENS.md section 7) | change of the default values of existing Account Ledger settings (number style, date format) and a one-time migration of the stored choice if the owner wants to keep it | APPROVED 2026-10-13 for the rupee sign; date format default still to confirm. Answers LR-16's Rs. question |


The mockup also shows tap on a Ledger calendar day (list of that day's bills below the grid). That is LR-03, not new.

## Status after the developer's answers of 2026-10-13

macOS is out of scope (frozen, not edited or deleted). Every item below is either APPROVED (may be implemented in its task), PROPOSED (written down, waiting for a yes) or DROPPED. Nothing in the mockup needs a logic change that is not on this list: the full mockup-versus-code comparison is DESIGN_DIRECTION_APPLE.md section 8.4.

| ID | Request | Why it matters | What would change | Status |
|---|---|---|---|---|
| LR-25 | Discard-changes prompt on every bill and side ledger form, and on the Account Ledger entry, transfer and note forms, only when there are unsaved edits; also on Android back (`PopScope`) | unsaved typing is lost silently today (B-G1-14) | dirty-state check from the form controllers versus their initial values; `PopScope(canPop: !dirty)`; the alert uses the shared alert; no data change | APPROVED 2026-10-13 (answer 9) |
| LR-26 | Add Items dialog (Account Ledger): warn when a half-typed row exists on OK (item, quantity or rate filled but not added) | the row is silently dropped and the entry amount is set from the other rows (G2-B11) | dialog validation on OK: alert "Add this row or discard it" with Add and Discard; no calculation change | APPROVED 2026-10-13 (answer 19) |
| LR-27 | Add Account: Save disabled while the name is empty | today an empty name closes silently (PARITY-003) | Save enabled state; PARITY-003 is superseded | APPROVED 2026-10-13 (answer 19) |
| LR-28 | Clear All Data warns that Account Ledger books and notes are erased too; Restore asks for the file first, then confirms | G3-B09 (undisclosed scope), G3-B10 (confirmation before the file is chosen) | dialog text and the order of two steps in `settings_screen.dart`; the operations themselves are unchanged; file validation before restore is a separate data item (BUGS_FOUND.md D-02) | APPROVED 2026-10-13 (answer 18) |
| LR-29 | Side ledger "Pending" summary must not net advances: sum only entries with pending above zero and show advances separately (or not at all) | verification found that the summaries add signed pending, so an overpaid entry lowers the total due (DESIGN_DIRECTION_APPLE.md 8.3, B-G1-09) | the summary calculation in the four side lists, the Side Ledger home and the Stats side tabs; per-entry pending (total minus paid) is unchanged | PROPOSED (answer 20 assumed no netting; the code nets) |
| LR-30 | Limit feet inputs (depth, PVC, MS pipe) to one decimal | answer 16 shows one decimal; inputs accept more | input formatter regex in the bill and side bore forms | PROPOSED (Q-O5) |
| LR-31 | CSV import: map depth feet, rates, extra charges (and step rate, notes, commission) from the app's own export instead of importing zeros | G3-B01, G3-B07: silent zeros on a round trip | auto-mapping table in `csv_import_screen.dart`; data written by import changes | APPROVED 2026-10-13 (answer 17), Phase 1; explicit yes already given for this item only |
| LR-32 | Double-tap Save must create one record | B-G1-01 and the same pattern in transfer, note, vehicle, agent and import | `_saving` flag in each Save handler (UI guard) | APPROVED 2026-10-13 (answer 17), Phase 1 |
| LR-33 | Calendar day totals must not mix months | B-03: `calendarDayTotalsProvider` keys by day of month only | key by full date, or restrict to the selected month; the Calendar toggle behaviour for other periods is decided in the task (default: totals computed for the selected month only) | APPROVED 2026-10-13 (answer 17), Phase 1 |
| LR-34 | A real loading and error state for the ledger lists | the mockup shows Ledger error and loading states; Hive reads are synchronous and cannot fail visibly today | none unless wanted: first-frame skeleton only after a rig switch or restore (UI); an error state needs a failure path in the notifiers | PROPOSED (default: no new state, mockup error screens used only for sync, import, export) |
| LR-35 | Appearance and accent storage | LR-23 detail | one key in the settings box (for example `themeMode` with values system, light, dark); `themeModeProvider`; no Hive schema change, no `schemaVersion` bump, no sync of this key (device setting) | part of LR-23, APPROVED |

LR-23 (Appearance) and LR-24 (rupee sign, `d MMM yyyy` default) are APPROVED as recorded above. LR-21 and LR-22 stay PROPOSED: metric cards ship first and the insight cards wait for a separate yes. LR-10, LR-11 and the data and sync items (BUGS_FOUND.md section 4) need plan mode and one explicit yes per item.

## Items appended by the audits

Appended verbatim from the audits. None is part of the redesign.

### L1. Forms and side ledger (g1)


Format: id, title - why it matters - what logic would change.

- L-01 Undo for deleting a side ledger entry - deleting a diesel, PVC, bit or hammer entry is immediate and permanent (`deleteEntry`); a mis-tap loses a bill, and the redesign cannot offer Undo - the delete would need a soft delete (tombstone/trash like Account Ledger) in the side ledger notifiers and `DatabaseService`, plus sync merge handling.
- L-02 Handling of stored types outside the form option lists - an old entry whose type string is not in `pvcTypes`, `bitTypes` or `hammerTypes` cannot be saved (B-G1-06) - either the save validation must ignore unknown legacy types, or data migration must normalize the type strings.
- L-03 Date range of side bore and side ledger pickers - `firstDate` 2020 and `lastDate` now + 365 differ from the main form (2000 to 2100) and produce an assertion for out-of-range entries - the allowed date range (a validation rule) would change if the product wants consistency; the redesign only clamps `initialDate`.
- L-04 Block Apply when a filter start date is after the end date - today the list silently empties - the filter validity rule in the four filter sheets/providers would change (redesign only shows a message).
- L-05 Idempotent add in notifiers - the redesign's `_saving` guard is UI only; a double submission from another path (macOS Enter plus click) would still create two entries - `addEntry` could ignore a second entry with an identical content hash within a short window, or accept a client-generated id created once per form instance (the id is created per `_saveEntry` call today).
- L-06 Definition of Pending in side ledger summaries - `totalPending += entry.pending` includes negative values, so advances reduce the total due (B-G1-09) - the summary calculation could sum only positive pending and show advances separately.
- L-07 Bill number format - main and side bore bills accept letters; side ledger bills are digits only; the uniqueness check is case-insensitive for bills and case-sensitive exact match for side ledger entries - one rule across all would change validators (`digitsOnly`, comparison).
- L-08 Rate display rounding in the PVC/Bit/Hammer cards - details show rates with `toStringAsFixed(0)` (a rate of 12.50 shows as 13) while totals use exact values - a formatting rule in the card text; changing the displayed precision is allowed as display, but the model's `TypeDetail.displayDetailed` text (used in exports) must not change.
- L-09 Type filter matches only the first stored type - an entry with 7 inch and 8 inch is not found by filtering "8 inch" - the filter predicate would change to match any type in `types`/`typeDetails`.
- L-10 Search by Bit ID and Hammer Name in list filters - IDs and names are stored but not searchable - new filter fields in `BitFilter`/`HammerFilter` and the predicate.
- L-11 Numeric validation on main bill form - no validators on rates, feet, less; negative impossible but empty and 0 accepted, and `Total` can be manually typed to 0 - new validators would change what can be saved.
- L-12 Bill duplicate check cost - `getAllLedgerEntries()` scans the vehicle's entries on every keystroke; a cached set of bill numbers in the provider would remove the scan (UI debounce is allowed and sufficient for now).
- L-13 Payment removal linked to a receiver book - removing a payment from the form and saving trashes the linked Income entry (PaymentLinkService); a user-visible warning needs the form to know whether a payment is linked, which is a read of existing data (allowed) but any confirmation tied to the link outcome changes nothing in logic.


### L2. Account Ledger (g2)


Format: id - title - why it matters - what logic would change.

- L-01 Keep Account Ledger destinations inside the right pane on desktop - on macOS the hub destinations are pushed on the root navigator and hide the shell sidebar and the hub list; users lose context - an inner `Navigator` or `Router` in `CashbookRootScreen` would change the navigation structure (push target), not any provider. Needs developer approval because "navigation outcomes" are frozen.
- L-02 Currency symbol Rs. versus the rupee sign - Account Ledger prints "Rs. 5,000" while the rest of the app uses the rupee sign; MEMORY.md lists this as an open decision; PARITY-084 allows either - `CashbookCalculator.formatMoney` (lib/core/utils/cashbook_calculator.dart:215-220) and the PDF/CSV export of Account Ledger would change; export content is frozen so confirm before touching.
- L-03 Cache `NumberFormat` instances in `CashbookCalculator.formatNumber` - a new `NumberFormat` is constructed on every call (calculator:210); lists with hundreds of rows pay this per frame - make the formatters `static final` per pattern; no output change.
- L-04 Day header pattern and default date format - `CashSettings.formatDayHeader` uses 'EEE, MMM dd yyyy' (provider:103), default `dateFormat` is 'MMM-dd-yyyy' (provider:56); DESIGN_SYSTEM section 10.3 proposes 'EEE, dd MMM yyyy' and a default of 'dd MMM yyyy' - default change only for new installs (stored user setting wins); day header should follow the chosen date format.
- L-05 Entry form edit should save a copy - the edit path mutates `widget.entry` before `updateEntry` returns (cashbook_entry_form_screen.dart:205-217); on an error the in-memory object already holds the unsaved values (G2-B09) - build a copy via `copyWith` and pass it to `updateEntry`.
- L-06 Delete copied bill files on remove and on discard - cashbook_entry_form_screen.dart:139-147 and 592-593 leave orphans (G2-B10) - add file deletion for attachments not present in the saved entry; sync must still keep files referenced by saved entries.
- L-07 Unsaved-changes guard for the entry form - PARITY-050 says Back discards without a prompt (reference app behavior); a discard confirm would be friendlier but changes the parity line - needs approval.
- L-08 Transfer: exclude the From book from the To list and refuse same-book before calling the provider - today the provider refuses same-book with an error snackbar (PARITY-058 logic); UI-only filtering is allowed but picking a default `_to` is already done in `initState`; keep as improvement only.
- L-09 Month/range label strings from `CashbookCalculator.rangeLabel` use an ASCII arrow and a fixed format and also feed the exports via `.replaceAll(' -> ', ' To ')` (home:105, report_dialog:144) - coupling between screen label and export text; split the two before changing either.
- L-10 Book totals on the Accounts screen are recomputed per book per build from the full entries list (books_screen:107-108) - a provider `cashBookBalancesProvider` computing the map once would remove the O(books x entries) work.
- L-11 Run the import preview and import off the UI isolate - `CashbookImportService.preview` and `run` are called on the UI isolate (cashbook_import_screen.dart:44, 70); a large source database blocks frames - moving the sqlite read to `compute` or `Isolate.run` changes the service, not the screen.
- L-12 Build PDF off the UI isolate - `CashbookExportService.buildPdf` is awaited on the UI isolate (cashbook_report_dialog.dart:44-47); a long report janks the progress indicator - run the document build in an isolate (service change); font loading stays on the main isolate.


### L3. Agents, settings, exports, stats (g3)


Format: title - why it matters - what logic would change.

- L-01 Fix CSV import auto-mapping - the app cannot re-import its own CSV export without manual fixes and silently zeroes depth feet, rates and extra charges (bugs_g3 G3-B01) - `_autoMapColumns` in csv_import_screen.dart: exact match first, aliases for the exported headers ("Bill Number", "Agent Name", "Depth Type", "Depth (feet)", "Depth Rate/ft", "PVC Type", "PVC (feet)", "PVC Rate/ft", "MS Pipe Type", "MS Pipe (feet)", "MS Pipe Rate/ft", "Extra Charges", "Total"), then `contains`.
- L-02 Duplicate detection on CSV import - importing the same file twice doubles every bill - `_validateAndParse` or `LedgerEntriesNotifier.importEntries` compares bill number + agent + date with existing bills and skips or flags duplicates.
- L-03 Date parsing options in CSV import - non-ISO dates (dd/MM/yyyy) all fail and an empty date silently becomes today - `_validateAndParse` date handling: accept dd/MM/yyyy and dd MMM yyyy; treat empty date as an error row.
- L-04 Import Step Rate, Notes, Commission (and payments) from CSV - round trip loses data - `_validateAndParse` constructs `LedgerEntry` with more fields; `isTotalManuallyEdited` handling.
- L-05 `firstWhere` without `orElse` in `_importEntries` - an unexpected agent miss aborts the import after agents were created - add `orElse`, or create agents and entries in one guarded step.
- L-06 Atomic restore and pre-validation - restore clears all boxes before reading the backup; a wrong JSON wipes the device (already in MEMORY.md as open bug) - `DatabaseService.restoreBackup`: validate schema and keys first, write to temporary boxes or keep a pre-restore snapshot, swap on success; also decide whether `clearAllData` should keep tombstones (risk of Drive resurrecting deleted records, UNVERIFIED).
- L-07 Duplicate agent name check on edit - rename can create two agents with the same name which merges them in name-keyed totals - `agentsProvider` / agents dialog validator: reuse `getAgentByName` excluding the agent being edited.
- L-08 Plain-language Drive sign-in errors - end users see keytool and Firebase instructions - `GoogleDriveService.signIn` error mapping: user message for ApiException 10, log developer text with `debugPrint` only.
- L-09 Move PDF and CSV generation and CSV parse off the UI isolate - large ranges freeze the UI and the progress indicator - use `compute`/`Isolate.run` for `_generatePdf*`, `ListToCsvConverter.convert` and CSV decode and validation (frozen content, only the execution context changes; Hive access must stay on the main isolate so entries are read first and passed as plain data).
- L-10 Settings sync status - the Settings Drive card shows last backup time but not sync state/errors from `syncProvider` - read `syncProvider` state in the card (needs the provider to expose last error and time; verify what it already exposes).
- L-11 Vehicle type change on a rig that has entries - flipping Main Bore and Side Bore hides or shows PVC fields on existing data without migration - decide whether the type should be locked once entries exist (model/provider rule).
- L-12 "Other agents" grouping in the By Agent donut - more than 6 agents make the chart unreadable; the existing logic groups nothing - aggregate agents beyond the top N into one slice (calculation change).
- L-13 Stats `lastYear` range semantics - "Year" covers the first day of this month last year to the end of this month (13 months) and 3 Mo and 6 Mo include the current month - decide if labels or ranges should change (`_getDateRange`); the redesign only displays the actual range under the chips.
- L-14 Multi-type piece counts (UNVERIFIED) - per-type pieces can sum to more than "Total Count" for entries with several types (stats_screen.dart:1048-1058) - confirm the meaning of `count` and fix the tally if needed.
- L-15 Permission request timing on Android 11 to 12 - system storage screen opens before the first frame with no explanation - move `_requestPermissions()` to first use (backup/export) or after the first frame (changes when the request happens; store-policy related, see MEMORY.md).
- L-16 Drive initialization off the critical path - `GoogleDriveService.initialize()` (silent sign-in) blocks `runApp` - run after the first frame (changes startup order; sync already guards on `isSignedIn`).
- L-17 Backup-before-restore - offer an automatic local snapshot file before a destructive restore or clear (new service call using existing `DatabaseService.createBackup`).
- L-18 Reversed date range handling - From after To silently yields empty results in export and stats screens - validators in the three screens or the range helpers (the redesign only shows an inline error).


## New proposed items found while reconciling the screen documents (2026-10-13)

All PROPOSED, none implemented, none needed for the first pass. Full text in the files named; IDs are stable.

### Side ledger and stats (r2)


Format: id, request, why, what would change, status. Nothing here is part of the redesign; the first pass ships the current behaviour.

#### L2-r2-1 Paid date on the PVC form
- Request: show an optional "Paid date" row on the PVC form (and keep it null when unset), like the Diesel form.
- Why: the mockup form `slForm` renders a "Paid date" row for `k=='diesel'||k=='pvc'`. `PvcEntry.paidDate` exists in the model (`lib/core/models/pvc_entry.dart` line 43) but `pvc_form_screen.dart` never reads or writes it (grep finds `paidDate` only in the Diesel form).
- What would change: the PVC form gains a date field and writes `paidDate` on save and reads it on edit; no model or schema change (the field already exists in the adapter). Cards and exports are not changed.
- Default until approved: the row is omitted from the PVC form.
- Status: proposed, new.

#### L2-r2-2 Per type pieces in Portfolio Side Ledger details
- Request: in the PVC, Bit and Hammer Details groups, tally pieces per type from each `typeDetails[].count` instead of adding the whole entry `count` to every selected type.
- Why: verified in `lib/features/stats/stats_screen.dart` lines 1043 to 1050: `typeCounts[type] += entry.count` for every type of an entry, but `entry.count` is the sum over all types (DESIGN_DIRECTION_APPLE.md 8.3). A bill with 7 inch (10) and 8 inch (5) shows 15 pcs under both types. The list screens use the per type counts and are right. Wrong number, display of a calculation.
- What would change: the per type tally loop in the stats Details (and the same tally if any other summary reuses it). `totalCount` (sum of entry counts) is unchanged.
- Default until approved: current numbers are kept (parity P-stats 54 is a baseline), the indented per type rows stay.
- Status: proposed, new. Suggest scheduling as a wrong-number fix by severity (BUGS_FOUND.md order), not Phase 1.

### Account Ledger (r3)


New proposed logic items found by group r3 (Account Ledger). Logic freeze stays: none of these is implemented.

| Id | Request | Why | What would change | Status |
|---|---|---|---|---|
| L2-r3-1 | Decide the fate of the Account Ledger "Currency Format" setting (`groupDigits`, `fixedDecimals`) now that LR-24 makes the rupee sign and en-IN grouping universal. Default proposal: `CashbookCalculator.formatMoney` and `formatNumber` delegate to the shared `RigFormat.money` (rupee sign, en-IN grouping, two decimals only with paise); the row stays with options "Grouped" (default), "Plain" and "Two decimals" applying on top; the Rs. prefix is removed. | The mockup shows the row but TOKENS.md section 7 says one formatter; the code prints "Rs." (calculator:214-219) and groups in the western style (1,234,567). PARITY-035 and PARITY-084 assert "Rs.". | `CashbookCalculator.formatMoney/formatNumber`, the `CashSettings` defaults, parity tests and the calculator tests; PDF and CSV exports keep their own format (frozen); stored settings are kept. | proposed, new (extends LR-24) |
| L2-r3-2 | Add `d MMM yyyy` to `CashSettings.dateFormats` as the default and `EEE, d MMM yyyy` as the day header (`dGroup`); keep the six existing patterns selectable; users with a stored pattern keep it. | LR-24 says the date default is `d MMM yyyy` but "still to confirm"; the code list has no such pattern and the day header (`formatDayHeader`) derives from the chosen pattern. | `CashSettings.dateFormats` list and default, `formatDayHeader`, one test; no schema change, key `cashbook.dateFormat` unchanged. | proposed, new (detail of LR-24) |

### Agents, settings, exports, theme (r4)


Format: id, request, why, what would change, status.

- L2-r4-1. Request: make the rig switch inside Vehicle Management (`_switchVehicle`, vehicle_management_screen.dart:141-162) call the shared `switchRig` of LR-01. Why: LR-01 names three copies (Ledger header sheet, desktop title bar, Portfolio header) but there is a fourth: it clears only `searchQueryProvider` and `ledgerFilterProvider`, refreshes ledger, diesel, pvc, bit, hammer and agents, then pops; it does not clear the four side filters or refresh vehicles. What would change: the body of `_switchVehicle` becomes one call plus the snackbar and pop; no behaviour is lost, the four side filters are also cleared. Status: proposed, new (extends approved LR-01).
- L2-r4-2. Request: extend the LR-25 discard prompt (PopScope with a dirty check) to the Agent Add or Edit sheet and the Rig Add or Edit sheet. Why: LR-25 lists bill, side ledger and Account Ledger entry, transfer and note forms only; the agent sheet has six fields (name, phone, notes, three rates) and loses them on back. What would change: wrap the two sheets in UnsavedChangesGuard; dirty means any controller differs from its initial value; no data change. Status: proposed, new. Default if not approved: no prompt.
- L2-r4-3. Request: one private function that refreshes the 12 providers after restore and after clear, replacing three copies in settings_screen.dart. Why: any new provider must be added three times today (old problem 15). What would change: pure refactor, same calls. Status: proposed, new (low priority, no user-visible effect).
- L2-r4-4. Request: decide how the final AppColors deletion treats macOS code. `desktop_shell.dart` references `AppColors` 21 times, so deleting `AppColors` (or `AppTheme`) breaks the macOS build, which must keep compiling (answer 15: shared code touched by the revamp must still compile there). What would change: either keep a frozen copy of `app_colors.dart` and the three gradient constants used by desktop code under a macOS-only name, or leave `AppColors` aliased until the macOS decision (D-08). Status: proposed, new, needs a developer decision before the cleanup task.


Related note for LR-01: Vehicle Management has a FOURTH rig-switch handler (`_switchVehicle`, `vehicle_management_screen.dart:141-162`, L2-r4-1). T-X10 replaces it with `switchRig` too. The frozen desktop shell keeps its own copy.
