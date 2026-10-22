# Screen map: mockup screen to Flutter file and widgets

Every screen of `rigledger_apple_mockup.html` (the J registry, 117 entries after the v2.0.2 update; the v2.0.1 and v2.0.2 sections at the end list what changed, and where they disagree with an older row the newest section wins) mapped to the Flutter file it restyles and the widgets (component names from COMPONENTS.md section 0) it uses. The "Doc" column names the file in `docs/design/screens/` whose Reconciliation section R1 holds the detail. Mockup states and overlays (empty, loading, error, alerts, sheets, popovers) are mapped inside the owning screen's doc. Sections come from the four reconciliation passes; the column set differs slightly per section.

## Ledger, bill forms, Portfolio, Account Ledger date picker, shell


The lead merges this into `docs/design/mockup/SCREEN_MAP.md`. Doc column = file in docs/design/screens/ with the R1 table.

| Mockup J screen | Group in J | Flutter file | Widgets | Doc |
|---|---|---|---|---|
| Home (Ledger, Daily) | Ledger tab | lib/features/home/combined_home_screen.dart, widgets/ledger_list.dart, widgets/summary_row.dart | LargeTitleScaffold, RigRigSheet trigger, RigSegmented, RigChipRow, RigCard + RigRing, RigMetricCard x4 (MoneyTile), DepthTile x5, RigGroup + RigRow, RowActions | combined_home_screen.md, ledger_list.md |
| Calendar view | Ledger tab | widgets/calendar_view.dart | RigCard grid | ledger_list.md |
| Side Ledger | Ledger tab | combined_home_screen.dart (`_buildSideLedgerContent`) | RigChipRow, RigCard, CategoryTile x4 | combined_home_screen.md |
| Switch Vehicle sheet | Ledger tab | combined_home_screen.dart (`_showVehicleSwitcher`), shared sheet widget | RigRigSheet (RigSheet, RigGroup, RigRow) | combined_home_screen.md, main_navigation.md |
| Search sheet | Ledger tab | widgets/search_sheet.dart | RigSheet, RigFormRow, RigButton | ledger_list.md |
| Filter sheet | Ledger tab | widgets/filter_sheet.dart | RigSheet, RigFormRow, RigButton | ledger_list.md |
| Add Entry sheet | Ledger tab | lib/features/navigation/main_navigation.dart | RigSheet, CategoryTile 2 x 2 | main_navigation.md |
| Side Bore rig home | Ledger tab | combined_home_screen.dart, ledger_list.dart | one DepthTile "Total Depth" | combined_home_screen.md |
| Side Ledger (Side rig) | Ledger tab | combined_home_screen.dart | CategoryTile x3 | combined_home_screen.md |
| Main Bore - Edit Entry | Bill forms | lib/features/ledger_form/ledger_form_screen.dart | form sheet scaffold, UnsavedChangesGuard, live card (MoneyTile x2), RigGroup, RigFormRow, CommissionSection, PaymentLogEditor, RigButton pill | ledger_form_screen.md |
| Main Bore - New Entry | Bill forms | same | same | ledger_form_screen.md |
| Add payment dialog | Bill forms | lib/features/ledger_form/widgets/payment_log_editor.dart | RigSheet, RigFormRow, RigSegmented, RigButton | payment_log_editor.md |
| Add agent dialog (form) | Bill forms | ledger_form_screen.dart, side_bore_form_screen.dart | RigSheet, RigFormRow, RigButton | ledger_form_screen.md, side_bore_form_screen.md |
| Side Bore - Edit Entry | Bill forms | lib/features/ledger_form/side_bore_form_screen.dart | as main form plus RigSegmented (Auto, Manual) | side_bore_form_screen.md |
| Side Bore - New Entry | Bill forms | same | same | side_bore_form_screen.md |
| Delete entry dialog | Bill forms | both form files | RigAlertDialog | ledger_form_screen.md, side_bore_form_screen.md |
| Overview | Portfolio | lib/features/stats/stats_screen.dart, lib/features/portfolio/portfolio_view.dart | LargeTitleScaffold, RigRigSheet trigger, RigSegmented, RigChipRow, RigCard (Profit), RigMetricCard x4, RigCard (By agent) | portfolio.md |
| Overview (agent filter) | Portfolio | same | same without Profit and Expenses | portfolio.md |
| Ledger tab (donut) | Portfolio | stats_screen.dart (charts) | RigMetricCard x4, RigCard donut | portfolio.md |
| Side Ledger tab | Portfolio | stats_screen.dart (charts) | RigCard x4, RigGroup | portfolio.md |
| Ledger empty | Apple direction: states | ledger_list.dart | EmptyState | ledger_list.md |
| Ledger loading | Apple direction: states | ledger_list.dart | Skeleton | ledger_list.md |
| Ledger error | Apple direction: states | none (not built, LR-34) | ErrorBanner | combined_home_screen.md |
| Ledger no search match | Apple direction: states | ledger_list.dart | EmptyState, RigButton | ledger_list.md |
| Side Ledger loading | Apple direction: states | combined_home_screen.dart | Skeleton | combined_home_screen.md |
| Portfolio loading | Apple direction: states | stats_screen.dart | Skeleton | portfolio.md |
| Bill row actions (long press) | Apple direction: overlays | ledger_list.dart | RowActions, RigSheet | ledger_list.md |
| Full value popover (tap a tile) | Apple direction: overlays | lib/core/widgets (MoneyTile) | MoneyTile popover | combined_home_screen.md |
| Delete entry alert | Apple direction: overlays | ledger_list.dart | RigAlertDialog | ledger_list.md |
| Account Ledger date picker (B2) | Apple direction: overlays | lib/features/cashbook/widgets/cashbook_period_bar.dart, new lib/core/widgets/date_picker_sheet.dart | DatePickerSheet (RigSheet), period navigator | accounts_daily_date_picker.md |
| Rig sheet from Portfolio (B1) | Apple direction: overlays | stats_screen.dart, shared sheet widget | RigRigSheet | portfolio.md |
| Calendar view with selected day | Apple direction: overlays | widgets/calendar_view.dart | RigGroup of RigRow | ledger_list.md (LR-03 proposed) |
| (tab bar on every root tab, not a J entry) | shell | lib/features/navigation/main_navigation.dart | RigTabBar, lazy IndexedStack | main_navigation.md |
| none (frozen) | none | lib/features/navigation/desktop_shell.dart | none | desktop_shell.md |
| none (dead code, deleted in T-Z99) | none | lib/features/home/home_screen.dart, lib/features/side_ledger/side_ledger_screen.dart | none | home_screen.md |

