> SUPERSEDED IN PART (2026-10-13): the look is now the Apple-inspired Android direction. Read "Reconciliation 2026-10-13" at the end of this file first; where it conflicts with sections 4 to 7 above, it wins.
# cashbook_home_screen.dart (Account Ledger home) plus widgets/cashbook_header, cashbook_period_bar, cashbook_row, cashbook_totals_strip

Group g2. Sources: lib/features/cashbook/cashbook_home_screen.dart (439 lines), widgets/cashbook_header.dart (58), widgets/cashbook_period_bar.dart (102), widgets/cashbook_row.dart (145, includes `CashbookDayHeader`), widgets/cashbook_totals_strip.dart (101). These four widget files are documented here because the home screen is their main user; `CashbookPeriodBar` and `CashbookTotalsStrip` are also reused by the summary screens and are referenced from those docs.

The Daily-filter date picker (overflow item "Date", `_pickDay`) is specified in screens/accounts_daily_date_picker.md and is not specified here. This doc only keeps its entry point (see section 5).

## 1. Purpose and primary user task

The working screen of the Account Ledger: pick a book, browse its entries newest first grouped by day for a period (All, Daily, Weekly, Monthly, Yearly) or a custom range, add an Income or Expense entry, see Income, Expense and Balance totals, search, filter, sort and make a report. Parity: PARITY-006, 013, 031..047, 080 (see parity_g2.md).

## 2. Current structure

`CashbookHomeScreen` (ConsumerStatefulWidget, home:21, param `onMenu`) returns a `Column` (home:215):

