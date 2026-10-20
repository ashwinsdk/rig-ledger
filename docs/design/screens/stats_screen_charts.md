> SUPERSEDED IN PART (2026-10-13): the look is now the Apple-inspired Android direction. Read "Reconciliation 2026-10-13" at the end of this file first; where it conflicts with sections 4 to 7 above, it wins.

# stats_screen_charts (lib/features/stats/stats_screen.dart, 1421 lines, parts owned by group g3)

Scope split. The lead owns: the Portfolio page header (title, rig name, rig switcher B1), the tab bar (Overview / Ledger / Side Ledger) and the Overview tab (`PortfolioView`, lines 154-173): see screens/portfolio.md. This doc owns: (a) the date-range chips and the custom range picker (lines 125-142, 266-298, 300-394, 396-438), (b) the Ledger tab (`_buildSummaryCards` 449, `_buildPieChartSection` 517), (c) the Side Ledger tab (4 mini pie charts 701-971, 4 detailed stat cards 973-1346), (d) private widgets `_SummaryCard` (1349) and `_StatRow` (1411). Range chips and the picker are shared by all three tabs, so the lead's header must host the `PeriodPresetBar` specified here.

## 1. Purpose and primary user task

See how the business did in a chosen period: Ledger tab = total, entry count, received and pending for bills, plus a by-agent share of billed total; Side Ledger tab = for Diesel, PVC, Bit and Hammer purchases how much was paid versus due, counts, litres, and per-type quantities. Task: pick a period, read 4 numbers, see which agent or category dominates.

## 2. Current structure

- `StatsScreen` (ConsumerStatefulWidget, `SingleTickerProviderStateMixin`): `_dateRangeOption` (enum `DateRangeOption`: today, currentMonth, lastThreeMonths, lastSixMonths, lastYear, all, custom), `_customStartDate`, `_customEndDate`, `_touchedIndex`, `_tabController` (length 3, disposed).
- `build` (49): watches `ledgerEntriesProvider`, `dieselEntriesProvider`, `pvcEntriesProvider`, `bitEntriesProvider`, `hammerEntriesProvider` into an unused record `final _ = (...)` (lines 51-58) and `currentVehicleProvider`; then a gradient header Column (title, rig name, pill TabBar, horizontally scrollable range chips), then `TabBarView`.
- Ledger tab: `SingleChildScrollView(padding 16)` > [custom range card when custom, `_buildSummaryCards()` (2x2 `_SummaryCard`s: Total, Entries, Received, Pending), `_buildPieChartSection()` ("By Agent" donut 200 dp + text legend rows)].
- Side Ledger tab: 2x2 grid of mini donut cards (Diesel, PVC, Bit, Hammer; PVC hidden for side bore, grid becomes 3 with an empty `Expanded`), heading "Detailed Statistics" (18 sp), 4 `_buildStatsCard`s (title, count, key/value rows) or `_buildEmptyStatsCard`.
- Each `_buildX` helper calls `ref.watch(<provider>)` itself, calls `_getDateRange()` (reads `DateTime.now()` each time), filters the whole list with `_filterByDateRange`, and aggregates in a loop, all inside `build`.
- Colors: `AppColors.chartColors` (8 blue/teal tones) for agent slices, `AppColors.success`/`warning` for Paid/Due slices, category icon colors: Diesel warning amber, PVC primary (mini) and accent (stats card), Bit success, Hammer error (mini and stats card).

## 3. Problems found

Rebuild cost and the unused-record pattern
1. `final _ = (ref.watch(...) x5)` (51-58) is dead code: every `_buildX` helper already watches its own provider. Its only effect is that the ENTIRE screen (header, tabs, all three tab bodies as built by `TabBarView`) rebuilds when any of five providers changes, including `pvcEntriesProvider` while the user looks at the Ledger tab. Also `ignore: unused_local_variable` hides the analyzer. Remove in implementation; scoped `Consumer`s per tab replace it.
2. `_touchedIndex` is a State field changed via `setState` inside the pie `touchCallback` (603-614). On macOS hover generates continuous `FlPointerHoverEvent`s, so every mouse move over the donut rebuilds the whole stats screen (header, chips, all tabs) and re-filters and re-aggregates every list (`_buildSummaryCards`, `_buildPieChartSection`). On mobile it rebuilds on touch drag. This is the largest perf risk on the page.
3. Aggregation in `build`: each of 11 builders filters the full provider list (O(n) with closure allocations) and `_getDateRange()` is called 11 times; the tab is rebuilt on each chip tap. With 5,000 bills this costs ms per frame while hovering.
4. `NumberFormat('#,##0.00')` constructed 6 times per build (466, 571, 1001, 1060, 1120, 1180).
5. `.asMap().entries.map(...)` for the legend (642) allocates per rebuild; `List.generate` for sections each time.

