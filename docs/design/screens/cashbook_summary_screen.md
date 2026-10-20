> SUPERSEDED IN PART (2026-10-13): the look is now the Apple-inspired Android direction. Read "Reconciliation 2026-10-13" at the end of this file first; where it conflicts with sections 4 to 7 above, it wins.
# cashbook_summary_screen.dart (Summary, all books)

Group g2. Source: lib/features/cashbook/cashbook_summary_screen.dart (89 lines).

## 1. Purpose and primary user task

See Total Income, Total Expense and Balance for every book that has entries in a chosen period, plus the grand total across books; tap a book to make it current and return to the ledger. Parity: PARITY-061.

## 2. Current structure

`CashbookSummaryScreen` (ConsumerStatefulWidget). Local state `_sel` (`CashPeriodSel`, default All). Tree: `Scaffold(cashAppBar('Summary'))` > `CashPageBody(900)` > `Column[CashPeriodSelector, Expanded(empty text or ListView.separated of Card > InkWell > Padding > Column[book name 16 w700, CashbookTotalsStrip]), Padding CashbookTotalsStrip (grand)]`.
Providers: `cashSettingsProvider` (watch), `cashSummaryProvider(_sel.query(null))` (watch; `.books` list of (book, totals), `.grand`). Tap: `currentCashBookIdProvider.notifier.select(s.book.id)` then `Navigator.pop(context)` if mounted.

## 3. Problems found

1. Default `Card` and `InkWell` radius 16 mismatch; the card is the only affordance that it is tappable; there is no chevron or hint that tapping switches the current book and exits the screen (summary:49-75).
2. Each card contains a full `CashbookTotalsStrip` (bordered box inside a card, 2 borders), so a list of N books shows N nested bordered boxes (summary:69-70).
3. Empty state is bare text `textHint` #94A3B8 (2.56:1) (summary:40-42).
4. Grand total strip is visually identical to book strips; it is not distinguished as the grand total and has no label "All accounts" (summary:79-83).
5. App bar and period selector as in the shared doc (gradient bar; chips clip; range icon steals width).
6. No back-navigation feedback after selecting a book (the screen just closes; the ledger header changes).
7. Grand strip sits outside the scroll area and takes about 56 dp always.

## 4. Redesign

- `RigScaffold(appBar: RigAppBar('Summary'), maxContentWidth: 640 on medium, 1100 on expanded)`. Period area: `RigChipRow` + `PeriodNavigator` (shared, see cashbook_home_screen.md 4.2; range icon in the navigator row).
- Book cards: `RigCard` (radius `lg`, padding `s4`, tappable, press `surfaceContainerHigh`): header row `[book name titleMedium] [Icons.chevron_right_rounded 20 onSurfaceVariant]`, below an `AmountTile` row (Total Income `moneyIn`, Total Expense `negative`, Balance `primary` or `negative`) without a second border. Semantics: "Open <book>" button.
- Expanded (>=900): book cards in a grid of 2 columns (min tile 360 dp).
- Grand total: pinned bottom `RigCard` tone `container` titled "All accounts" (new label text, `labelMedium` `onSurfaceVariant`) with the same three tiles; `RigSection` caption above is not needed.
- Empty: `EmptyState(icon: Icons.bar_chart_rounded, title: 'No transactions', hint: 'Try another period')` (title text unchanged).
- Tap behavior unchanged: select the book then pop. No snackbar is added on return (the ledger header already shows the new book name).

Desktop: hover `surfaceContainerHigh`, pointer cursor, Enter on focused card opens, content max width 1100.

Tokens: spacing `s4`, gap `s2`; radius `lg`; type `titleMedium`, `labelMedium`, `amountMedium`; colors as above.

State table:

| State | Rule |
|---|---|
| Default | cards + grand total |
| Loading | none |
| Empty | `EmptyState` |
| Error | none |
| Disabled | none |

Motion: card press `fast`; list change on period shift cross-fade `base`.

## 5. Logic touchpoints that must stay untouched

- `cashSummaryProvider(_sel.query(null))` and its `books` / `grand` shape; per-book cards only for books with entries in the period.
- `currentCashBookIdProvider.notifier.select(s.book.id)` followed by `Navigator.pop` guarded by `context.mounted`.
- `CashPeriodSel` default All and the "All when custom" chip rule.
- Totals definition: `CashTotals.balance = in - out`; grand = sum across books for the period.

## 6. Acceptance criteria

1. For period All, each book with entries has a card whose Income, Expense and Balance equal the ledger totals of that book (no previous balance).
2. Grand total equals the sum of the cards; shown even when one card exists.
3. Tapping a card closes the screen and the ledger shows that book.
4. Period tabs change the figures; custom range via the navigator icon works; chevrons shift Daily, Weekly, Monthly, Yearly.
5. Empty period shows the empty state, grand total still shown as zeros.
6. 360 dp, 200 percent text: no overflow (tiles stack).
7. Cards >= 72 dp tall and keyboard focusable.

## 7. Performance notes

