> SUPERSEDED IN PART (2026-10-13): the look is now the Apple-inspired Android direction. Read "Reconciliation 2026-10-13" at the end of this file first; where it conflicts with sections 4 to 7 above, it wins.
# cashbook_books_screen.dart (Accounts) plus cashbook_book_picker_dialog.dart and cashbook_book_dialogs.dart

Group g2. Sources: lib/features/cashbook/cashbook_books_screen.dart (138 lines), cashbook_book_picker_dialog.dart (107), cashbook_book_dialogs.dart (258). The picker and the dialogs (Add Account, Edit Account via `showCashTextPrompt`, Opening Balance, two-step delete) belong to this screen's flows and share this doc.

## 1. Purpose and primary user task

Manage books (accounts): see each book with its balance, add, rename, delete (two confirmations), set the opening balance, and switch the current book from a picker dialog opened from the ledger header, Account Summary and Calendar. Parity: PARITY-002..012, 082.

## 2. Current structure

`CashbookBooksScreen` (books:12): `Scaffold(appBar: cashAppBar('Accounts', actions: [TextButton 'ADD ACCOUNT']))` > `CashPageBody(700)` > `Column[TextField search, Expanded ListView.separated of Card > ListTile]`. Each row: name (w600), subtitle "Receiver book" or "Custom book" (12 sp), trailing balance text (green when >= 0, red when < 0, `CashColors`), `onTap: _rowMenu`. `_rowMenu` (23-66) opens a bottom sheet with Edit, Delete (red icon) and Opening Balance, then:
- Edit: `showRenameCashBookDialog` (dialogs:114-128) -> `showCashTextPrompt` -> `cashBooksProvider.notifier.renameBook`.
- Delete: refuses when `cashBooksProvider.length <= 1` ("Cannot delete the last book" snackbar); else `confirmDeleteCashBook` (dialogs:242-258): two `confirmCashDialog`s ("Delete" then "Are You Sure ?"), then `deleteBook`.
- Opening Balance: `showOpeningBalanceDialog` (dialogs:131-162) -> `_OpeningBalanceDialog` (amount, sign toggle, date) -> `setOpeningBalance`.

Picker: `showCashBookPicker` -> `_BookPickerDialog` (picker:18-107): `AlertDialog` "Accounts" with an "Edit" text button (pops and pushes `CashbookBooksScreen`), search `TextField`, `ListView` of radio-style `ListTile`s (current book checked, receiver icon) and an "Add Account" row; tap returns the `CashBook`.

`_AddBookDialog` (dialogs:17-111): Name, Opening Balance [Optional], sign toggle, date, "Receiver book" switch; `_save` closes silently when the name is empty (PARITY-003), calls `addBook`, shows the provider error in a snackbar.

State sources: `cashBooksProvider` (watch; notifier `addBook`, `renameBook`, `setOpeningBalance`, `deleteBook`), `cashEntriesProvider` (watch, to compute per-book totals via `CashbookCalculator.totals`), `cashSettingsProvider` (watch, formatMoney, formatDate), `currentCashBookProvider` (picker, watch). Local: `_query` string (screen and picker), dialog controllers in State.

## 3. Problems found

