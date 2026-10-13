# RigLedger - Current Tasks

Active work only. Tech debt and known gaps go in `BACKLOG.md`. Finished tasks move to `DONE.md` (not auto-loaded).

Task format:

```
## T-XXX Title [PENDING|IN_PROGRESS|DONE|BLOCKED]
Goal:
Files:
Depends:
Resume notes:
Commit:
```

## v2.0.1 PLAN (source: developer bug list of 2026-10-13, Flutter app only, APPROVED 2026-10-13)

Rules for this plan: no `macos/`, `desktop_shell.dart` or `desktop_auth_service.dart` edits (frozen; `agents_screen.dart` stays because the desktop shell imports it). One Hive schema bump for the whole release: 5 -> 6, done in the first task that needs it (T-H06 or T-H10, whichever runs first). Every task: `flutter analyze`, update MODELS.md/ARCHITECTURE.md when a model or box changes, commit, never push. Order is by dependency.

DECISIONS CONFIRMED 2026-10-13: step rate for new types = none by default with an optional 7 or 8 inch table per type; rename updates all bills and agent prices, delete is blocked while in use; Account Ledger filled Save returns, outlined Add another keeps the form.

## T-H01 File save and storage permission (bug 11) [DONE]
Goal: saving a PDF, CSV or backup works on Android 11 and up. Remove the redundant `File(result).write...` after `FilePicker.saveFile` (the picker already writes through SAF; the second write hits Permission denied), remove the runtime storage permission gate and the launch-time request, drop `MANAGE_EXTERNAL_STORAGE` and the dead `requestLegacyExternalStorage` from the manifest (READ/WRITE_EXTERNAL_STORAGE limited with `maxSdkVersion`), catch save errors in `FileSaveService` and fall back to Share with a clear message, and encode CSV/JSON with `utf8.encode` (today `codeUnits` corrupts the rupee sign and Tamil text).
Files: lib/core/services/file_save_service.dart, lib/main.dart, android/app/src/main/AndroidManifest.xml, callers in lib/features/export, cashbook_report_dialog.dart, settings_screen.dart, .claude/context/ARCHITECTURE.md (Android specifics), docs/v2.0.0-review.md note
Depends: none
Resume notes: FileSaveService rewritten (SAF only on Android, no second write, Share fallback on failure, UTF-8), main.dart permission request removed, manifest MANAGE_EXTERNAL_STORAGE and requestLegacyExternalStorage removed, READ/WRITE limited by maxSdkVersion. analyze 210 infos (unchanged), 68 tests pass. Not verifiable here: a real save on an Android 11+ device. BACKLOG.md entry for MANAGE_EXTERNAL_STORAGE left untouched (developer has uncommitted edits there); mark it done when convenient.
Commit: Fix PDF and file saving without storage permission

## T-H02 Account Ledger: return to the ledger after saving (bug 10) [DONE]
Goal: a new entry returns to the Account Ledger home. Cause found: "Save and continue" is the filled primary button and by design keeps the form open; "Save and exit" is the outlined one. Proposal: filled "Save" = save and return, outlined "Save and add another" keeps the form (resets amount, notes, items, bills), and an empty amount shows an inline error instead of doing nothing.
Files: lib/features/cashbook/cashbook_entry_form_screen.dart (lines about 199-259 and 624-646), test/cashbook_flow_add_test.dart
Depends: none
Resume notes: filled Save returns to the ledger, outlined Save and add another keeps the form (clears amount, notes, items, bills), empty amount shows an inline 'Enter an amount' error, the 'Saved' snackbar is 1 second so it does not cover the buttons (showCashSnack got a duration param). Tests: flow tests use Save, new test/cashbook_flow_save_test.dart. analyze 210 infos (unchanged), 69 tests pass.
Commit: Return to Account Ledger after saving an entry

