> SUPERSEDED IN PART (2026-10-13): the look is now the Apple-inspired Android direction. Read "Reconciliation 2026-10-13" at the end of this file first; where it conflicts with sections 4 to 7 above, it wins.
# cashbook_calendar_screen.dart (Calendar)

Group g2. Source: lib/features/cashbook/cashbook_calendar_screen.dart (214 lines).

## 1. Purpose and primary user task

Month grid for one book showing per day income (green) and expense (red) sums; tap a day with entries to list them in a sheet and open one for editing; month totals below. Parity: PARITY-064.

## 2. Current structure

`CashbookCalendarScreen` (ConsumerStatefulWidget). Local state `_month` (first of month), `_bookId` (override). Providers: `cashSettingsProvider`, `cashBooksProvider`, `currentCashBookProvider`, `cashDaySummaryProvider(q)` and `cashQueryEntriesProvider(q)` with `q = (bookId, period: monthly, anchor: _month, custom: null)`. Tree: `Scaffold(cashAppBar(book.name, actions: [Icons.account_balance_wallet_outlined -> showCashBookPicker]))` > `CashPageBody(800)` > `Column[8 dp, CashbookPeriodBar (label + chevrons, `_shift`), weekday header Row (Sun..Sat 12 sp), Expanded GridView.builder (7 columns, childAspectRatio 0.72), CashbookTotalsStrip]`. Cell (`InkWell` > `Container` radius 6, border primary when today else `AppColors.border`): day number 12 sp, then income `FittedBox` 10 sp green and expense 10 sp red when > 0. Tap (only if the day has entries) -> `_showDay` bottom sheet: heading `settings.formatDayHeader(day)`, `ListTile`s (notes, time, amount colored) -> pop then push `CashbookEntryFormScreen(entry: e)`. Weeks start Sunday (`range.start.weekday % 7`).

## 3. Problems found

1. Cell overflow risk at large text scale (fixed aspect 0.72, 12 sp + two 10 sp lines scale with text) (calendar:98-153) (G2-B03). Cells are about 50 x 69 dp at 360 dp width.
2. Amount text 10 sp is below the 11 sp floor (calendar:137-148) (G2-B04); `FittedBox` shrinks long values further (illegible).
3. Today is marked only by a primary border and w800 day number (border `AppColors.primary` 1 px) (calendar:120-131); no filled marker.
4. Days without entries are `InkWell`s with `onTap: null` but still look the same as days with entries, except the missing amounts; days with entries have no affordance beyond the amounts.
5. Book selection is an icon in the app bar with the book name as the title (calendar:58-67): title is not tappable; no dropdown arrow; inconsistent with the ledger header and Account Summary selector.
6. Weekday labels are hard-coded English abbreviations in a `const` list (fine for an English-only app) at 12 sp w600 default color.
7. `GridView.builder` inside `Expanded` with `childAspectRatio` ignores available height: on a tall phone cells leave empty space below; on a short desktop window rows are clipped by scroll (not an overflow, but the month does not fit without scrolling).
8. Day sheet: `ListTile(dense: true)` rows 40 dp high, no total for the day, default sheet shape (calendar:172-212).
9. `books.firstWhere(... orElse: current ?? books.first)` may throw with no books (calendar:36-37) (G2-B13).
10. The month label uses `CashbookCalculator.rangeLabel` ("Oct-01-2026 -> Oct-31-2026"), a range for a month grid; a month title is clearer ("monthTitle" token) (calendar:73-74).
11. The month totals strip includes only income, expense and balance; fine.
12. Month navigation: chevrons through `CashbookPeriodBar`; no "Today" shortcut.

## 4. Redesign

- `RigScaffold(appBar: RigAppBar(title: 'Calendar', actions: []), maxContentWidth: 640 on medium, 960 on expanded)`. Book selector pill under the app bar (same pill as Account Summary) opening `showCashBookPicker`; it replaces the app-bar icon. Book name is no longer the app bar title (the title becomes "Calendar").
- `PeriodNavigator` label = month title "October 2026" built with `monthTitle` ('MMMM yyyy', `RigFormat`), chevrons move months (`_shift`), `onLabelTap` none. A text button "Today" (`labelLarge`) appears at the end of the row when `_month` is not the current month; it sets `_month` to the current month (UI state only).
- Weekday header: `labelMedium` `onSurfaceVariant`, height 32, Sunday first (unchanged).
- Grid cell `CalendarDayCell` (radius `md`, fill `surface`, 1 px `outlineVariant`; today: fill `primaryContainer` and 2 px `primary` border; selected-with-entries press `surfaceContainerHigh`):
  - Compact normal text scale (<1.3): cell aspect from available height: `childAspectRatio = cellWidth / max(64, 28 + 2 * 14 * textScale)`; contents: day number `labelMedium` w600 top-left, income `labelSmall` (11 sp) `moneyIn` and expense `labelSmall` `negative`, each one line, `Text` with `maxLines: 1`, `overflow: ellipsis`, no FittedBox (values use `settings.formatNumber`, short form not applicable; if a value does not fit, ellipsis and the full values are in the day sheet).
  - Large text scale (>= 1.3) or width < 340: the cell shows only the day number and up to two 8 dp dots (`moneyIn` dot if income > 0, `negative` dot if expense > 0); amounts are read in the day sheet. Semantics on each cell: "12 October, income X, expense Y" built from the same formatted values.
  - Expanded (>=900): cell min height 96, amounts at `bodySmall`, full values visible.
  - Days without entries: `onTap: null`, text `onSurfaceVariant`; days with entries are distinguished by their amounts (or dots) plus hover and focus state; no extra accent bar.
