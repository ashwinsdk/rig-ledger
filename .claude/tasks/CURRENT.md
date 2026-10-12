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

## T-CB02 DatabaseService boxes, CRUD, trash, schema 4 [PENDING]
Goal: register adapters, open cash_books/cash_entries/cash_notes boxes, CRUD with tombstones, trash helpers with 30 day auto-purge, schemaVersion 4, backup/restore keys with null-safe reads.
Files: lib/core/database/database_service.dart
Depends: T-CB01
Resume notes:
Commit:

## T-CB03 SyncService merge for cash collections [PENDING]
Goal: merge cashBooks, cashEntries, cashNotes; tolerate missing keys; refuse to overwrite a remote snapshot with a higher version (all devices must update).
Files: lib/core/services/sync_service.dart
Depends: T-CB02
Resume notes: add new refresh calls to the refresh pattern docs.
Commit:

## T-CB04 Calculator utility and unit tests [PENDING]
Goal: running balance, previous balance, period ranges, grouping, rounding, number formatting (Rs. prefix).
Files: lib/core/utils/cashbook_calculator.dart, test/cashbook_calculator_test.dart
Depends: T-CB01
Resume notes: cover PARITY-020, 033, 034, 037, 038.
Commit:

## T-CB05 Providers [PENDING]
Goal: CashBooksNotifier, CashEntriesNotifier, CashNotesNotifier, view-config and derived providers, settings provider.
Files: lib/core/providers/cashbook_provider.dart
Depends: T-CB02, T-CB04
Resume notes:
Commit:

## T-CB06 Books: picker, Accounts screen, add/edit/delete, opening balance [PENDING]
Goal: PARITY-001..012, 082.
Files: lib/features/cashbook/cashbook_books_screen.dart, cashbook_book_picker_dialog.dart
Depends: T-CB05
Resume notes:
Commit:

## T-CB07 Entry form, calculator sheet, items dialog [PENDING]
Goal: PARITY-013..030.
Files: lib/features/cashbook/cashbook_entry_form_screen.dart, cashbook_calculator_sheet.dart, cashbook_items_dialog.dart
Depends: T-CB05
Resume notes:
Commit:

## T-CB08 Book home screen: list, tabs, totals [PENDING]
Goal: PARITY-031..041, 080.
Files: lib/features/cashbook/cashbook_home_screen.dart, widgets/cashbook_row.dart, cashbook_totals_strip.dart, cashbook_period_bar.dart, cashbook_day_header.dart
Depends: T-CB05, T-CB07
Resume notes:
Commit:

## T-CB09 Search, filters, sort, date range [PENDING]
Goal: PARITY-042..047.
Files: cashbook_home_screen.dart, cashbook_provider.dart
Depends: T-CB08
Resume notes:
Commit:

## T-CB10 Edit, copy, delete, trash screen [PENDING]
Goal: PARITY-048..056.
Files: cashbook_entry_form_screen.dart, cashbook_trash_screen.dart
Depends: T-CB08
Resume notes:
Commit:

## T-CB11 Transfer [PENDING]
Goal: PARITY-057..060 with transferGroupId.
Files: cashbook_transfer_screen.dart
Depends: T-CB06
Resume notes:
Commit:

## T-CB12 Summaries and calendar [PENDING]
Goal: PARITY-061..064.
Files: cashbook_summary_screen.dart, cashbook_account_summary_screen.dart, cashbook_all_transactions_screen.dart, cashbook_calendar_screen.dart
Depends: T-CB08
Resume notes:
Commit:

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

## T-CB16 Hub screen and fifth tab [PENDING]
Goal: PARITY-077, 083; fifth tab in both shells; desktop two-pane layout.
Files: cashbook_hub_screen.dart, lib/features/navigation/main_navigation.dart, desktop_shell.dart
Depends: T-CB08
Resume notes: IndexedStack 5 items, Cmd+5, update ARCHITECTURE.md.
Commit:

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
