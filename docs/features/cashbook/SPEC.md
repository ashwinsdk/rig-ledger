# Cashbook feature - SPEC for RigLedger

Status: DRAFT for developer review. Docs only; nothing in lib/ has been changed.
Sources: DATA_MODEL.md (database facts), SCREENS.md (UI), BEHAVIOUR.md (observed behaviour). Reference app: package cashbook.cashbook v238 (Android).
Tags: [OBS] observed in the app or database, [ASM] assumed or inferred and still to verify.

## 0. Developer decisions (applied) and v2.0.0 context

Source: developer answers plus v2.0.0.md (Major feature 1 "Account Ledger", feature 4 payment logs with receivers).
- D1 Out of scope: Cash Calculator, ads, Remove Ads, Rate Us, Recommend. Print: kept only if trivial (PDF share covers it).
- D2 Books are GLOBAL (not per vehicle) and double as receivers. A book is either a receiver book (created for a person who receives money on RigLedger entries) or a custom book (any name the user adds). Models: CashBook.kind (0 = custom, 1 = receiver) and an optional CashBook.receiverId if receivers become their own entity (decided: not needed).
- D3 Labels: Income / Expense (no relabel dialog, no custom mode). "Transaction names" screen dropped; PARITY-078 becomes "labels are Income and Expense everywhere".
- D4 Trash is auto-purged (retention 30 days, same as tombstones). Purge records tombstones.
- D5 Import of real data only after the feature is stable (T-CB17 stays last).
- D6 Sync: all devices must update; no unknown-key passthrough. Bump the snapshot version and refuse to merge a snapshot with a higher version on an older build (T-CB03).
- D7 Export: PDF plus CSV only (no xlsx).
- D8 A new sqlite reader dependency is accepted for the import tool.
- D9 Money stays double (project rule), totals summed in integer paise for display.
- D10 Visual: RigLedger theme, reference layout and behaviour (section 8 option 2).
- D11 Currency: show "Rs." prefix or the rupee sign on amounts in the cash book.
- D12 Entry point: a FIFTH tab "Account Ledger" in main_navigation.dart and desktop_shell.dart (IndexedStack goes from 4 to 5; desktopNavIndexProvider and Cmd+5).
- D13 macOS: two-pane layout accepted.
- D14 Emulator second pass: only if a gap blocks implementation.

### Receiver integration (from v2.0.0 feature 4)
- Every payment on a main-bore or side-bore LedgerEntry becomes a logged payment (amount, date, receiver book). That payment-log model belongs to the v2.0.0 ledger work, not this spec, but the cash book must expose these hooks:
  - CashEntry.sourceType (String?: 'ledger_payment'), CashEntry.sourceId (String?: LedgerEntry.id) and CashEntry.sourcePaymentId (String?: payment log id). Adding a payment to a ledger entry with receiver R creates a Cash In entry in R's book with notes such as "<bill no> <agent/address>" and these three fields set.
  - Editing the payment updates the linked CashEntry; deleting the payment moves the linked CashEntry to trash (or removes it); the cash book UI lets the user edit these entries (decided Q-N4; editing the amount or date also updates the source payment) and offers "open source entry".
  - Creating a receiver creates its CashBook (kind = receiver). Renaming or deleting a receiver follows the book rules; deleting a receiver with payments needs an explicit warning.
- Commission (v2.0.0 feature 2) and the Portfolio page (feature 3) are separate specs. The Portfolio totals must not include cash-book entries unless they are linked via sourceType.
- Backward compatibility: existing LedgerEntry.receivedCash / receivedPhonePe have no receiver; old entries are not migrated and get no receiver book (Q-N3).

## 1. Feature summary and parity checklist

Feature: a general purpose cash book inside RigLedger. The user keeps several named books; each book holds dated Cash In / Cash Out entries with a note; running balances and period totals are computed; entries can be searched, filtered, sorted, copied, trashed and restored; money can be transferred between books; a to-do notebook; summaries, a calendar view, and PDF / CSV export. Works offline, syncs through the existing Drive snapshot.

Parity checklist (each line is testable; the reference app is the oracle):

Books
- PARITY-001 The app has at least one book; a default book named "Cash Book" exists on first use. [OBS]
- PARITY-002 Add Account dialog has Name, optional Opening Balance, "+" / "-" sign, date (default today), Cancel and Save. [OBS]
- PARITY-003 Saving with an empty name closes the dialog and creates nothing. [OBS]
- PARITY-004 A non-empty Opening Balance creates one entry in the new book with notes "Opening Balance"; "+" makes it Cash In, "-" makes it Cash Out. [OBS]
- PARITY-005 Creating a book does not switch to it. [OBS]
- PARITY-006 Tapping the book name on the main screen opens a picker dialog: title "Accounts", "Edit" link, search field, list, "Add Account". [OBS]
- PARITY-007 The Accounts screen lists books with a search field and an ADD ACCOUNT button; tapping a row offers Edit, Delete, Opening Balance. [OBS]
- PARITY-008 Renaming a book keeps all its entries attached to it. [OBS]
- PARITY-009 Deleting a book needs two confirmations ("If you delete this account then all transactions in this account will also get deleted", then "Are You Sure ?"). [OBS]
- PARITY-010 Deleting a book moves its entries to the trash (soft delete) and removes the book from lists. [OBS]
- PARITY-011 Editing the Opening Balance changes the existing "Opening Balance" entry in place; sign "-" converts it to Cash Out. [OBS]
- PARITY-012 The last opened book is remembered across launches. [ASM: seen once, later launch showed first book; verify]