- Day sheet: `RigSheet` on compact (title = `settings.formatDayHeader(day)`, `titleMedium`), dialog max 480 on expanded; rows `LedgerRowTile` compact (type badge, notes, time, amount); a footer line "Income <n> | Expense <n>" using the same day sums from `cashDaySummaryProvider`. Tapping a row closes the sheet and opens the edit form (same as today).
- Month totals: `CashTotalsCard` (unchanged values).
- Empty month: grid still shown; totals zeros; `EmptyState` is not used (a grid is not empty); a one-line `bodySmall` `textMuted` hint under the grid "No transactions this month".

Desktop: the grid uses the full max width; hover on cells with entries (`surfaceContainerHigh`), pointer cursor, Enter opens the day sheet (as a dialog), arrow keys move focus between days, PageUp/PageDown change month (UI shortcuts).

Tokens: spacing `s4` page, grid gap 4 (`s1`), cell padding `s1`; radius `md`; type `labelMedium`, `labelSmall`, `titleMedium`; colors `moneyIn`, `negative`, `primary`, `primaryContainer`, `outlineVariant`, `onSurfaceVariant`.

State table:

| State | Rule |
|---|---|
| Default | month grid |
| Loading | none |
| Empty month | grid with hint line |
| Error | none |
| Disabled | cells without entries not tappable |
| Today | `primaryContainer` fill |

Motion: month change cross-fade `base` 200 ms with slide 16 dp horizontally in the direction of travel (disabled in reduced motion); cell press `fast`.

## 5. Logic touchpoints that must stay untouched

- `q = (bookId, period: monthly, anchor: _month, custom: null)` and the two providers; day lookup `days[day]`.
- Sunday-first grid: `lead = range.start.weekday % 7`; `daysInMonth = range.lastDay.day`.
- Only days with `t != null` open the day sheet; the sheet lists entries whose `dateOnly == day`; tap pops the sheet then pushes `CashbookEntryFormScreen(entry: e)`.
- Income shown only when `t.cashIn > 0`, expense when `t.cashOut > 0`.
- `_shift` uses `DateTime(_month.year, _month.month + d)`.
- Book selection rule `_bookId ?? current?.id` and the picker.
- Totals via `CashbookCalculator.totals(entries)`.

## 6. Acceptance criteria

