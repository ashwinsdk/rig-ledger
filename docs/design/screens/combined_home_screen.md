> SUPERSEDED IN PART (2026-10-13): the look is now the Apple-inspired Android direction. Read "Reconciliation 2026-10-13" at the end of this file first; where it conflicts with sections 4 to 7 above, it wins.
# combined_home_screen.dart (Ledger tab and Side Ledger tab)

File: `lib/features/home/combined_home_screen.dart`, 1274 lines. Hosts: Ledger tab (summary, list, calendar) and Side Ledger tab (period controls, summary, four category tiles). Child widgets are in `screens/ledger_list.md`. The collapsing header (B4) and highlights (B5) are specified in `HIGHLIGHTS_AND_COLLAPSE.md`; this document applies them and does not repeat them.

"Main ledger screen" = the Ledger tab. "Side ledger screen" = the Side Ledger tab of this file (see the question about `side_ledger_screen.dart`, which is dead code).

## 1. Purpose and primary user task

Ledger tab: scan bills for a period, see money totals and feet totals, open a bill, add a bill (FAB or Cmd+N). Side Ledger tab: see purchases (diesel, PVC, bit, hammer) for a period and open a category list. Rig context: switch rig from the header.

## 2. Current structure

- `CombinedHomeScreen` (ConsumerStatefulWidget, `SingleTickerProviderStateMixin`, `TabController(length: 2)`): `Scaffold > Column[gradient Container header, Expanded(TabBarView[ Column[SummaryRow, Expanded(LedgerList | CalendarViewWidget)], _buildSideLedgerContent() ])]`.
- Header (lines 57-445): app bar row (search, tappable title with rig name, filter with active dot), white-pill `TabBar`, search-active line, then period controls inside an `AnimatedBuilder(animation: _tabController)` that shows chips, optional custom range row, month or year navigator, and Daily/Calendar toggle only for the Ledger tab (otherwise a 12 dp spacer).
- Providers watched at the top of `build` (lines 57-67): `selectedMonthProvider`, `selectedYearProvider`, `customStartDateProvider`, `customEndDateProvider`, `isDailyViewProvider`, `searchQueryProvider`, `ledgerFilterProvider`, `timePeriodProvider`, `currentVehicleProvider`.
- Side Ledger tab (`_buildSideLedgerContent`, line 494): watches 5 date providers, `isSideBoreProvider` and the 4 entry providers, filters each list by period inside `build` (`_filterByTimePeriod`), then builds chips, navigator, a summary card (`_buildMiniStatDouble` x2 to 4), and `_buildCategoryCard` tiles that push `DieselListScreen`, `PvcListScreen` (and bit/hammer list screens).
- Overlays: `_showVehicleSwitcher` (bottom sheet, line 1081), `_showSearchSheet`, `_showFilterSheet` (both transparent-background modal sheets), `showDateRangePicker` for custom ranges (main line 1224 and side `_pickSideLedgerDateRange`).

## 3. Problems found