- `cashSummaryProvider` is family-keyed; only the screen rebuilds on `_sel` change; extract `_BookSummaryCard` as a const-friendly widget with `ValueKey(book.id)`.
- List is short; builder retained. No `IntrinsicHeight` in tiles (the strip used one).
- `setState` only on selection change.


## Reconciliation 2026-10-13 (Apple look, Android only)

### R1. Mockup screens and Flutter mapping

| Mockup screen (J registry) | Mockup render function | Flutter file | Widgets | Notes |
|---|---|---|---|---|
| Summary | `SC.cbSummary` | lib/features/cashbook/cashbook_summary_screen.dart | LargeTitleScaffold (pushed), RigChipRow, period navigator, tappable RigCard per book (name, chevron, three MoneyText columns), RigGroup caption "All accounts", totals strip, EmptyState | Grand total is the last block of the scroll, not a pinned card (conflicts_r3.md C-06). |

### R2. What changes in the redesign (supersedes section 4)

Summary (pushed from the drawer):
1. LargeTitleScaffold, title "Summary", back chevron.
2. Period: RigChipRow (All, Daily, Weekly, Monthly, Yearly, Range) then the period navigator (hidden for All and a custom range).
3. One tappable RigCard per book that has entries in the period (radius 20, margin 20, gap 12, press by ink): first row the book name (17 sp weight 600) and a chevron in `label3`; second row three columns with gap 12: Income (12 sp weight 600 `moneyInText`, value 17 sp weight 700), Expense (`moneyOutText`), Balance (`accentText`, or `moneyOutText` when negative). Values are MoneyText with the fit pipeline, never compact. Tap selects the book and pops back to the ledger (unchanged).
4. Section caption "All accounts" (22 sp weight 700 section title) then the totals strip of the grand totals (three RigCards, same style as the home strip). Not pinned.
5. Empty: EmptyState icon `bar_chart` 52, "No transactions", "Nothing was recorded in this period." The "All accounts" strip still shows zeros.


Old section 4 items:

- Old 4 appbar and max width 640 or 1100: CHANGED to LargeTitleScaffold; widths DROPPED.
- Old period area (RigChipRow plus PeriodNavigator, range icon in the navigator row): CHANGED, the Range chip replaces the icon.
- Old book cards with AmountTiles: KEPT as RigCards with three columns; RigCard radius 20 not `lg`.
- Old expanded 2-column grid: DROPPED.
- Old pinned bottom "All accounts" RigCard: CHANGED to the last block of the scroll (mockup); the caption text "All accounts" KEPT.
- Old empty state (icon `bar_chart_rounded`, hint "Try another period"): CHANGED to the mockup hint text.
- Old desktop paragraph (hover, Enter): DROPPED.


States:

| State | Rule in the new look |
|---|---|
| Default | cards plus the all-accounts strip |
| Loading | not applicable |
| Empty | EmptyState plus zero strip |
| Error | not applicable |
| Disabled | navigator hidden for All and a custom range |


Motion: ink press on cards; period change cross-fades the list in 200 ms; reduced motion removes it.


### R3. Logic touchpoints and LR items

Untouched: `cashSummaryProvider(_sel.query(null))` and its `books` and `grand` shape, per-book cards only for books with entries, `select(book.id)` then `pop` guarded by `context.mounted`, default All and the All-when-custom chip rule, `balance = in - out`.


- LR-24 (approved): rupee sign and en-IN grouping in every value.
- LR-33 (approved, Phase 1): calendar day totals; not used here, listed because the Summary shares the period selector.
- No new logic item.


### R4. Acceptance criteria delta

1. For period All each card equals the ledger totals of that book (no previous balance); the grand strip equals the sum of the cards even with one card.
2. Tapping a card closes the screen and the ledger shows that book.
3. No value shows L or Cr; at text scale 200 percent the three columns stack and the numbers stay at least 11 px.
4. The last block clears the bottom inset by 24 dp; no floating tab bar on this pushed screen.
5. Android back pops to the ledger; 360 dp and 412 dp, light and dark.


### R5. Parity delta

Change on purpose:

- PARITY-061: the grand total is the last block of the scroll instead of a pinned card (mockup); values are identical.
- PARITY-035 and 084: the rupee sign replaces "Rs.".


Must stay identical:

- PARITY-061 per-book cards, grand total equal to the sum, all period tabs and custom range, tap makes the book current and returns.


### R6. Performance and Android notes

- Edge to edge: status bar transparent; bottom inset from `MediaQuery.viewPaddingOf(context).bottom`. Pushed screens have no floating tab bar; content ends at inset + 24 dp, or inset + 110 dp when a pinned bottom pill is present.
- Keyboard: `resizeToAvoidBottomInset: true`; a pinned bottom pill sits above the keyboard; sheets add `MediaQuery.viewInsetsOf(context).bottom`; the focused field scrolls to the centre.
- List strategy: `ListView.builder` of cards; compute the per-book totals inside the provider result; no controllers on this screen.
- Cache MoneyText measurements per width; one transparent Material ancestor for ink.