Charts and accessibility
6. Color-only slice identification: the By Agent donut shows no labels on slices (title empty unless touched, 628). The only link between a slice and an agent is a 12 x 12 swatch in the legend; with 8 blue/teal tones this is not distinguishable: #252B49 vs #315D9A luminance ratio 2.08, #315D9A vs #4A6FA5 1.30, #618DCE vs #7BA3D3 1.29. Adjacent slices of similar hue are unreadable, especially for color-blind users and in grayscale.
7. The palette modulo 8 (626, 656) repeats colors from the ninth agent: two agents get the same swatch and slice color; there is no "Other" grouping.
8. Slice contrast against the white card: #B7CDED (gradient5) is 1.62:1 and #7BA3D3 2.62:1, below the 3:1 needed for graphical objects. The touched label is white 12 sp bold on slice colors (630-634): white on #B7CDED is 1.62:1, unreadable.
9. Touch-only percentage: the donut only reveals a percentage while touched (628). Keyboard and screen-reader users cannot read it; the legend does show amount and percent (good) so the information exists as text, but the chart itself has no `Semantics` label. No `semanticsLabel` summarizing "By agent: A 40 percent, B 25 percent...".
10. Mini Paid/Due donuts (859-971): slice colors `success` #10B981 and `warning` #F59E0B have a luminance ratio of 1.18:1 (almost identical lightness): deuteranopia and tritanopia cannot tell them apart; the labels "Paid" and "Due" sit under the chart in a Row (spaceAround) without swatches, so the mapping slice-to-label is positional guesswork. Label texts are 10 sp and values 11 sp (934, 941), below the 11 sp floor, and the amounts are not shown at all, only percents.
11. Amount percentages: `entry.value / total * 100` (622, 645) produces NaN% when the by-agent total is 0 (for example bills with total 0 only). `NaN.toStringAsFixed(1)` prints "NaN". Also negative totals would give negative slice values (fl_chart ignores/clips). Display bug in the legend: "NaN%".
12. Mini charts: `centerSpaceRadius: 20`, `radius: 18` in a 80 dp box (900-921): the ring is 18 dp thick; hit area for touch is irrelevant (no touch). When a category has only paid or only due the ring is a single color with no outline.
13. Center-of-donut empty: no total or label inside the ring; "By Agent" donut has `centerSpaceRadius: 50` empty. A center label (total) would use the space.
14. Category colors are inconsistent between the mini donut icon and the detailed card: Diesel amber (710) vs primary (1006); PVC primary (737) vs accent (1067); Bit green both; Hammer red both. Hammer in `error` red and Bit in `success` green reuse semantic status colors as identities, so a red Hammer tile looks like a problem and a green Bit icon sits beside the green "Paid" slice.

Text scale and layout
15. Legend row (647-690): name `Expanded`, amount `Text` (no flex), fixed `SizedBox(width: 50)` percentage. At 200 percent the percentage "100.0%" (14 sp x 2 = 28 sp bold) is about 90 dp wide in a 50 dp box and wraps character by character; the amount (`₹1,23,456.00` about 130 dp at 28 sp) takes most of the row so the agent name collapses to a few characters. Real layout bug at large text. 
16. `_StatRow` rows (1320-1342): `Row(spaceBetween)` with two `Text`s and no `Flexible`: label "Total Amount" + value `₹12,34,567.00` at 200 percent exceeds the card width (about 294 dp inner) and throws a RenderFlex overflow. 
17. `_SummaryCard` (1349-1409): value is in `FittedBox(scaleDown)` at 20 sp: at 200 percent the amount scales down to fit half of the screen width (about 150 dp), which makes the largest number the smallest visible text. Title 12 sp `textSecondary`. Each card is half width (2 columns) even at 1280 dp wide macOS windows (no max width: the content wrapper does not constrain, see core doc).
18. Mini donut cards in a 2-column grid at compact: each card is about 158 dp wide minus 24 padding = 134 dp inner; at 200 percent title row (icon 18 + 8 + "Hammer" at 28 sp) fits, but "Paid"/"Due" columns spaceAround at 10-11 sp scaled 2x fit barely. UNVERIFIED on device.
19. When the rig is side bore the grid has an empty `Expanded(SizedBox())` cell (213): an unbalanced layout with a hole.
20. "Pending" on the Ledger tab sums `balance` (506); the rest of the app (ledger list, PDF) says "Balance". Business label "Balance" must keep meaning, so the label divergence is an inconsistency (not changed here; the label stays as is unless the developer confirms, see incons_g3.md).
21. Range chips (266-298): `GestureDetector` pills 13 sp, about 34 dp tall (8 + ~18 + 8), no semantics, no focus ring, selected state = white fill vs 20 percent white fill (color only; also selection weight change). Tap area under 48 dp. Chips live inside a horizontally scrollable row with no fade: "Custom" and "All" can be clipped (known issue: "All" cut to "Al" on 360 dp, see PROGRESS screenshots 01/05).
22. "Day" chip means today only (403-404), "Year" means from the first of this month last year to the end of this month (13 months) (426-431) and "3 Mo"/"6 Mo" include the current month: the labels do not explain the range. The actual range is nowhere displayed (no caption "1 Oct 2026 to 31 Oct 2026").
23. Custom range picker (300-374): two tappable texts with a `Icons.arrow_forward` between, no border, no visible field affordance, tap area about 40 dp tall; From after To is allowed and silently shows empty data; `firstDate 2000`/`lastDate 2100`; date text 14 sp w500 `onSurface`. The same card is rendered once per tab (three copies).
24. Empty states: By Agent shows a 48 dp icon plus two lines (531-565) but the hint color is `textHint` #94A3B8 2.56:1; mini cards show "No data" 12 sp `textHint`; detailed cards show "No entries in selected period". Three different empty patterns, none with a "change period" action.
25. Cards use `BoxShadow(blur 10)` x about 12 per Side Ledger tab (all inside a `SingleChildScrollView`, not lazily built): raster cost and no virtualization. The Side Ledger tab builds all 8 cards at once.
26. Currency: `NumberFormat('#,##0.00')` with literal rupee sign everywhere (466 and others): western grouping, differs from PDFs ("Rs.").
27. PVC/Bit/Hammer "type counts" (1048-1058): an entry with several types adds `entry.count` to EACH type's tally while `totalCount` adds `entry.count` once, so the per-type pcs can sum to more than Total Count. UNVERIFIED semantics (if `count` is per type this is right; if it is the entry total it overstates). Logged for the developer, not changed.
28. The tab content has no max width on macOS (content wrapper only removes padding): on a 1280 dp window the 2x2 summary cards become 560 dp wide each with a tiny number.