1. App bar action "ADD ACCOUNT" is an all-caps `TextButton` with `Colors.white` text (books:79-84): off-scale caps copy, color literal, and no visual weight as the primary action.
2. Tapping a row opens a bottom sheet with three commands (books:23-52). The row looks like a navigation item (card with title) but does not open the book; there is no way to open a book from this screen (selection happens in the picker). The sheet duplicates three commands in a list with a red delete icon beside neutral icons, order Edit, Delete, Opening Balance puts Delete in the middle (books:36-48).
3. Balance color: green for zero and positive (books:121-123); zero should be neutral. `CashColors.income/expense` literals.
4. `Card(margin: zero)` default elevation (books:109), `ListTile` default density; subtitle 12 sp `textSecondary` (4.76:1 ok).
5. Search `TextField` has no clear button, no `textInputAction`, `setState` per keystroke on the whole screen (books:92-98).
6. Totals recomputed per row, per build, from the full `cashEntriesProvider` list (books:107-108): O(books x entries) with a full-list watch, plus `CashbookCalculator.totals` allocs. At 50 books and 20k entries each rebuild iterates 1M items.
7. Picker: `AlertDialog` with `SizedBox(width: 360)` fixed (picker:50): overflows below 360+48 dp wide windows (small phones are about 360 dp, dialog inset 40 each side gives 280 dp for content). `ListTile(dense: true)` rows are 40 dp high (picker:67-69). Radio icons are drawn manually (`Icons.radio_button_checked`) without semantics (picker:70-76). "No books found" text color `textSecondary` (picker:86). No empty-state icon.
8. Picker "Edit" is a text button in the title with `Navigator.pop` then `Navigator.of(context).push` using the dialog's own context after pop (picker:40-44): works because the pop is queued, but the context is already being removed; UNVERIFIED on slow devices.
9. Add Account dialog: five stacked controls in an `AlertDialog` (dialogs:62-110): amount and sign and date are separate rows, "Opening Balance [Optional]" label with brackets, sign toggle labeled "+ Income" / "- Expense" (common:143-144), no `textInputAction`, Save closes silently with an empty name (PARITY-003, required) but gives no hint why nothing was created.
10. Opening Balance dialog: sign toggle semantics unclear ("+ Income", "- Expense"); `Save` with an empty amount saves 0 (`parseAmount(...) ?? 0`, dialogs:234), which sets the opening balance to zero instead of being refused, no confirmation.
11. Delete flow: two dialogs in a row with texts "Delete" and "Are You Sure ?" (dialogs:244-255); the second title has a stray space before the question mark (copy parity with the reference app); both dialogs show the confirm label "Delete" in red (fine) but Cancel is the left text button, same weight.
12. Feedback: no snackbar after add, rename, delete or opening balance saved (only errors show). After delete the list just changes.
13. Empty states: no empty state for a search with no results on the screen (books:100-132 renders nothing).
14. `CashPageBody(maxWidth: 700)` only applies on desktop.

## 4. Redesign

### 4.1 Accounts screen

- `RigScaffold(appBar: RigAppBar(title: 'Accounts', actions: [tonal Add account button on medium/expanded, IconButton Icons.add_rounded on compact]))`, `maxContentWidth` 640 (medium) / 1100 (expanded, two-column grid of cards, 2 columns at >=900).
- Search: `RigSearchField` (hint "Search", clear icon when non-empty), padding `s4`, margin bottom `s2`. Filter state remains local `_query`.
- Row = `RigCard` (level 1, radius `lg`, padding `s4`, min height 72) as `RigListRow`: leading 40 `primaryContainer` rounded square (radius `md`) with `Icons.account_balance_wallet_rounded` (or `Icons.person_pin_rounded` for receiver books) 24 `primary`; title `titleMedium`; subtitle "Receiver book" / "Custom book" `bodySmall` `onSurfaceVariant`; trailing `AmountText` style medium: tone `moneyIn` when balance > 0, `negative` when < 0, neutral `onSurfaceVariant` when 0. Values from `settings.formatMoney` (unchanged).
- Row interaction: tap opens a `RigChoiceDialog` as a sheet on compact (`RigSheet`, title = book name, subtitle = kind) and as a popup menu anchored to the row on expanded, with the same three commands in the order Edit, Opening Balance, then a divider and Delete (`negative`, `Icons.delete_rounded`). Order change is presentation only. A trailing `Icons.more_vert_rounded` button (tooltip "Account options") opens the same menu; the row tap keeps current behavior (menu).
- Add account: tonal button "Add account" (Title case copy; was "ADD ACCOUNT") at the top-right on medium and expanded, `IconButton` with tooltip on compact; additionally an `EmptyState` action.
- Empty: no books matching the search: `EmptyState(icon: Icons.search_off_rounded, title: 'No books found', hint: 'Try another name')`. (Existing copy "No books found" from the picker is reused.)
- Feedback: `showRigSnack` success after add ("Account added"), rename ("Account renamed"), opening balance ("Opening balance saved"), delete ("Account deleted"); the error messages from the provider are shown unchanged as error snackbars.

