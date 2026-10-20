> SUPERSEDED IN PART (2026-10-13): the look is now the Apple-inspired Android direction. Read "Reconciliation 2026-10-13" at the end of this file first; where it conflicts with sections 4 to 7 above, it wins.
# cashbook_account_summary_screen.dart (Account Summary, per day)

Group g2. Source: lib/features/cashbook/cashbook_account_summary_screen.dart (163 lines).

## 1. Purpose and primary user task

For one book, show per day Income, Expense and Savings (income minus expense) over a period (All, Weekly, Monthly, Yearly; no Daily) plus the period totals. Parity: PARITY-062.

## 2. Current structure

`CashbookAccountSummaryScreen` (ConsumerStatefulWidget). Local state `_sel` (default Monthly), `_bookId` (override of the current book). Providers: `cashSettingsProvider`, `currentCashBookProvider`, `cashBooksProvider`, `cashDaySummaryProvider(q)` (map day to totals), `cashQueryEntriesProvider(q)` (entries for totals via `CashbookCalculator.totals`). Tree: `Scaffold(cashAppBar('Account Summary'))` > `CashPageBody(900)` > `Column[InkWell book name + arrow_drop_down (opens showCashBookPicker), CashPeriodSelector(periods: All, Weekly, Monthly, Yearly), header Row (Date, Income, Expense, Savings; each flex 3), Divider, Expanded(empty text or ListView of day Containers), Padding CashbookTotalsStrip]`. Rows show `settings.formatDate(day)` 13 sp and three right-aligned `FittedBox` numbers (`settings.formatNumber`, 13 sp w600; Savings colored `balance` or `expense` when < 0). Days iterate `days.entries.toList().reversed`.

## 3. Problems found

1. Book selector is a bare `InkWell` Row with 8 dp top padding; hit height about 32 dp (account_summary:43-58).
2. Four columns with equal flex 3 and `FittedBox`: dates and numbers share equal width, so at 360 dp each is about 80 dp and 8-digit values shrink (account_summary:149-162).
3. Column headers "Date, Income, Expense, Savings" are default-size w700 with raw color literals (account_summary:71-100); header is not sticky: it scrolls above the list but is outside the list so it is fixed (fine) but not visually a table header (no fill).
4. Rows are flat Containers with a nearly invisible 1 px #F1F5F9 border (account_summary:110-116).
5. 13 sp numeric text is off-scale; `Savings` zero shows primary color.
6. `ListView(children:)` builds every day eagerly and reverses the list on each build (account_summary:107-137) (G2-B14).
7. `books.firstWhere(... orElse: current ?? books.first)` could throw if there are no books (account_summary:31-32) (G2-B13).
8. Empty state bare text `textHint` (2.56:1) (account_summary:104-106).
9. Totals strip: no label that it excludes the previous balance (parity note) so Balance looks different from the ledger Balance in the same period when previous balance exists.
10. No weekday in the date text, so scanning by weekday is hard (display only).

## 4. Redesign

- `RigScaffold(appBar: RigAppBar('Account Summary'), maxContentWidth 640 / 1100)`.
- Book selector: pill identical to the ledger header selector but on `surface` (fill `surfaceContainer`, text `titleMedium` `onSurface`, trailing `Icons.expand_more_rounded`), min 48 high, same `showCashBookPicker` behavior, placed under the app bar with padding `s4`.
- Period: `RigChipRow` (All, Weekly, Monthly, Yearly) + `PeriodNavigator` (shared).
- Table: sticky header row (`surfaceContainer`, 40 dp, `labelMedium` `onSurfaceVariant`): "Date" (flex 4, left), "Income" (right), "Expense" (right), "Savings" (right); on compact (<420) the Savings column header is "Savings" and the date column shows `dd MMM` through `settings.formatDate` unchanged (no truncation: date column uses intrinsic width, numbers share the rest). Rows: min height 48, padding `s4` x `s2`, date `bodyMedium`, numbers `amountSmall` right aligned tabular with `moneyIn`, `negative` and Savings `primary` (positive), `negative` (< 0), `onSurfaceVariant` (zero). Alternate rows no zebra; divider `RigDivider` inset `s4` 1 px `outlineVariant`.
- Compact large-text fallback (text scale >= 1.3 or width < 340): each day becomes a two-line `RigListRow`: title date, below it the three values with captions "Income", "Expense", "Savings" (so numbers never shrink).
- Bottom: `CashTotalsCard` (Total Income, Total Expense, Balance) with a caption `bodySmall` `onSurfaceVariant` "Does not include previous balance" (new caption copy; it states the existing rule).
- Empty: `EmptyState(icon: Icons.insights_rounded, title: 'No transactions', hint: 'Try another period or account')`.

Desktop: table at max width 1100, hover `surfaceContainerHigh`, no row tap action (rows are not tappable today; none added).

Tokens: `s4`, `s2`; radius `md` (selector), `lg` (card); type `labelMedium`, `bodyMedium`, `amountSmall`; colors `moneyIn`, `negative`, `primary`, `onSurfaceVariant`, `surfaceContainer`.

State table: Default (table); Loading none; Empty `EmptyState`; Error none; Disabled none; Book missing (guard) `EmptyState('No accounts')`.

Motion: period change cross-fade `base`.

## 5. Logic touchpoints that must stay untouched

- `cashDaySummaryProvider(q)` and `cashQueryEntriesProvider(q)` with `q = _sel.query(book.id)`; Savings = day `balance` (in minus out); totals via `CashbookCalculator.totals(entries)` (excludes the previous balance).
- Period list: All, Weekly, Monthly, Yearly only; default Monthly.
- Day order: newest first (`reversed` of the map entries; the provider returns ascending).
- `_bookId ?? current?.id` selection rule and the picker call.
- `settings.formatDate(day)` for dates and `settings.formatNumber(v)` (no currency symbol in the cells).

## 6. Acceptance criteria

1. Per-day Income, Expense and Savings equal the ledger values for the same book and period; Savings = Income - Expense.
2. Totals strip equals the sums of the rows; excludes previous balance.
3. Switching the book through the selector updates the whole screen; the current book of the ledger is not changed.
4. Days are newest first; each day with entries appears once.
5. No Daily tab.
6. Long numbers stay fully visible at 200 percent text (fallback layout).
7. 1000-day dataset scrolls at 60 fps (builder list).
8. Selector hit area >= 48 dp.

## 7. Performance notes

- Replace `ListView(children: [for ...])` with `ListView.builder` over a list computed once per provider value (`days.entries.toList().reversed.toList()` memoized with `select`).
- Watch `cashDaySummaryProvider(q)` and `cashQueryEntriesProvider(q)` in separate `Consumer`s: the totals card needs only totals.
- `_num` helper builds a `FittedBox` per cell; the redesign removes `FittedBox` from the normal path.
- `setState` only on `_sel`/`_bookId` change.


## Reconciliation 2026-10-13 (Apple look, Android only)

### R1. Mockup screens and Flutter mapping

| Mockup screen (J registry) | Mockup render function | Flutter file | Widgets | Notes |
|---|---|---|---|---|
| Account Summary | `SC.cbAcctSummary` | lib/features/cashbook/cashbook_account_summary_screen.dart | LargeTitleScaffold (pushed), book pill, RigChipRow (All, Weekly, Monthly, Yearly), period navigator, totals strip, RigGroup of per-day RigRows, EmptyState | Mockup puts the strip above the day list and shows each day as a two-line row with a "Savings" value. |

### R2. What changes in the redesign (supersedes section 4)