1. B4: the header plus summary leave about 326 dp of 914 dp for the list (36 percent). Cite combined_home_screen.dart:63-445 and summary_row.dart.
2. B5: highlight values collide or overflow (see HIGHLIGHTS_AND_COLLAPSE.md B.1). Side Ledger summary uses `Row(spaceAround)` with fixed-style `Text` (lines 722-760): long quantity or amount overflows.
3. Header controls are repeated: month and year navigation rows are written twice each (main lines 305-380, side lines 650-720) with different colors (white on gradient vs default on page).
4. Side Ledger period chips are in the page body on a white background while Ledger chips are in the gradient header (screenshot 05 vs 00): same control, two looks, two code paths (`_buildPeriodChip`, `_buildSideLedgerPeriodChip`).
5. Chips clip: "All" renders as "Al" at 411 dp in the Side Ledger tab (screenshot 05); no fade or scroll hint.
6. Two white pill toggles (`TabBar` and the Daily/Calendar toggle built from `GestureDetector`s) with different heights (56 vs 44) and no focus, no semantics, no keyboard support, no 48 dp guarantee on the inner segments' semantics.
7. Rig switcher: the title area is a `GestureDetector` (no ripple, no tooltip, no semantics); tap target is the title column (about 40 dp high).
8. The filter active dot uses `AppColors.warning` as a 8 dp dot without text alternative.
9. Rebuild scope: the whole 1274-line state rebuilds on any of 9 providers; the Side Ledger tab re-filters four lists every build.
10. Copy and formats: summary values use `₹` plus `#,##0.00`, custom range prints `dd MMM yyyy`, month title `MMMM yyyy`, list day header `EEE, dd MMM yyyy`, Account Ledger `MMM-dd-yyyy`.
11. Empty state on first launch only says "Tap + to add your first entry" (ledger_list.dart:40), even when the empty result comes from a filter or search (no way to tell).
12. `Colors.blue`, `Colors.indigo`, `Colors.teal`, `Colors.cyan`, `Colors.orange` as feet tile colors (summary_row.dart:104-155): five unrelated hues for five similar quantities, no meaning.
13. No empty or loading state on the Side Ledger summary; zero values show as colored `0.00` (screenshot 05).
14. FAB `AppColors.primary` plain `Icons.add` with no label; on the Side Ledger tab it opens a chooser sheet; behavior differs by tab with no hint.

## 4. Redesign

### 4.1 Frame (all widths)

`RigScaffold(body: NestedScrollView ...)` per HIGHLIGHTS_AND_COLLAPSE.md A.5. Pinned: `RigAppBar` row + `RigTabBar` (Ledger, Side Ledger). Collapsible: period chips, navigator, Daily/Calendar `RigSegmented`, highlights. Status strip when collapsed.

### 4.2 Ledger tab

| Part | Compact | Expanded (macOS) |
|---|---|---|
| App bar row | `[search] [RigSwitcher title: "RigLedger" + rig] [filter + dot] [collapse toggle]`, 56 dp, `headerSurface`, `onPrimary` | in-page title dropped (title bar has the rig); row holds search field (inline `RigSearchField`, replaces the modal sheet only visually; same `searchQueryProvider`), filter button, collapse toggle |
| Tabs | underline `RigTabBar` 40 dp | left aligned tabs 40 dp, content max width 1100 |
| Period chips | `RigChipRow` order Month, 3 Mo, 6 Mo, Year, Custom, All (current order kept), fade edge | inline right of the tabs |
| Navigator | `PeriodNavigator` month or year, 48 dp arrows, label `titleMedium`; custom range row `[date range label] [Edit]` | same row, inline |
| View toggle | `RigSegmented` Daily, Calendar, 40 dp | inline |
| Highlights | `HighlightsPanel` (B5) | 4 + 5 tiles in one or two rows |
| List | `SliverList` of `DayGroupHeader` + `LedgerEntryCard` | same, cards capped at 720 dp wide, two-column grid at width over 1100 (optional, decide in prototype) |
| FAB | `FloatingActionButton.extended` is NOT used; keep the 56 dp FAB, bottom padding 88 on the list | sidebar "New Entry" button stays; FAB hidden on macOS (it already is) |

Tokens: header `headerSurface`; chips `ChoiceChip` selected `primaryContainer` with `primary` text on a light body (the chips move out of the dark header when the header becomes flat, so contrast comes from the surface, not white-on-gradient); text `onPrimary` only on `headerSurface`.

### 4.3 Side Ledger tab

Same frame. The period chips, navigator and custom range row use the SAME components as the Ledger tab but bound to the side ledger providers (`sideLedgerTimePeriodProvider` etc.), so the controls look identical in both tabs. Highlights: one `AmountTile` per category (Diesel: litres and amount; PVC: pieces and amount; Bit; Hammer; side bore: Bit and Hammer only), 2 columns (1 at text scale over 130 percent), quantity line and amount line each fitted per B5. Below, `CategoryTile`s (icon, title, count line, amount, chevron) in a 2-column grid (compact), 4-across (expanded). Category identity colors from `categoryDiesel/Pvc/Bit/Hammer` tokens.