### 4.2 Book picker

- `RigChoiceDialog` presentation: bottom sheet on compact (`RigSheet`, max height 70 percent, search at top), dialog on expanded (max width 480). Title "Accounts", trailing text button "Edit" (opens the Accounts screen exactly as today).
- Rows: `RigListRow` min height 48 (touch) with `Radio`-like leading (`Icons.radio_button_checked_rounded` / `Icons.radio_button_unchecked_rounded` 20, `primary`) plus semantics `selected`, receiver books show a trailing `Icons.person_pin_rounded` 16 with tooltip "Receiver book". Search field with clear icon. "Add Account" row is a pinned tonal row at the bottom (`Icons.add_rounded`, label "Add Account"), not scrolling with the list.
- Empty: "No books found" with `Icons.search_off_rounded` 48.
- Width is `min(480, screen width - 32)`; no fixed 360.

### 4.3 Add Account dialog and Opening Balance dialog

- `RigDialogShell`, max width 440, content scrollable. Field order unchanged (Name, Opening Balance [Optional], sign, date, Receiver book switch). Labels: "Name", "Opening Balance (optional)", sign `RigSegmented` with Income and Expense options (min height 48), `RigDateField` label "Date", `RigSwitchRow` "Receiver book" with the existing subtitle "Receives payments logged on bills".
- `textInputAction`: next from Name to Opening Balance, done at the last text field; keyboard: Name `TextCapitalization.words`, amount decimal.
- Add Account Save with an empty name still closes without creating (PARITY-003); the Save button is rendered disabled (tonal) while the name is empty, but tapping it is still allowed? Decision: keep it enabled to preserve PARITY-003 exactly, and show no error (Q4 in the report asks whether to disable instead).
- Opening Balance dialog: same pattern; label "Amount"; unchanged empty-amount behavior (saves 0).
- Confirm delete: `ConfirmDialog` x2 with the same titles and messages ("Delete" then "Are You Sure ?", message texts unchanged); confirm in `negative`; first dialog message in `bodyMedium`; second dialog keeps the title text exactly.

### 4.4 Tokens

Spacing `s4` page padding, `s2` between cards, `s3` between dialog fields. Radius: cards `lg`, dialogs `xl`, fields `md`. Type: book name `titleMedium`, kind `bodySmall`, balance `amountMedium`. Colors: `moneyIn`, `negative`, `onSurfaceVariant`, `primaryContainer`, `outlineVariant`.

### 4.5 State table

| State | Rule |
|---|---|
| Default | list |
| Loading | none |
| Empty | no books after search: `EmptyState`; zero books cannot occur (default book) |
| Error | provider error strings shown in `showRigSnack(kind: error)` |
| Disabled | menu "Delete" of the last book stays visible and shows the existing snackbar "Cannot delete the last book" when chosen |

Motion: sheet entrance `slow`; card press `fast`; no list animation.

## 5. Logic touchpoints that must stay untouched

- `cashBooksProvider.notifier.addBook(name, kind: receiver ? 1 : 0, openingBalance, openingIsPositive, openingDate)` and its `(book, error)` record (dialogs:44-50, 56).
- `renameBook`, `setOpeningBalance(bookId, amount, isPositive, date)`, `deleteBook(id)` and the "last book" guard (`length <= 1`, books:58-61).
- Opening balance entry lookup: `sourceType == null`, `notes == cashOpeningBalanceNotes`, earliest by `compareChronological` (dialogs:133-142).
- Empty name closes the Add dialog without creating (PARITY-003); empty amount in Opening Balance saves 0.
- Picker returns the tapped `CashBook` through `Navigator.pop(context, b)`; callers do `currentCashBookIdProvider.notifier.select` and `clearFilters` themselves.
- Creating a book does not switch to it (PARITY-005).
- Two-step delete texts and order (PARITY-009), entries to trash (PARITY-010).
- Controllers inside `_AddBookDialogState` and `_OpeningBalanceDialogState` (dispose in State).
- `cashEntriesProvider` read for totals uses `CashbookCalculator.totals`, which ignores deleted entries.

## 6. Acceptance criteria

1. Each book row shows name, kind and balance with the same value as before; zero is neutral.
2. Row menu offers Edit, Opening Balance, Delete (same actions); Delete of the only book shows "Cannot delete the last book".
3. Add Account with an empty name creates nothing and closes; with a name and optional opening balance creates a book and (when a balance was typed) one entry noted "Opening Balance" with the chosen sign; the current book does not change.
4. Delete asks two confirmations; entries go to Deleted Transactions.
5. Picker: current book shows a checked radio; tapping a book returns it and the ledger switches; Edit opens the Accounts screen; Add Account opens the dialog and the new book appears in the list.
6. Every tap target >= 48 dp (touch); picker rows 48 dp.
7. Picker and dialogs work at 360 dp width and 200 percent text scale without overflow.
8. Snackbars appear after add, rename, opening balance, delete.
9. No `Colors.x`, hex, `CashColors` in these files.
10. Search on both the screen and the picker is case-insensitive substring (unchanged).

## 7. Performance notes

- Move per-book totals out of `itemBuilder`: compute a `Map<String, CashTotals>` once per `cashEntriesProvider` value (provider-side is L-10 in logic_g2.md; widget-side: `ref.watch(cashEntriesProvider.select(...))` to a precomputed map held by a small `BookBalances` widget).
- Search: keep `_query` in a small `StatefulWidget` around the list so the header and add button do not rebuild per keystroke.
- Picker `ListView(shrinkWrap: true)` with all children built eagerly is fine for under 50 books; use `ListView.builder` beyond that.
- Dialog controllers are State-owned and disposed correctly (dialogs:31-36, 191-195).
- Use `const` for the three menu items and the `Icon`s.


## Reconciliation 2026-10-13 (Apple look, Android only)

### R1. Mockup screens and Flutter mapping

| Mockup screen (J registry) | Mockup render function | Flutter file | Widgets | Notes |
|---|---|---|---|---|
| Accounts screen | `SC.cbBooks` | lib/features/cashbook/cashbook_books_screen.dart | LargeTitleScaffold (pushed, title "Accounts", add button), RigGroup with a search row, RigRow (29 dp icon tile, title, subtitle, balance), EmptyState | Balance cells use `mf` in the mockup (compact allowed); the redesign uses MoneyText without compact (conflicts_r3.md C-03). |
| Account actions sheet | `cbBookSheet` | cashbook_books_screen.dart (`showModalBottomSheet`) | RigSheet with title = book name, RigGroup of RigRows Edit, Opening Balance, Delete (destructive) | Same three commands as today. |
| Add Account dialog | `cbBookDlg` | lib/features/cashbook/cashbook_book_dialogs.dart (`_AddBookDialogState`) | RigSheet "Add Account": RigGroup of RigFormRows (Name, Opening balance with rupee prefix, Type RigSegmented, Date row, Receiver book RigSwitch), pinned RigButton "Save" | Save is disabled while the name is empty (LR-27). |
| Book picker | `cbPicker` | lib/features/cashbook/cashbook_book_picker_dialog.dart | RigSheet (search RigGroup, RigRow list, Add Account row, Edit text button) | Check mark replaces the radio icon. |
| Accounts list empty | `SC.cbBooks` with `UI.state=empty` | cashbook_books_screen.dart | EmptyState with a RigButton "Add Account" | Mockup text: "No accounts", "Add an account to start recording." The old doc used "No books found" for a search with no hit. |

### R2. What changes in the redesign (supersedes section 4)

Accounts screen (pushed from the drawer):
1. LargeTitleScaffold, title "Accounts", back chevron at left, trailing "+" glass button (48 dp, tooltip "Add account").
2. Search: a RigGroup with one row holding a search glyph and a left-aligned field, placeholder "Search accounts"; case-insensitive substring filter (unchanged).
3. Account list: one RigGroup. Each RigRow (min 56 dp): 29 dp rounded tile (`commission` colour with `person_pin` glyph for a receiver book, `accent` with a wallet glyph for a custom book), title 17 sp weight 600, subtitle 13 sp "Receiver book" or "Custom book", balance at right (17 sp, `moneyInText` when not negative else `moneyOutText`, full value, never compact). Tap opens the actions sheet.
4. Actions sheet (RigSheet, 28 radius, grabber, title = book name): Edit, Opening Balance, Delete (`moneyOutButton` tinted icon and `moneyOutText` label). Delete of the last book still shows the snackbar "Cannot delete the last book".
5. Add Account sheet: RigGroup rows Name (hint "Required"), Opening balance (rupee prefix, hint "Optional"), Type (RigSegmented Income and Expense, 200 dp wide), Date (`dFull`), Receiver book (RigSwitch) with the footer text "Receiver books receive payments logged on bills."; pinned RigButton "Save" (50 dp pill, `accentButton`), disabled at 40 percent opacity until the name has a non-space character (LR-27, supersedes PARITY-003).
6. Opening Balance sheet: Amount (rupee prefix), Type, Date; pinned "Save". Empty amount saves 0 (unchanged).
7. Edit Account sheet: one Name row and pinned "Save"; the controller is State-owned.
8. Delete flow: RigAlertDialog "Delete" with the message "If you delete this account then all transactions in this account will also get deleted.", then RigAlertDialog "Are You Sure?" with "Transactions go to Deleted Transactions for 30 days." Both destructive actions in `moneyOutText`. The second title keeps the text "Are You Sure?" (the code has "Are You Sure ?", see conflicts_r3.md C-08).
9. Book picker sheet: title "Accounts", Edit text button (opens the Accounts screen), search RigGroup, one RigRow per book with the check mark (22 dp, `accent`) on the current one, then "Add Account".


Old section 4 items:

- Old 4.1 RigScaffold with a tonal Add button on medium and expanded and a two-column grid: DROPPED; the "+" glass button on compact is KEPT.
- Old 4.1 search RigSearchField: CHANGED to the search RigGroup row; behaviour KEPT.
- Old 4.1 RigCard per book: CHANGED to RigRows in one RigGroup.
- Old 4.1 tap opens a RigChoiceDialog sheet on compact and a popup on expanded: CHANGED to the RigSheet only (popup DROPPED). Command order KEPT.
- Old 4.1 feedback snackbars ("Account added" and so on): KEPT as RigSnack; the mockup does not show them, they are optional copy.
- Old 4.2 picker as sheet (compact) and dialog (expanded): CHANGED to the sheet only; radio icons replaced by the check mark; the receiver tooltip becomes the subtitle text.
- Old 4.3 Add Account dialog and the decision to keep Save enabled for PARITY-003: CHANGED. Save is disabled while the name is empty (LR-27).
- Old 4.3 Opening Balance dialog: CHANGED to a sheet; unchanged behaviour.
- Old 4.3 two ConfirmDialogs: CHANGED to RigAlertDialog; texts KEPT.
- Old 4.4 tokens and 4.5 states: CHANGED to the tokens in this section; empty copy changes as listed.


States:

| State | Rule in the new look |
|---|---|
| Default | search row plus list |
| Loading | not applicable |
| Empty | no accounts (cannot occur, default book exists; mockup state): EmptyState "No accounts" with RigButton "Add Account". Search with no hit: "No books found", hint "Try another name" |
| Error | provider error strings in RigSnack |
| Disabled | Save disabled while the name is empty; Delete of the last book keeps its snackbar |