## 4. Redesign

### 4.1 Period selection (shared by Overview, Ledger, Side Ledger)

New component `PeriodPresetBar` (see components_g3.md; it generalizes `RigChipRow`) replaces `_buildRangeChip` and the custom picker. It sits directly under the lead's tab bar inside the header area on compact, on a `surface` band with a 1 px `outlineVariant` bottom border (NOT on the gradient: the chips are no longer white-on-gradient; this removes the 2.7:1 white 80 percent text issue).

- Chips (same order, same labels and same `DateRangeOption` mapping): Day, Month, 3 Mo, 6 Mo, Year, All, Custom. `ChoiceChip`, visual height 32, hit target 48, label `labelLarge`, selected = `primaryContainer` fill + `primary` label + check icon (`Icons.check_rounded` 16), unselected = `surface` fill + 1 px `outlineVariant` + `onSurface` label.
- Compact (<600): horizontally scrollable `ListView` with 8 dp gaps, 16 dp edge padding and a 24 dp fade on the trailing edge (`ShaderMask`), and the selected chip is scrolled into view (`Scrollable.ensureVisible`) so "All" or "Custom" is never cut. Medium and expanded: all 7 chips fit in one row (`Wrap`, no scroll).
- Range caption directly under the chips, `bodySmall` `onSurfaceVariant`, one line: "1 Oct 2026 to 31 Oct 2026" (computed from the same `_getDateRange()` result; for All: "All time"). Gives meaning to Day, Year, 3 Mo, 6 Mo without changing their ranges. Wraps at large text.
- Custom: when selected, a `CustomRangeRow` appears under the caption (all tabs, rendered once in the header region, not per tab): two `RigDateField`s "From" and "To" side by side (stacked below 360 dp or at text scale >= 1.5), 56 dp each, icon `Icons.calendar_today_rounded`, text `dd MMM yyyy`; From after To shows an inline error "From date must be on or before To date" (display only; the data range logic is unchanged and the computed range is used as today). The default custom range stays first of this month to today as today.
- Desktop: chips are keyboard focusable (Left/Right moves, Space selects), hover `surfaceContainerHigh`, picker opens `showDatePicker` as a dialog.

The lead writes the header; this doc fixes the contract: the header hosts `PeriodPresetBar` + `CustomRangeRow` bound to the existing State fields `_dateRangeOption`, `_customStartDate`, `_customEndDate` and exposes `_getDateRange()` unchanged.

### 4.2 Ledger tab

