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

Feature: Account Ledger (cashbook replica, v2.0.0 feature 1). Full spec: `docs/features/cashbook/SPEC.md` (parity lines PARITY-001..084, decisions D1..D14). Flags: T-CB01/02/03 touch Hive models, DatabaseService and SyncService; T-CB15 touches export.

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

## T-CB13 Notebook [PENDING]
Goal: PARITY-065..068.
Files: cashbook_notebook_screen.dart, cashbook_note_form_screen.dart
Depends: T-CB05
Resume notes:
Commit:

## T-CB14 Settings and Income/Expense labels [PENDING]
Goal: PARITY-027, 028, 035, 039, 040, 076, 078, 079, 084.
Files: cashbook_settings_screen.dart, cashbook_provider.dart
Depends: T-CB05
Resume notes:
Commit:

## T-CB15 PDF and CSV export [PENDING]
Goal: PARITY-069..074 (PDF and CSV only).
Files: lib/core/services/cashbook_export_service.dart
Depends: T-CB08, T-CB12
Resume notes:
Commit:

## T-CB16 Hub screen and fifth tab [DONE]
Goal: PARITY-077, 083; fifth tab in both shells; desktop two-pane layout.
Files: cashbook_hub_screen.dart, lib/features/navigation/main_navigation.dart, desktop_shell.dart
Depends: T-CB08
Resume notes: Account Ledger is tab index 3 (Settings moved to 4, Cmd+4 / Cmd+5). Mobile: drawer hub; wide desktop: two panes. Hub list `_hubItems` in cashbook_hub_screen.dart: each later screen task adds its own entry. Verified on the Android emulator (add income, list, totals). ARCHITECTURE.md updated. Mobile bottom label is 'Accounts' (5 tabs truncate longer text).
Commit: Add Account Ledger hub and fifth tab in both shells

## T-CB19 Receiver and payment-log hooks [PENDING]
Goal: PARITY-081, 082; linked CashEntry create/update/trash from ledger payments (editable in book).
Files: cashbook_provider.dart, database_service.dart, v2.0.0 payment-log files
Depends: T-CB05, v2.0.0 payment log model
Resume notes:
Commit:

## T-CB17 Import tool [PENDING]
Goal: one-time import from the reference app .db (dry run and report), only once the feature is stable.
Files: cashbook_import_screen.dart, cashbook_import_service.dart, pubspec.yaml (sqlite reader)
Depends: T-CB02, feature stable
Resume notes:
Commit:

## T-CB18 Parity QA pass and docs [PENDING]
Goal: walk PARITY-001..084 against the reference app; update MODELS.md, ARCHITECTURE.md, MEMORY.md.
Files: docs/features/cashbook/*, .claude/context/*.md
Depends: all
Resume notes:
Commit:
