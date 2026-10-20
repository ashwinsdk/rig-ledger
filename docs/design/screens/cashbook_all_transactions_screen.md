> SUPERSEDED IN PART (2026-10-13): the look is now the Apple-inspired Android direction. Read "Reconciliation 2026-10-13" at the end of this file first; where it conflicts with sections 4 to 7 above, it wins.
# cashbook_all_transactions_screen.dart (Transaction-All Accounts)

Group g2. Source: lib/features/cashbook/cashbook_all_transactions_screen.dart (204 lines).

## 1. Purpose and primary user task

List the entries of every book in one list, grouped by day (newest first), with the book name and a single Amount column colored by type; search by notes, description or book name; tap a row to edit. Totals strip for the shown rows. Parity: PARITY-063.

## 2. Current structure

`CashbookAllTransactionsScreen` (ConsumerStatefulWidget). Local state `_sel` (`CashPeriodSel`, default All), `_searching`, `_query` (no controller; the field is uncontrolled). Providers: `cashSettingsProvider`, `cashBooksProvider` (names map), `cashQueryEntriesProvider(_sel.query(null))`. The filter (notes, description, book name, lowercase contains) and `CashbookCalculator.totals` run in `build`. Grouping by `dateOnly` into a flattened `items` list. Tree: hand-built `AppBar` (gradient flexible space, white text, search toggle icon) > `CashPageBody(900)` > `Column[CashPeriodSelector, header Row (Date flex 5, Accounts flex 3, Amount flex 3), Divider, Expanded(empty text or ListView.builder of CashbookDayHeader and InkWell rows), CashbookTotalsStrip]`. Row: notes (maxLines 2) + time 12 sp (flex 5), book name 13 sp (flex 3, maxLines 2), amount `FittedBox` colored income/expense (flex 3). Tap pushes `CashbookEntryFormScreen(entry: e)`.

## 3. Problems found

1. Hand-built `AppBar` with gradient and white text also on desktop, unlike `cashAppBar` (all_transactions:58-90): another third variant of the header (see incons_g2.md 1).
2. Search `TextField` has no controller, no clear button, no tooltip on the toggle icon (all_transactions:60-88).
3. The search filter and the totals run on every build (all_transactions:34-43); fine for hundreds of entries, grows linearly after that. Closing search resets `_query` (all_transactions:84-88), which is intended.
4. Single Amount column with color only distinguishing Income and Expense: no sign, no icon (all_transactions:134-135) (color is the only signal, violates DESIGN_SYSTEM 16).
5. Book name column 13 sp truncated at 2 lines in a flex-3 column; at 360 dp the book column is about 85 dp (all_transactions:167-173).
6. Header "Date" over notes again misleading (all_transactions:105).
7. Rows have no hover, no min height guarantee (about 52 dp), bottom border #F1F5F9 (all_transactions:141-147).
8. Empty state bare text `textHint` (all_transactions:122-124); no distinction between no data and no search match.
9. No indication of how many rows or what the totals cover (period vs search) except the strip.
10. Desktop: no context menu; same row tap only.

## 4. Redesign

- `RigScaffold(appBar: RigAppBar(title: 'Transaction-All Accounts', actions: [search toggle (Icons.search_rounded / Icons.close_rounded, tooltip "Search" / "Close search")]))`. In search mode the title is a `RigSearchField` with a controller owned by State (new `_searchController`, disposed in `dispose`; text and `_query` stay in sync via `onChanged`) and a clear icon.
- Period: `RigChipRow` + `PeriodNavigator`.
- Rows: `LedgerRowTile` variant "all books" (see cashbook_home_screen.md 4.3 for anatomy): compact = `[TypeBadge] [notes bodyLarge maxLines 2 / meta: time bodySmall + book name as a `labelMedium` pill (surfaceContainer fill, radius full) maxLines 1] [AmountText medium, moneyIn or negative]`; medium and expanded = table with columns Details (flex 5), Account (flex 3), Amount (flex 3, right) and a sticky header row "Details | Account | Amount" (the header text "Accounts" becomes "Account" singular; "Date" becomes "Details", see Q1). Day groups use `DayGroupHeader` and one `RigCard` segment per day (same as home).
- Totals: `CashTotalsCard` with the same three values as today, labelled by `CashLabels` strings.
- Empty: no data: `EmptyState(icon: Icons.receipt_long_rounded, title: 'No transactions')`; no match: hint "No match for the search" and a tonal "Clear search" button.
- Desktop: hover `surfaceContainerHigh`, right-click context menu with "Edit" only, Enter opens, max width 1100, Cmd+F focuses the search field (UI shortcut only).

Tokens: row padding `s4` x `s3`; book pill `labelMedium`; amounts `amountMedium`; colors `moneyIn`, `negative`, `onSurfaceVariant`, `surfaceContainer`, `outlineVariant`.

State table: Default (list); Loading none; Empty (two variants); Error none; Disabled none; Searching (search field in the app bar).

Motion: search field cross-fade `base`; period shift cross-fade `base`.

## 5. Logic touchpoints that must stay untouched

- `cashQueryEntriesProvider(_sel.query(null))`, the entries order (newest first) and grouping by `CashbookCalculator.dateOnly`.
- Filter definition: lowercase contains on `notes`, `description` or the book name from `cashBooksProvider`.
- `CashbookCalculator.totals(entries)` over the filtered entries.
- Row tap pushes `CashbookEntryFormScreen(entry: e)`; amount color by `e.isCashIn`; `settings.formatMoney(e.amount)` and `settings.formatTime(e.date)`.
- Search toggle resets `_query` when closed.

## 6. Acceptance criteria

1. Entries from all books appear grouped by day, newest first, each with its book name; amounts match their books.
2. Typing in search filters live by notes, description or book name (case-insensitive); closing search restores the full list; totals follow the visible rows.
3. Tapping a row opens the edit form of that entry (any book).
4. Income and Expense rows differ by icon badge and color; a screen reader announces "Income" or "Expense".
5. Period tabs and navigator behave like the ledger home (All, Daily, Weekly, Monthly, Yearly; custom range).
6. Layout holds at 360 dp and 200 percent text scale; book names truncate with ellipsis but amounts do not.
7. Header and period controls identical to other Account Ledger screens.
8. Search field retains the typed text across rebuilds (controller owned in State).

## 7. Performance notes

- Move the filter and the grouping into a memoized helper keyed by (entries identity, query); today both run on every build, including each keystroke (the list itself is rebuilt, but the `ListView.builder` only lays out visible rows).
- Extract `_AllRow` with `ValueKey(entry.id)`; `names` map computed once per books change.
- Add a `TextEditingController` (State-owned) instead of an uncontrolled field to avoid losing text on rebuild.
- `setState` only for `_query`, `_sel`, `_searching`.


## Reconciliation 2026-10-13 (Apple look, Android only)

### R1. Mockup screens and Flutter mapping

| Mockup screen (J registry) | Mockup render function | Flutter file | Widgets | Notes |
|---|---|---|---|---|
| Transaction-All Accounts | `SC.cbAllTx` | lib/features/cashbook/cashbook_all_transactions_screen.dart | LargeTitleScaffold (pushed), search RigGroup row, RigChipRow, period navigator, totals strip, sticky day headers with RigGroups of RigRows (notes, time and book name, signed amount), EmptyState | Mockup screen title is "All Transactions"; the hub label and the code title are "Transaction-All Accounts" (conflicts_r3.md C-10). |

### R2. What changes in the redesign (supersedes section 4)

Transaction-All Accounts (pushed from the drawer):
1. LargeTitleScaffold, title "Transaction-All Accounts" (keep the code and hub text; the mockup shortens it), back chevron. The search button of the old design is replaced by an always-visible search row.
2. Search: RigGroup row with a search glyph and the field, placeholder "Search notes and accounts"; live filter on notes, description or book name (unchanged).
3. RigChipRow (All, Daily, Weekly, Monthly, Yearly, Range) and the period navigator.
4. Totals strip (Income, Expense, Balance of the visible rows), no previous balance. Totals strip: three RigCards (Income, Expense, Balance) with MoneyText using the fit pipeline and never compact (L and Cr are only for MoneyTile and the Portfolio metric cards).
5. List: sticky day header (`dGroup`) then a RigGroup of RigRows: line 1 notes (17 sp weight 600, "-" placeholder), line 2 13 sp `label2` time and the book name separated by " | ", signed amount at the right coloured by type. Tap opens the edit form of that entry.
6. Empty: EmptyState icon `list_alt`, "No transactions", "Nothing matches this period or search."


Old section 4 items:

- Old 4 appbar with a search toggle and the search title field: CHANGED to a persistent search row (the toggle and its reset rule: the old rule "closing search restores the list" becomes clearing the text).
- Old `LedgerRowTile` with TypeBadge and book pill: CHANGED to the two-line RigRow with the book name as text; TypeBadge and pill DROPPED.
- Old `CashTotalsCard` at the bottom: CHANGED to the strip above the list.
- Old empty variants and the "Clear search" button: CHANGED to the mockup text; the button is KEPT only as the Clear action of clearing the field (the field has its own clear glyph).
- Old desktop paragraph (hover, right-click, Cmd+F): DROPPED.


States:

| State | Rule in the new look |
|---|---|
| Default | search, chips, strip, grouped list |
| Loading | not applicable |
| Empty | EmptyState "No transactions" |
| Error | not applicable |
| Disabled | navigator hidden for All and a custom range |
| Searching | text in the field; totals follow the visible rows |


Motion: ink press on rows; period shift cross-fade 200 ms; reduced motion removes it.


### R3. Logic touchpoints and LR items

Untouched: `cashQueryEntriesProvider(_sel.query(null))`, newest-first order, grouping by `dateOnly`, filter by lowercase contains on notes, description or book name, `CashbookCalculator.totals` over the filtered rows, the row tap opening `CashbookEntryFormScreen(entry:)`, State-owned search controller retaining its text across rebuilds.


- LR-24 (approved): rupee sign and the day header format.
- LR-25 (approved): the edit form opened from a row carries the discard prompt.
- No new logic item.


### R4. Acceptance criteria delta

1. Entries from all books appear grouped by day, newest first, each with its book name; amounts match their books.
2. Typing in the search row filters live; clearing restores the list; totals follow the visible rows.
3. Tapping a row opens that entry in the edit form (any book).
4. Income and Expense rows are told apart by the sign and colour and announced as "Income" or "Expense".
5. Book names truncate with an ellipsis; amounts never compact or truncate; 360 dp and 412 dp, text scale 130 and 200 percent.
6. The keyboard open with a search: the first results stay visible; the field keeps its text on rotation or rebuild (portrait only).
7. Android back closes the keyboard first, then pops.


### R5. Parity delta

Change on purpose:

- PARITY-035 and 084: rupee sign.
- Search entry: always visible instead of a toggle (no parity line asserts the toggle).


Must stay identical:

- Filter definition, ordering, grouping, totals over filtered rows, tap to edit.


### R6. Performance and Android notes

- Edge to edge: status bar transparent; bottom inset from `MediaQuery.viewPaddingOf(context).bottom`. Pushed screens have no floating tab bar; content ends at inset + 24 dp, or inset + 110 dp when a pinned bottom pill is present.
- Keyboard: `resizeToAvoidBottomInset: true`; a pinned bottom pill sits above the keyboard; sheets add `MediaQuery.viewInsetsOf(context).bottom`; the focused field scrolls to the centre.
- List strategy: builder over the flattened day and row items with sticky headers (`SliverMainAxisGroup`); fall back to plain headers if the profile misses the budget.
- Search: debounce is not added (logic freeze); filtering stays synchronous and memoised on (entries identity, query).
- Controller: the search controller is State-owned and disposed (verify when the toggle is replaced by a persistent row).