1. The grid for a month shows each day with entries with correct income and expense sums (match the ledger's Monthly view for the same book).
2. Sunday is the first column; the first of the month sits under the correct weekday.
3. Today is visibly filled in the current month only.
4. Tapping a day with entries opens its list; a day without entries does nothing.
5. Month navigation (chevrons, Today, PageUp/PageDown) changes the grid and totals.
6. At 200 percent text scale on 360 dp: no overflow stripes; cells show dots; day sheet shows the amounts.
7. Book selector opens the picker; changing it updates the grid; the ledger's current book is unchanged.
8. Every cell has a semantics label with date and sums.

## 7. Performance notes

- Cells: at most 42 widgets; use `const` weekday header; compute `days[day]`, formatted strings once per provider value.
- Watch `cashDaySummaryProvider(q)` and `cashQueryEntriesProvider(q)` once; entries are only needed for the sheet and totals: read them lazily with `ref.read` on tap and use `select` for the totals (`CashbookCalculator.totals` over entries per build is O(entries in month)).
- Extract `CalendarDayCell` as a const-constructible widget; `FittedBox` removed from the normal path.
- `GridView.builder` with fixed cell count is fine; set `shrinkWrap: false`, `physics: NeverScrollable` when the month fits, otherwise scroll.


## Reconciliation 2026-10-13 (Apple look, Android only)

### R1. Mockup screens and Flutter mapping

| Mockup screen (J registry) | Mockup render function | Flutter file | Widgets | Notes |
|---|---|---|---|---|
| Calendar | `SC.cbCalendar`, `cbDaySheet` | lib/features/cashbook/cashbook_calendar_screen.dart | LargeTitleScaffold (pushed), book pill, month navigator, 7-column grid of day buttons (`cd`), totals strip, RigSheet for a day | The mockup cell shows one net value (income minus expense) under the day number; the code shows income and expense separately (conflicts_r3.md C-11). |

### R2. What changes in the redesign (supersedes section 4)

Calendar (pushed from the drawer):
1. LargeTitleScaffold, title "Calendar", back chevron.
2. Book pill (opens the book picker; does not change the ledger current book).
3. Month navigator (`dMonth`, for example "October 2026"), 48 dp chevrons; the label is not tappable.
4. Grid: weekday letters S M T W T F S (Sunday first, 32 dp row), 7 columns; each day cell is a 48 dp minimum square-ish button (radius 12) with the day number; today has a `accentTint` fill and an accent outline; a day with entries shows its amounts under the number (at text scale up to 130 percent) and opens the day sheet; a day without entries is inert. Large text (130 percent and over, or width under 340 dp): cells show only the number and up to two 8 dp dots (`moneyInText` colour dot for income, `moneyOutText` for expense); amounts are read in the day sheet.
5. Totals strip for the month (Income, Expense, Balance). Totals strip: three RigCards (Income, Expense, Balance) with MoneyText using the fit pipeline and never compact (L and Cr are only for MoneyTile and the Portfolio metric cards).
6. Day sheet: RigSheet titled `dGroup` of the day, RigGroup of RigRows (notes, time, signed amount); tap pops the sheet then opens the edit form (unchanged).


Old section 4 items:

- Old 4 appbar, book selector pill, PeriodNavigator with Today button: CHANGED to LargeTitleScaffold, the shared pill and the month navigator; the "Today" button is DROPPED (the mockup shows none; add it only if the developer asks).
- Old cell design (day number top-left, income and expense in two lines, bordered cell): CHANGED to the mockup cell (number only plus net amount line); the separate income and expense lines are KEPT in the code until the developer resolves C-11.
- Old large-text dot fallback: KEPT.
- Old expanded grid and desktop keys (PageUp, arrows): DROPPED.
- Old empty month hint under the grid: KEPT as one 13 sp `label2` line.
- Old day sheet on compact and dialog on expanded: CHANGED to the sheet only.
- Old month change slide animation: CHANGED to a 200 ms cross-fade (reduced motion removes it).


States:

| State | Rule in the new look |
|---|---|
| Default | month grid, strip |
| Loading | not applicable |
| Empty month | grid shown, strip zeros, hint "No transactions this month" |
| Error | not applicable |
| Disabled | day cells without entries are not tappable |
| Today | `accentTint` fill and outline in the current month only |


Motion: ink press on cells; month change cross-fade 200 ms; sheet rise 250 ms; reduced motion removes both.


### R3. Logic touchpoints and LR items

Untouched: the monthly query `(bookId, monthly, anchor _month)` and the two providers, Sunday-first arithmetic (`weekday % 7`), only days with a total open the sheet, income and expense shown only when above zero, `_shift` arithmetic, book selection rule, totals via `CashbookCalculator.totals`.


- LR-33 (approved, Phase 1): calendar day totals must not mix months; `calendarDayTotalsProvider` keys by full date or is restricted to the selected month. This screen reads the cashbook day summaries, not that provider; verify the cashbook path has no month mixing (the cashbook query uses a single month, so it is already safe).
- LR-24 (approved): `dMonth` and `dGroup` formats; rupee sign in the sheet.
- No new logic item.


### R4. Acceptance criteria delta

1. Each day shows the right sums (matching the ledger Monthly view); Sunday is the first column; the 1st sits under the right weekday; today is highlighted in the current month only.
2. A day with entries opens its sheet; a day without entries does nothing; the sheet lists that day only.
3. Month chevrons change the grid and strip; the grid never mixes entries of two months.
4. At text scale 200 percent no overflow: cells show dots; the sheet shows full amounts.
5. Each cell has a semantics label "12 October, income N, expense N".
6. Targets 48 dp at 360 dp and 412 dp, light and dark.


### R5. Parity delta

Change on purpose:

- PARITY-064: if the developer chooses the mockup net value for the cell, the cell shows one number instead of two (open question C-11); the day sheet and strip keep both values.
- PARITY-064 date strings use `dMonth` and `dGroup`.


Must stay identical:

- PARITY-064 sums per day equal the ledger, Sunday first, tap lists entries, month totals equal the ledger.


### R6. Performance and Android notes

- Edge to edge: status bar transparent; bottom inset from `MediaQuery.viewPaddingOf(context).bottom`. Pushed screens have no floating tab bar; content ends at inset + 24 dp, or inset + 110 dp when a pinned bottom pill is present.
- Keyboard: `resizeToAvoidBottomInset: true`; a pinned bottom pill sits above the keyboard; sheets add `MediaQuery.viewInsetsOf(context).bottom`; the focused field scrolls to the centre.
- Grid: `GridView.count(crossAxisCount: 7)` with up to 42 cells; no per-cell `BackdropFilter`; a cell is const-friendly with `ValueKey(day)`.
- Cache the month totals map per (book, month); no controllers on this screen.