### 4.4 State table

| State | Ledger tab | Side Ledger tab |
|---|---|---|
| Default | list + highlights | tiles + categories |
| Loading | highlight skeletons for one frame, list skeleton rows if load exceeds 200 ms | tile skeletons |
| Empty, no data at all | `EmptyState` "No entries yet", hint "Tap + to add your first entry" (existing copy) | tiles with zeros muted (`textMuted`), no color accent on zero |
| Empty, because search or filter | `EmptyState` "No entries match", hint "Clear the search or filters", tonal button "Clear" (calls the existing reset of `searchQueryProvider` and `ledgerFilterProvider`) | n/a |
| Error | not applicable (local data); sync errors surface in the sync indicator and a snackbar | same |
| Disabled | collapse toggle disabled when content fits | same |

### 4.5 Rig switcher

`RigSwitcher` replaces `_showVehicleSwitcher` and the desktop popup (single component, sheet on compact, `MenuAnchor` popup on expanded). Min tap target 48 x 48, tooltip "Switch rig", semantics "Rig: <name>, switch". The handler is the shared `switchRig` (see `screens/portfolio.md` 4.2, requires approval); until approved the existing handler body is moved unchanged into a single method.

### 4.6 Motion

Collapse and reveal 200 ms `curveEnter`; tab switch 150 ms; chip selection 150 ms color; sheet 300 ms. Reduced motion: instant.

## 5. Logic touchpoints that must stay untouched

Providers: `homeTabIndexProvider` (written in `_onTabChanged`), `timePeriodProvider`, `selectedMonthProvider`, `selectedYearProvider`, `customStartDateProvider`, `customEndDateProvider`, `isDailyViewProvider`, `searchQueryProvider`, `ledgerFilterProvider`, `groupedLedgerEntriesProvider`, `monthlyStatsProvider`, `feetTotalsProvider`, `calendarDayTotalsProvider`, `currentVehicleProvider.setCurrentVehicle`, `vehiclesProvider`, the side ledger providers (`sideLedgerTimePeriodProvider`, `sideLedgerSelectedMonthProvider`, `sideLedgerSelectedYearProvider`, `sideLedgerCustomStartDateProvider`, `sideLedgerCustomEndDateProvider`, `dieselEntriesProvider`, `pvcEntriesProvider`, `bitEntriesProvider`, `hammerEntriesProvider`), `_filterByTimePeriod` semantics (period boundaries), `showDateRangePicker` bounds (2000 to today for the main ledger; keep the exact first/last dates), the tab labels "Ledger" and "Side Ledger", chip labels, "Daily" and "Calendar". Navigation: FAB opens `LedgerFormScreen` or `SideBoreFormScreen` by vehicle type, or `_showAddSideLedgerSheet` on the Side Ledger tab (main_navigation.dart). `TabController` and its listener stay.

## 6. Acceptance criteria

1. (B4) Collapsed header leaves at least 650 dp for the list on 411 x 914 dp; scroll up reveals; tap on the strip reveals (HIGHLIGHTS A.7 items 1-11).
2. (B5) All 19 stress rows render without overflow at 4 widths and 3 text scales.
3. Changing period chips, month, year, custom range, Daily/Calendar, search or filter gives the same list, totals and feet totals as before for the same data (parity lines in PARITY_CHECKLIST.md, section Ledger).
4. Side Ledger chips, navigator and custom range look and behave the same as the Ledger tab's and use the side ledger state only (changing the Ledger period does not change the Side Ledger period and vice versa, same as today).
5. The vehicle selector lists all rigs, marks the current, switches, clears search and filter, and refreshes data.
6. The filter icon shows an active indicator whenever `ledgerFilterProvider.hasFilters`, and the strip shows "Filters on".
7. All header controls have a 48 x 48 dp hit area on mobile and a visible focus ring on macOS.
8. Empty and filtered-empty states show the right message.
9. Switching Ledger and Side Ledger tabs keeps each tab's scroll offset.
10. No emoji, no hard-coded color in the new widgets (`grep` check in the task).