Account Summary (pushed from the drawer):
1. LargeTitleScaffold, title "Account Summary", back chevron.
2. Book pill (same pill as the home screen, 48 dp box) opens the book picker sheet; it does not change the ledger current book.
3. RigChipRow: All, Weekly, Monthly, Yearly (no Daily, no Range chip; default Monthly), then the period navigator.
4. Totals strip: three RigCards (Income, Expense, Balance) for the selected book and period; excludes the previous balance. Totals strip: three RigCards (Income, Expense, Balance) with MoneyText using the fit pipeline and never compact (L and Cr are only for MoneyTile and the Portfolio metric cards).
5. Day list: one RigGroup, newest first. Each RigRow (min 64 dp): line 1 `dGroup` date in weight 600; line 2 13 sp "Income <full>  |  Expense <full>" with the words coloured `moneyInText` and `moneyOutText`; at the right a small "Savings" caption (11 sp `label2`) above the value (17 sp weight 700, `accentText` or `moneyOutText` when negative). Rows are not tappable.
6. Empty: EmptyState icon `pie_chart_outline`, "No transactions", "Nothing was recorded in this period."


Old section 4 items:

- Old 4 appbar, max width: CHANGED and DROPPED respectively.
- Old book selector pill on `surfaceContainer`: CHANGED to the shared `pillb`.
- Old table with sticky header (Date, Income, Expense, Savings): CHANGED to two-line RigRows; the sticky table header and the narrow-width column logic are DROPPED, so the large-text fallback is now the default layout.
- Old bottom `CashTotalsCard` with the caption "Does not include previous balance": CHANGED to the strip at the top; the caption is KEPT as a 13 sp footer under the strip (copy kept, not shown in the mockup).
- Old desktop hover: DROPPED.
- Old empty state: CHANGED to the mockup text.


States:

| State | Rule in the new look |
|---|---|
| Default | pill, chips, navigator, strip, day rows |
| Loading | not applicable |
| Empty | EmptyState |
| Error | not applicable |
| Disabled | book missing guard: EmptyState "No accounts" |


Motion: ink press on the pill and chips; period change cross-fade 200 ms; reduced motion removes it.


### R3. Logic touchpoints and LR items

Untouched: `cashDaySummaryProvider(q)` and `cashQueryEntriesProvider(q)` with `q = _sel.query(book.id)`, Savings = in minus out, totals exclude the previous balance, period list All, Weekly, Monthly, Yearly with default Monthly, newest-first order, `_bookId ?? current?.id`, `settings.formatDate(day)`.


- LR-24 (approved): the day text becomes `dGroup` by default and amounts carry the rupee sign (the old cells showed no symbol; the mockup shows the rupee sign).
- L2-r3-2 (proposed, new): Format Date options and default `d MMM yyyy`.
- No other logic item.


### R4. Acceptance criteria delta

1. Per-day Income, Expense and Savings equal the ledger values for the same book and period; Savings = Income minus Expense; the strip equals the sum of the rows and excludes the previous balance.
2. Changing the book through the pill updates the screen and leaves the ledger current book unchanged.
3. Days are newest first, each day once; there is no Daily chip.
4. At text scale 200 percent the row shows income, expense and savings on separate lines, no value is shrunk below 11 px or compacted.
5. A 1000-day dataset scrolls within the budget (p99 under 16 ms) because the list is a builder.
6. Pill hit area 48 dp; Android back pops; 360 dp and 412 dp, light and dark.


### R5. Parity delta

Change on purpose:

- PARITY-062: the totals strip sits above the day list; values unchanged.
- PARITY-035 and 084: cells show the rupee sign (the old screen showed numbers only).


Must stay identical:

- PARITY-062 rows, Savings formula, strip equals sums, no Daily tab, book selector does not change the ledger book.


### R6. Performance and Android notes

- Edge to edge: status bar transparent; bottom inset from `MediaQuery.viewPaddingOf(context).bottom`. Pushed screens have no floating tab bar; content ends at inset + 24 dp, or inset + 110 dp when a pinned bottom pill is present.
- Keyboard: `resizeToAvoidBottomInset: true`; a pinned bottom pill sits above the keyboard; sheets add `MediaQuery.viewInsetsOf(context).bottom`; the focused field scrolls to the centre.
- List strategy: `ListView.builder`, ValueKey per day; the provider returns ascending and the view reverses lazily.
- No controllers; the picker sheet returns a book through `Navigator.pop`.