## T-H03 Account Ledger: same look as the ledger pages (bug 9) [DONE]
Goal: Account Ledger home uses the main ledger visual language. Period chips and date navigator move into the gradient header with the same pill style; the totals become a top summary card (radius 16, shadow, icons, rupee format) instead of the bottom strip; rows become floating cards (radius 16, soft shadow, 16 pt side margin) with day headers; Income and Expense colours use AppColors success and error; empty state with icon. Logic and providers unchanged.
Files: lib/features/cashbook/cashbook_home_screen.dart, widgets/cashbook_header.dart, cashbook_period_bar.dart, cashbook_row.dart, cashbook_totals_strip.dart, cashbook_common.dart, pushed screens' cashAppBar (use AdaptiveHeader style)
Depends: none
Resume notes: mobile header holds the pill chips and the white date navigator (desktop keeps them below the slim header); totals are a top card (radius 16, shadow, icons, rupee format) via the restyled CashbookTotalsStrip, which the other cashbook screens still show at the bottom; entries are floating cards with scaled amounts; plain day headers; icon empty state; CashColors now AppColors.success and error; money prefix is the rupee sign on screen (CashbookCalculator.formatMoney; exports use formatNumber and are unchanged). PlatformHelper.debugIsDesktopOverride added for tests; new test/cashbook_home_layout_test.dart caught and fixed an amount overflow. Pushed cashbook screens keep cashAppBar. 70 tests pass, analyze 210 infos. Not verified on a device.
Commit: Restyle Account Ledger to match the ledger pages

## T-H04 Shared rig switcher (LR-01) [DONE]
Goal: one `switchRig(ref, vehicle)` (await setCurrentVehicle, clear search and ledger filter, refresh all providers) and one reusable rig picker sheet, used by the Ledger header and Vehicle Management (desktop shell keeps its own copy).
Files: new lib/core/providers/rig_switch.dart and lib/core/widgets/rig_picker_sheet.dart, lib/features/home/combined_home_screen.dart (about 1081-1195), lib/features/settings/vehicle_management_screen.dart (about 141-162), test/switch_rig_test.dart
Depends: none
Resume notes: lib/core/providers/rig_switch.dart (switchRig: awaits setCurrentVehicle, clears search, ledger filter and the four side filters, refreshes ledger, diesel, pvc, bit, hammer, agents; returns false if already current) and lib/core/widgets/rig_picker_sheet.dart (showRigPickerSheet with onSwitched). Used by the Ledger header sheet and Vehicle Management. Desktop shell keeps its own copy (frozen). test/switch_rig_test.dart. 71 tests pass, analyze 0 errors.
Commit: Extract shared switchRig and rig picker sheet

## T-H05 Portfolio: change rig and clearer All rigs / This rig (bugs 7, 8) [PENDING]
Goal: the rig name in the Portfolio header is a tappable pill that opens the rig picker and changes the global rig; the This rig / All rigs choice becomes a clear two-option control next to it (new `portfolioScopeProvider` so header and body agree); the agent chip resets when the rig changes.
Files: lib/features/stats/stats_screen.dart (header about 80-86), lib/features/portfolio/portfolio_view.dart (about 24-110), lib/core/providers/portfolio_provider.dart
Depends: T-H04
Resume notes:
Commit: Add rig switcher and scope control to Portfolio

## T-H06 Ledger types: user-defined depth, PVC and MS pipe types (bug 2, part 1) [PENDING] [HIVE/SYNC FLAG]
Goal: depth types, PVC types and MS pipe types become user-editable lists (add any inch such as 9inch; rename; delete). Seeded with the current values (7inch, 8inch / 7inch, 8inch / 6inch) so nothing changes for existing data. Stored as JSON in the settings box under `ledgerTypes.depth|pvc|ms` with an updatedAt, exposed by `LedgerTypesNotifier` (load, add, rename, delete, refresh), added to backup, restore and the Drive merge (settings box is not synced today), schema 5 -> 6. Settings screen "Ledger types" to manage the lists. Rules (proposed): rename updates every bill and every agent rate that uses the type; delete is blocked while any bill uses it (shows the count); step rate for new types follows the decision below.
Step rate decision (proposed, needs confirmation): the hardcoded 7 inch and 8 inch brackets stay; every other depth type gets NO step rate by default (0), with a per-type toggle "use the 7 inch table" or "use the 8 inch table"; no custom bracket editor in 2.0.1 (BACKLOG item stays).
Files: new lib/core/providers/ledger_types_provider.dart, lib/features/settings/ledger_types_screen.dart, database_service.dart (backup, restore, schema), sync_service.dart, ledger_entry.dart (calculateStepRate lookup), settings_screen.dart entry, MODELS.md, ARCHITECTURE.md, tests
Depends: none
Resume notes:
Commit: Add user-defined ledger types with backup and sync