1. `CashHeader` (widgets/cashbook_header.dart): gradient on mobile, white with bottom border on desktop; leading menu or back icon, title (book selector `InkWell` with `Icons.arrow_drop_down`, or a search `TextField` when `_searching`), actions Search, Report (PDF icon), overflow `PopupMenuButton` (`_overflow`, home:116).
2. `CashbookPeriodTabs` (period_bar.dart:15): horizontally scrollable `ChoiceChip`s All, Daily, Weekly, Monthly, Yearly.
3. `CashbookPeriodBar` (period_bar.dart:62): pill with chevrons and a label like "Oct-12-2026 -> Oct-12-2026".
4. Active filter line (home:297-325): text "Search: ... | Income | Oldest first" and a "Clear" TextButton.
5. Column header row "Date | Income | Expense" (home:327-352) and `Divider`.
6. Expanded list inside `CashPageBody`: `ListView.builder` over a flattened `items` list of `'prev'` marker, `DateTime` (day header) and `CashLedgerRow` (home:204-210, 359-392). Empty state is a muted "No transactions" (home:356-358).
7. Bottom block (home:395-435): Income and Expense `ElevatedButton`s (flat green #059669 and red #DC2626) then `CashbookTotalsStrip` (Total Income, Total Expense, Balance; plus "Previous Balance" and final "Balance" lines when `hasPreviousBalance`).

State sources:
- watch: `currentCashBookProvider`, `cashViewConfigProvider` (type, ascending, period, customRange, query), `cashLedgerProvider` (rows, groups, totals, range, previousBalance, hasPreviousBalance), `cashSettingsProvider` (formatting, showTime, showDateInEntry, showBalancePerEntry).
- read/write: `cashViewConfigProvider.notifier` (`setQuery`, `setDay`, `setCustomRange`, `setAscending`, `setType`, `clearFilters`, `setPeriod`, `shift`), `currentCashBookIdProvider.notifier.select`, `cashSettingsProvider.notifier.updateSettings` (reporter name).
- Local state: `_searching` (bool), `_searchController` (disposed in `dispose`, home:36-39, correct).
- Navigation: `CashbookEntryFormScreen` (add via `_openForm`, edit via `_openEdit`), `showCashBookPicker`, `showCashReportDialog`, `showReporterNameDialog`, `pickCashDateRange`, `showCashTextPrompt` (Notes search dialog).

Widget details:
- `CashbookRow` (row.dart:29): Material + InkWell (`onTap` and `onLongPress` both call the edit callback), padding 16x10, bottom border `AppColors.divider`; line 1: notes (15 sp, maxLines 2) + description (12 sp primary) at flex 5, then two flex-3 amount cells right-aligned (Income column or Expense column, `FittedBox.scaleDown`, 16 w700, color #059669/#DC2626); line 2: date/time meta (12 sp textSecondary), attachment icon 14, link icon 14 (when `sourceType != null`), spacer, "Balance N" 12 sp.
- `CashbookDayHeader` (row.dart:8): full-width band `AppColors.divider` fill, 16x6 padding, w700 text from `settings.formatDayHeader`.
- `CashbookTotalsStrip` (totals_strip.dart:10): bordered container radius 12, `IntrinsicHeight` row of 3 cells (label 12 w600, value `FittedBox` 15 w700), optional two `_line` rows below.

## 3. Problems found

Visual hierarchy and consistency
1. Header: gradient bar on mobile (header.dart:53-56) with white text, white-with-border bar on desktop (header.dart:44-52): neither is the shared `RigAppBar`. Title style is hard-coded 18/20 sp (header.dart:32).
2. Income and Expense buttons are flat saturated blocks, `ElevatedButton` with `backgroundColor: CashColors.income/expense` (home:404-422). White 14 sp text on #059669 is 3.77:1 (fails AA 4.5); on #DC2626 it is 4.83:1 (passes). They are the only buttons in the app with semantic fills and no icon.
3. Rows are flat Material strips separated by 1 px #F1F5F9 lines (row.dart:68-77), which is nearly invisible on white (1.1:1); every other list in the redesign uses `RigCard`. The day header is a gray band that looks like a divider, not a heading (row.dart:16-23).
4. Amount cells shrink with `FittedBox(scaleDown)` inside a flex-3 slot (row.dart:54-63; totals_strip.dart:34-39). A long value like a seven-digit amount shrinks to unreadable size at 200 percent text scale instead of using free width. The column is mostly empty: one of the two amount cells is always blank, wasting about 27 percent of the row width on compact.
5. The column header says "Date" (home:333) but the column shows notes; the date is in the meta line. Misleading label.
6. Currency prefix "Rs. " and date patterns come from `CashSettings` (provider:100-108): "Rs. 5,000", "Oct-12-2026", day header "Mon, Oct 12 2026". The range label uses a hard-coded pattern and an ASCII arrow (`CashbookCalculator.rangeLabel`, calculator:194-199) so it ignores the user's date-format setting (the rows use `formatDate`, the range label does not). Day header also ignores the setting (`formatDayHeader`, provider:103).
7. Colors: `AppColors.textHint` (#94A3B8, 2.56:1) for the empty state and for the "-" placeholder note (home:358, row.dart:97); `textSecondary` (#64748B) 12 sp meta is 4.76:1 (ok). Icons 14 px (row.dart:125,130) are below the 16 minimum inline size.
8. Search field inside the app bar sets white text colors by platform (home:233-250), duplicating the header color logic. There is no clear (x) button while searching, only the back arrow, which also clears (home:43-47).

Tap targets and form friction
9. The book selector tap area is the text row with 6 dp vertical padding, about 36 dp tall (home:257-269). Under 48.
10. Overflow `PopupMenuButton` has a tooltip but the menu mixes commands (Notes, Date, Select Date Range), sort (asc/desc checked), filters (Income, Expense checked), Clear filters and "Your Name and Address" (home:148-171) with no dividers or grouping. Filter state is invisible until a line appears under the period bar.
11. Period chips: five chips need about 376 dp on a 360 dp phone; the row scrolls with no fade so a clipped "Yearly" looks truncated (period_bar.dart:29-56). Same defect already noted for Portfolio.
12. Period bar chevron buttons are 48 dp but the bar is a flat tinted pill with `AppColors.primary.withValues(alpha: .08)` (period_bar.dart:73); the label cannot be tapped (Daily date jump lives in the overflow menu, see B2).
13. When shift is disabled (All, custom range, searching) the chevrons are replaced by empty `SizedBox(48)` (period_bar.dart:83-84) so the label stays centered but there is no indication of why (no disabled state, no explanation).
14. Row `onLongPress: onTap` (row.dart:71-72) duplicates tap. There is no desktop context menu or hover state.
15. Attachment and link icons carry no tooltip or semantics label (row.dart:122-131).

States
16. Empty state is a bare muted text (home:356-358); PARITY-080 says "no empty-state text" (reference app) but SPEC deviation already accepted in T-CB08. No distinction between "book is empty", "filters hide everything" and "search found nothing".
17. No loading state (data is local; acceptable) and no feedback after Report beyond the dialog; no snackbar when a filter or sort changes.

Density
18. The bottom block (two 48 dp buttons plus a 3-cell strip plus two summary lines) can be about 170 dp of a 640 dp usable height on compact phones in Daily, Weekly, Monthly or Yearly (with Previous Balance lines). The list gets the leftovers.

## 4. Redesign

Principle: same data, same controls, same behavior, restyled with the shared system. Everything below uses `RigSpace`, `RigRadius`, type and color tokens only.

### 4.1 Shell and header

- `RigScaffold(appBar: RigAppBar(...), body, bottomBar: LedgerActionBar)`; `maxContentWidth`: compact and medium none (full width up to 640 on medium centered), expanded 1100.
- `RigAppBar` (mobile flat `headerSurface` 56 dp, desktop 48 dp surface with bottom border). Leading: menu (`Icons.menu_rounded`) when `onMenu != null`; back (`Icons.arrow_back_rounded`) when `_searching`. Title: `BookSelector` (below). Actions in this order: Search (`Icons.search_rounded`), Report (`Icons.picture_as_pdf_rounded`, tooltip "Report"), overflow (`Icons.more_vert_rounded`, tooltip "More options"). Each action 48x48 (40 with pointer).
- `BookSelector`: a `RigCard`-less tappable pill: height 40 (48 hit target via padding), radius `full`, fill `onPrimary` at 12 percent alpha on the flat header (use `colorScheme.onPrimary.withValues(alpha: .12)`), text `titleMedium` `onPrimary` maxLines 1 ellipsis, trailing `Icons.expand_more_rounded` 24. Opens `showCashBookPicker` (unchanged). Semantics: button, label "Account, <name>, change".
- Search mode: title becomes `RigSearchField` (borderless, `bodyLarge`, hint "Search", autofocus) with a trailing clear icon (`Icons.close_rounded`, visible when text is non-empty, clears only the text). Back arrow keeps the old behavior (clears and exits).

### 4.2 Period controls

- `RigChipRow` for All, Daily, Weekly, Monthly, Yearly: `ChoiceChip`, height 32 visual and 48 hit target, spacing `s2`, horizontal padding `s4` (compact) / `s6` (medium) / `s6` (expanded), scroll fade at the clipped edge, selected chip scrolls into view on change. Selected: fill `primary`, label `onPrimary`; unselected: fill `surface`, 1 px `outlineVariant`, label `onSurface` `labelLarge`. The selected chip when `customRange != null` stays "All" exactly as today (`cfg.customRange != null ? CashPeriod.all : cfg.period`).
- `PeriodNavigator` in place of `CashbookPeriodBar`: height 48, fill `surfaceContainer`, radius `md`, margin horizontal `s4`, previous and next `IconButton` (`Icons.chevron_left_rounded`, `Icons.chevron_right_rounded`, 48x48), center label `titleSmall` `onSurface`, centered, maxLines 2 at large text scale. Label text is built in the widget from `range.start` and `range.lastDay` with `settings.formatDate`, joined by " - " (ASCII hyphen), a single date when both are the same day, "All" for no range. This replaces the arrow string only on screen; the export strings from `CashbookCalculator.rangeLabel` are untouched. Disabled chevrons (`onShift == null`): icons render at `onSurface` 38 percent alpha and the tooltip says "Not available for All, custom range or search"; the chevron slots keep their width so the label does not jump.
- `onLabelTap`: only in Daily it opens the Daily date picker described in screens/accounts_daily_date_picker.md (do not duplicate the spec here). Other periods: label not tappable.
- Active filter line becomes `FilterSummaryBar`: a `RigChipRow`-style row of read-only `InputChip`s (`Search: "..."`, `Income`, `Expense`, `Oldest first`), each with an `x` to remove only that facet (calls the same notifier methods: `setQuery('')`, `setType(all)`, `setAscending(false)`), plus a text button "Clear" (calls `clearFilters`, clears the search controller, `_searching = false`). Fill `primaryContainer`, text `primary`. Shown only when `cfg.type != all || cfg.ascending || searching` (same condition as today).

### 4.3 List

- Day group: `DayGroupHeader` (pinned on compact and medium via `SliverMainAxisGroup` if the list is converted to slivers, otherwise not pinned; pinned is optional, not required): text `titleSmall` `onSurfaceVariant`, background `background`, padding `s4` horizontal, `s2` vertical, min height 36. Text from `settings.formatDayHeader` (unchanged string).
- "Previous Balance" row (the `'prev'` marker): a `RigCard` tone `container` (surfaceContainer), one line: label "Previous Balance" `bodyMedium` italic `onSurfaceVariant`, value `AmountText` style small, tone neutral (negative uses `negative`). Same text, same value, same position (first row).
- Ledger row `LedgerRowTile` (replaces `CashbookRow`): segmented card. Rows of one day share one visual card: first row has top radius `lg`, last row has bottom radius `lg`, 1 px `outlineVariant` border, fill `surface`, rows separated by `RigDivider` inset `s4`. Position (first/middle/last/only) is computed in the list builder from neighbor items (UI only). List stays `ListView.builder` over the same flattened `items`.
  - Compact (<600): one trailing amount column. Layout `[TypeBadge 32] [Column: notes bodyLarge maxLines 2 (placeholder "-" in textMuted), description bodySmall primary maxLines 1, meta bodySmall onSurfaceVariant: date (if showDateInEntry) and time (if showTime), then attachment icon 16 and link icon 16 with tooltips "Bill attached" and "Linked to a bill payment"] [Column right: AmountText style medium tone moneyIn or negative (Income or Expense), below it "Balance <n>" bodySmall onSurfaceVariant when showBalancePerEntry]`. `TypeBadge` is a 32 circle `moneyInContainer` with `Icons.south_west_rounded` 16 `moneyIn` for Income, `negativeContainer` with `Icons.north_east_rounded` `negative` for Expense; it carries semantics "Income" or "Expense" so color is not the only signal. Amount takes intrinsic width (min 88 dp, max 55 percent of row); notes ellipsize first. No `FittedBox` unless the intrinsic width exceeds 55 percent, then `FittedBox(scaleDown)` as a last resort.
  - Medium and expanded (>=600): keep the two-column table that PARITY-032 describes. Column header row (sticky under the filter bar, `surfaceContainer`, `labelMedium` `onSurfaceVariant`, height 36): "Details" (flex 5, left), "Income" (flex 3, right, `moneyIn`), "Expense" (flex 3, right, `negative`). Label "Details" replaces the misleading "Date" (copy change; see Q1). The row uses the same content as compact except the badge is removed and the amount goes to its own column (right aligned, tabular). The "Balance <n>" caption sits under the amount in whichever column holds it.
  - Min height 72 (two lines); whole row is the tap target; `onTap` and `onLongPress` both open edit (unchanged). Desktop: hover `surfaceContainerHigh`, `SystemMouseCursors.click`, right-click opens a context menu with exactly one item "Edit" (same as tap; no new actions), Enter on focused row opens edit.
- Empty states (`EmptyState`): no entries at all for the book: icon `Icons.receipt_long_rounded` 48 `textMuted`, title "No transactions" (`titleMedium`), hint "Add an Income or Expense to get started" (`bodySmall`). Entries exist but filters or the period hide all: title "No transactions" and hint "Try another period or clear filters", tonal button "Clear filters" (same `clearFilters` call). Search without results: hint "No match for the search". The hint copy is new text only; the title text is the existing "No transactions".

### 4.4 Bottom action area

`LedgerActionBar` pinned to the bottom (SafeArea, resizeToAvoidBottomInset), surface level 3 only when the list scrolls under it (otherwise level 1 with top 1 px `outlineVariant`), padding `s4`, `s3`:
- Row of two `FilledButton.icon`, height 48 (40 with pointer), radius `md`, gap `s3`, equal width: Income (`Icons.add_rounded`, background `moneyIn`, foreground `onPrimary`) and Expense (`Icons.remove_rounded`, background `negative`, foreground `onPrimary`). Contrast: onPrimary on moneyIn 5.48:1, onPrimary on negative 6.47:1. Disabled (`book == null`): `onSurface` 12 percent fill, 38 percent text. Labels remain `CashLabels.income` and `CashLabels.expense`.
- `CashTotalsCard` (replaces `CashbookTotalsStrip` visuals): `RigCard` tone `container`, padding `s3`, radius `lg`. Row of three `AmountTile`s separated by 1 px `outlineVariant` dividers (not `VerticalDivider` in `IntrinsicHeight`, use fixed `SizedBox(height: 40)`): "Total Income" (`moneyIn`), "Total Expense" (`negative`), "Balance" (`primary`, or `negative` when below zero). Label `labelMedium` `onSurfaceVariant` (labels no longer carry the semantic color, rule section 3.2), value `amountMedium`. Values wrap to two lines or use `FittedBox` only when wider than the tile (>=1.3 text scale uses a 2-row stack instead of 3 columns: each metric on its own row, label left, value right). Below, when `previousBalance != null`: two `MoneyLabelValueRow`s "Previous Balance" and "Balance" (the second bold, `amountMedium`), same values as today (`roundMoney(previousBalance + balance)`). Values come from `settings.formatMoney` so the user's number-style setting and the "Rs." prefix are preserved (the symbol decision Rs. vs rupee sign is open: see logic_g2.md L-02).
- Expanded: buttons and totals sit side by side in one row (buttons left 40 percent, totals right 60 percent) to give the list more height.

### 4.5 Overflow menu

`RigMenuButton` (tooltip "More options") with grouped items separated by dividers: [Notes, Date, Select Date Range] [Date Ascending, Date Descending (checked)] [Income, Expense (checked)] [Clear filters] [Your Name and Address]. Same labels, same values. Checked items use `Icons.check_rounded` trailing. `Date` item opens the picker specified in accounts_daily_date_picker.md.

### 4.6 Tokens summary

Spacing: screen horizontal `s4` (compact), `s6` (medium, expanded); row padding `s4` x `s3`; group gap `s2`; action bar padding `s4`/`s3`. Radius: rows and cards `lg`, buttons and period navigator `md`, chips and book selector `full`. Type: row notes `bodyLarge`, meta `bodySmall`, amounts `amountMedium`, totals `amountMedium`, headers `titleSmall`. Colors: `onSurface`, `onSurfaceVariant`, `textMuted` (placeholders), `moneyIn`, `negative`, `primary`, `surfaceContainer`, `outlineVariant`.

### 4.7 State table

| State | Rule |
|---|---|
| Default | as above |
| Loading | none needed (local data); first frame never shows a spinner |
| Empty | three variants above |
| Error | no errors from providers; Report failure is shown by `showRigSnack(error)` (in report doc) |
| Disabled | Income/Expense buttons when `book == null`; period chevrons per 4.2 |
| Searching | header shows `RigSearchField`; period navigator chevrons disabled (existing rule `searching`) |
| Filtered | `FilterSummaryBar` visible |

### 4.8 Motion

Chip select and chevron press: `fast` 150 ms; `FilterSummaryBar` appears with `base` 200 ms size transition (`curveEnter`); list day changes (shift period) cross-fade `base` 200 ms; none when reduced motion is on.

## 5. Logic touchpoints that must stay untouched

- Providers and notifier methods listed in section 2 (names exactly: `cashViewConfigProvider.notifier.setQuery/setDay/setCustomRange/setAscending/setType/clearFilters/setPeriod/shift`, `currentCashBookIdProvider.notifier.select`, `cashSettingsProvider.notifier.updateSettings`).
- `_pickBook` order: `select(book.id)` then `clearFilters()` (home:175-181).
- `_report` builds `CashExportData` from `cashLedgerProvider`, with `rows` reversed when not ascending, `rangeLabel` replaced `' -> '` by `' To '` (home:93-114): export content must not change.
- `items` flattening rule: `'prev'` first only if `view.hasPreviousBalance`, then per group the day then its rows (home:204-210).
- Chevrons are disabled when `period == all || customRange != null || searching` (home:291-295).
- Active filter line condition (home:297).
- `CashLabels.income`, `CashLabels.expense`, `CashLabels.totalIncome`, `CashLabels.totalExpense`, `CashLabels.balance` strings.
- Row amount goes in the Income column when `entry.isCashIn` else the Expense column (PARITY-032); `showBalancePerEntry`, `showTime`, `showDateInEntry` switches.
- Totals strip: previous balance lines exactly when `previousBalance != null`; final Balance = `CashbookCalculator.roundMoney(previousBalance + balance)`.
- `onTap` and `onLongPress` both call `_openEdit(row.entry)`; `_openForm(income:)` passes `initialCashIn`.
- Search controller is owned and disposed by the State (home:33-39). `showCashTextPrompt` owns its controller.
- No widget Keys are defined in these files today; the redesign must not add behavior to keys.

## 6. Acceptance criteria

1. With the same data, the book shows the same rows in the same order, same amounts, same running balance and same totals as before (compare against parity_g2.md section H).
2. Header has no gradient and no hard-coded color; book selector opens the picker; selector hit area >= 48 dp tall.
3. Income and Expense buttons are each >= 48 dp tall on touch, with icon and label; contrast of label on fill >= 4.5:1.
4. Period chip row shows a fade at a clipped edge and the selected chip is visible without manual scroll.
5. Period navigator label uses the date-format user setting; same-day range shows one date; no "->" on screen; export files still contain " To " ranges as before.
6. At 200 percent text scale on a 360 dp wide screen: no overflow stripes, amounts fully visible (not clipped), totals card switches to the stacked layout.
7. Compact rows show one amount column with a type badge; medium and expanded show Income and Expense columns with a "Details" header.
8. Empty state variants appear for: empty book, filtered-out, search without result; "Clear filters" resets as the overflow item does.
9. Removing one filter chip changes only that facet; "Clear" clears all and exits search mode.
10. Desktop: hover highlight on rows, right-click shows "Edit", Enter opens edit, focus ring visible, content max width 1100.
11. Search field has a clear icon that empties text without leaving search mode.
12. No `Colors.x`, no hex, no `AppColors` direct reads in the redesigned files.
13. Icons all `_rounded`; attachment and link icons are 16 dp with tooltips.

## 7. Performance notes

- `build` currently watches whole `cashViewConfigProvider`, `cashLedgerProvider` and `cashSettingsProvider` in one widget and rebuilds the entire screen (header, chips, list, footer) on any change, including every keystroke in search (`setQuery`). Split into small const-friendly widgets: `LedgerHeader` (watch `currentCashBookProvider.select(name)` and `_searching`), `PeriodControls` (watch `cashViewConfigProvider.select((c) => (c.period, c.customRange))` and the range label), `LedgerList` (watch `cashLedgerProvider.select((v) => v.groups)` plus `previousBalance`), `LedgerFooter` (watch `cashLedgerProvider.select((v) => (v.totals, v.previousBalance, v.hasPreviousBalance))`).
- `items` list is rebuilt on every build (home:204-210); compute it inside `LedgerList` only, memoize by identity of `view.groups`.
- Keep `ListView.builder` with `itemExtent` unknown (variable rows); set `cacheExtent` default; add `ValueKey(entry.id)` per row so edits do not rebuild neighbors; `addAutomaticKeepAlives: false`.
- Avoid `IntrinsicHeight` in the totals card (totals_strip.dart:58) because it forces a second layout pass; use the fixed 40 dp divider.
- `Material` + `InkWell` per row creates one Material per row; use one `Material(type: transparency)` ancestor for the list and `InkWell` rows inside it.
- No blurred shadows in rows or the action bar (elevation level 3 only for the pinned bar when content scrolls under it).
- `settings.formatMoney` creates a `NumberFormat` per call (calculator:210); format only visible rows (the builder already does) and never inside `build` of a parent that rebuilds on every keystroke. Cache is a logic item (L-03).
- Controllers: `_searchController` correctly disposed. `setState` is used only for `_searching`.


## Reconciliation 2026-10-13 (Apple look, Android only)

### R1. Mockup screens and Flutter mapping

| Mockup screen (J registry) | Mockup render function | Flutter file | Widgets | Notes |
|---|---|---|---|---|
| Home (All) | `cbHome`, `cbRows`, `cbStrip`, `cbPeriodChips`, `cbPbar` | lib/features/cashbook/cashbook_home_screen.dart, widgets/cashbook_header.dart, cashbook_period_bar.dart, cashbook_row.dart, cashbook_totals_strip.dart | LargeTitleScaffold (root, title "Accounts", menu button, status strip), RigChipRow, RigCard x3 (strip), RigGroup, RigRow, RowActions, RigButton (moneyInButton and moneyOutButton), EmptyState, MoneyText | Title is "Accounts" with a book pill below it; the book name is no longer the title. |
| Home (Monthly, previous balance) | `cbHome` with `CB.period=monthly` | same files | RigChipRow, period navigator (`pnav`), RigGroup with two RigRows (Previous balance, Balance with previous), Previous Balance row at the top of the list | Previous balance appears twice in the mockup: in the group under the strip and as the first list row (see conflicts_r3.md C-04). |
| Receiver book (linked rows) | `cbRows` with `e.ln` | cashbook_row.dart | RigRow with a 14 dp link icon and the text "Linked to a bill" | Code tooltip says "Linked to a bill payment"; keep the longer text as the semantics label. |
| Overflow menu / Account Ledger overflow sheet | `cbMenu` | cashbook_home_screen.dart (`_overflow`) | RigSheet (full), RigGroup, RigRow with check marks, section captions Sort and Filter | Replaces `PopupMenuButton`; same 9 commands plus Your Name and Address. |
| Book picker | `cbPicker` | cashbook_book_picker_dialog.dart | RigSheet, search RigGroup, RigRow with icon tile, subtitle "Receiver book" or "Custom book", check mark for the current book, Add Account row, Edit text button | Documented in cashbook_books_screen.md. |
| Account Ledger date picker (B2) | `cbDatePick`, `datePick` | cashbook_home_screen.dart (`_pickDay`) | DatePickerSheet (B2) | Spec is screens/accounts_daily_date_picker.md (group r1); only referenced here. Depends on LR-02. |
| Accounts empty | `cbHome` with `UI.state=empty` | cashbook_home_screen.dart | EmptyState (icon `account_balance_wallet_outlined`, "No transactions", "Add an income or an expense to get started.") | Matches the old empty-book hint plus a sentence. |
| Accounts loading | `cbHome` with `UI.state=loading` | cashbook_home_screen.dart | Skeleton x4 inside the list area | Mockup only: data is local. LR-34 default says no new state; use a skeleton only for the first frame after a book switch if ever needed. |

### R2. What changes in the redesign (supersedes section 4)

Layout top to bottom on the Accounts tab (root of tab 4), flat canvas:
1. LargeTitleScaffold: status bar edge to edge, 56 dp bar row with the menu button at left (opens the drawer) and Search, Report (PDF) and More buttons at right (each a 48 dp glass button); large title "Accounts" 34 sp collapsing to a 17 sp inline title. When collapsed, the optional status strip (48 dp) shows the book name at left and "Balance <amount>" at right in `outstandingText` or `moneyOutText` when negative and `accentText` otherwise; tapping it scrolls to top. The strip uses the solid 94 percent surface with a hairline (no blur by default).
2. Search mode (inline, above the book pill): a RigGroup row of height 44 with a search glyph and the field, and a text button "Cancel" that clears the text and leaves search mode. Placeholder "Search notes and accounts" (the mockup text; the code placeholder today is "Search").
3. Book pill (`pillb`): full-radius pill, 48 dp touch box, wallet or person glyph, book name (one line, ellipsis), expand glyph. Opens the book picker sheet.
4. Period chips: RigChipRow with All, Daily, Weekly, Monthly, Yearly and Range (inverse selected chip, 48 dp box around a smaller visible pill, horizontally scrolling with a fade at a clipped edge). The Range chip opens the Select Date Range sheet (UI route to the same `pickCashDateRange` contract).
5. Period navigator: previous and next 48 dp buttons around the label (`dFull` to `dFull`, or "All time"); in Daily the label has an expand glyph and opens the DatePickerSheet (B2). Hidden when period is All, a custom range is set, or a search is active (the chevron-disabled rule moves to a hidden navigator in the mockup).
6. Active filter row: a 36 dp pill with the filter text joined by " | " and a text button "Clear".
7. Totals strip (three RigCards in a row, gap 12, radius 20): Income (`moneyInText`), Expense (`moneyOutText`), Balance (`accentText`, or `moneyOutText` when negative). Label 12 sp weight 600, value 17 sp weight 700 with tabular figures. The value is MoneyText with the fit pipeline: full value, scale to 75 percent, shrink to the 11 px guard, then the value moves to its own line; NEVER compact L or Cr (binding answer 3; the mockup `mfit` allows compact here, see conflicts_r3.md C-03). When previous balance is non zero: a RigGroup with two RigRows, "Previous balance" and bold "Balance with previous".
8. Action buttons (scroll with the content, not pinned): two RigButtons side by side, 50 dp pill, gap 12: Income uses `moneyInButton` fill with a white label (`onMoneyButton`), Expense uses `moneyOutButton` with a white label. Disabled when there is no current book: 40 percent opacity.
9. Ledger list: Previous Balance row (when settings show it, period is not All, no search, value not zero) in a RigGroup; then one block per day: sticky day header (`dGroup`, "N entry" or "N entries" at right, 15 sp weight 600, `label2`, background canvas, hairline none) and a RigGroup holding that day's RigRows.
10. Ledger row (replaces `CashbookRow`): two lines, min 64 dp. Line 1: notes 17 sp weight 600 (placeholder "No notes" in `label2`) left, signed amount right ("+" for Income in `moneyInText`, "-" for Expense in `moneyOutText`, 17 sp weight 700, never compact). Line 2 (13 sp `label2`): optional time with `dRow` date when "show date" is on, link glyph with "Linked to a bill", spacer, "Balance <full amount>" when the setting is on. Description and the attachment glyph (existing data) stay on line 2. Tap and long press both open edit (unchanged). RowActions: swipe left reveals Edit (`accentButton`, 76 dp) and Delete (`moneyOutButton`, 76 dp); long press menu holds the same two commands as the non-gesture path. Delete runs the existing confirm "Move this transaction to Deleted Transactions?" then `moveToTrash`.
11. Bottom padding of the list: 62 + `viewPaddingOf.bottom` + 8 + 24 (tab bar height, inset, float, gap) so the last row clears the floating RigTabBar.


Old section 4 items:

- Old 4.1 shell (RigScaffold, RigAppBar, BookSelector in the title, search field in the title): CHANGED to LargeTitleScaffold with the title "Accounts"; the book selector becomes the book pill below the title; search is an inline row under the bar. Actions order Search, Report, overflow KEPT.
- Old 4.1 maxContentWidth and desktop bar height: DROPPED (macOS, medium and expanded).
- Old 4.2 RigChipRow: CHANGED to the inverse-selected RigChipRow with a sixth Range chip (new visible entry point for Select Date Range; the overflow item stays); the 5 periods KEPT.
- Old 4.2 PeriodNavigator (filled pill, tinted): CHANGED to the mockup `pnav` (label centred, 48 dp chevrons, no tinted pill); label from `settings.formatDate` KEPT (default becomes `d MMM yyyy`, LR-24); onLabelTap in Daily to the B2 sheet KEPT.
- Old 4.2 FilterSummaryBar with per-facet remove icons: CHANGED to the single text pill with "Clear"; per-facet removal is DROPPED (mockup does not show it; the overflow Clear filters item remains).
- Old 4.3 DayGroupHeader (pinned optional): CHANGED to sticky headers (mockup `.gh` is sticky). Sticky is accepted only with a flat canvas background and no blur; see R6 for the cost.
- Old 4.3 Previous Balance row in a RigCard: CHANGED to a RigGroup row, as in the mockup.
- Old 4.3 LedgerRowTile compact with TypeBadge and the medium/expanded two-column table with "Details" header: CHANGED to one two-line row with a signed amount; TypeBadge and the table are DROPPED (colour plus sign carry the type; the screen reader label says "Income" or "Expense").
- Old 4.3 desktop hover, right-click menu, Enter key: DROPPED.
- Old 4.3 empty-state variants (empty book, filtered out, search without result): KEPT as three texts in EmptyState; the mockup shows "No transactions" with "Add an income or an expense to get started." for an empty book and "Nothing matches this period or filter." for a filter.
- Old 4.4 LedgerActionBar pinned at the bottom with the totals card: CHANGED. The totals strip moves above the list, the two buttons are inline and scroll; there is no pinned bottom bar (the floating RigTabBar owns the bottom edge). The icons on the buttons are DROPPED (mockup shows text only).
- Old 4.4 expanded side-by-side buttons and totals: DROPPED.
- Old 4.5 overflow menu as grouped popup: CHANGED to a full-height RigSheet with captions Sort and Filter and check marks; same labels and values.
- Old 4.6 tokens (s4 margins, md radii, gradient-free header colours): CHANGED to 20 dp margins, 12 gap, 20 radius and the colour roles above.
- Old 4.7 state table: KEPT in substance; Loading and Error rows are CHANGED to mockup-only states (skeleton and ErrorBanner "Could not load transactions", reachable only if LR-34 is approved).
- Old 4.8 motion: CHANGED to 200 to 350 ms ease-out; chips and rows use ink press, no scale.


States:

| State | Rule in the new look |
|---|---|
| Default | strip, buttons, grouped day list as above |
| Loading | Skeleton x4 cards under the book pill (mockup "Accounts loading"); not wired unless LR-34 is approved |
| Empty | EmptyState: icon `account_balance_wallet_outlined` 52, "No transactions", "Add an income or an expense to get started." Filtered or period-empty: "No transactions", "Nothing matches this period or filter." |
| Error | ErrorBanner "Could not load transactions" with "Nothing was changed." (mockup only, LR-34 proposed); Report failure stays a RigSnack |
| Disabled | Income and Expense buttons at 40 percent opacity with no current book; navigator hidden for All, custom range and search |
| Searching | inline search row; navigator hidden; active filter pill shows `Search: "text"` |
| Filtered | filter pill with "Clear" |


Motion: sticky header and strip crossfade 200 ms when the title collapses (ValueNotifier flip, no per-scroll setState); period change cross-fades the list in 200 ms; ink press on rows, chips, pill and buttons; no animation when `MediaQuery.disableAnimationsOf` is true.


### R3. Logic touchpoints and LR items

Untouched: the provider and notifier calls of section 5 (`setQuery/setDay/setCustomRange/setAscending/setType/clearFilters/setPeriod/shift`, `select`, `updateSettings`), `_pickBook` order, `_report` export construction, list flattening, row amount placement rule, the totals and previous-balance arithmetic, `onTap` and `onLongPress` both opening edit, State-owned search controller.


- LR-24 (approved for the rupee sign; date default to confirm): rupee sign and en-IN grouping in rows, strip and balances; default date pattern `d MMM yyyy` for `formatDate`; the day header becomes `dGroup` (`EEE, d MMM yyyy`) while the setting stays a user choice (see L2-r3-2 in logic2_r3.md).
- LR-02 (approved): `CashViewConfigNotifier.setAnchor(DateTime)` for the Daily date sheet (B2).
- LR-25 (approved): not on the home screen; the discard prompt belongs to the forms it opens.
- LR-34 (proposed): loading and error states are mockup-only unless approved.
- L2-r3-1 (proposed, new): fate of the Currency Format setting under LR-24.
- Swipe Edit and Delete on a row reuse `_openEdit` and `moveToTrash` with the existing confirm text: UI entry point only, no logic change, no LR.


### R4. Acceptance criteria delta

1. At 360 dp and 412 dp, light and dark, the screen shows title "Accounts", book pill, period chips, strip, two buttons and the list in that order; the same data gives the same rows, running balances and totals as before (parity_g2.md section H).
2. At text scale 130 and 200 percent no amount is clipped: values use the fit pipeline (full, 75 percent, 11 px guard, own line) and never show L or Cr; the strip cards stack to one column at 200 percent.
3. Income and Expense buttons are 50 dp tall pills; label contrast on `moneyInButton` and `moneyOutButton` is at least 4.5:1 in both themes (white label); the buttons scroll away with the list.
4. The last list row ends at least 24 dp above the floating tab bar (62 + inset + 8 + 24 from the bottom edge) with gesture navigation and with 3-button navigation.
5. Collapsing the large title shows the status strip with the book name and balance; tapping it returns to the top; no frame builds during scroll except the two crossfading widgets.
6. Swipe left on a row shows Edit and Delete 76 dp wide; long press shows the same two commands; Delete shows the existing confirm and moves the entry to Deleted Transactions; edit by tap still works.
7. Android back: closes the overflow sheet, the picker or the date sheet first; then the keyboard; then nothing on the root tab (search mode is left with its Cancel button, as the back arrow does today).
8. With the keyboard open in search mode the list and the field stay visible and the RigTabBar is hidden.
9. Period navigator is hidden for All, a custom range and while searching; in Daily its label opens the DatePickerSheet and a chosen date shows that day.
10. No money text anywhere on this screen contains "Rs."; negative values read "-" then the rupee sign.


### R5. Parity delta

Change on purpose:

- PARITY-035 and PARITY-084 (Rs. prefix): amounts show the rupee sign with en-IN grouping, two decimals only with paise (LR-24).
- PARITY-080 and the accepted T-CB08 deviation: empty book now shows an icon, a title and a hint (copy change only, still no data).
- PARITY-032 row anatomy: one signed amount column instead of the Income and Expense columns (the compact form that parity_g2.md line 3 already allows).
- PARITY-031 day header text: `EEE, d MMM yyyy` by default (LR-24); the string is still driven by the Format Date setting.
- PARITY-036 chevrons inactive: the navigator is hidden instead of drawn inactive for All, a custom range and search.


Must stay identical:

- PARITY-006 book picker, PARITY-013 add Income and Expense entry points, PARITY-033 running balance, PARITY-034 totals, PARITY-037 and 038 previous and negative balance, PARITY-039 and 040 display switches, PARITY-042 live search, PARITY-043 to 047 overflow commands and filters, PARITY-048 edit by tap.
- Order newest first (ascending by choice), grouping by day, the Balance per entry text and its value.


### R6. Performance and Android notes

- Edge to edge: status bar transparent, bottom inset from `MediaQuery.viewPaddingOf(context).bottom` (never a hard-coded 24). Root tab content ends at 62 + inset + 8 + 24 dp (tab bar height 62, its float 8, list gap 24).
- Keyboard: `resizeToAvoidBottomInset: true`; the floating RigTabBar is hidden while the keyboard is open; the focused field is scrolled to the centre with `Scrollable.ensureVisible`.
- Back: root tab back is swallowed by the shell `PopScope(canPop: false)` (unchanged); pushed screens pop normally.
- Sticky day headers cost: use `SliverMainAxisGroup` with `SliverPersistentHeader(pinned: true)` per day; cost grows with the number of days on screen. Budget: p90 under 8 ms. If a 500 entry, 120 day profile run exceeds budget, fall back to non-sticky headers (MOCKUP_NOTES.md cheap alternative).
- List strategy: one `CustomScrollView`; rows built lazily with `ValueKey(entry.id)`; one transparent Material ancestor for ink; no per-row shadow (RigGroup shadow only in light, radius 20 clip per group, not per row).
- Split the single big `build`: header and search (watch book name and `_searching`), period controls (`select` on period, anchor, custom), strip (select on totals), list (select on groups); `setState` only for `_searching`.
- Cache: compute the flattened items list once per `view.groups` identity; MoneyText measures once per (string, style, scale, width).
- Controllers: `_searchController` is State-owned and disposed (verified in code, home:33-39). The Notes dialog (`showCashTextPrompt`) owns its controller in State. No change.
- No BackdropFilter inside the scrolling list; the collapsed bar and the tab bar use the solid 94 percent surface with a hairline unless the Glass blur toggle is on (default OFF).