## Side ledger and Portfolio charts


The lead merges these rows into `mockup/SCREEN_MAP.md`. Mockup labels are the J registry labels (exact); rows marked "no registry label" are opened from a screen that has one.

| Mockup J screen | Render function | Flutter file | Widgets |
|---|---|---|---|
| Diesel Ledger | `slList({k:'diesel'})` (`SC.diesel`) | `lib/features/side_ledger/diesel/diesel_list_screen.dart` | LargeTitleScaffold, CategoryTile (`catDiesel`), MoneyTile, RigGroup, RigRow, RowActions, EmptyState, RigAlertDialog, RigSnack |
| Diesel Ledger empty | `slList` with empty state | same | EmptyState, Skeleton (first frame only) |
| PVC Ledger | `slList({k:'pvc'})` (`SC.pvc`) | `lib/features/side_ledger/pvc/pvc_list_screen.dart` | as Diesel Ledger, `catPvc`, RigChipRow in the filter |
| Bit Ledger | `slList({k:'bit'})` (`SC.bit`) | `lib/features/side_ledger/bit/bit_list_screen.dart` | as Diesel Ledger, `catBit` |
| Hammer Ledger | `slList({k:'hammer'})` (`SC.hammer`) | `lib/features/side_ledger/hammer/hammer_list_screen.dart` | as Diesel Ledger, `catHammer` |
| (no registry label) Filter Entries sheet, four variants | `slFilter(k)` | the four `_XFilterSheet` classes in the list files | RigSheet, RigGroup, RigFormRow, RigChipRow, RigButton |
| (no registry label) Delete Entry alert | `slDel(k, bill)` | the four list files | RigAlertDialog, RigSnack |
| Add Diesel Entry | `newSl('diesel')` then `slForm` | `lib/features/side_ledger/diesel/diesel_form_screen.dart` | form route, live card (MoneyTile x2), RigGroup, RigFormRow, RigButton, UnsavedChangesGuard, RigSnack |
| Add PVC Entry | `slForm({k:'pvc'})` | `lib/features/side_ledger/pvc/pvc_form_screen.dart` | as above plus RigChipRow (multi), per type RigGroup |
| Add Bit Entry | `newSl('bit')` then `slForm` | `lib/features/side_ledger/bit/bit_form_screen.dart` | as PVC form |
| Add Hammer Entry | `newSl('hammer')` then `slForm` | `lib/features/side_ledger/hammer/hammer_form_screen.dart` | as PVC form |
| (edit, no registry label) | `editSl(k, i)` | the four form files | same, title "Edit <Category> Entry", button "Update Entry" |
| Ledger tab (donut) | `portfolioTab()` branch `tab==1` | `lib/features/stats/stats_screen.dart` | RigChipRow, RigMetricCard x4, RigCard, RigRing donut variant, legend RigRows, EmptyState |
| Side Ledger tab | `portfolioTab()` branch `tab==2` | `lib/features/stats/stats_screen.dart` | RigMetricCard style category cards with Paid and Due donut, RigGroup details, EmptyState |
| none (dead code) | none | `lib/features/side_ledger/side_ledger_screen.dart` | none, deleted in T-Z99 |