## 7. Performance notes

- Split `build` into leaf consumers: `_HeaderRow`, `_PeriodControls`, `_StatusStrip`, `HighlightsPanel`, `_LedgerBody`, `_SideBody`. Each uses `ref.watch(provider.select(...))`.
- Move `_filterByTimePeriod` results for the side ledger into a derived `Provider` family in a follow-up only if it is already a pure function of existing state (no new logic); until then memoize inside one `Consumer` so the four lists are filtered once per input change, not once per rebuild.
- `TabBarView` children: ledger body is a `CustomScrollView` with `SliverList.builder`; side body a `CustomScrollView` with `SliverGrid` for tiles.
- Dispose: `_tabController` (exists), the scroll controller (new), `ValueNotifier<bool> collapsed` (new).
- Avoid `AnimatedBuilder(animation: _tabController)` wrapping the whole control column (lines 211 and 244 rebuild all controls on tab animation ticks): listen to `tabController.animation` only in the status strip.
- Cache `DateFormat` instances in `RigFormat`.


## Reconciliation 2026-10-13 (Apple look, Android only)

Source of truth: `docs/design/mockup/rigledger_apple_mockup.html` (functions `ledgerTab`, `billList`, `calView`, `sideLedger`, `rigSheet`, `searchSheet`, `filterSheet`, `addEntrySheet`), TOKENS.md and DESIGN_DIRECTION_APPLE.md sections 1, 7, 8. Android only, portrait, 360 dp minimum width, light, dark and system. Everything about macOS, expanded widths (over 900 dp), hover, Cmd shortcuts and two-pane layouts in sections 1 to 7 above is DROPPED (the macOS code stays frozen, never edited here). The B4 collapse mechanism of section 4.1 is REPLACED (see R2); the B5 highlight layout is REPLACED (see R2 and `docs/design/temp/design_wip/highlights_update_r1.md`).

### R1. Mockup screens and Flutter mapping

| Mockup screen (J label) | Render function | Flutter file | Widgets | Notes |
|---|---|---|---|---|
| Home (Ledger, Daily) | `ledgerTab` + `billList` | `lib/features/home/combined_home_screen.dart`, `widgets/ledger_list.dart`, `widgets/summary_row.dart` (replaced by tiles) | LargeTitleScaffold (root, status strip), RigRigSheet trigger pill, RigSegmented (Ledger, Side Ledger), RigChipRow, period navigator (existing widget restyled), RigSegmented (Daily, Calendar), RigCard + RigRing, RigMetricCard x4 (MoneyTile), DepthTile x5, RigGroup + RigRow (bill rows), RowActions | `TabController` and `homeTabIndexProvider` stay |
| Calendar view | `calView` | `widgets/calendar_view.dart` | RigCard grid (7 columns), RigGroup (selected day bills) | day tap list is LR-03 (proposed); day totals fixed by LR-33 |
| Calendar view with selected day | `calView` with `UI.calSel` | `widgets/calendar_view.dart` | same plus RigGroup of the day | LR-03, not in the first pass |
| Side Ledger | `sideLedger` | `combined_home_screen.dart` (`_buildSideLedgerContent`) | RigChipRow, RigCard (Purchases, hero 44), CategoryTile x4 (gradient, 28 radius), RigSegmented | PVC tile hidden for side bore |
| Side Ledger (Side rig) | `sideLedger` with `isSide()` | same | same, 3 CategoryTiles | no PVC |
| Side Bore rig home | `ledgerTab` with side rig | same + `ledger_list.dart` | one wide DepthTile "Total Depth" (1 column) | no PVC anywhere |
| Switch Vehicle sheet | `rigSheet` | `combined_home_screen.dart` (`_showVehicleSwitcher`, replaced) | RigRigSheet (RigSheet + RigGroup + RigRow) | title is "Switch Rig" (answer 4), shared `switchRig` (LR-01) |
| Search sheet | `searchSheet` | `widgets/search_sheet.dart` | RigSheet, RigFormRow (search), RigButton x2 | writes `searchQueryProvider` live as today |
| Filter sheet | `filterSheet` | `widgets/filter_sheet.dart` | RigSheet, RigGroup of RigFormRow, RigButton (Apply, Cancel), text button Clear All | |
| Add Entry sheet | `addEntrySheet` | `lib/features/navigation/main_navigation.dart` (`_showAddSideLedgerSheet`) | RigSheet + CategoryTile 2 x 2 (min height 104) | see main_navigation.md |
| Ledger empty | `emptyUI` | `ledger_list.dart` | EmptyState | |
| Ledger loading | `skelList(4)` | `ledger_list.dart` | Skeleton | first frame after a rig switch or restore only (LR-34 proposed) |
| Ledger error | `errUI` | none | ErrorBanner | not built: no failure path exists (LR-34 default) |
| Ledger no search match | `emptyUI` | `ledger_list.dart` | EmptyState + RigButton | |
| Side Ledger loading | skeleton tiles | `combined_home_screen.dart` | Skeleton | first frame only |
| Bill row actions (long press) | `rowMenu` | `ledger_list.dart` | RowActions -> RigSheet (Edit, Delete) | reuses the form route and the form's delete confirm |
| Full value popover (tap a tile) | `showFull` | `lib/core/widgets/` (MoneyTile) | MoneyTile popover | 2.6 s, tap elsewhere closes |
| Delete entry alert | `delBillDlg` | `ledger_list.dart` (via RowActions) | RigAlertDialog | see ledger_form_screen.md for the text |

### R2. What changes in the redesign (supersedes section 4)

Layout of the Ledger tab, top to bottom (412 x 892 dp reference; margins 20, card gap 12, card radius 20):

1. Status bar edge to edge (`viewPaddingOf.top`, 28 dp in the mockup). Title row 56 dp: large title "Ledger" (34, weight 700) on the left in the bar row; trailing three glass buttons 48 dp: Search, Filter (9 dp `outstanding` dot when `ledgerFilterProvider.hasFilters`), Add (the former FAB). The large title scrolls with the content. After 6 dp of scroll the bar gets a solid 94 percent surface (`barSolid`) with a 0.5 dp hairline and a centred 17 dp title appears (200 ms fade). Blur only behind the Glass blur toggle (default OFF, never inside scrolling content).
2. Status strip (48 dp, appears under the collapsed bar, only on the Ledger tab): period label (15, 600, ellipsis), "Balance " + `money(balance)` in `outstandingText`, a "Filters on" badge when filters are active. Tap scrolls to the top in 250 ms (this is the reveal). Search state: a small "Search on" badge in the strip (UI only, from `searchQueryProvider`).
3. Rig pill (48 dp, `fill`, full radius, icon `precision_manufacturing` or `construction` by rig type, name ellipsis, `expand_more`). Opens RigRigSheet. One rig only: plain text, no arrow (rule kept).
4. RigSegmented "Ledger | Side Ledger" (48 dp). Drives the existing `TabController`.
5. RigChipRow, order Month, 3 Mo, 6 Mo, Year, Custom, All (selected = inverse chip, 48 dp box around a 34 dp pill), then the navigator (month or year, chevrons 48 dp, label 17/600) or, for Custom, "d MMM yyyy to d MMM yyyy" + Edit. Then RigSegmented "Daily | Calendar". Active search shows a pill row "Search: <q>" + text button Clear.
6. Highlights (B5, see below) then the section title "Feet" (22) or "Depth" for side bore, then DepthTiles.
7. List: day groups. Sticky day header (`dGroup`, 15/600 `lb2`, day total right in `accentText`), then RigGroup (card radius 20, hairline separators inset 16) of bill rows.
8. Bottom: list padding = `62 + viewPaddingOf.bottom + 8 + 24` so the last row clears the floating RigTabBar.