Motion: sheets rise 250 ms ease-out; ink press on rows; Save disabled to enabled change is instant; no list animation; reduced motion removes the rise.


### R3. Logic touchpoints and LR items

Untouched: `addBook(name, kind, openingBalance, openingIsPositive, openingDate)` and its `(book, error)` record, `renameBook`, `setOpeningBalance`, `deleteBook` with the last-book guard, the opening balance entry lookup, picker return value, creating a book does not switch to it (PARITY-005), two-step delete texts and order (PARITY-009), entries to trash (PARITY-010), State-owned controllers.


- LR-27 (approved): Add Account Save disabled while the name is empty; PARITY-003 silent close is superseded. The provider guard (empty name creates nothing) stays as a second line of defence.
- LR-24 (approved): balances and the prefix use the rupee sign.
- LR-32 (approved, Phase 1): double-tap Save guard (`_saving` flag) on the Add Account Save as well.
- No new logic item.


### R4. Acceptance criteria delta

1. Add Account: the Save pill is disabled (40 percent opacity, not focusable) while the name field is empty or only spaces; typing a name enables it; a tap on the enabled pill creates the book and closes the sheet; no silent close is possible.
2. Each row shows name, kind and the full balance (never L or Cr), `moneyInText` or `moneyOutText`, zero neutral; at text scale 200 percent the balance moves to its own line instead of shrinking below 11 px.
3. Actions sheet offers Edit, Opening Balance, Delete; Delete of the only book shows "Cannot delete the last book"; a normal delete asks twice and moves the entries to Deleted Transactions.
4. Picker: the current book has the check mark; tapping a book returns it and the ledger switches; Edit opens the Accounts screen; Add Account opens the sheet and the new book appears.
5. Receiver switch creates a book of kind receiver; the row subtitle reads "Receiver book".
6. Android back closes the sheet or alert; the keyboard closes first; dialogs and sheets keep their controllers in State (no crash on close).
7. All targets are at least 48 dp at 360 dp and 412 dp, light and dark.


### R5. Parity delta

Change on purpose:

- PARITY-003: empty name now cannot be saved (disabled Save) instead of closing silently (LR-27). Update parity_g2.md line 28 to: Save is disabled with an empty name and nothing is created.
- PARITY-002: the Add Account form is a sheet; fields and order identical.
- PARITY-035 and 084: balances show the rupee sign.


Must stay identical:

- PARITY-004 opening balance entry, PARITY-005 create does not switch, PARITY-006 picker, PARITY-007 row menu, PARITY-008 rename keeps entries, PARITY-009 two-step delete, PARITY-010 delete trashes entries, PARITY-011 edit opening balance in place, PARITY-012 last book remembered.


### R6. Performance and Android notes

- Edge to edge: status bar transparent; bottom inset from `MediaQuery.viewPaddingOf(context).bottom`. Pushed screens have no floating tab bar; content ends at inset + 24 dp, or inset + 110 dp when a pinned bottom pill is present.
- Keyboard: `resizeToAvoidBottomInset: true`; a pinned bottom pill sits above the keyboard; sheets add `MediaQuery.viewInsetsOf(context).bottom`; the focused field scrolls to the centre.
- List strategy: `ListView.builder` inside one RigGroup per scroll (fewer than 50 books is safe eagerly); precompute per-book totals once per `cashEntriesProvider` value.
- Search query kept in a small StatefulWidget around the list so the title and add button do not rebuild per keystroke.
- Controllers: `_AddBookDialogState` (`_name`, `_opening`) and `_OpeningBalanceDialogState` (`_controller`) are State-owned and disposed in code (verified); keep them in the sheet State when the dialog becomes a sheet. The Edit Account prompt uses `showCashTextPrompt` (State-owned, verified).
- Disabled Save needs a listener on `_name`: use `ValueListenableBuilder` on the controller around the button only, not a full-sheet `setState`.