## T-H07 Ledger types used everywhere (bug 2, part 2) [PENDING] [EXPORT FLAG]
Goal: the lists drive every screen: main bore form dropdowns (value always unioned into the items so editing an old bill never crashes), filter sheet, ledger card chips, `feetTotalsProvider` made dynamic (map per type, an Other bucket for unknown strings; side bore total depth from all entries), both duplicated PDF totals blocks, CSV import (unknown imported types are offered to be added), CSV and PDF type columns unchanged.
Files: ledger_form_screen.dart (about 683-867), filter_sheet.dart, ledger_provider.dart (about 298-333), summary_row.dart, ledger_list.dart, pdf_export_screen.dart (about 600-702 and 916-1093), csv_import_screen.dart (about 600-605), side_bore_form_screen.dart (placeholders), tests
Depends: T-H06
Resume notes:
Commit: Use user-defined ledger types across screens and exports

## T-H08 Agent commission per type (bug 3) [PENDING] [HIVE FLAG]
Goal: an agent has a static price per foot for each depth type, each PVC type and each MS pipe type, plus the existing three numbers kept as the fallback for types without a price. New `Agent.commissionRatesJson` (HiveField 10, key `depth:7inch`), helpers `rateFor(category, type)`, new agent dialogs with a per-type editor, forms re-apply the agent price whenever the agent or a type changes (unless the rate was typed). Bills keep their three stored rates, so old bills, totals and exports are untouched. Rename and delete of a type update the map (T-H06 rules).
Files: agent.dart (+ build_runner), agent_provider.dart, agents_screen.dart dialogs (extract to lib/features/agents/agent_dialogs.dart), ledger_form_screen.dart, side_bore_form_screen.dart, MODELS.md, tests (map round trip, fallback, old backup)
Depends: T-H06
Resume notes:
Commit: Add per-type commission prices to agents

## T-H09 Commission clearly visible on each ledger entry (bug 6) [PENDING]
Goal: in the bill form the commission section shows separate totals (Depth, PVC, MS pipe, Total commission, marked "manual" when overridden) in a read-only breakdown, commission rows appear in the Calculation Preview under a "not in total" divider, and the bill card shows separate commission chips instead of one weak chip.
Files: commission_section.dart, ledger_form_screen.dart (about 969-989 and 1088-1146), side_bore_form_screen.dart, ledger_list.dart (about 235-247)
Depends: T-H08
Resume notes:
Commit: Show commission breakdown on bill form and card

## T-H10 Other expenses: model, database, sync, providers (bug 5, part 1) [PENDING] [HIVE/SYNC FLAG]
Goal: new side ledger category "Other expenses" for both rig types. `OtherExpenseEntry` (typeId 12; id, vehicleId, date, billNumber optional, description required, total, paid, pending, balance, paidDate, notes, createdAt, updatedAt), box `other_expense_entries`, CRUD with tombstones, backup and restore (missing key defaults to empty), clear-all, rig delete cascade, Drive merge, provider, 9th refresh call at every refresh site, schema 6 (if not already bumped).
Files: new lib/core/models/other_expense_entry.dart (+ build_runner), database_service.dart, sync_service.dart, side_ledger_provider.dart, sync_provider.dart, settings_screen.dart, vehicle_management_screen.dart, combined_home_screen.dart, main_navigation.dart, MODELS.md, ARCHITECTURE.md, CONVENTIONS.md (refresh list), tests (model round trip, sync merge)
Depends: none
Resume notes:
Commit: Add Other expenses model, storage and sync

## T-H11 Other expenses: side ledger screens (bug 5, part 2) [PENDING]
Goal: Other expenses card and mini stat on the Side Ledger tab, an Other option in the Add Entry sheet, form and list screens modelled on Diesel. Show for main bore and side bore. Fix `_getEntryDate` so the time filter works for the new type.
Files: new lib/features/side_ledger/other/other_expense_form_screen.dart and other_expense_list_screen.dart, combined_home_screen.dart (about 493-830 and 990-996), main_navigation.dart (Add Entry sheet)
Depends: T-H10
Resume notes:
Commit: Add Other expenses screens to the Side Ledger

## T-H12 Other expenses in Portfolio, Stats and exports (bug 5, part 3) [PENDING] [EXPORT FLAG]
Goal: Portfolio expenses breakdown and profit include Other expenses; Stats gets a pie and a stats card; CSV and PDF exports get the new type.
Files: portfolio_provider.dart, portfolio_calculator.dart, portfolio_view.dart, stats_screen.dart, csv_export_screen.dart, pdf_export_screen.dart, test/portfolio_calculator_test.dart
Depends: T-H11
Resume notes:
Commit: Include Other expenses in Portfolio, Stats and exports