Entry form
- PARITY-013 Main screen has big "Cash In" (green) and "Cash Out" (red) buttons that open the form pre-set to that type. [OBS]
- PARITY-014 Form fields in order: type chips, date with previous/next day arrows and calendar, time, amount, notes, Add Bills, Add Items. [OBS]
- PARITY-015 Date defaults to today, time to now; date format MMM-dd-yyyy; time hh:mm a (or 24 hour by setting). [OBS]
- PARITY-016 The type can be switched inside the form with the two chips. [OBS]
- PARITY-017 Amount field uses a decimal keyboard, ignores non-numeric characters and the minus sign (amounts are never negative). [OBS]
- PARITY-018 An empty amount blocks saving with no message and the form stays open. [OBS]
- PARITY-019 A zero amount can be saved. [OBS]
- PARITY-020 Amounts are rounded to 2 decimals when saved (1.239 becomes 1.24). [OBS]
- PARITY-021 Notes may be empty; notes can contain newlines. [OBS]
- PARITY-022 Date arrows move one day and cross month boundaries; future dates are allowed. [OBS]
- PARITY-023 Moving the date keeps the time of day. [OBS]
- PARITY-024 "Save and exit" saves and returns to the list. [OBS]
- PARITY-025 "Save and continue" saves, clears amount and notes, keeps the form open. [OBS]
- PARITY-026 Calculator icon in the amount field opens a calculator sheet (digits, 00, 000, comma, dot, + - * /, delete) that returns a value to the field. [OBS for layout, ASM for return]
- PARITY-027 Notes field autocompletes from earlier notes when the "Notes suggestion" setting is on (default on). [OBS setting, ASM behaviour]
- PARITY-028 Setting "Add description / Category" (default off) adds a "Description / Category" autocomplete field under Notes. [OBS]
- PARITY-029 "Add Items" opens a dialog with Item, Quantity, Unit, Rate, Add, an "Item (N)" count and "Total X", Cancel / OK. [OBS layout; storage unknown]
- PARITY-030 "Add Bills" offers Camera, Gallery, PDF and keeps up to 3 attachments per entry. [OBS menu, ASM limit]

List, balances, totals
- PARITY-031 Main list is newest first, grouped under day headers formatted "EEE, MMM dd yyyy". [OBS]
- PARITY-032 Row shows notes, time, amount in the Cash In column (green) or Cash Out column (red), and "Balance N". [OBS]
- PARITY-033 Running balance of a row = sum of in minus out of all non-deleted entries of the book up to and including that row in chronological order (date then time then id). [OBS for date/time, ASM for tie break]
- PARITY-034 Totals strip: Total Cash In, Total Cash Out, Balance = in minus out of the rows shown. [OBS]
- PARITY-035 Number format: grouping commas, no trailing ".00", decimals only when present, negative with "-", no currency symbol; Currency Format setting offers "1234" and "1,234.00". [OBS]
- PARITY-036 Tabs All, Daily, Weekly, Monthly, Yearly with a period bar and previous/next arrows ("MMM-dd-yyyy -> MMM-dd-yyyy"). [OBS for All and Monthly, ASM for others]
- PARITY-037 In a period tab the list begins with "Previous Balance N" (net of everything before the period) and the totals strip adds "Previous Balance" and a final "Balance" row (period balance plus previous balance); setting "Previous Balance" (default on) controls it. [OBS]
- PARITY-038 Negative balances show a leading minus. [OBS]
- PARITY-039 Setting "Show balance after each transaction" (default on) shows or hides the per-row balance. [OBS default, ASM toggle effect]
- PARITY-040 Setting "Show date in each entry" (default off) shows the date inside each row. [ASM]
- PARITY-041 Very long amounts wrap inside their column without crashing (a polished version may shrink the text instead). [OBS]

Search, filter, sort
- PARITY-042 Keyword search filters live on notes, case-insensitive substring, across all periods; totals reflect the filtered rows. [OBS]
- PARITY-043 Overflow menu: Notes (search dialog), Date (single day picker), Select Date Range (start and end, default today), Date Ascending, Date Descending, Cash In, Cash Out, Print, Your Name and Address, How to use the app?. [OBS]
- PARITY-044 Cash In shows only cash-in entries; Cash Out only cash-out entries; totals recompute. [OBS]
- PARITY-045 Date Ascending reverses the list order (oldest first). [OBS]
- PARITY-046 Active type filter and sort combine and persist while the screen stays open. [OBS]
- PARITY-047 Description (category) can be searched or filtered. [ASM]