B4 (REPLACES sections 4.1, 4.2 first row, A.2 to A.5 of HIGHLIGHTS_AND_COLLAPSE.md): the only collapsing parts are the large title and the strip. Chips, navigators, segmented controls, highlights scroll away with the content like any other row; they do not float or snap back. DROPPED: floating and snap header, chevron reveal toggle in the app bar, `NestedScrollView` with `flexibleSpace`, the 36 dp strip height (now 48 dp), the persisted or session collapsed flag. Implementation: `LargeTitleScaffold` = `CustomScrollView` + a pinned `SliverPersistentHeader` for the bar (height `top inset + 56`) whose collapsed flag is a `ValueNotifier<bool>` flipped when `offset > 6` (root) or `> 34` (pushed); the strip is a second pinned sliver shown only when the flag is true. No `setState` per scroll tick.

B5 (REPLACES B.2, B.3 of HIGHLIGHTS_AND_COLLAPSE.md for the Ledger tab):
- Ring card: `RigCard` (padding 16) with a `Row` that wraps (`Wrap`, spacing 12): `RigRing` 128 dp at 100 percent text scale (`128 * (1 + (scale - 1) * 0.7)`), stroke 18, round caps, track `moneyIn` at 22 percent opacity, progress `moneyIn`, fraction `received / total` clamped 0 to 1 (0 when total is 0), centre label `NN%` (22, 700) over "collected" (11, `lb2`), percent is `round(received / total * 100)`. Right block (flex, min 200 dp): "Received" (15, 600), `MoneyTile` value 28/700 `moneyInText`, "of " + `MoneyTile` Billed + " billed" (13, `lb2`). Ring reveal 900 ms ease-out, off under reduced motion.
- Metric cards: 2 x 2 `RigMetricCard` grid (gap 12, padding 14, radius 20): Total (`accentText`, caption "N bills"), Received (`moneyInText`), Balance (`outstandingText`, caption "still to collect"), Commission (`commissionText`, caption "not part of total"). Label 15/600, value 26/700, caption 13 `lb2`. At 412 dp each card is 180 dp wide, at 360 dp 154 dp. At text scale 190 percent and above the grid becomes 1 column.
- Depth tiles: `DepthTile` in a 3 column grid (gap 12): 7" Depth, 8" Depth, 7" PVC, 8" PVC, MS Pipe; five tiles wrap 3 + 2 (left aligned, the last row keeps the column width). Padding 12 x 10, label 12 `lb2`, value 17/600, `ftq`. At 360 dp each tile is about 99 dp wide. At text scale 190 percent and above: 2 columns (2 + 2 + 1). Side bore: one full width tile "Total Depth" (1 column), no PVC.
- Feet rule: `ftq(n)` = up to one decimal, trailing `.0` hidden (350 ft, 350.5 ft), en-IN grouping, same in the bill card, the summary tiles and the form pre-fill. A sum is rounded to one decimal before the `.0` is hidden (0.1 + 0.2 shows 0.3). Compact L and Cr (feet) is allowed only inside DepthTile after the fit pipeline.
- MoneyText fit pipeline (RigFormat): full value, then scale down to 75 percent, then compact (`₹2.28 L`, `₹22.7 Cr`), last guard shrinks to 11 sp; tap shows the full value in a popover. Compact is ONLY for MoneyTile and RigMetricCard values and the ring card values. Day header totals, bill rows and the status strip never compact (they scale to 75 percent, then 11 sp, then the value moves to its own line).

Side Ledger tab (REPLACES 4.3): RigChipRow (same order), navigator, RigCard "Purchases" (15 `lb2`, hero 44/700 `MoneyTile`, below it Paid `moneyInText` and Pending `outstandingText`, 17/600; "Pending" keeps its name here, answer 10), section title "Categories" (22), CategoryTile 2 column grid (gap 12, radius 28, padding 16, min height 150 dp, gradient from `catDiesel`/`catPvc`/`catBit`/`catHammer` to a 62 percent mix with white, black `onTile` label): icon 30 (`local_gas_station`, `plumbing`, `circle`, `hardware`), name, count line ("N entries, X L" or "N pieces"), `MoneyTile` total, "X pending" when above zero. 1 column at text scale 190 percent and above. Strip: none on this tab.