## T-H13 Ledger home: smaller header, scrollable pinned summary (bug 1) [PENDING]
Goal: entries are clearly visible. The big header shrinks (one compact app bar row, period chips and month navigator merged into one row, smaller Daily/Calendar toggle). The pinned Total, Received, Balance, Commission and the feet totals per type become one horizontally scrollable strip. The list gets most of the screen.
Files: combined_home_screen.dart (about 68-491), summary_row.dart (rewrite), ledger_list.dart if spacing changes; dead file home_screen.dart left alone
Depends: T-H07
Resume notes:
Commit: Shrink ledger header and make pinned totals scrollable

## T-H14 Agents inside Portfolio, remove the Agents tab (bug 4) [PENDING]
Goal: mobile tabs become Ledger, Portfolio, Accounts, Settings. Portfolio gets an Agents section (all agents including ones with no bills, period totals and commission from the existing calculator, Add agent in the section header, tap opens a detail sheet to edit, delete with the existing reassign flow, and set per-type commission prices). `agents_screen.dart` stays for the frozen desktop shell and shares the extracted dialogs. Update UX docs that mention the Agents tab.
Files: main_navigation.dart, portfolio_view.dart, agent_dialogs.dart, agents_screen.dart (use shared dialogs only), docs/design/UX_FLOWS.md
Depends: T-H05, T-H08
Resume notes:
Commit: Move agents into Portfolio and remove the Agents tab

## T-H15 Version 2.0.1 and release notes [PENDING]
Goal: pubspec 2.0.1+6, MEMORY.md, BACKLOG.md, short release review of tested and untested areas.
Files: pubspec.yaml, MEMORY.md, docs
Depends: all
Resume notes:
Commit: Bump version to 2.0.1+6

v2.0.0 plan (source: v2.0.0.md). Order: T-V201..T-V208, then T-CB19, T-CB17, T-CB18, T-V209 (final test, bug and improvement review).
Assumption to confirm with the developer: commission = quantity (ft) x commission rate per unit (Rs per ft) for depth, PVC and MS pipe, never added to the bill total (v2.0.0.md example "1000 x 2", "150 x 40", "100 x 60" read as quantity x rate).

Feature: Account Ledger (cashbook replica, v2.0.0 feature 1). Full spec: `docs/features/cashbook/SPEC.md` (parity lines PARITY-001..084, decisions D1..D14). Flags: T-CB01/02/03 touch Hive models, DatabaseService and SyncService; T-CB15 touches export.

## OPEN (nothing IN_PROGRESS)
Awaiting developer: confirm commission formula (ft x rate per ft), profit definition, LICENSE copyright line, Rs. vs rupee sign. Unverified: macOS app run, real Drive sync, camera/gallery bills, share/save dialogs for new exports. Unscheduled fixes are in BACKLOG.md and docs/v2.0.0-review.md section 3.2.

## T-V201 Payment log, commission fields on LedgerEntry and Agent [DONE]
Goal: LedgerPayment (plain class, JSON in LedgerEntry.paymentsJson), commission fields on LedgerEntry (rates per unit for depth, PVC, MS pipe, commission amount, manual flag), default commission rates on Agent, schemaVersion 5, MODELS.md.
Files: lib/core/models/ledger_payment.dart, ledger_entry.dart, agent.dart, *.g.dart, database_service.dart, .claude/context/MODELS.md
Depends: T-CB02
Resume notes: LedgerPayment, LedgerEntry fields 32-37 (defaultValue on new non-null fields), Agent fields 7-9, schemaVersion 5. 9 tests including a binary compat test (records written by pre-2.0.0 adapters load with defaults). CSV/PDF columns come with T-V204.
Commit: Add payment log and commission fields to ledger models

## T-V202 Payment log editor in main and side bore forms [DONE]
Goal: replace the single Cash/PhonePe inputs with a payment log (amount, mode, date, receiver book, payer name, note); totals = unlogged base + logs; fixes the payee-add bug in the side bore form.
Files: lib/features/ledger_form/widgets/payment_log_editor.dart, ledger_form_screen.dart, side_bore_form_screen.dart
Depends: T-V201
Resume notes: PaymentLogEditor widget (list, add/edit dialog with mode, date, receiver book incl. New receiver, payer name autocomplete; Earlier received row for legacy unlogged amounts). Both forms use it; entry totals = base + logs; entry.phonePeName keeps the latest payer. phonePeNamesProvider also reads payment payers. This replaces the old PhonePe name dropdown (the payee-not-shown-until-saved bug cannot occur any more). The receiver link (Income entry in the book) is T-V203; until then payments only live on the bill.
Commit: Add payment log editor to main and side bore forms