Edit, copy, delete, trash
- PARITY-048 Tapping a row opens "Edit Transaction" (long press does the same). [OBS]
- PARITY-049 Edit form has the same fields plus a Book field to move the entry, Delete (left), Save (right), Copy toolbar action. [OBS]
- PARITY-050 Back from the edit form discards changes without a prompt. [OBS]
- PARITY-051 Copy offers "Copy to same account" and "Copy to different account"; same-account copy opens a prefilled add form (same date, time, amount, notes). [OBS]
- PARITY-052 Delete asks for confirmation then moves the entry to Deleted Transactions; balances and totals update. [OBS]
- PARITY-053 Deleted Transactions lists Date | Accounts | Amount rows with the entry date-time; tapping a row offers Restore or Delete; overflow offers Delete All. [OBS]
- PARITY-054 Restore returns the entry to its book and balances recompute. [OBS]
- PARITY-055 Permanent Delete asks "Delete Transaction" confirm and removes the entry for good. [OBS]
- PARITY-056 Trash is auto-purged after the retention period; restoring an entry whose book was deleted asks the user to pick a book. [DECIDED]

Transfer
- PARITY-057 Transfer screen: Amount, From, To (book spinners), date, time, Notes, Transfer button. [OBS]
- PARITY-058 Transfer creates a Cash Out in the source with notes "To <dest>" + newline + notes, and a Cash In in the destination with "From <src>" + newline + notes, at the chosen date and time. [OBS]
- PARITY-059 The form is cleared after a transfer and stays on screen. [OBS]
- PARITY-060 Empty amount does nothing. [OBS]

Summaries and calendar
- PARITY-061 Summary: one card per book with entries (name, Total Cash In, Total Cash Out, Balance) plus a grand total strip; tabs All, Daily, Weekly, Monthly, Yearly; date range button. [OBS]
- PARITY-062 Account Summary: book picker in the title, tabs All, Weekly, Monthly, Yearly, one row per day (Date, Cash In, Cash Out, Savings) and period totals (excluding previous balance). [OBS]
- PARITY-063 Transaction-All Accounts: all books in one list with a single signed-by-color Amount column and the book name; search, report, totals across books. [OBS]
- PARITY-064 Calendar: month grid with per-day income (green) and expense (red) sums, month navigation, month totals, book chosen via overflow "Accounts". [OBS]

Notebook
- PARITY-065 Notebook lists notes with tabs All, Daily, Weekly, Monthly, Yearly, period bar, a checkbox per row, stats Completed / Pending / Total, floating add button. [OBS]
- PARITY-066 Add note form: date, time, multiline Notes, Save; edit form adds Delete with confirmation. [OBS]
- PARITY-067 Checking a note marks it completed immediately and updates stats. [OBS]
- PARITY-068 Notebook overflow: Completed, Pending, Date Ascending, Date Descending, Report. [OBS]