Layout compact: `ListView` (padding 16, gap s3):
1. `SummaryGrid` of 4 `AmountTile`s in a 2 x 2 grid (gap s3): Total (tone neutral, `primary` value), Entries (count, `onSurface`), Received (`moneyIn`), Pending (`outstanding`; label stays "Pending" in this tab, see inconsistency note). Each tile: label `labelMedium` `onSurfaceVariant`, value `amountLarge` tabular with `AmountText` (`compact: auto`: values >= 1,00,000 show compact only when the tile is narrower than the full text at current text scale; tapping a compact tile shows the full value in a tooltip/sheet), min height 88, never a fixed height. At text scale >= 1.5 the grid becomes one column.
2. `ChartCard` "By Agent" (`RigCard`, padding s4): header `titleMedium` + `bodySmall` "N agents" caption; donut 200 dp (size = `min(200, width)`), `centerSpaceRadius` 56, center label: `labelMedium` "Total" and `amountMedium` of the period total (exact existing `total` sum); `sectionsSpace` 2 with `surface` gaps; slice colors `chartSeries[i]` with i in 0..5; beyond 6 agents the 7th onward are rendered in the existing legend but share the color `chartSeries[6]` ("Other agents" is NOT created because it would change the grouping logic; instead the legend rows beyond 6 show a hollow swatch with the index number so rows stay distinguishable; logic request for true Other grouping in logic_g3.md).
   - Legend (text rows, always visible, replaces color-only identification): `RigListRow` dense (min height 48): leading swatch 12 dp rounded square (same `chartSeries[i]` color as its slice), rows ordered by value descending exactly like the slice order; name `bodyMedium` (2 lines allowed), trailing column: amount `amountSmall` and percent `bodySmall` stacked right-aligned (stacked, not side by side, so no fixed 50 dp box). Percent uses the same `toStringAsFixed(1)`; if total is 0 the percent shows "0.0%" via a display guard `total > 0 ? value / total * 100 : 0` (UI guard to avoid NaN; the number semantics for total > 0 are unchanged).
   - Tapping or hovering a legend row highlights the slice (sets the existing `_touchedIndex` through a `ValueNotifier<int?>`, not setState) and vice versa; focus on a legend row also highlights it, giving keyboard parity. Touched slice shows its percent label in `onPrimary` ONLY when the slice color has >= 4.5:1 with white; otherwise the label renders `onSurface` outside the ring via the center label (center label switches to "<agent> 40.0%").
   - Chart `Semantics(label: 'By agent share of total: A 40.0 percent, B 25.0 percent, ...')` built from the same data (first 6 then "and N more").
   - Empty: `EmptyState(icon: Icons.pie_chart_rounded 48, title: 'No data available', hint: 'Add ledger entries to see statistics', action: TextButton 'Change period')`.

Expanded (>900): content max 1100; summary tiles in one row of 4; the "By Agent" card splits horizontally: donut left (40 percent), legend right (60 percent) with scrollbar when more than 8 rows.

### 4.3 Side Ledger tab

1. Category overview: `CategoryGrid` of 4 (3 for side bore, grid centers the remaining tiles with `Wrap` alignment center, so no empty hole) `ChartCard`s. Each mini card: header icon in a 32 dp circle `categoryX container` with glyph `categoryX` + title `titleSmall`; donut 96 dp (ring thickness 14, `centerSpaceRadius` 28) with center text Paid percent (`labelMedium`); slices: Paid = `moneyIn`, Due = `outstanding` PLUS a distinguishing pattern: Due slice gets a 2 dp `surface` stroke and the legend swatches differ in shape (Paid filled circle, Due hollow ring) so lightness similarity does not matter. Below the ring a 2-row text legend: `[swatch] Paid  Rs. amount  NN%` and `[swatch] Due  Rs. amount  NN%` (`bodySmall` 12 sp label, `amountSmall` value) stacked in a `Column`, so values are visible (they are `totalPaid` and `totalPending` already computed). Minimum text size 12 sp (was 10 and 11).
   - Category identity colors `categoryDiesel`, `categoryPvc`, `categoryBit`, `categoryHammer` (DESIGN_SYSTEM section 3.2) are used for the icon circle AND the detailed card so the same category looks the same in both places; none of them is a status color (Hammer no longer red, Bit no longer green).
   - Grid: compact 2 columns (`childAspectRatio` is NOT used; each tile sizes by content in a `Wrap` of equal-width children `(width - 12) / 2`); at text scale >= 1.5 one column. Medium 2 columns, expanded 4 columns at max width 1100.
   - Empty mini card: icon + "No data" (`bodySmall` `textMuted`) and no donut; the card keeps the same height as filled cards (min height 180) so the grid does not jump when the period changes.
2. "Detailed Statistics" heading (`titleMedium`) then `DetailStatCard`s: header row (icon circle, title `titleMedium`, "N entries" `bodySmall`) and key/value rows via `MoneyLabelValueRow`: label `bodyMedium` `onSurfaceVariant` (`Expanded`, wraps), value `amountSmall` right-aligned (`Flexible`, wraps under the label if needed at large text). Paid value `moneyIn`, Pending value `outstanding`, others `onSurface`. Per-type rows (e.g. "7 inch") are indented 16 dp, `bodySmall`. Empty detailed card: single row "No entries in selected period" with `Icons.inbox_rounded` and a `TextButton` "Change period" that scrolls to the top/focuses the chips.
3. Expanded: detailed cards in a two-column `Wrap` (max 1100), same card widths.

### 4.4 Chart rules (applies to both tabs)