Bill row (REPLACES `_LedgerEntryCard`, ledger_list.md R2): a RigRow inside the day RigGroup, never an individual card.

Day header: sticky (`SliverPersistentHeader(pinned)` per group, decision C-5; fall back to `sliver_tools` `SliverStickyHeader` if profiling misses the p99 target).

Tab swipe: `TabBarView` physics `NeverScrollableScrollPhysics` (row swipe actions use horizontal drags, see conflicts_r1.md C1); the segmented control is the only way to switch.

States:

| State | Ledger tab | Side Ledger tab |
|---|---|---|
| Default | as above | as above |
| Loading | Skeleton rows (4) after a rig switch or restore, first frame only; title, rig pill and chips stay | two Skeleton tiles 150 dp, radius 28 |
| Empty, no data | EmptyState icon `receipt_long_outlined` 52, "No entries yet", "Tap + to add your first entry.", RigButton "Add entry"; no ring, no tiles | tiles with zeros in `lb2`, no accent |
| Empty, search or filter | "No entries match", "Try a different search or clear the filters.", RigButton "Clear search and filters" (resets `searchQueryProvider` and `ledgerFilterProvider`) | n/a |
| Error | not built (LR-34 default: no failure path) | same |
| Disabled | none | none |

Old section 4 item by item: 4.1 frame CHANGED (R2 above); 4.2 Ledger tab table: compact column CHANGED, expanded (macOS) column DROPPED, "collapse toggle" DROPPED, FAB CHANGED (Add button in the large title row); 4.3 Side Ledger CHANGED (tiles become gradient CategoryTiles, 4-across expanded DROPPED); 4.4 state table CHANGED (above); 4.5 rig switcher CHANGED (RigRigSheet, no popup menu, no `MenuAnchor`); 4.6 motion KEPT with new values: bar fade 200 ms, strip fade 200 ms, scroll to top 250 ms, ring 900 ms, press feedback by ink (`InkWell`, `pressOverlay`, no scale), sheet rise 300 ms, all instant under `MediaQuery.disableAnimationsOf`.

Motion tokens: 200 to 350 ms ease-out; no count-up animations on money.

### R3. Logic touchpoints and LR items

Untouched (still valid): every provider and function in section 5 above (`homeTabIndexProvider`, period, month, year, custom, `isDailyViewProvider`, `searchQueryProvider`, `ledgerFilterProvider`, `groupedLedgerEntriesProvider`, `monthlyStatsProvider`, `feetTotalsProvider`, `calendarDayTotalsProvider`, the side ledger period providers, the four entry providers, `_filterByTimePeriod`, `showDateRangePicker` bounds 2000 to today, tab labels, chip labels, "Daily", "Calendar", the FAB routing now on the Add button).

| Item | Status |
|---|---|
| LR-01 shared `switchRig` (RigRigSheet calls it; also clears the four side filters) | approved |
| LR-03 calendar day tap lists that day's bills | proposed, not in the first pass |
| LR-05 search debounce | not scheduled (search stays live per key) |
| LR-13 feet rule, one decimal | decided; input restriction LR-30 proposed (Q-O5), default is display rounding |
| LR-33 calendar day totals must not mix months | approved, Phase 1 |
| LR-34 loading and error state for lists | proposed, default: skeleton after rig switch or restore only |
| LR-07 persisted collapsed header | no longer needed (no collapsed header state to persist), closed |
| Label rename "Pending" to "Balance" | the Ledger tab and main summary already say Balance; this tab needs no change (Stats Ledger tab rename is in portfolio.md) |
| Proposed, new | none (see `temp/design_wip/logic2_r1.md`) |

### R4. Acceptance criteria delta