## T-V203 Payment to receiver book link (T-CB19) [DONE]
Goal: PaymentLinkService creates, updates and trashes Income entries in receiver books from ledger payments; editing in the book updates the bill; reconcile after sync; receiver books are created from the payment dialog.
Files: lib/core/services/payment_link_service.dart, ledger_provider.dart, cashbook_provider.dart, sync_provider.dart
Depends: T-V202, T-CB05
Resume notes: PaymentLinkService (create/update/trash incomes from payments; editing the income edits the payment; trashing it keeps the payment and clears the receiver; restore relinks; deleting a book or a bill handled; reconcile at startup and inside sync before the push). LedgerEntriesNotifier, CashEntriesNotifier and AgentsNotifier now take a Ref. 8 link tests + whole suite green (replaced the broken template widget_test.dart with a theme smoke test). The Income/Expense chip lock for linked entries was added in T-CB18.
Commit: Link bill payments to receiver books in Account Ledger

## T-V204 Commission on main and side bore entries [DONE]
Goal: commission rates per entry (prefilled from agent defaults, manually editable), computed commission shown in form, list card, and the main summary bar; not added to total; agent commission defaults editable in Agents screen; CSV/PDF export column.
Files: ledger_form_screen.dart, side_bore_form_screen.dart, ledger_list.dart, combined_home_screen.dart, summary_row.dart, agents_screen.dart, export screens
Depends: T-V201
Resume notes: CommissionSection widget in both forms (rates per ft, auto calc with manual override and Auto reset, agent defaults copied to new bills), commission chip on bill cards, 4th item in the main summary bar (monthlyStatsProvider 'commission'), agent dialogs (default rates) and agent card line (agentCommissionTotalsProvider), CSV column and PDF column/summary. Commission is never added to total. Side bore uses depth only. Verified on the emulator (summary bar, side bore form, payment dialog).
Commit: Add commission to bills, agents, summary bar and exports

## T-V205 Portfolio page [DONE]
Goal: total, received, pending, commission, expenses and profit with filters (day, month, 6 months, year, all, custom, by agent).
Files: lib/features/portfolio/portfolio_screen.dart, lib/core/providers/portfolio_provider.dart, navigation
Depends: T-V204
Resume notes: Portfolio lives in the former Stats tab (renamed Portfolio): tabs Overview (new) / Ledger / Side Ledger, range chips Day, Month, 3 Mo, 6 Mo, Year, All, Custom. Overview = profit card (received - expenses - commission, plus expected profit), total/received/pending/commission cards, expenses breakdown, by-agent table, agent filter (hides expenses and profit because expenses are not per agent), This rig / All rigs toggle. Pure PortfolioCalculator with 5 tests. MODELS.md note: DieselEntry has total/paid (not amount).
Commit: Add Portfolio overview with profit, commission and agent filters