- Series colors only from `chartSeries[0..5]` and category tokens; no gradients, no shadows; slice gap 2 px `surface`.
- Text on slices: none; all numbers are in the legend rows or the center.
- Animation: fl_chart `swapAnimationDuration` 200 ms (`base`) with `Curves.easeOutCubic`; zero when `MediaQuery.disableAnimationsOf`.
- Never rely on hover for information: the legend and center label are the accessible equivalents.
- Max donut size 220 dp on wide screens.

State table
| State | Ledger tab | Side Ledger tab |
|---|---|---|
| Default | 4 tiles + By Agent | 4 mini cards + 4 detail cards |
| Loading | n/a (providers are synchronous); tiles show skeleton only if a provider reports loading (none today) | same |
| Empty | tiles show zeros; By Agent `EmptyState` | mini cards "No data"; detail cards empty row |
| Error | n/a (no async); invalid custom range inline error | same |
| Disabled | Custom chip focus when the range is invalid keeps data empty | same |

Motion: chip selection 150 ms; donut 200 ms; tab content cross-fade handled by the lead's tab bar.

Tokens: spacing s1 s2 s3 s4 s6; radius lg (cards), md (tiles), sm (chips), full (swatches); type titleMedium, titleSmall, bodyMedium, bodySmall, labelMedium, labelLarge, amountLarge, amountMedium, amountSmall; colors primary, primaryContainer, surface, surfaceContainer, onSurface, onSurfaceVariant, textMuted, outlineVariant, moneyIn, outstanding, chartSeries[0..5], categoryDiesel/Pvc/Bit/Hammer and their containers.

Components: `PeriodPresetBar`, `CustomRangeRow`, `RigDateField`, `AmountTile`, `AmountGrid`, `AmountText`, `ChartCard`, `DonutChart` (new wrapper around fl_chart `PieChart`), `ChartLegendRow`, `CategoryTile` (existing catalogue entry, used for the mini card header), `DetailStatCard`, `MoneyLabelValueRow`, `EmptyState`.

## 5. Logic touchpoints that must stay untouched