REPLACES section 6 items 1, 7 and 9 and ADDS the rest. Run at 360 dp and 412 dp, light and dark, text scale 100, 130 and 200 percent.
1. Collapsed state: pinned height = top inset + 56 + 48 (strip). At 412 x 892 dp with a 28 dp inset it is 132 dp and the list region is at least 700 dp (the floating tab bar overlaps the last 94 dp only at the list end).
2. Scrolling past 6 dp shows the solid bar, hairline, centred 17 dp "Ledger" and the strip; scrolling back to the top removes them. Tapping the strip scrolls to the top in 250 ms (instant with reduced motion).
3. No `setState` per scroll frame (build count of `CombinedHomeScreen` stays flat while scrolling).
4. All stress rows of HIGHLIGHTS_AND_COLLAPSE.md B.6 (as updated by `temp/design_wip/highlights_update_r1.md`) render without overflow at 360 and 412 dp and 100, 130, 200 percent; widths 320 and 900 are dropped.
5. Metric cards 2 x 2 at 100 and 130 percent, 1 column at 200 percent; depth tiles 3 columns (3 + 2) at 100 and 130 percent, 2 columns at 200 percent; side bore shows one tile.
6. Ring percent equals `round(received / total * 100)`, ring is empty when total is 0, and the right block reads "Received" and "of X billed".
7. Feet show up to one decimal with trailing `.0` hidden in the tiles, the bill card and the summary (350 and 350.5).
8. Rig pill opens RigRigSheet (title "Switch Rig", rigs with type, check on the current, footnote "The rig you choose applies to Ledger, Portfolio and Agents.") and the sheet selection runs `switchRig`.
9. The Add button in the title row opens the right form for the rig type on the Ledger tab and the chooser sheet on the Side Ledger tab.
10. A horizontal swipe on a bill row never changes the Ledger/Side Ledger tab.
11. Filter dot appears iff `hasFilters`; the strip shows "Filters on"; active search shows "Search on" in the strip and the "Search: <q>" row.
12. Keyboard open (Search sheet, Filter sheet): the focused field and the primary button stay above the keyboard (sheet bottom padding = `viewInsetsOf.bottom`); the floating tab bar is hidden while the keyboard is open.
13. Android back: closes keyboard, then sheet or dialog, then does nothing on this root tab (root `PopScope(canPop: false)`, Q-O6 open).
14. Every control has a 48 dp hit area; no emoji, no raw colour (`grep` check in the task).

### R5. Parity delta

Changed on purpose: P-LED-5 feet display (one decimal, `.0` hidden), P-LED-6 calendar totals (LR-33, month only), P-NAV-3 (FAB replaced by the Add button in the title row, same routing), P-LED-12 (rig switch through RigRigSheet and `switchRig`, search and filter cleared, plus the four side filters), "Vehicle" copy becomes "Rig", the Side Ledger Pending label is unchanged.
Identical: P-LED-1 to P-LED-4, P-LED-7 to P-LED-11, P-LED-13, P-LED-14, P-SLD-1 to P-SLD-3 (sets of bills, sums, sort order, period state independence, filter and search semantics, picker bounds).

### R6. Performance and Android notes

- Insets: `MediaQuery.viewPaddingOf` for the top bar and the bottom reserve; never hard-code 28 or 24. Edge to edge via `SystemChrome` (T-A12).
- List: one `CustomScrollView`; day groups as slivers with `SliverList.builder` for rows; keys `ValueKey(entry.id)`; no per-card `BoxShadow` (RigGroup has one shadow in light, none in dark).
- Leaf consumers (`_TitleBar`, `_Strip`, `_PeriodControls`, `_Highlights`, `_DayList`) with `select`; `MoneyText` caches `TextPainter` results per (string, style, scale, width).
- Sticky headers: measure in profile mode; budgets p90 build and raster under 8 ms, p99 under 16 ms, janky under 2 percent, tab switch under 100 ms. No `BackdropFilter` inside scrolling content; blur toggle default OFF.
- Dispose: `TabController` (exists), scroll controller and `ValueNotifier<bool>` (new). Lazy tabs apply to Portfolio, Agents and Settings only; Ledger stays built at launch (Q-O3).