Export and backup
- PARITY-069 Report button offers PDF and Excel; each saves a file and opens the share sheet. [OBS]
- PARITY-070 Report honours the active filters and period. [OBS]
- PARITY-071 Single-book PDF: A4, centered book name, range line, table (#, Date, Notes, Cash In, Cash Out, Balance) oldest first, then Total Cash In / Total Cash Out / Balance box. [OBS]
- PARITY-072 All-books PDF: date top right, title "Cash Book", range line, table (#, Date, Notes, Cash In, Cash Out, Accounts), summary box, no balance column. [OBS]
- PARITY-073 Excel export is a legacy .xls with sheet "Transactions" and text-formatted numbers. [OBS] RigLedger ships CSV instead (D7).
- PARITY-074 Export file names are "<Book> <MMM-dd-yyyy>.<ext>" for one book and "cashbook <MMM-dd-yyyy>.<ext>" for all books. [OBS]
- PARITY-075 Backup Data writes a database file and Restore Data replaces all data from a chosen file after an "Are You Sure ?" confirmation; round trip keeps every row. [OBS]
- PARITY-076 Settings screen holds: date format (6 patterns), Show Time, Time Format 12/24, Currency Format, the checkboxes listed in B09 with the observed defaults. [OBS]
- PARITY-077 Hub (inside the fifth tab) lists: Summary, Account Summary, Transaction-All, Accounts, Transfer, Report-All, Transaction names, Notebook, Calendar, Backup and Restore, Settings, Deleted Transactions, Help. [OBS] Transaction names, Cash Calculator, Remove Ads, Rate Us, Recommend are out of scope (D1, D3).
- PARITY-078 "Transaction names" lets the user relabel Cash In / Cash Out as "Income / Expense" or custom labels everywhere. [OBS dialog, ASM effect]
- PARITY-079 "Your Name and Address" text appears on reports. [ASM]
- PARITY-080 Empty book shows empty list with totals 0 and no empty-state text. [OBS]

- PARITY-081 Payments logged on a bill with a receiver create a linked Income entry in the receiver's book; editing or deleting the payment updates or trashes it. [v2.0.0]
- PARITY-082 Receiver books are created with the receiver and appear in the book picker marked as receivers. [v2.0.0]
- PARITY-083 The Account Ledger is the fifth bottom tab on Android and the fifth sidebar item on macOS. [D12]
- PARITY-084 Amounts display with an Rs. prefix or rupee sign. [D11]

Count: 84 PARITY lines (items marked ASM must be verified in the reference app before sign-off).

## 2. Proposed Hive models

Naming follows the project (snake_case files, PascalCase classes, toMap/toJson as in MODELS.md). All extend HiveObject, have id (UUID string), createdAt, updatedAt, copyWith, toJson/fromJson.

typeIds: the grep of lib/core/models shows 0, 1, 4 to 10 used. Proposed: CashBook = 2, CashEntry = 3, CashNote = 11. Re-grep before coding.

### CashBook (typeId 2) - lib/core/models/cash_book.dart
| Field | HiveField | Type | Notes |
|---|---|---|---|
| id | 0 | String | UUID |
| name | 1 | String | Unique (case-insensitive) recommended |
| createdAt | 2 | DateTime | |
| updatedAt | 3 | DateTime | |
| sortOrder | 4 | int | New; default 0; reference app sorts by creation order |
| kind | 5 | int | 0 custom book, 1 receiver book (v2.0.0) |
| receiverId | 6 | String? | RESERVED, unused: receivers are just books (Q-N1); omit this field in T-CB01 |

### CashEntry (typeId 3) - lib/core/models/cash_entry.dart
| Field | HiveField | Type | Notes |
|---|---|---|---|
| id | 0 | String | UUID (reference uses an integer; kept in importedLegacyId) |
| bookId | 1 | String | FK to CashBook.id (reference links by book name text; we use the id) |
| date | 2 | DateTime | Local date and time of the entry (see section 3) |
| amount | 3 | double | Always >= 0, rounded to 2 decimals |
| isCashIn | 4 | bool | Replaces the pair cash_in / cash_out / transactionType |
| notes | 5 | String | Empty string allowed |
| description | 6 | String? | The "Description / Category" text |
| attachmentPaths | 7 | List<String>? | Up to 3 (bill, bill2, bill3) |
| itemsJson | 8 | String? | Line items from Add Items (storage unknown in reference; JSON list of item, qty, unit, rate) |
| isDeleted | 9 | bool | Trash flag |
| deletedAt | 10 | DateTime? | When moved to trash |
| transferGroupId | 11 | String? | NEW: links the two rows of a transfer (reference has none); null for imports |
| importedLegacyId | 12 | int? | Reference row id, for idempotent re-import |
| createdAt | 13 | DateTime | |
| updatedAt | 14 | DateTime | Needed for sync (reference has none) |
| bookNameSnapshot | 15 | String? | Name of the book at trash time |
| sourceType | 16 | String? | 'ledger_payment' when created from a bill payment |
| sourceId | 17 | String? | LedgerEntry.id of the bill |
| sourcePaymentId | 18 | String? | Payment log id |

No stored balance (reference stores 0 in every row). Balance is computed.

### CashNote (typeId 11) - lib/core/models/cash_note.dart
| Field | HiveField | Type | Notes |
|---|---|---|---|
| id | 0 | String | |
| date | 1 | DateTime | |
| text | 2 | String | |
| isCompleted | 3 | bool | Reference stores a text flag |
| createdAt | 4 | DateTime | |
| updatedAt | 5 | DateTime | |

### Settings (existing settings box, no new model)
Keys with prefix `cashbook.`: dateFormat, showTime, timeFormat, currencyFormat, showDateInEntry, showPreviousBalance, showBalancePerEntry, showDescription, notesSuggestion, showTimeInReports, reporterName (Your Name and Address), labelMode (cashInOut | incomeExpense | custom), customLabelIn, customLabelOut, lastCashBookId. Defaults from BEHAVIOUR.md B09.

### Scoping decision (vehicleId)
DECIDED (D2): global books; no vehicleId on CashBook. Remove HiveField 5 vehicleId from CashBook and use HiveField 5 `kind` (int, 0 custom, 1 receiver) and HiveField 6 `receiverId` (String?). Cash books are not hidden or refreshed on vehicle switch.

### Deletes and tombstones
- Trash is a soft delete: CashEntry.isDeleted = true, deletedAt set, updatedAt bumped. It syncs like any update (last updatedAt wins). No tombstone.
- Permanent delete (purge from trash, Delete All, or deleting a book's trashed entries): call DatabaseService.recordTombstone(id, 'cash_entries') then remove. Same for books ('cash_books') and notes ('cash_notes').
- Deleting a book: set isDeleted-equivalent? Reference soft-deletes the entries but hard-deletes the book. Proposal: record a tombstone for the book, soft-delete its entries (they stay in trash with a copy of the old book name in `deletedBookName` field, see below). Use CashEntry HiveField 15 `bookNameSnapshot` (String?) so trashed entries of a deleted book can show a name and be restored into a recreated or chosen book. [Resolves PARITY-056 by design; confirm with the developer.]

## 3. Money and date rules (consistent with CONVENTIONS.md)
- Money: `double`, as everywhere in the project. Round to 2 decimals with `(v * 100).round() / 100` on save (matches PARITY-020). Sums: add as doubles, display rounded to 2 decimals; to avoid drift, compute totals by summing integer paise (`(amount * 100).round()`) and dividing once for display. Alternative (int paise storage) is better but breaks the "all monetary values stored as double" convention; not proposed.
- Zero allowed; negative not allowed (amount >= 0; type holds the sign).
- Display: intl NumberFormat with grouping and 0 to 2 fraction digits (the reference drops ".00"). Currency Format setting "1,234.00" forces 2 fraction digits. Amounts carry an "Rs." prefix or rupee sign (D11; final).
- Dates: DateTime local, serialised ISO 8601 in toJson (project rule; no timezone handling). Reference stores true UTC epoch milliseconds; import converts with `DateTime.fromMillisecondsSinceEpoch(ms).toLocal()` (the device zone at import time).
- Ordering: by date, then createdAt, then id for ties.
- Period boundaries: Daily = the selected day; Weekly = week containing the date (Sunday start, to verify); Monthly = first to last day of the month; Yearly = Jan 1 to Dec 31; All = no bounds. "Previous balance" = signed sum of non-deleted entries with date before the period start.

## 4. Provider plan and screen plan

Files (project naming):
- lib/core/models/cash_book.dart, cash_entry.dart, cash_note.dart (+ .g.dart generated)
- lib/core/providers/cashbook_provider.dart: `CashBooksNotifier` (StateNotifier<List<CashBook>>), `CashEntriesNotifier` (StateNotifier<List<CashEntry>>), `CashNotesNotifier`; each with loadXxx, addXxx, updateXxx, deleteXxx, refresh per CONVENTIONS.md. Never call DatabaseService from widgets.
- Derived providers (Provider): `currentCashBookProvider` (StateProvider<String?> for id, resolved to CashBook), `cashEntriesOfBookProvider`, `cashViewConfigProvider` (StateProvider of a small immutable class: tab, anchor date, search query, type filter, sort order, custom range), `cashVisibleEntriesProvider` (applies filters), `cashLedgerRowsProvider` (rows with running balance and day groups), `cashTotalsProvider` (in, out, balance, previousBalance), `cashSummaryByBookProvider`, `cashDailySummaryProvider`, `cashTrashProvider`, `cashSettingsProvider` (StateNotifier over the settings box).
- Pure logic in lib/core/utils/cashbook_calculator.dart (balance, period ranges, grouping) so it is unit-testable.
- Services: lib/core/services/cashbook_export_service.dart (PDF with the existing `pdf` package, CSV with `csv`, share with `share_plus`, save via existing file_save_service.dart), lib/core/services/cashbook_import_service.dart.

Screens (lib/features/cashbook/):
- cashbook_home_screen.dart (main book screen: toolbar, tabs, list, big buttons, totals strip)
- cashbook_entry_form_screen.dart (add/edit, `cashbook_calculator_sheet.dart` widget)
- cashbook_items_dialog.dart, cashbook_book_picker_dialog.dart, cashbook_books_screen.dart (Accounts)
- cashbook_transfer_screen.dart, cashbook_trash_screen.dart
- cashbook_summary_screen.dart, cashbook_account_summary_screen.dart, cashbook_all_transactions_screen.dart, cashbook_calendar_screen.dart
- cashbook_notebook_screen.dart, cashbook_note_form_screen.dart
- cashbook_settings_screen.dart, cashbook_hub_screen.dart (replaces the drawer, see below)
- cashbook_import_screen.dart (one-time import)
- widgets/: cashbook_row.dart, cashbook_totals_strip.dart, cashbook_period_bar.dart, cashbook_day_header.dart

Navigation (no named routes, Navigator.push MaterialPageRoute):
- Entry point (D12): a fifth tab "Account Ledger". Both shells use an IndexedStack of 4 screens (Ledger, Stats, Agents, Settings); add a fifth in `main_navigation.dart` and `desktop_shell.dart`, extend `desktopNavIndexProvider` and add Cmd+5. Update ARCHITECTURE.md.
- The reference drawer becomes `cashbook_hub_screen.dart`: a list of destinations (mobile) or a left sidebar inside the feature (desktop).

Adaptive layout:
- Mobile: single column as in SCREENS.md, `AdaptiveHeader` for headers, bottom action buttons and totals strip.
- Desktop (macOS, width above 900): two panes, left pane book list and hub destinations, right pane the ledger; forms as centered dialogs max width 700 (CONVENTIONS); Cmd+N opens the new entry form for the current book; search field always visible in the header instead of the collapsing search view.

## 5. Impact analysis

DatabaseService (lib/core/database/database_service.dart):
- Register adapters CashBookAdapter, CashEntryAdapter, CashNoteAdapter in initialize().
- Open boxes: `cash_books`, `cash_entries`, `cash_notes` (Box<T>, key = id). Add `late static` fields and name constants like the existing ones.
- CRUD: saveCashBook, deleteCashBook (tombstone first), same for entries and notes; helpers for trash (moveToTrash, restore, purgeTrash), bulk `renameBook` is NOT needed because entries reference bookId.
- `schemaVersion` 3 to 4. `_performMigrations` is a stub; no data transform required because the boxes are new (brand new boxes are empty on old installs). Bump version only.
- Backup map (around line 296-330): add keys `cashBooks`, `cashEntries`, `cashNotes`. `restoreBackup` and `_clearAllDataForRestore` must clear and refill the new boxes, using `backup['cashBooks'] ?? []` so backups made by older app versions restore without error.
- Add the three new refresh calls to the provider refresh pattern after vehicle switch or sync (ARCHITECTURE.md lists 8; becomes 11). Update that doc when implemented.

SyncService (lib/core/services/sync_service.dart):
- `_merge()` add three `_mergeCollection` calls for `cashBooks`, `cashEntries`, `cashNotes` with collection names matching the tombstone box names. Treat a missing key on either side as an empty list.
- Tombstone rule is unchanged: tombstone beats entity if deletedAt >= updatedAt. Because CashEntry has a real updatedAt, last-writer-wins works; the reference had no timestamps so imported rows get updatedAt = import time.
- Backward compatibility (D6: all devices must update): an older RigLedger build that syncs will rewrite the Drive snapshot without the cash keys, dropping cash data from Drive (local data on the newer devices survives and re-uploads on the next sync). Mitigation (decided): the release bumps snapshot `version` to 4 and the new merge refuses to overwrite a remote snapshot whose version is higher than the local build knows; users are told to update every device. Note the v2.0.0 release also changes LedgerEntry payments, so pick one version bump for both.
- Hive writes during sync have no lock (existing danger zone); cash entries add more write traffic, notably "Save and continue".

Export:
- Existing export screens (csv_export_screen.dart, pdf_export_screen.dart) are ledger-specific; do not extend them. Add cashbook_export_service.dart and reuse `pdf`, `csv`, `share_plus`, `file_picker`, file_save_service.dart. CSV replaces the reference's .xls (PARITY-073); optional xlsx later.

Settings screen: add a "Cash Book" entry that pushes cashbook_hub_screen.dart; cash settings live on cashbook_settings_screen.dart to keep settings.dart small.

Other: MODELS.md typeId registry and ARCHITECTURE.md boxes list must be updated when implemented. build_runner must be run after the models are added. flutter analyze after each task.

## 6. Import plan (one-time import from the reference app's backup .db)

Input: a .db file produced by the reference app (Backup Data) or an old backup (older column order; read by column name). Tool: cashbook_import_screen.dart reached from Account Ledger settings, using file_picker, and the `sqflite`/`sqlite3` package read-only (a new dependency; alternative is to ask users to export CSV, but the reference has no CSV, so a sqlite reader is required; accepted, D8).

Mapping:
| Source | Target |
|---|---|
| accounts._id, name | CashBook (new UUID, name; keep a temporary map name to id). Books named identically to an existing CashBook are merged. |
| cashTransaction.accounts (text) | bookId via the name map; if a name has no accounts row, create the book. |
| cashTransaction.id | CashEntry.importedLegacyId (idempotency: skip rows whose importedLegacyId already exists for that book name) |
| date (epoch ms) | date = DateTime.fromMillisecondsSinceEpoch(ms).toLocal() |
| cash_in, cash_out, transactionType | isCashIn = transactionType == 1 (fallback: cash_in > 0); amount = cash_in or cash_out, rounded to 2 decimals |
| balance | ignored (always 0) |
| notes, description | notes, description (trim nothing) |
| bill, bill2, bill3 | attachmentPaths only if the file path exists on the device; otherwise dropped and counted in the import report |
| isDeleted, deletedDate | isDeleted, deletedAt = DateTime(ms).toLocal() |
| (none) | createdAt = updatedAt = import time |
| notebook (date, note, completed) | CashNote; completed text mapped true for "true", "1", "yes", "completed" (verify values) |
| CurrencyNotes, room_master_table, android_metadata | ignored |

Steps: pick file, open read-only, show counts per book and deleted rows, preview, confirm, write in one pass with batched `putAll`, show a report (books created, entries imported, skipped, attachments dropped). Never delete or modify the source file. Dry-run mode first. The real user data has 24 books and about 2000 entries, so use batch writes and a progress indicator.

## 7. Task breakdown (format of .claude/tasks/CURRENT.md; NOT written to CURRENT.md)

Prefix T-CB used to avoid clashing with existing ids; renumber when promoted.

## T-CB01 Cashbook models and adapters [PENDING]
Goal: CashBook (typeId 2), CashEntry (typeId 3), CashNote (typeId 11) with copyWith, toJson/fromJson, generated adapters.
Files: lib/core/models/cash_book.dart, cash_entry.dart, cash_note.dart, *.g.dart (generated)
Depends: typeId re-grep
Resume notes: run build_runner; update MODELS.md.
Commit:

## T-CB02 DatabaseService boxes, CRUD, trash, schema 4 [PENDING]
Goal: register adapters, open boxes, CRUD with tombstones, trash helpers, schemaVersion 4, backup/restore keys with null-safe reads.
Files: lib/core/database/database_service.dart
Depends: T-CB01
Resume notes: purge uses recordTombstone before delete.
Commit:

## T-CB03 SyncService merge for cash collections [PENDING]
Goal: merge cashBooks, cashEntries, cashNotes; tolerate missing keys; keep older snapshots restorable.
Files: lib/core/services/sync_service.dart
Depends: T-CB02
Resume notes: add the three refresh calls to the refresh pattern after sync.
Commit:

## T-CB04 Calculator utility and unit tests [PENDING]
Goal: running balance, previous balance, period ranges, grouping, rounding, number formatting.
Files: lib/core/utils/cashbook_calculator.dart, test/cashbook_calculator_test.dart
Depends: T-CB01
Resume notes: cover PARITY-020, 033, 034, 037, 038.
Commit:

## T-CB05 Providers [PENDING]
Goal: CashBooksNotifier, CashEntriesNotifier, CashNotesNotifier, view-config and derived providers, settings provider.
Files: lib/core/providers/cashbook_provider.dart
Depends: T-CB02, T-CB04
Resume notes: follow the 5-method notifier rule.
Commit:

## T-CB06 Books: picker, Accounts screen, add/edit/delete, opening balance [PENDING]
Goal: PARITY-001 to 012.
Files: lib/features/cashbook/cashbook_books_screen.dart, cashbook_book_picker_dialog.dart
Depends: T-CB05
Resume notes: two-step delete confirm; trash the entries.
Commit:

## T-CB07 Entry form, calculator sheet, items dialog [PENDING]
Goal: PARITY-013 to 030 (attachments stored as paths, may be stubbed).
Files: lib/features/cashbook/cashbook_entry_form_screen.dart, cashbook_calculator_sheet.dart, cashbook_items_dialog.dart
Depends: T-CB05
Resume notes: amount filter, rounding, Save and continue.
Commit:

## T-CB08 Book home screen: list, tabs, totals [PENDING]
Goal: PARITY-031 to 041, 080.
Files: lib/features/cashbook/cashbook_home_screen.dart, widgets/cashbook_row.dart, cashbook_totals_strip.dart, cashbook_period_bar.dart, cashbook_day_header.dart
Depends: T-CB05, T-CB07
Resume notes: AdaptiveHeader; mobile layout first.
Commit:

## T-CB09 Search, filters, sort, date range [PENDING]
Goal: PARITY-042 to 047.
Files: cashbook_home_screen.dart, cashbook_provider.dart
Depends: T-CB08
Resume notes: filters and sort combine.
Commit:

## T-CB10 Edit, copy, delete, trash screen [PENDING]
Goal: PARITY-048 to 056.
Files: cashbook_entry_form_screen.dart, cashbook_trash_screen.dart
Depends: T-CB08
Resume notes: bookNameSnapshot for entries of deleted books.
Commit:

## T-CB11 Transfer [PENDING]
Goal: PARITY-057 to 060 with transferGroupId.
Files: cashbook_transfer_screen.dart
Depends: T-CB06
Resume notes: create both rows in one batch.
Commit:

## T-CB12 Summaries and calendar [PENDING]
Goal: PARITY-061 to 064.
Files: cashbook_summary_screen.dart, cashbook_account_summary_screen.dart, cashbook_all_transactions_screen.dart, cashbook_calendar_screen.dart
Depends: T-CB08
Resume notes: reuse period bar widget.
Commit:

## T-CB13 Notebook [PENDING]
Goal: PARITY-065 to 068.
Files: cashbook_notebook_screen.dart, cashbook_note_form_screen.dart
Depends: T-CB05
Resume notes: checkbox toggles isCompleted.
Commit:

## T-CB14 Settings and label modes [PENDING]
Goal: PARITY-027, 028, 035, 039, 040, 076, 078 (fixed Income/Expense), 079, 084.
Files: cashbook_settings_screen.dart, cashbook_provider.dart
Depends: T-CB05
Resume notes: label modes feed all headers.
Commit:

## T-CB15 PDF and CSV export [PENDING]
Goal: PARITY-069 to 074 (PDF and CSV only).
Files: lib/core/services/cashbook_export_service.dart, reports UI hooks
Depends: T-CB08, T-CB12
Resume notes: reuse file_save_service.dart.
Commit:

## T-CB16 Hub screen and Settings entry point [PENDING]
Goal: PARITY-077, 083; fifth tab in both shells; desktop two-pane layout.
Files: cashbook_hub_screen.dart, lib/features/navigation/main_navigation.dart, desktop_shell.dart
Depends: T-CB08
Resume notes: IndexedStack 5 items, Cmd+5, update ARCHITECTURE.md.
Commit:

## T-CB19 Receiver and payment-log hooks [PENDING]
Goal: PARITY-081, 082; linked CashEntry create/update/trash from ledger payments; receiver book creation.
Files: cashbook_provider.dart, database_service.dart, (v2.0.0 payment-log files)
Depends: T-CB05, v2.0.0 payment log model
Resume notes: sourceType/sourceId/sourcePaymentId; open-source navigation.
Commit:

## T-CB17 Import tool [PENDING]
Goal: section 6, with dry run and report.
Files: cashbook_import_screen.dart, cashbook_import_service.dart, pubspec.yaml (sqlite reader), 
Depends: T-CB02, feature stable (D5)
Resume notes: idempotent by importedLegacyId; test with a copy of the reference backup.
Commit:

## T-CB18 Parity QA pass and docs [PENDING]
Goal: walk PARITY-001 to 080 against the reference app; update MODELS.md, ARCHITECTURE.md, MEMORY.md.
Files: docs/features/cashbook/*, .claude/context/*.md
Depends: all
Resume notes: mark each parity line pass/fail in PROGRESS.md.
Commit:

## 8. Visual decision

Reference look (SCREENS.md): flat Material blue app bar (#2196F3), light blue-grey background (#ECEFF1), white cards, green and red full-width action buttons, green/red/blue number colors, compact dense list rows, bottom totals strip. No logo or brand colors beyond the blue.

RigLedger theme: brand gradient #252B49 -> #315D9A -> #618DCE, primary AppColors.primary (#315D9A), light only, AdaptiveHeader, Category colors.

Option 1 - Visual copy with own icons: reproduce the reference exactly (flat #2196F3 toolbar, #4CAF50/#EF5350 buttons, same paddings and row anatomy, same chips), using Material icons only and no original assets. Pro: instant familiarity, simplest to check against PARITY. Con: the feature looks foreign next to the rest of RigLedger and adds a second palette.

Option 2 - RigLedger theme, same layout and behaviour (CHOSEN, D10): keep the structure (header, tabs, day groups, row anatomy, two action buttons, totals strip) but use AdaptiveHeader with the brand gradient, AppColors.primary for chips and selection, and keep green and red only for money semantics (cash in / cash out) since those are functional colors. Pro: consistent look, desktop adaptation comes naturally. Con: small visual drift from the original; parity is judged on behaviour and layout, not pixels.

Decision: option 2.

## 9. Unknowns and risks

| Unknown | Why | How to verify later |
|---|---|---|
| Storage and display of Add Items line items | The backup has no items table or column; the test did not save items | Save an entry with items in the reference app, make a backup, diff the DB (notes/description text or an undiscovered table) |
| Attachment storage (bill, bill2, bill3) | All NULL in the reference data | Attach an image and PDF, back up, read the stored string (path or uri) |
| Drive backup format and restore from Drive | Needs Google sign-in (LOCKED) | Sign in on a throwaway account and inspect the Drive file (likely the same .db) |
| Password and fingerprint lock behaviour | Not exercised | Enable and observe launch flow, recovery path |
| "Transaction names" effect | Dialog seen only | Switch to Income/Expense and walk the screens |
| Daily, Weekly, Yearly tab rules (week start, labels) | Only All and Monthly checked | Test each tab with entries across week boundaries |
| Tie-break order for entries with the same timestamp | All test rows differed by seconds | Create two entries with the same second (edit times) |
| Restoring a trashed entry whose book was deleted | Not tested | Delete a book, restore one entry, see result |
| Search scope (notes only or also description) | Description empty in tests | Enable description, add text, search for it |
| "Date" overflow filter result and Select Date Range semantics (inclusive end) | Only dialogs opened | Apply and compare lists |
| Notes autocomplete rule | Not exercised | Type a prefix of an old note |
| Print action | Not run | Trigger from main overflow |
| Money precision for very large sums | Reference uses double | RigLedger uses the same; compare rounding of totals at 1e11 |
| Time zone: reference stores UTC instants, RigLedger stores local DateTime | Import converts at import time | Import on a device in a different zone and compare shown times |
| Old-app sync overwrite dropping cash data (section 5) | Behaviour of older builds | Test an older build against a snapshot with cash keys |
| Android runtime ads, in-app purchase | Out of scope | n/a |

Risks: scope (the reference has about 15 screens), double-based money, a new sqlite dependency for import, and the second palette if option 1 is chosen.

## Questions

Resolved: Q-N1 receivers are just books (no separate entity, agents are not receivers); Q-N2 trash retention 30 days; Q-N3 old payments without a receiver are not migrated; Q-N4 payment-linked Income entries are editable in the book; Q-N5 amounts use the "Rs." prefix. (Original wording follows.) Q-N1 are receivers a new entity or just books (and are Agents receivers)? Q-N2 trash retention days (proposal 30)? Q-N3 how are pre-2.0 payments without a receiver migrated? Q-N4 should cash-book Income entries from payments be editable in the book or read-only? Q-N5 rupee sign or "Rs." text (CONVENTIONS says Rs. prefix)?