- `DateRangeOption` enum values and meaning; `_getDateRange()` exactly (today, current month, last 3 and 6 months, "lastYear" = first day of this month last year to end of this month, all = 2000 to 2100, custom with defaults); `endOfDay` 23:59:59.999; custom default (first of month to now).
- `_filterByDateRange` (inclusive of start and end), the aggregation sums: `total`, `received`, `balance` per bill; agent totals by `agentName` (not id); diesel `litre`, `total`, `paid`, `pending`, avg rate `totalAmount / totalLitres` when litres > 0; PVC/Bit/Hammer `types ?? [type]` per-type tally with `entry.count`, `total`, `paid`, `pending`, `count`.
- Provider reads: `ledgerEntriesProvider`, `dieselEntriesProvider`, `pvcEntriesProvider`, `bitEntriesProvider`, `hammerEntriesProvider`, `currentVehicleProvider`, `isSideBoreProvider` (PVC hidden for side bore in charts and stats).
- `PortfolioView(start:, end:)` receives `null, null` for All and the computed range otherwise (lead's area; this doc only guarantees the same State fields feed it).
- Labels: "Total", "Entries", "Received", "Pending", "By Agent", "Detailed Statistics", "Paid", "Due", "Total Litres", "Total Amount", "Avg Rate", "Total Count", "Total Value", "pcs", "L".

## 6. Acceptance criteria

1. For a fixed data set, each of the 7 chips shows the same totals, counts, agent shares and category figures as before the redesign (compare Total, Received, Pending, Entries, every agent percent, every Paid/Due percent and all detail rows).
2. The range caption under the chips equals the actual range used: Month shows the first and last day of the current month; Day shows today twice or once; All shows "All time".
3. "All" and "Custom" chips are fully visible or scrolled into view on a 360 dp wide screen; no chip text is clipped at 100, 130 or 200 percent text scale.
4. Selecting a chip never changes tabs; Custom shows From/To fields once (not once per tab); From after To shows an inline error and the tabs show empty data.
5. Hovering the By Agent donut on macOS does not rebuild the header or the other tab (verify with the Flutter performance overlay: rebuild count of the header stays 0 during hover).
6. By Agent legend rows show name, amount and percent as text; hovering or focusing a row highlights its slice; the center label shows the highlighted agent and percent.
7. With zero total the legend shows "0.0%" (never "NaN%").
8. With 7 or more agents every legend row is still visually distinguishable (number or hollow swatch) and the donut uses `chartSeries` only.
9. Each mini category donut shows Paid and Due amounts and percents as text with different swatch shapes; text is at least 12 sp.
10. The same category has the same icon color on the mini card and the detail card; Hammer and Bit do not use red or green.
11. At text scale 200 percent no legend row, tile or stat row overflows or wraps one character per line; tile values are never scaled below 70 percent.
12. Side bore rig: only three category tiles, centered, no empty cell, and no PVC anywhere.
13. All chips, tiles with actions, legend rows and date fields are at least 48 dp on mobile.
14. Screen readers announce each chart's `Semantics` label and each chip as "<label>, selected/not selected".
15. No `Colors.*`, hex, `AppColors.*` or `BoxShadow` remains in the owned parts.

## 7. Performance notes

- Delete the unused `final _ = (...)` record. Make each tab a separate `ConsumerWidget`: `LedgerStatsTab` watches only `ledgerEntriesProvider`; `SideLedgerStatsTab` watches the four side providers; each takes `(start, end)` as parameters. A `Provider.family` for the aggregates would be a provider change (logic freeze): instead compute aggregates inside the tab widget with a small pure function `LedgerStatsAggregate.from(entries, start, end)` memoized by a State-held cache (no new package): keep `_lastInputs` identity (`identical(entries, _lastEntries) && start == _lastStart && end == _lastEnd`) and reuse the result in State.
- Hover/touch state: `ValueNotifier<int?> highlightIndex` consumed by a `ValueListenableBuilder` around `DonutChart` and the legend only. No `setState` in `touchCallback`.
- Wrap each donut in `RepaintBoundary`; rebuild only when sections list changes (`ListEquality`).
- `_getDateRange()` once per build of the header, passed down; `NumberFormat` is `static final` (`RigFormat`).
- Side Ledger tab: replace the eager `SingleChildScrollView(Column)` of 8 cards by `CustomScrollView` with `SliverGrid`/`SliverList` (detail cards lazy). Cards use no shadows (tonal border).
- `fl_chart` ^0.66: pass `const` where possible; keep `sections` creation out of `build` through the memoized aggregate.


## Reconciliation 2026-10-13 (Apple look, Android only)

Scope is the same as the top of this file: range chips and the custom range (shared by the three Portfolio tabs, the lead's `portfolio.md` hosts the header), the Ledger tab (donut) and the Side Ledger tab. Sources: `portfolioTab` (branches `P.tab==1` and `P.tab==2`), `donut`, `mcard`, `chips`, `PRR`, `AGC`, registry group "Portfolio".

### R1. Mockup screens and Flutter mapping

| Mockup screen (J label) | Render function | Flutter file | Widgets | Notes |
|---|---|---|---|---|
| Ledger tab (donut) | `portfolioTab()` with `S.pr.tab==1` | `lib/features/stats/stats_screen.dart` (the Ledger tab: `_buildSummaryCards`, `_buildPieChartSection`) | RigSegmented (Overview, Ledger, Side Ledger, hosted by the lead), RigChipRow (range), RigGroup + RigFormRow (From, To when Custom), RigMetricCard x4 (2 columns), RigCard "By agent" with a donut (RigRing segments), legend RigRows, EmptyState | tab label of the pending metric becomes "Balance" |
| Side Ledger tab | `portfolioTab()` with `S.pr.tab==2` | same (`_buildMiniPieChart` x4, `_buildStatsCard` x4) | RigMetricCard-style category cards with a Paid and Due donut, RigGroup detail lists, CategoryTile colours (`catDiesel`, `catPvc`, `catBit`, `catHammer`), EmptyState text rows | PVC hidden on side bore rigs |
| Overview, Overview (agent filter), Portfolio loading | `portfolioTab()` `P.tab==0` | `portfolio.md` (group r1) | not covered here | the range chips and Custom rows above are shared with it |

### R2. What changes in the redesign (supersedes section 4)

Shared header (hosted by `portfolio.md`): large title "Portfolio", the rig pill (B1), RigSegmented, then the range chips (RigChipRow, 48 dp boxes, inverse selected chip, horizontal scroll with the selected chip scrolled into view so "All" and "Custom" are never clipped at 360 dp). Chip order in the mockup is Day, Month, 3 Mo, 6 Mo, Year, All, Custom; answer 5 fixes the order Month, 3 Mo, 6 Mo, Year, Custom, All and leaves Day to Q-O1; the order follows answer 5 (conflict C-r2-4). Labels and the `DateRangeOption` mapping are unchanged. A one line caption under the chips (t13 `labelSecondary`, for example "1 Oct 2026 to 31 Oct 2026", "All time") is KEPT from old section 4.1 although the mockup does not draw it (it explains Day, Year, 3 Mo, 6 Mo; same `_getDateRange()` result). Custom shows once, in the header, as a RigGroup with two rows "From" and "To" (value "Select date" in `labelSecondary`, date `d MMM yyyy`), 48 dp rows; From after To shows an inline caption "From date must be on or before To date" (display only). Custom picker range stays 2000 to 2100 (no clamp needed; `pickRigDate` clamps anyway).

Ledger tab, top to bottom (margin 20, gap 12):
1. Grid of four RigMetricCards (2 columns, one column at text scale 200): Total (icon `account_balance_wallet_outlined`, value `accentText`), Entries (count, plain integer), Received (`moneyInText`), Balance (icon `pending_outlined`, value `outstandingText`). Radius 20, padding 14. Money values are highlight tile values (fit pipeline, compact `L` or `Cr` allowed, tap shows the full value). The label "Pending" becomes "Balance" on this tab ONLY (answer 10): one string change in `_buildSummaryCards` (`title: 'Pending'` at stats_screen.dart line 505); the value is still the sum of `balance`. The mockup still prints "Pending" here (conflict C-r2-5); the brief wins.
2. Card "By agent" (RigCard, padding 16, title t17 600): donut 150 dp wide, centred, margin 10 dp vertical: outer radius 56 dp, ring thickness 13 dp (the mockup ring is 14 of 60 units in a 160 unit box), 2 unit gap between slices, no text on slices, no hole text (the old center label idea is DROPPED, the mockup has none). Slices in descending total order from the colour list `accent`, `moneyIn`, `outstanding`, `commission`, `catPvc`, `catHammer` repeating after six agents (mockup `AGC`).
3. Legend rows under the donut, always visible, one per slice in the same order, 48 dp min height: dot 8 dp (same colour as its slice), agent name t15 (up to 2 lines), amount t13 `labelSecondary` (full money, never compact in a row), share t15 700 `accentText` right aligned with a minimum width 56 dp (not a fixed 44 dp: "100.0%" at 200 percent needs more). Share keeps one decimal like today (`toStringAsFixed(1)`), the mockup rounds to a whole number (conflict C-r2-6). If the total is 0 the share is "0.0%" (UI guard against "NaN%").
4. Accessible legend: each row exposes `Semantics(label: '<agent>, <amount>, <share> percent of total')`; the donut itself is `ExcludeSemantics` with one summary label "By agent share of total: A 40.0 percent, B 25.0 percent, and N more"; rows beyond the sixth colour show the row number inside a hollow dot so that two agents with the same colour stay distinguishable.
5. Empty: EmptyState (`pie_chart_outline`, "No data available", "Add ledger entries to see statistics.") instead of the donut card; metric cards show zeros.

Side Ledger tab:
1. Grid (2 columns, 1 column at text scale 200) of up to four category cards, order Diesel, PVC, Bit, Hammer, PVC removed on side bore rigs (three cards: the third spans the row centred, no empty cell). Card: RigCard radius 20, padding 14, header icon 18 dp in the category colour (`local_gas_station` `catDiesel`, `view_column` `catPvc`, `circle` `catBit`, `hardware` `catHammer`; mockup glyphs) and name t15 600; donut 96 dp: outer radius 36 dp, ring thickness 24 dp, hole radius 12 dp (units: ir 20 in the 160 box), slices Paid `moneyIn` and Due `outstanding`; below, one row `Paid <N>%` (`moneyInText`) at the left and `Due <N>%` (`outstandingText`) at the right, t12. Percent is a whole number, as today (`toStringAsFixed(0)`). With no data (paid + pending = 0) the card shows "No data" (t13, centred, 34 dp padding) instead of the ring and keeps its height.
2. Accessible legend: the row text carries the words Paid and Due, so colour is never the only signal; swatches use different shapes (Paid filled disc, Due hollow ring) for the legend and the ring slice for Due gets a 2 dp `surface1` stroke; the card has `Semantics(label: '<Category>: paid <N> percent, <amount>; due <N> percent, <amount>')`. Minimum text size 12 sp (old 10 and 11 sp text is DROPPED).
3. Section title "Details" (t22 700), then one RigGroup per category: first row = category name (600) and "N entries" (`labelSecondary`); rows then show Diesel: Total litres (`qty` + " L"), Total amount, Average rate (`money` + " per L", "--" when litres are 0); Bit, Hammer and PVC: Total count (N + " pcs"), Total value; all: Paid (`moneyInText`), Pending (`outstandingText`). The per type pieces rows of the current code (indented `<type>: N pcs`) are KEPT after Total count (the mockup omits them, conflict C-r2-7; P-stats 54 requires them). Amounts in rows are full money (answer 3), never compact. Empty: a single row "No entries in selected period".
4. "Pending" stays "Pending" on this tab (answer 10 applies to the Ledger tab only).

Old section 4 item by item: 4.1 Period selection CHANGED (`PeriodPresetBar` becomes RigChipRow, gradient band DROPPED, order per answer 5, caption KEPT, CustomRangeRow becomes the From and To RigGroup); 4.2 Ledger tab CHANGED (RigMetricCards, donut centre label DROPPED, legend rows CHANGED, "Balance" label); 4.3 Side Ledger tab CHANGED (mini donut cards per the mockup, `CategoryGrid` expanded columns DROPPED, category colours per answer 8); 4.4 Chart rules KEPT in part (no shadows, no text on slices, animation 200 ms off with reduced motion, legend is the accessible equivalent; hover rules and max 220 dp on wide screens DROPPED).

States:

| State | Ledger tab | Side Ledger tab |
|---|---|---|
| Default | 4 metric cards + By agent | 4 (or 3) category cards + Details |
| Loading | Skeleton only on the first visit build (lazy tab, answer 12); no provider state (C-3, LR-34 proposed) | same |
| Empty | zeros in the cards, EmptyState instead of the donut | "No data" in each card, "No entries in selected period" in each detail group |
| Error | none; invalid Custom range shows the inline caption | same |
| Disabled | none | none |

Motion: 200 to 350 ms ease-out; the donut and bars reveal once on first build; ink press feedback on chips and cards; everything off under reduced motion.

### R3. Logic touchpoints and LR items

Untouched (section 5 stays): `DateRangeOption` and `_getDateRange()` (Day = today, Month, 3 Mo, 6 Mo, Year = first of this month last year to end of this month, All = 2000 to 2100, Custom default first of month to today), `_filterByDateRange` (inclusive), every aggregation (total, received, balance per bill, agent totals by `agentName`, diesel litres, total, paid, pending and average rate, side ledger per type tallies), provider reads, PVC hidden on side bore, the `PortfolioView(start, end)` hand-over.

LR and findings:
- Rename "Pending" to "Balance" on the Ledger tab: a label change, answer 10, no logic.
- LR-29 proposed: the Side Ledger tab Pending and the donut Due slice sum signed `pending`, so advances reduce them (code verified at stats_screen.dart lines 714 to 807 and 991 to 1056). The mockup shows the same netting. First pass ships the code behaviour. If approved, Pending and Due use only entries with `pending > 0` and a new row "Advances" (`moneyInText`) appears in each Details group only when advances exist; Paid percent then uses `paid / (paid + due)`. This changes the numbers of P-stats 54, so it needs the yes. The Due slice must be drawn with `max(0, value)` so a negative sum cannot break the ring (UI guard, the printed percent is unchanged).
- LR-34 proposed: no loading or error state is built.
- New, proposed: L2-r2-2 (per type pieces in Details use `entry.count` of the whole entry for EACH type, which overstates multi type bills; this is a wrong number). See `temp/design_wip/logic2_r2.md`.
- LR-21 and LR-22 (insight cards) are the Overview tab, not this file.

### R4. Acceptance criteria delta

1. The Ledger tab card label reads "Balance" and the value equals the sum of `balance` for the range; the Side Ledger tab still reads "Pending".
2. For fixed data each range chip shows the same Total, Entries, Received, Balance, agent shares and category Paid and Due percents as before (parity 52 to 54, with "Pending" renamed on the Ledger tab only).
3. The chip row shows all chips or scrolls the selected one into view at 360 dp and 412 dp, text scale 100, 130, 200; "All" and "Custom" are never cut.
4. The By agent legend lists every agent with name, amount and share as text; at text scale 200 no row overflows and the share is not wrapped by characters; with total 0 it shows "0.0%".
5. With 7 or more agents every legend row is distinguishable (numbered hollow dot after the sixth colour).
6. Each category card shows words and percents for Paid and Due, 12 sp minimum, swatch shapes differ; the screen reader reads the summary label.
7. Category colours match the lists and tiles: Diesel orange, PVC teal, Bit purple, Hammer pink; none is red or green.
8. Side bore rig: three category cards, third centred, no PVC anywhere.
9. Light and dark: slice and text colours come from RigColors; slice versus card contrast at least 3 : 1 for the ring colours used (`moneyIn`, `outstanding`, category colours) and 4.5 : 1 for text.
10. Metric cards compact only in the highlight tiles with the full value on tap; rows and legends never compact.
11. Android back from the tab follows the root tab rule of the shell; Custom pickers close first.

### R5. Parity delta

Intentional: P-stats 52 label "Pending" becomes "Balance" on the Ledger tab; slices and legend use the new colours; Rs. and the rupee sign follow LR-24; the Side Ledger tab shows Paid and Due as percents in the cards and amounts in Details (unchanged data). Identical: P-stats 53 (agent shares, order by total descending, sums about 100), P-stats 54 (Detailed values, including per type pieces), 55, 56, 57.

### R6. Performance and Android notes

- Portfolio is a lazy tab (answer 12): built on first visit, then kept alive. Delete the unused `final _ = (ref.watch(...) x5)` record; give each tab its own `ConsumerWidget` watching only its providers; compute the aggregates once per input change (memoised by identity of the lists, `start`, `end`), `_getDateRange()` once per header build.
- No touch handler on the donut (the mockup donut is static): with fl_chart set `PieTouchData(enabled: false)` or draw the ring with a `CustomPainter`; either way the `_touchedIndex` `setState` per touch is gone and nothing rebuilds the header on touch. Wrap each ring in a `RepaintBoundary`.
- `CustomScrollView` with `SliverGrid` and lazy detail groups instead of one eager column; no `BoxShadow` blur and no `BackdropFilter` in scrolling content. Targets: p90 build and raster under 8 ms, p99 under 16 ms, tab switch under 100 ms.
- Insets: pad the bottom with the floating tab bar height (62) + `viewPaddingOf.bottom` + 8 + 24. `NumberFormat` becomes `RigFormat` statics.