## Account Ledger


Mockup J screen to Flutter file and widgets (group r3, Account Ledger). Merge into mockup/SCREEN_MAP.md.

| Mockup J screen | Flutter file | Widgets |
|---|---|---|
| Drawer hub | lib/features/cashbook/cashbook_hub_screen.dart (`_HubPanel`, `_hubItems`) | Flutter `Drawer` kept as the container (see conflicts_r3.md C-01); content: RigCard header, RigGroup of 12 RigRow with `chev: true` and a coloured 29 dp icon tile; LargeTitleScaffold menu button in `CashbookHomeScreen` |
| Home (All) | cashbook_hub_screen.dart (`CashbookRootScreen`) | LargeTitleScaffold (root, title "Accounts") owns the menu button that opens the drawer |
| Home (All) | lib/features/cashbook/cashbook_home_screen.dart, widgets/cashbook_header.dart, cashbook_period_bar.dart, cashbook_row.dart, cashbook_totals_strip.dart | LargeTitleScaffold (root, title "Accounts", menu button, status strip), RigChipRow, RigCard x3 (strip), RigGroup, RigRow, RowActions, RigButton (moneyInButton and moneyOutButton), EmptyState, MoneyText |
| Home (Monthly, previous balance) | same files | RigChipRow, period navigator (`pnav`), RigGroup with two RigRows (Previous balance, Balance with previous), Previous Balance row at the top of the list |
| Receiver book (linked rows) | cashbook_row.dart | RigRow with a 14 dp link icon and the text "Linked to a bill" |
| Overflow menu / Account Ledger overflow sheet | cashbook_home_screen.dart (`_overflow`) | RigSheet (full), RigGroup, RigRow with check marks, section captions Sort and Filter |
| Book picker | cashbook_book_picker_dialog.dart | RigSheet, search RigGroup, RigRow with icon tile, subtitle "Receiver book" or "Custom book", check mark for the current book, Add Account row, Edit text button |
| Account Ledger date picker (B2) | cashbook_home_screen.dart (`_pickDay`) | DatePickerSheet (B2) |
| Accounts empty | cashbook_home_screen.dart | EmptyState (icon `account_balance_wallet_outlined`, "No transactions", "Add an income or an expense to get started.") |
| Accounts loading | cashbook_home_screen.dart | Skeleton x4 inside the list area |
| Add Income form, Edit Transaction form (snackbar, confirm, date field) | lib/features/cashbook/widgets/cashbook_common.dart | RigSnack (floating capsule), RigAlertDialog, RigSegmented (sign toggle), DatePickerSheet (B2), RigFormRow, RigSheet |
| Account Ledger date picker (B2) | cashbook_common.dart (`CashDateField`), widgets/cashbook_period_selector.dart | DatePickerSheet (B2) |
| Home (All) period controls | widgets/cashbook_period_selector.dart (`CashPeriodSelector`) | RigChipRow (periods plus Range), period navigator, RigSheet "Select Date Range" with two RigFormRows |
| Overflow menu (Notes search) | cashbook_common.dart (`showCashTextPrompt`) | RigSheet with one RigFormRow and a pinned RigButton |
| Accounts screen | lib/features/cashbook/cashbook_books_screen.dart | LargeTitleScaffold (pushed, title "Accounts", add button), RigGroup with a search row, RigRow (29 dp icon tile, title, subtitle, balance), EmptyState |
| Account actions sheet | cashbook_books_screen.dart (`showModalBottomSheet`) | RigSheet with title = book name, RigGroup of RigRows Edit, Opening Balance, Delete (destructive) |
| Add Account dialog | lib/features/cashbook/cashbook_book_dialogs.dart (`_AddBookDialogState`) | RigSheet "Add Account": RigGroup of RigFormRows (Name, Opening balance with rupee prefix, Type RigSegmented, Date row, Receiver book RigSwitch), pinned RigButton "Save" |
| Book picker | lib/features/cashbook/cashbook_book_picker_dialog.dart | RigSheet (search RigGroup, RigRow list, Add Account row, Edit text button) |
| Accounts list empty | cashbook_books_screen.dart | EmptyState with a RigButton "Add Account" |
| Add Income form | lib/features/cashbook/cashbook_entry_form_screen.dart | Full-height form screen (grabber, close button, title), RigSegmented, RigCard (amount), RigGroup of RigFormRows, RigRow (Bills, Items), RigButton pair, UnsavedChangesGuard |
| Edit Transaction form | same file | same plus Account RigFormRow, Copy and More glass buttons, Delete tonal RigButton, linked-entry hint |
| Calculator sheet | lib/features/cashbook/cashbook_calculator_sheet.dart | RigSheet "Calculator", display block, 4 x 5 grid of round keys, pinned RigButton "Use" |
| Add Items dialog | lib/features/cashbook/cashbook_items_dialog.dart | full-height RigSheet "Add Items": RigGroup of four RigFormRows plus an "Add item" row, caption with count and total, RigGroup of item RigRows, pinned RigButton "OK", RigAlertDialog for the half-typed row (LR-26) |
| Add Bills sheet (inside Add Income form) | cashbook_entry_form_screen.dart (`PopupMenuButton` today) | RigSheet "Add Bills" with RigRows Camera, Gallery, PDF |
| Copy sheet | cashbook_entry_form_screen.dart | RigSheet "Copy" (two RigRows), RigSheet "Select account" |
| Account Ledger date picker (B2) | cashbook_entry_form_screen.dart (date row) | DatePickerSheet (B2) |
| Transfer | lib/features/cashbook/cashbook_transfer_screen.dart | LargeTitleScaffold (pushed, title "Transfer"), RigGroup of RigFormRows (Amount with rupee prefix, From and To selectors, Date, Time, Notes), pinned RigButton "Transfer", UnsavedChangesGuard |
| Summary | lib/features/cashbook/cashbook_summary_screen.dart | LargeTitleScaffold (pushed), RigChipRow, period navigator, tappable RigCard per book (name, chevron, three MoneyText columns), RigGroup caption "All accounts", totals strip, EmptyState |
| Account Summary | lib/features/cashbook/cashbook_account_summary_screen.dart | LargeTitleScaffold (pushed), book pill, RigChipRow (All, Weekly, Monthly, Yearly), period navigator, totals strip, RigGroup of per-day RigRows, EmptyState |
| Transaction-All Accounts | lib/features/cashbook/cashbook_all_transactions_screen.dart | LargeTitleScaffold (pushed), search RigGroup row, RigChipRow, period navigator, totals strip, sticky day headers with RigGroups of RigRows (notes, time and book name, signed amount), EmptyState |
| Calendar | lib/features/cashbook/cashbook_calendar_screen.dart | LargeTitleScaffold (pushed), book pill, month navigator, 7-column grid of day buttons (`cd`), totals strip, RigSheet for a day |
| Notebook | lib/features/cashbook/cashbook_notebook_screen.dart | LargeTitleScaffold (pushed, trailing Add and More glass buttons), RigChipRow, period navigator, three RigCards (Completed, Pending, Total), RigGroup sections "Pending" and "Completed" of note rows with RigCheck and RowActions, EmptyState, RigSheet (menu) |
| Notebook empty | cashbook_notebook_screen.dart | EmptyState (icon `sticky_note_2`, "No notes", "Tap + to write a note.") |
| Note form | lib/features/cashbook/cashbook_note_form_screen.dart | LargeTitleScaffold (pushed, title "New Note" or "Edit Note"), RigGroup (Date, Time rows), RigGroup (multi-line Notes row), pinned buttons (Delete tonal, Save filled), UnsavedChangesGuard |
| Deleted Transactions | lib/features/cashbook/cashbook_trash_screen.dart | LargeTitleScaffold (pushed, trailing More), footer text, RigGroup of entry rows with RowActions (Restore, Delete), RigSheet (Restore, Delete), RigAlertDialog, EmptyState |
| Deleted Transactions empty | cashbook_trash_screen.dart | EmptyState (icon `delete_sweep`, "No deleted transactions", "Deleted transactions appear here for 30 days.") |
| Account Ledger settings | lib/features/cashbook/cashbook_settings_screen.dart | LargeTitleScaffold (pushed, title "Settings"), RigGroup x3, RigRow (value and chevron), RigSwitch rows, RigSheet (Format Date, Your Name and Address) |
| Import (dry run) | lib/features/cashbook/cashbook_import_screen.dart | LargeTitleScaffold (pushed, title "Import from cashbook app"), footer text, RigButton (secondary), RigGroup rows, RigRow with RigSwitch, pinned or inline RigButton "Import", RigAlertDialog |
| Import (result) | cashbook_import_screen.dart | RigCard with a check glyph and "Import complete", RigGroup rows, RigButton "Done" |
| Report dialog (all) | lib/features/cashbook/cashbook_report_dialog.dart (`showCashReportAllDialog`) | RigSheet "Report - All Accounts": RigChipRow (All, Select Date Range), RigSegmented (PDF, CSV), pinned RigButton "OK" |
| Home (All) Report button | cashbook_report_dialog.dart (`showCashReportDialog`) | RigSheet "Report": RigGroup of RigRows PDF and CSV with coloured icon tiles |
| Help | lib/features/cashbook/cashbook_help_screen.dart | LargeTitleScaffold (pushed, title "Help"), one RigCard per topic (title 17 sp weight 600, body 15 sp `label2`) |