## T-V206 Side bore fixes: remove PVC, location suggestions [DONE]
Goal: no PVC anywhere for side bore vehicles (entry card, summary, side ledger, add sheets, filters, stats, exports); address autocomplete in the side bore form like main bore.
Files: ledger_list.dart, combined_home_screen.dart, side_ledger_screen.dart, filter_sheet.dart, stats_screen.dart, main_navigation.dart, desktop_shell.dart, side_bore_form_screen.dart
Depends: none
Resume notes: isSideBoreProvider; PVC hidden for side bore in bill cards, depth label, side ledger summary and category cards, add-entry sheet/dialog, filter sheet, stats charts/details, PDF columns and summary, CSV type list, Portfolio expenses. New shared AddressAutocompleteField used by both forms (side bore now has location suggestions; also removes a listener leak in the main form's old autocomplete). Payee bug: fixed by the payment dialog (T-V202). Verified on the emulator (side bore rig).
Commit: Remove PVC for side bore rigs and add location suggestions

## T-V207 App information, private license [DONE]
Goal: About screen (version from build, package id, data and privacy facts verifiable from the code, third-party licenses via Flutter license page), proprietary LICENSE file, font OFL notices.
Files: lib/features/settings/about_screen.dart, settings_screen.dart, LICENSE, assets/fonts/*
Depends: none
Resume notes: root LICENSE (proprietary, copyright line from the git author and first commit year; owner must confirm it, governing law and a contact address are intentionally omitted), declared as an asset; AppInfo (every value traceable to the repo); About screen (version from package_info_plus, data and Drive facts, Android permissions from the manifest, license text, Flutter license page with Noto OFL notices registered, developer link); replaced the old About dialog that hardcoded 'Version 1.0.7' / 'Version: 7' (pubspec said 1.0.4+4). Widget test added.
Commit: Add About screen, proprietary license and verified app information

## T-V208 Version bump to 2.0.0 [DONE]
Goal: pubspec version 2.0.0+N, MEMORY.md, docs.
Files: pubspec.yaml
Depends: all feature tasks
Resume notes: pubspec version 2.0.0+5 (build number must keep increasing for Play Store). Both platforms read it at build time.
Commit: Bump version to 2.0.0+5

## T-V209 Full test pass, bug review, improvement review [DONE]
Goal: run all tests and the app on the emulator end to end; write docs/v2.0.0-review.md with bugs found and improvement ideas; add backlog items.
Files: docs/v2.0.0-review.md, .claude/tasks/BACKLOG.md
Depends: all
Resume notes: 68 automated tests pass; emulator walkthrough of the main v2 flows; macOS app not runnable here (missing GoogleService-Info.plist). docs/v2.0.0-review.md lists tested and untested areas, 10 bugs fixed, open bugs and improvements; BACKLOG.md updated.
Commit: Add v2.0.0 review with tested areas, bugs and improvements

## T-CB01 Cashbook models and adapters [DONE]
Goal: CashBook (typeId 2), CashEntry (typeId 3), CashNote (typeId 11) with copyWith, toJson/fromJson, generated adapters. No receiverId on CashBook (receivers are just books).
Files: lib/core/models/cash_book.dart, cash_entry.dart, cash_note.dart, *.g.dart (generated), .claude/context/MODELS.md
Depends: typeId re-grep (done: 2, 3, 11 free)
Resume notes: models written, build_runner run (generated .g.dart present), flutter analyze clean for new files (only pre-existing test/widget_test.dart error remains), MODELS.md updated. Adapters are NOT registered yet (T-CB02). Committed.
Commit: Add cashbook Hive models (CashBook, CashEntry, CashNote)

## T-CB02 DatabaseService boxes, CRUD, trash, schema 4 [DONE]
Goal: register adapters, open cash_books/cash_entries/cash_notes boxes, CRUD with tombstones, trash helpers with 30 day auto-purge, schemaVersion 4, backup/restore keys with null-safe reads.
Files: lib/core/database/database_service.dart
Depends: T-CB01
Resume notes: adapters registered, 3 boxes, CRUD, trash (30 day purge at startup), default book id default_cash_book (timestamps 2000 so sync never resurrects it), schemaVersion 4, backup/restore keys null-safe.
Commit: Add cashbook boxes, CRUD, trash purge and schema 4

## T-CB03 SyncService merge for cash collections [DONE]
Goal: merge cashBooks, cashEntries, cashNotes; tolerate missing keys; refuse to overwrite a remote snapshot with a higher version (all devices must update).
Files: lib/core/services/sync_service.dart
Depends: T-CB02
Resume notes: merge covers cashBooks, cashEntries, cashNotes (missing keys tolerated); remote snapshot with higher version is refused. Provider refresh calls are added in T-CB05.
Commit: Merge cashbook collections in sync and refuse newer snapshots

## T-CB04 Calculator utility and unit tests [DONE]
Goal: running balance, previous balance, period ranges, grouping, rounding, number formatting (Rs. prefix).
Files: lib/core/utils/cashbook_calculator.dart, test/cashbook_calculator_test.dart
Depends: T-CB01
Resume notes: 10 tests pass. Rule found in the reference app: running balance restarts from the period previous balance and accumulates over the rows shown only (searches and filters get their own running balance). Weeks start Sunday (assumption).
Commit: Add cashbook calculator utility with unit tests

## T-CB05 Providers [DONE]
Goal: CashBooksNotifier, CashEntriesNotifier, CashNotesNotifier, view-config and derived providers, settings provider.
Files: lib/core/providers/cashbook_provider.dart
Depends: T-CB02, T-CB04
Resume notes: providers for books, entries (incl. transfer, trash), notes, settings (Income/Expense labels fixed), home view config and derived ledger, summary/day-summary families keyed by CashQuery record. Refresh added to sync_provider and the 3 restore/clear sites in settings_screen. Unit tests for providers not written (logic is in the calculator).
Commit: Add cashbook providers and refresh wiring

## T-CB06 Books: picker, Accounts screen, add/edit/delete, opening balance [DONE]
Goal: PARITY-001..012, 082.
Files: lib/features/cashbook/cashbook_books_screen.dart, cashbook_book_picker_dialog.dart
Depends: T-CB05
Resume notes: add/rename/opening-balance dialogs, two-step delete, picker, Accounts screen done. Not reachable from the UI until the hub/tab task. Receiver switch added to Add Account.
Commit: Add cashbook book picker, Accounts screen and book dialogs

## T-CB07 Entry form, calculator sheet, items dialog [DONE]
Goal: PARITY-013..030.
Files: lib/features/cashbook/cashbook_entry_form_screen.dart, cashbook_calculator_sheet.dart, cashbook_items_dialog.dart
Depends: T-CB05
Resume notes: form covers add AND edit (book dropdown, Delete to trash with confirm, Copy to same/other account), calculator sheet with tested evaluator, items dialog (sets amount from total), bills via camera/gallery/pdf copied into app support dir (image_picker added to pubspec). T-CB10 now only needs trash screen and list wiring. Voice input (mic) not implemented.
Commit: Add cashbook entry form, calculator sheet and items dialog

## T-CB08 Book home screen: list, tabs, totals [DONE]
Goal: PARITY-031..041, 080.
Files: lib/features/cashbook/cashbook_home_screen.dart, widgets/cashbook_row.dart, cashbook_totals_strip.dart, cashbook_period_bar.dart, cashbook_day_header.dart
Depends: T-CB05, T-CB07
Resume notes: home screen with header/book selector, tabs, period bar, grouped list, Previous Balance row, Income/Expense buttons, totals strip; row tap opens edit. Search/overflow come in T-CB09. Deviation: shows a muted 'No transactions' hint on empty lists (PARITY-080 said none). T-CB16 (hub/tab) is being done next so the screens can be run.
Commit: Add Account Ledger home screen with list, tabs and totals

## T-CB09 Search, filters, sort, date range [DONE]
Goal: PARITY-042..047.
Files: cashbook_home_screen.dart, cashbook_provider.dart
Depends: T-CB08
Resume notes: search (toolbar, live, ignores period), overflow menu (Notes, Date, Select Date Range, asc/desc, Income, Expense, Clear filters), active-filter bar. 11 provider/DB integration tests in test/cashbook_provider_test.dart pass (Hive in a temp dir). 'Your Name and Address' and Print/Report come with T-CB14/T-CB15.
Commit: Add cashbook search, filters, sort and date range with tests

## T-CB10 Edit, copy, delete, trash screen [DONE]
Goal: PARITY-048..056.
Files: cashbook_entry_form_screen.dart, cashbook_trash_screen.dart
Depends: T-CB08
Resume notes: edit/copy/delete live in the entry form (T-CB07); this task added the Deleted Transactions screen (Restore/Delete per row, Delete All, 30 day note, restore into another book when the book is gone) and its hub entry.
Commit: Add cashbook Deleted Transactions screen

## T-CB11 Transfer [DONE]
Goal: PARITY-057..060 with transferGroupId.
Files: cashbook_transfer_screen.dart
Depends: T-CB06
Resume notes: Transfer screen + hub entry; logic (linked pair, notes format, same-book refusal) covered by provider tests.
Commit: Add cashbook Transfer screen

## T-CB12 Summaries and calendar [DONE]
Goal: PARITY-061..064.
Files: cashbook_summary_screen.dart, cashbook_account_summary_screen.dart, cashbook_all_transactions_screen.dart, cashbook_calendar_screen.dart
Depends: T-CB08
Resume notes: Summary (tap a book to open it), Account Summary, Transaction-All (search + tabs), Calendar (tap a day lists entries). Shared CashPeriodSel/CashPeriodSelector widget and pickCashDateRange. Hub entries added.
Commit: Add cashbook summaries, all-transactions and calendar screens

## T-CB13 Notebook [DONE]
Goal: PARITY-065..068.
Files: cashbook_notebook_screen.dart, cashbook_note_form_screen.dart
Depends: T-CB05
Resume notes: Notebook (tabs, period bar, checkbox toggles completed, stats strip, Completed/Pending/asc/desc overflow, FAB add) and note form with delete confirm. Notebook 'Report' overflow item skipped (no PDF for notes). Hub entry added.
Commit: Add cashbook Notebook screens

## T-CB14 Settings and Income/Expense labels [DONE]
Goal: PARITY-027, 028, 035, 039, 040, 076, 078, 079, 084.
Files: cashbook_settings_screen.dart, cashbook_provider.dart
Depends: T-CB05
Resume notes: settings screen (date format, show time, 12/24h, currency/number style, 6 display switches, Your Name and Address) + same dialog in home overflow; labels fixed to Income/Expense. Settings persisted under cashbook.* keys. Number style = group digits x fixed decimals. Dark mode, fingerprint, language dropped (RigLedger is light-only, English-only).
Commit: Add cashbook settings screen and number style options

## T-CB15 PDF and CSV export [DONE]
Goal: PARITY-069..074 (PDF and CSV only).
Files: lib/core/services/cashbook_export_service.dart
Depends: T-CB08, T-CB12
Resume notes: PDF (A4, single-book and all-books layouts) and CSV (UTF-8 with BOM) via cashbook_export_service.dart; Report button on the home header honours period/search/filters; Report-All Accounts hub item; share/save via FileSaveService. Bundled Noto Sans + Noto Sans Tamil (OFL, licenses in assets/fonts) so Tamil notes render in PDFs. File names '<Book> <MMM-dd-yyyy>.ext' and 'cashbook <date>.ext'. Excel/xls dropped (decision D7). 6 export tests pass.
Commit: Add cashbook PDF and CSV export with bundled Tamil font

## T-CB16 Hub screen and fifth tab [DONE]
Goal: PARITY-077, 083; fifth tab in both shells; desktop two-pane layout.
Files: cashbook_hub_screen.dart, lib/features/navigation/main_navigation.dart, desktop_shell.dart
Depends: T-CB08
Resume notes: Account Ledger is tab index 3 (Settings moved to 4, Cmd+4 / Cmd+5). Mobile: drawer hub; wide desktop: two panes. Hub list `_hubItems` in cashbook_hub_screen.dart: each later screen task adds its own entry. Verified on the Android emulator (add income, list, totals). ARCHITECTURE.md updated. Mobile bottom label is 'Accounts' (5 tabs truncate longer text).
Commit: Add Account Ledger hub and fifth tab in both shells

## T-CB19 Receiver and payment-log hooks [DONE]
Goal: PARITY-081, 082; linked CashEntry create/update/trash from ledger payments (editable in book).
Files: cashbook_provider.dart, database_service.dart, v2.0.0 payment-log files
Depends: T-CB05, v2.0.0 payment log model
Resume notes: implemented as T-V203 (PaymentLinkService).
Commit: Link bill payments to receiver books in Account Ledger

## T-CB17 Import tool [DONE]
Goal: one-time import from the reference app .db (dry run and report), only once the feature is stable.
Files: cashbook_import_screen.dart, cashbook_import_service.dart, pubspec.yaml (sqlite reader)
Depends: T-CB02, feature stable
Resume notes: sqlite3 ^3.5 (build hooks, no flutter_libs; works on Android, verified on the emulator; macOS build could NOT be verified: needs macos/Runner/GoogleService-Info.plist, not in the repo). CashbookImportService: dry run preview, import by column name (both column orders), merge books by name, idempotent via importedLegacyId, trash imported with deletedAt = import time (30 day window), notebook import, never touches the source file. 6 tests with synthetic databases. Screen with dry run, confirm, progress, report; hub entry. Tested on the emulator with a real backup file (test data only).
Commit: Add one-time import from the cashbook app backup

## T-CB18 Parity QA pass and docs [DONE]
Goal: walk PARITY-001..084 against the reference app; update MODELS.md, ARCHITECTURE.md, MEMORY.md.
Files: docs/features/cashbook/*, .claude/context/*.md
Depends: all
Resume notes: PARITY_STATUS.md written (84 lines: PASS/IMPL/DEVIATION). Fixes found by the QA tests: missing Material in the desktop two-pane layout, linked entry type lock, Help screen, dialog controller crash, vehicle delete orphans, restore of orphaned linked income. README, ARCHITECTURE and MODELS updated.
Commit: Fix desktop Material ancestor, lock linked entry type, add Help and flow tests (and later QA fix commits)