## Agents, Settings, exports, app root and theme


Merge target: docs/design/mockup/SCREEN_MAP.md. Components use the 2026-10-13 names.

| Mockup J screen | Flutter file | Widgets |
|---|---|---|
| (removed in v2.0.1) Agents / Agents list | the Agents tab is gone from the phone shell; `agents_screen.dart` stays only for the frozen desktop shell. The list became the Agents section of Portfolio Overview (see the v2.0.1 section) | none |
| Agents (inside Portfolio) / Add Agent dialog | lib/features/agents/agent_dialogs.dart (showAddAgentDialog, CommissionRatesFields; becomes a sheet widget owning one controller per type price) | RigSheet (full height), RigGroup, RigFormRow, RigButton |
| Agents (inside Portfolio) / Edit Agent dialog | agent_dialogs.dart (showEditAgentDialog) | same, title "Edit Agent", button "Save" |
| Agents (inside Portfolio) / Delete Agent dialog | agent_dialogs.dart (showDeleteAgentDialog) | RigAlertDialog |
| Apple direction: overlays / Agent delete with entries | same | RigSheet, ErrorBanner, RigGroup of RigRows, RigFormRow, RigButton (destructive); no default choice (G3-B15) |
| Apple direction: states / Portfolio agents empty | lib/features/portfolio/portfolio_view.dart (`_AgentsSection`, no agents) | one line of text and the Add agent button |
| Settings / Settings (Drive connected) | lib/features/settings/settings_screen.dart (SettingsScreen, _GoogleDriveBackupCard) | LargeTitleScaffold, RigCard hero, RigButton (filled, tonal), RigGroup, RigRow, RigSwitch |
| Settings / Settings (Drive not connected) | same | RigCard hero, RigGroup, RigButton |
| Apple direction: states / Settings Drive sync error | same | ErrorBanner with Retry (reads syncProvider status and errorMessage) |
| Apple direction: overlays / Appearance sheet | lib/features/settings/settings_screen.dart (new _AppearanceSheet) | RigSheet, RigGroup, RigRow (check) |
| Settings / Clear All Data dialog | lib/features/settings/settings_screen.dart (_showClearDataDialog) | RigAlertDialog |
| Settings / Restore Backup dialog | lib/features/settings/settings_screen.dart (_restoreBackup, file picker first) | RigAlertDialog |
| Settings / Vehicle Management | lib/features/settings/vehicle_management_screen.dart (VehicleManagementScreen) | LargeTitleScaffold, RigGroup, RigRow, RowActions |
| Settings / Add Vehicle dialog | lib/features/settings/vehicle_management_screen.dart (_VehicleFormDialog, becomes a sheet widget) | RigSheet, RigFormRow, RigGroup of RigRows, RigButton |
| Settings / Export to CSV | lib/features/export/csv_export_screen.dart | LargeTitleScaffold, RigChipRow, RigGroup + RigSwitch, RigCard, RigButton |
| Settings / Import from CSV | lib/features/export/csv_import_screen.dart | LargeTitleScaffold, RigSegmented (read-only step indicator), RigCard, RigGroup of RigFormRows, RigSwitch, RigMetricCard, ErrorBanner, RigButton |
| Settings / Export to PDF | lib/features/export/pdf_export_screen.dart (config part) | LargeTitleScaffold, RigChipRow, RigGroup of RigFormRows, DatePickerSheet, RigGroup (summary), RigButton |
| Settings / About | lib/features/settings/about_screen.dart (AboutScreen, _LicenseTextScreen) | LargeTitleScaffold, RigCard, RigGroup, RigRow |
| (Dev panel: Theme, Device, System navigation, System back) | lib/main.dart (RigLedgerApp, main()) | MaterialApp theme/darkTheme/themeMode, SystemUiOverlayStyle, PopScope |
| (token source, no J screen) | lib/core/theme/rig_colors.dart, rig_theme.dart, lib/core/utils/rig_format.dart, lib/core/widgets/* | RigColors, RigTheme, RigFormat and the component set; deletes AdaptiveHeader, GradientAppBar, AppColors aliases |

## v2.0.1 update (Flutter app 2.0.1+6; 111 J entries)

What changed in the mockup so that it matches `docs/v2.0.1-review.md`. Tab indices are now 0 Ledger, 1 Portfolio, 2 Accounts, 3 Settings: **the Agents tab was removed** (the J group "Agents" became "Agents (inside Portfolio)"; the old Agents list, its swipe rows and the Agents empty state no longer exist).

| Mockup J screen | Group in J | Flutter file | Widgets and notes |
|---|---|---|---|
| Home (Ledger, Daily), Calendar view | Ledger tab | combined_home_screen.dart, widgets/summary_row.dart | one slim row with the month or year arrows (or the custom range text) and a small Daily/Calendar toggle (`.segs`, icon buttons with aria labels); the ring card and the 2 x 2 metric cards were replaced by ONE slim card that scrolls sideways (`.sumstrip`: Total, Received, Balance, Commission); under it the collapsible feet bar (`.feetbar`) |
| Feet drop down expanded | Ledger tab (new) | summary_row.dart (`_feetPanel`) | "Depth by type", "PVC by type", "MS pipe by type", one chip per user-defined type with its feet (`7"`, `9"`; zero shows `0 ft`) |
| Side Bore rig home (Total Depth, no drop down) | Ledger tab | summary_row.dart | "Total Depth" tile at the end of the strip, no feet bar |
| Side Ledger, Side Ledger (Side rig) | Ledger tab | combined_home_screen.dart (`_buildSideLedgerContent`) | an "Other expenses" category tile (receipt icon, `--c-oth`); the Flutter mini stat row ("Other", entries and total) is covered by the tile subtitle and the Purchases card, the mockup has no mini stat row for any category |
| Add Entry sheet, Add Entry sheet (Side rig, 4 options) | Ledger tab | main_navigation.dart | 5 options on a main bore rig (Diesel, PVC, Bit, Hammer, Other), 4 on a side bore rig |
| Main Bore - Edit Entry (manual commission), (9inch) | Bill forms (new) | ledger_form_screen.dart, widgets/commission_section.dart | Depth, PVC and MS dropdowns list the user-defined types; commission breakdown box (Depth, PVC, MS pipe commission, divider, Total commission with an amber "manual" tag); Calculation Preview has the "Commission (not in total)" block |
| Home bill cards | Ledger tab | widgets/ledger_list.dart (`_CommissionStrip`) | commission strip "Commission X" (marked "(manual)") with Depth, PVC, MS amounts on the right |
| Other Expenses list, (date filter), (Side rig), Date range sheet | Side ledger (new) | lib/features/side_ledger/other/other_expense_list_screen.dart | summary card Entries / Total / Paid / Pending (`.g-other` gradient), date range filter button, swipe rows, empty and clear filter states |
| Add Other Expense, Edit Other Expense | Side ledger (new) | other_expense_form_screen.dart | Date, Bill Number (Optional), Description *, Amount *, Total Amount box, Paid Amount, Pending or Balance (Advance) box, Paid Date (Optional), Notes, Save Entry or Update Entry |
| Overview, Overview (agent filter), Overview (All rigs scope) | Portfolio | stats_screen.dart, portfolio_view.dart | rig pill with a dropdown arrow opens the Switch Rig sheet (changes the global rig); This rig / All rigs as two large pills with icons (`.scope`) and a hint line ("Showing Main Rig only", "Showing all 2 rigs together"); the agent chip row lists only agents with bills in the scope and resets on a scope or rig change; expenses insight lists Diesel, PVC (not side bore), Bit, Hammer, Other expenses; profit includes Other expenses |
| Side Ledger tab | Portfolio | stats_screen.dart (`_buildOtherPieChart`, `_buildOtherStats`) | mini pie card "Other" and detail card "Other expenses" (Total Value, Paid, Pending) |
| Agents section (Portfolio Overview) | Agents (inside Portfolio) (new) | portfolio_view.dart (`_AgentsSection`, `_AgentRow`) | every agent, "no bills" for agents without bills, Total, Received, Pending, Commission for the period, "Add agent" in the section header |
| Agent detail sheet, Agent detail sheet (no bills) | Agents (inside Portfolio) (new) | portfolio_view.dart (`_AgentSheet`) | name, phone, notes, "This period" totals, "Commission per foot" (Depth 7", Depth 9", PVC 7", MS 6", then "(other sizes)" defaults), Delete and Edit |
| Add Agent dialog, Edit Agent dialog | Agents (inside Portfolio) | lib/features/agents/agent_dialogs.dart | contact fields, a price field per depth, PVC and MS pipe type, defaults for types without a price |
| Ledger Types, Add type dialog, Rename type dialog, Step rate table sheet, Delete type dialog | Settings (new) | lib/features/settings/ledger_types_screen.dart | sections Depth types, PVC types, MS pipe types with Add, Rename, Delete; "N bills" and "Step rate: 7 inch table" per depth type; errors as snackbars: "Enter the size in inches, for example 9 or 9.5", "9inch already exists", "N bills use 9inch. Change them first.", "Keep at least one depth type" |
| Export to CSV (Other expenses), Export to PDF (Other expenses) | Settings (new) | csv_export_screen.dart, pdf_export_screen.dart | an "Other expenses" export type with its own columns and summary |
| Add Income form, Edit Transaction form | Account Ledger | cashbook_entry_form_screen.dart | new entry: outlined "Save and add another" plus filled "Save" (returns, 1 second "Saved" snack); "Save and add another" clears amount, notes, items and bills and stays; an empty amount shows the inline error "Enter an amount" |
| Home (All) and the other Account Ledger screens | Account Ledger | cashbook_home_screen.dart and widgets | already the same look as the ledger pages in the Apple mockup (summary cards, floating grouped rows, day headers), so only the Save behaviour changed |

## v2.0.2 update (Flutter app 2.0.2+7; 117 J entries)

What changed in the mockup so that it matches `docs/v2.0.2-review.md`. Six J entries were added (111 to 117); the rest of the registry is unchanged. A bill now has LINES (several per category), so every row below that mentions depth, PVC or MS pipe feet reads "summed over the lines".

| Mockup J screen | Group in J | Flutter file | Widgets and notes |
|---|---|---|---|
| Main Bore - Edit Entry (two depth lines, two PVC lines) | Bill forms (new) | ledger_form_screen.dart, widgets/line_editor.dart (`LinesSection`, `LineController`), widgets/commission_section.dart | bill 1044 (Karthik): Depth 200 ft 7inch x 90 and 150 ft 8inch x 95, PVC 80 ft 7inch x 150 and 60 ft 8inch x 170. One line card per line (`LineCard`: Type dropdown from the Ledger Types list, feet, rate per foot); with more than one line each card has a header "Depth line 2" and a remove X (48 dp); "Add Depth line", "Add PVC line", "Add MS Pipe line" text buttons (`AddLineButton`) below the cards. "Step Rate" becomes "Step Rate, all depth lines" with several lines. Calculation Preview: one row per line ("Depth 1 7inch (200 ft x ₹90)"), Step Rate, Extra Charges, Total, then "Commission (not in total)" with one row per line and the total commission |
| Main Bore - Edit Entry (two depth lines, step on one line) | Bill forms (new) | same | bill 1045: 7inch 320 ft (step rate 20 ft x 10 = 200) plus 9inch 150 ft (no table); the step rate is the SUM of the step rate of each depth line worked out alone (own type table, feet from 0): Total 28,800 + 200 + 15,000 = 44,000 |
| Commission section with several lines | Bill forms (new) | widgets/commission_section.dart (`CommissionRow`, `_breakdown`) | one rate field per line ("Depth 7inch rate" with one line, "Depth 1 7inch rate" with several) with the helper "200 ft = ₹2,000", then the breakdown box (Depth, PVC, MS pipe commission, Total commission with the amber "manual" tag when typed) and the Commission field |
| Side Bore - Edit Entry (two depth lines) | Bill forms (new) | side_bore_form_screen.dart (`LinesSection` with `showType: false`) | bill 204: depth lines only ("Depth (ft)", "Rate/ft", no Type dropdown, no step rate), "Add Depth line", Total = sum of feet x rate (19,200), commission rows "Depth 1 rate", "Depth 2 rate" |
| Home bill cards | Ledger tab | widgets/ledger_list.dart (`_InfoChip`, `_depthText`, `_CommissionStrip`) | Depth chip for several lines "200ft (7inch) + 150ft (8inch)" (one line: "350ft (7inch)", side bore: "220ft"), PVC chip lists every PVC type "7inch + 8inch"; chips wrap to a second row when long; the commission strip kinds come from the lines |
| Feet drop down expanded, Home (summary strip) | Ledger tab | core/utils/feet_totals.dart, widgets/summary_row.dart | every line counts under its own type (Depth by type, PVC by type, MS pipe by type) |
| Filter sheet | Ledger tab | filter_sheet.dart | depth type and PVC type filters match a bill when ANY line has the type (`hasType`) |
| Ledger Types | Settings | ledger_types_screen.dart | "N bills" counts a bill when any of its lines uses the size; rename updates every line; delete is refused while any line uses it |
| Export to CSV, Export to PDF (Ledger type) | Settings | csv_export_screen.dart, pdf_export_screen.dart, ledger_entry.dart (`typeLabel`) | a "Sample, bill #1044 with several lines" group: type cells "7inch + 8inch", feet as sums, rate = average (amount / feet); import keeps one line per category |
| Overview (Portfolio) | Portfolio | portfolio_view.dart (`_AgentFilterPill`) | the agent chip row is ONE pill "Agent: All agents" (person icon, dropdown arrow, tinted `acc-tint` with an accent outline when an agent is chosen, shows the agent name); the choice resets on a This rig / All rigs or rig change |
| Agent filter sheet, Agent filter sheet (search typed) | Portfolio (new) | portfolio_view.dart (`_AgentFilterSheet`) | sheet "Filter by agent": search field "Search agents", "All agents" row (subtitle "7 bills", hidden while searching), one row per agent sorted by total descending then name ("no bills" or "N bills \| ₹total" for the scope and period), check mark on the chosen row, "No agent matches"; choosing closes the sheet and filters the Overview (profit hidden with an agent filter as before) |
| Agent detail sheet, Add Agent dialog, Edit Agent dialog, Delete Agent dialog | Agents (inside Portfolio) | portfolio_view.dart, agent_dialogs.dart | in the mockup Edit and Delete now really change the data: saving updates the agent (price edits show in "Commission per foot", the name everywhere), Delete removes the agent and deletes or reassigns its bills (bills keep their stored rates) |

## v2.0.3 update (Flutter app 2.0.3+8; 121 J entries)

What changed in the mockup so that it matches `docs/v2.0.3-review.md`. Four J entries were added in a new group "Agent view (v2.0.3)" (117 to 121); the Portfolio "Overview (agent filter)" entry was renamed "Overview (agent view, Murugan)" because choosing an agent now shows the agent view.

| Mockup J screen | Group in J | Flutter file | Widgets and notes |
|---|---|---|---|
| Agent view (3 month, Karthik) | Agent view (v2.0.3) (new) | lib/features/portfolio/agent_view.dart (`AgentView`), portfolio_view.dart (`_PortfolioViewState.build`) | Portfolio, Overview, 3 Mo, This rig, agent Karthik. Pill "Agent: Karthik" (tinted), then: gradient header (`.agh`: person icon, name, tune icon button "Prices and details", period "01 Aug 2026 to 13 Oct 2026", "Commission earned" amount, outlined back button "All agents"); profit card (`.agp`, `_profitCard`: "Profit from this agent (received - commission)", green or red, "Expected when all pending is collected: ...", "All agents, after expenses: ...", the "Expenses are not tracked per agent" note); two rows of cards Bills / Total and Received / Pending (`_kpi`, the mockup reuses the metric card); "By month" table (`.mtb`, `_monthTable`, only when the period spans more than one month); "Bills" and one card per bill newest first (`.agb`, `_BillRow`: date, #number, address, Total / Received / Balance, commission strip); totals row (`.agt`, `_totalRow`) |
| Agent view (manual commission bill) | Agent view (v2.0.3) (new) | same | scrolled to bill 1037: the strip reads "Commission (manual)" and has no Depth / PVC / MS split (the split shows only when there is more than one kind and the commission is not manual) |
| Agent view (no bills, empty state) | Agent view (v2.0.3) (new) | same | Prakash has no bills: header, profit card (all zero, green), cards, then "No bills for Prakash in this period"; no month table, no bill cards, no totals row |
| Edit Agent dialog (prices change existing bills) | Agent view (v2.0.3) (new) | lib/features/agents/agent_dialogs.dart (`showEditAgentDialog`), lib/core/providers/agent_provider.dart (`updateAgent`), lib/core/services/commission_recalc.dart | Save runs the recalculation on the page data and shows the snack "Agent updated" or "Agent updated. Commission changed on N bills" ("1 bill" for one); the dialog itself did not change |
| Agents section (Portfolio Overview) | Agents (inside Portfolio) | portfolio_view.dart (`_AgentRow`) | a tap on the row opens that agent's view; a 48 dp info icon button on the right (tooltip and aria label "Prices and details") opens the details sheet; the chevron is gone |
| Overview (agent view, Murugan) | Portfolio | portfolio_view.dart | the agent view replaces the profit card, the metric cards, the expenses card, the Agents section and the definitions foot |
| Agent filter sheet | Portfolio | portfolio_view.dart (`_AgentFilterSheet`) | unchanged; choosing an agent now opens the agent view, "All agents" returns to the Overview |
