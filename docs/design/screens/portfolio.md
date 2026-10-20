> SUPERSEDED IN PART (2026-10-13): the look is now the Apple-inspired Android direction. Read "Reconciliation 2026-10-13" at the end of this file first; where it conflicts with sections 4 to 7 above, it wins.
# Portfolio page (including B1: change the rig)

Matched files: `lib/features/stats/stats_screen.dart` (class `StatsScreen`, header lines 59-134, tabs Overview / Ledger / Side Ledger, range chips) and `lib/features/portfolio/portfolio_view.dart` (Overview tab). Bottom-nav and sidebar label is "Portfolio"; the file name still says Stats. The Ledger and Side Ledger stat tabs and charts are specified in `screens/stats_screen_charts.md` (written by the charts audit).

## 1. Purpose and primary user task

See how the business is doing for a period: total billed, received, pending, commission, expenses and profit; filter by agent; compare one rig or all rigs. Secondary: see charts per category.

## 2. Current structure

- `StatsScreen` (ConsumerStatefulWidget, `SingleTickerProviderStateMixin`): `Column[gradient header Container, Expanded(TabBarView)]`. Header holds title "Portfolio", plain-text rig name (`currentVehicleProvider`, not tappable), a white-pill `TabBar` (Overview, Ledger, Side Ledger), a horizontal row of range chips (Day, Month, 3 Mo, 6 Mo, Year, All, Custom). Local state: `_dateRangeOption`, `_customStartDate`, `_customEndDate`, `_touchedIndex`.
- `PortfolioView`: `SingleChildScrollView` with `This rig / All rigs` `SegmentedButton<bool>` (local `_allRigs`), agent `ChoiceChip`s (local `_agentId`), `_ProfitCard`, four `_MetricCard`s, `_ExpensesCard`, `_AgentsCard`, `_DefinitionsCard`. Data: `portfolioSourceProvider(_allRigs)`; math: `PortfolioCalculator.compute(...)`.
- `build` of `StatsScreen` watches five entry providers only to force rebuilds (`final _ = (ref.watch(...), ...)`, lines 49-55) and rebuilds the whole header and charts on any entry change.

## 3. Problems found

1. No way to change the rig here; the user must go back to the Ledger tab (mobile) to switch, then return. Header shows the rig name as inert text (stats_screen.dart:75-84). On macOS the title bar switcher exists but nothing in the page indicates it governs the page.
2. Range chips overflow the width: "All" is clipped to "Al" at 411 dp (screenshot 01) with no scroll affordance; chip order differs from the Ledger tab (Day, Month, 3 Mo, 6 Mo, Year, All, Custom versus Month, 3 Mo, 6 Mo, Year, Custom, All).
3. Header stacks title, rig, tabs and chips: about 220 dp before content on a phone.
4. Contrast: green Received (#10B981, 2.54:1) and amber Pending (#F59E0B, 2.15:1) used as text; subtitle white at 80 percent over gradient stop #618DCE is about 2.7:1.
5. Money uses western grouping and a literal rupee sign string (`'₹${_money.format(...)}'`, 3 places in portfolio_view.dart) while Account Ledger uses "Rs.".
6. `_MetricCard` value is `FittedBox`ed but the profit hero text is not clamped (see HIGHLIGHTS_AND_COLLAPSE.md B5).
7. `_agentId` is reset inside `build` (portfolio_view.dart:32-34), a state mutation during build (benign today, fragile).
8. `portfolioSourceProvider(true)` reads `DatabaseService` boxes directly inside a provider; it only refreshes when the current rig's providers emit.
9. Tap targets: agent chips are `ChoiceChip` with default padding (about 40 dp); segmented button ok.

## 4. Redesign

### 4.1 Structure (compact)

`RigScaffold` with `RigAppBar(title: 'Portfolio', rig control)`, tabs as underline `RigTabBar` (Overview, Ledger, Side Ledger) in the app bar bottom, then a one-row period selector (below), then content. The period row and the page header use the same collapse mechanism as the ledger (HIGHLIGHTS_AND_COLLAPSE.md) only if the Overview content is long enough (it is a scroll view); the Overview tab uses `SliverAppBar(floating, snap)` for the period row.

Range chips become `RigChipRow` with a right-edge fade and the selected chip scrolled into view on build (`Scrollable.ensureVisible`), order unchanged: Day, Month, 3 Mo, 6 Mo, Year, All, Custom. (Order alignment with the Ledger tab is a copy decision, see questions.)

### 4.2 B1: change the rig

Default assumption (as given): the page uses the SAME global current-rig switch as the rest of the app (the `currentVehicleProvider` plus the full refresh), not a page-only filter. The existing `This rig / All rigs` toggle stays and is unrelated: it only widens the data source of the Overview.

Mobile (compact, medium):
- Header control: the rig name becomes a pill button in the app bar subtitle position: `[Icons.precision_manufacturing_rounded or Icons.construction_rounded 16] [Rig name, labelLarge, onPrimary] [Icons.arrow_drop_down_rounded 20]`, min height 48, on the `headerSurface`. Same visual and same component (`RigSwitcher`) as the Ledger header's rig control (combined_home_screen.dart:94 today), so the two screens match.
- Tap opens the same selector as the Ledger header: bottom sheet `RigSheet` titled "Switch rig" listing every rig (icon by type, name, "Main Bore" or "Side Bore", check on the current). Existing copy in the sheet today is "Switch Vehicle" and "Select a vehicle to view its ledger"; the screen docs keep the app's term "rig" for the control text and keep the sheet strings as they are unless the copy decision (final questions, Brand) changes them.
- If only one rig exists the control renders as plain text without the arrow (same rule as the desktop title bar, `vehicles.length > 1`).
- Selecting a rig runs the same handler as the Ledger header sheet. All three existing handlers (Ledger sheet, desktop title bar, and this one) are replaced by ONE shared function `switchRig(ref, vehicle)` that performs, in this order: `await currentVehicleProvider.notifier.setCurrentVehicle(vehicle)`, clear `searchQueryProvider` and `ledgerFilterProvider` (as the Ledger sheet does), then the eight `refresh()` calls from CONVENTIONS.md. This is an extraction of existing code, not new behavior, and fixes the inconsistencies listed in BUGS_FOUND.md (B-01, B-02). Needs approval (Logic exceptions).
- Feedback: after switching, show `RigSnack` "Switched to <rig name>"; the Overview shows skeleton tiles for one frame while providers reload. The Ledger tab behind keeps its state (IndexedStack) and shows the new rig's data.
- The agent filter (`_agentId`) resets because the agent set changes; the existing reset logic in build already does this, but it moves to `didUpdateWidget`/provider listener in the redesign without changing the rule.

macOS (expanded):
- The title bar `PopupMenuButton<Vehicle>` stays the global switcher. In the page header the rig control renders as a quiet outlined chip "Rig: <name>" (not a second competing control) that opens the same popup menu anchored below it (`MenuAnchor`), with the same items and the same radio-style check. Keyboard: Tab to focus, Enter or Space opens, arrow keys move, Enter selects, Esc closes.
- When `vehicles.length == 1` the chip is text only.
- A line of helper text under the `This rig / All rigs` toggle states which rig "This rig" refers to ("This rig: <name>") so the two controls cannot be confused.

### 4.3 Overview layout per width

| Width | Layout |
|---|---|
| Compact (under 600) | profit card (full width), 2x2 metric grid (`AmountGrid`, B5 rules), expenses card, by-agent card, definitions as a collapsible `ExpansionTile` (default collapsed) |
| Medium (600-900) | profit card spans two columns; metrics 4 in a row; expenses and by-agent side by side |
| Expanded (over 900) | content max width 1100, two columns: left (profit, metrics, by-agent), right (expenses, definitions); chips and toggle in one inline toolbar row |

Tokens: cards `RigCard` (level 1, radius lg, padding 16), profit hero `displayAmount` (28, tabular) with tone `moneyIn` when profit is not negative and `negative` when it is, the "Expected when all pending is collected" line `bodySmall` `onSurfaceVariant`, metrics via `AmountTile` (labels Total billed, Received, Pending, Commission unchanged; "not part of total" caption stays).

### 4.4 State table

| State | Behavior |
|---|---|
| Default | as above |
| Loading (rig switch) | metric tiles show 96 x 20 skeleton for a frame; profit card keeps previous numbers dimmed to 60 percent only if the load is longer than 200 ms (no Opacity: `AnimatedOpacity`) |
| Empty (no bills in range) | zero values, `EmptyState` caption "No bills in this period" inside the by-agent card; metrics show zero |
| Error | not applicable (local data); if `PortfolioCalculator` throws, `ErrorBanner` with Retry that re-reads the providers |
| Disabled | rig control disabled while a switch is in progress (prevents double switch) |

### 4.5 Motion

Tab and chip changes 150 ms; sheet 300 ms; numbers do not count up (no animated counters on money).

## 5. Logic touchpoints that must stay untouched

`portfolioSourceProvider(bool)`, `PortfolioCalculator.compute(...)` and its parameters, `currentVehicleProvider.setCurrentVehicle`, the eight `refresh()` calls, `searchQueryProvider`, `ledgerFilterProvider`, `DateRangeOption` and `_getDateRange()` in stats_screen.dart, the `_agentId` reset rule, the labels (Total billed, Received, Pending, Commission, Profit definitions text in `_DefinitionsCard`), expenses grouping. `PortfolioView(start:, end:)` constructor stays.

## 6. Acceptance criteria

1. On Android with two or more rigs, the Portfolio header shows the rig name with a drop-down arrow; tapping it opens the rig selector listing all rigs with the current one checked.
2. Selecting another rig updates the header, the Overview numbers, the Ledger and Side Ledger stat tabs, and the Ledger bottom tab, without restarting the app.
3. Numbers for rig X after switching equal the numbers shown by the Ledger tab for rig X for the same period (parity line P-PORT-3).
4. With one rig, the header shows no arrow and tapping does nothing.
5. macOS: the title bar switcher and the page chip show the same current rig at all times and open the same list; the sidebar item stays selected.
6. `This rig / All rigs` still toggles the data source; with All rigs the helper text states the switcher does not change the Overview scope.
7. Range chips: all seven are reachable by horizontal scroll; the selected one is visible on entry; none is clipped without a fade hint.
8. At 200 percent text scale no overflow in the header; the rig pill truncates with ellipsis after 20 characters and the full name shows in a tooltip.
9. Profit negative shows `-` sign and `negative` tone; positive uses `moneyIn`.

## 7. Performance notes

- Remove the tuple of five `ref.watch` calls from `StatsScreen.build`; each tab body watches only what it renders.
- `PortfolioView`: split into `_ProfitCard`, `_Metrics`, `_Expenses`, `_Agents` consumers with `select` on the computed summary; compute `PortfolioCalculator.compute` once per (source, range, agent) in a memoized provider (a Riverpod `Provider.family` keyed on the same inputs, no new logic) rather than inside `build`.
- Charts live in other tabs: build them lazily (`TabBarView` already lazy-builds on first visit; keep `AutomaticKeepAliveClientMixin` off).
- Dispose `_tabController` (already done); remove the unused `_touchedIndex` rebuild coupling by moving chart touch state into the chart widget.


## Reconciliation 2026-10-13 (Apple look, Android only)

Mockup source: `portfolioTab`, `rigPill`, `rigSheet`, `mcard`, `insight`, `lineChart`, `barsChart`, `donut` in `docs/design/mockup/rigledger_apple_mockup.html`. Dropped from sections 1 to 7: macOS and expanded layouts (4.2 macOS paragraph, the Medium and Expanded rows of 4.3), gradient header, `RigAppBar`, `RigTabBar` underline tabs, hover and keyboard focus on the page chip.

### R1. Mockup screens and Flutter mapping

| Mockup screen (J label) | Render function | Flutter file | Widgets | Notes |
|---|---|---|---|---|
| Overview | `portfolioTab` (tab 0) | `lib/features/stats/stats_screen.dart`, `lib/features/portfolio/portfolio_view.dart` | LargeTitleScaffold (root, title "Portfolio"), RigRigSheet trigger pill, RigSegmented (Overview, Ledger, Side Ledger), RigChipRow, RigSegmented (This rig, All rigs), RigChipRow (agents), RigCard (Profit, hero 44), RigMetricCard x4 (MoneyTile), insight cards (later), RigCard (By agent) | metric cards first, insight cards after LR-21 and LR-22 |
| Overview (agent filter) | `portfolioTab` with `agent=a1` | same | same without the Profit card and the Expenses insight | existing rule: agent selected hides expenses and profit |
| Ledger tab (donut) | `portfolioTab` (tab 1) | `stats_screen.dart` and chart widgets (see stats_screen_charts.md) | RigMetricCard x4, RigCard with donut and legend, RigRow | label "Balance" instead of "Pending" on this tab (answer 10) |
| Side Ledger tab | `portfolioTab` (tab 2) | same | RigCard x4 (donut Paid and Due), RigGroup (Details) | PVC hidden for side bore; "Pending" keeps its name |
| Portfolio loading | `skelList` | `stats_screen.dart` | Skeleton | first frame after a rig switch only |
| Rig sheet from Portfolio (B1) | `rigSheet` | `stats_screen.dart` (header), shared sheet widget | RigRigSheet (RigSheet, RigGroup, RigRow with check), RigSnack "Switched to <rig>" | calls `switchRig` (LR-01) |

### R2. What changes in the redesign (supersedes section 4)

Layout top to bottom (Overview, 412 dp, margins 20, gap 12, card radius 20):
1. LargeTitleScaffold root: large title "Portfolio" (34) in the bar row; no trailing buttons; collapses to a centred 17 dp title after 6 dp of scroll with a solid 94 percent bar and hairline. No status strip on this screen.
2. B1 rig pill, directly under the title: 48 dp, `fill`, full radius, icon `precision_manufacturing` or `construction`, rig name (ellipsis, tooltip with the full name), `expand_more`. Same widget as the Ledger tab pill. Tap opens RigRigSheet: RigSheet "Switch Rig", RigGroup of RigRows (leading 30 dp tinted icon, name, "Main Bore" or "Side Bore", trailing `check` in `accent` for the current rig), footnote "The rig you choose applies to Ledger, Portfolio and Agents." Selecting a rig runs `switchRig`, closes the sheet, shows RigSnack "Switched to <rig name>". With one rig the pill is plain text without the arrow (existing rule `vehicles.length > 1`). Disabled while a switch runs (prevents a double switch). `This rig / All rigs` stays a separate control and helper text "This rig: <name>" is replaced by the pill itself (it already shows the rig).
3. RigSegmented Overview | Ledger | Side Ledger (48 dp).
4. Range chips, SAME ORDER as the Ledger tab (answer 5): Month, 3 Mo, 6 Mo, Year, Custom, All. The Day chip is removed unless the Ledger tab also gets one (Q-O1, open); the mockup still shows the old order with Day first (conflicts_r1.md C5). Custom shows a RigGroup with two rows From and To (value "Select date", date picker as today, bounds unchanged).
5. Overview: RigSegmented "This rig | All rigs"; agent RigChipRow ("All agents" then names, 48 dp boxes).
6. Profit card (all agents only): RigCard, "Profit" (15, 600, `lb2`), hero 44/700 `MoneyTile` in `moneyInText` (or `moneyOutText` when negative), caption "Received minus expenses minus commission" (13, `lb2`), hairline, "Expected when all pending is collected" + value in `accentText` bold. With an agent selected: a RigCard "Expenses are not tracked per agent, so profit is shown for all agents only." (existing rule).
7. Section title "Pinned" (22) then 2 x 2 RigMetricCards (MoneyTile): Total billed (`accentText`, "N bills"), Received (`moneyInText`), Pending (`outstandingText`, "after X less" when less is above zero), Commission (`commissionText`, "not part of total"). Label "Pending" is kept on the Overview until Q-O2 is answered. These cards ship FIRST.
8. Section title "Highlights" and the insight cards ship LATER (after LR-21 and LR-22 are approved): Collection (line chart billed, received, average with a scrub marker and legend) and Expenses (bar chart per category, sentence "Expenses were X in this period, mostly on Y."). Each card: icon + title (`moneyInText` for Collection, `catDieselText` for Expenses), chevron, sentence (15), chart 130 dp, legend (tiles 20/700 with the value at the scrub position). Until approved the Highlights section is not rendered and the mockup elements carry the "needs logic" mark.
9. By agent card (all agents only): per agent name (17, 600), "N bills" (13), a 6 dp bar (width = agent total / total), then Total, Received, Pending, Commission in 13 sp with their `-Text` colours; hairline between agents. Empty: EmptyState "No bills in this period" inside the card.
10. Footnote (13, `lb2`): "Total billed is the sum of bill totals. Pending is total minus received minus less. Commission is never part of a bill total. Expenses are side ledger purchases in the period. Profit is received minus expenses minus commission." (the existing definitions text, no longer a collapsible tile).
11. List bottom padding = `62 + viewPaddingOf.bottom + 8 + 24` for the floating RigTabBar.

Ledger tab of Portfolio: 2 x 2 metric cards Total, Entries, Received and Balance (renamed from Pending, answer 10), then a RigCard "By agent" with a donut (agent palette) and rows (dot, name, `MoneyText` total, percent in `accentText`); empty state "No data available" / "Add ledger entries to see statistics." Side Ledger tab of Portfolio: one RigCard per category (icon in its `cat*` colour, donut Paid `moneyIn` and Due `outstanding`, "Paid N%" and "Due N%") in a 2 column grid, then a "Details" section of RigGroups per category (entries, litres or pieces, amounts, Paid in `moneyInText`, Pending in `outstandingText`); "No entries in selected period" when empty. Chart specifics stay in stats_screen_charts.md.

Money: compact only inside the Profit card and the RigMetricCards (tap shows the full value in a popover); rows, the By agent card and legends use full values that scale to 75 percent then 11 sp (answer 3). Numbers never count up.

States:

| State | Behaviour |
|---|---|
| Default | as above |
| Loading | Skeleton rows (4) for the first frame after a rig switch; rig pill and chips stay |
| Empty (no bills in range) | zero metric cards, By agent card shows EmptyState |
| Error | not built (local data; LR-34 default); a calculator exception shows ErrorBanner with Retry |
| Disabled | rig pill disabled while a switch runs |

Old section 4 mapping: 4.1 structure CHANGED (large title, no `RigAppBar`), chip fade/scroll KEPT as horizontal scroll with the selected chip scrolled into view; chip order CHANGED (answer 5); 4.2 B1 mobile CHANGED (pill + RigRigSheet, copy "Switch Rig", snackbar KEPT), macOS paragraph DROPPED; 4.3 width table DROPPED except compact (profit card, 2 x 2 grid, By agent, definitions now a footnote); 4.4 state table CHANGED; 4.5 motion: bar fade 200 ms, chip and tab 150 ms, sheet 300 ms, ink press feedback, instant under reduced motion; no counters.

### R3. Logic touchpoints and LR items

Untouched: `portfolioSourceProvider(bool)`, `PortfolioCalculator.compute`, `currentVehicleProvider.setCurrentVehicle`, the eight `refresh()` calls (now through `switchRig`), `searchQueryProvider`, `ledgerFilterProvider`, `DateRangeOption` and `_getDateRange()`, the `_agentId` reset rule, the label texts of the definitions, expenses grouping, `PortfolioView(start:, end:)`.

| Item | Status |
|---|---|
| LR-01 shared `switchRig` | approved (B1) |
| LR-21 daily series for the Collection insight | proposed; metric cards first |
| LR-22 comparison to earlier periods and the sentences | proposed, deferred |
| LR-09 unified period model | not scheduled; chips use the Ledger order without a shared provider |
| Q-O1 Day chip | open (default: remove from Portfolio) |
| Q-O2 "Pending" versus "Balance" on the Overview card | open (default: Pending) |
| Stats Ledger tab "Pending" renamed "Balance" (answer 10) | approved, one label change |
| LR-10 `portfolioSourceProvider(true)` reading boxes | needs approval, not part of the restyle |
| Proposed, new | none |

### R4. Acceptance criteria delta

REPLACES section 6 items 1, 5, 7 and 8; ADDS the rest. 360 and 412 dp, light and dark, text scale 100, 130, 200 percent.
1. With two or more rigs the pill shows icon, rig name and a down arrow; tapping it opens "Switch Rig" with all rigs, type labels and a check on the current one; with one rig there is no arrow and no tap action.
2. Selecting a rig updates the title area, Overview numbers, the Ledger and Side Ledger stat tabs and the Ledger bottom tab, shows "Switched to <name>", and clears search and filters (including the four side filters); numbers equal the Ledger tab for the same period (P-PORT-3).
3. Range chips appear in the order Month, 3 Mo, 6 Mo, Year, Custom, All; the selected chip is visible on entry; all remain reachable by horizontal scroll.
4. The Overview shows the 2 x 2 metric cards at 100 and 130 percent and 1 column at 200 percent; values over 12 characters scale to 75 percent, then compact; tap shows the full value; Profit shows a minus sign and `moneyOutText` when negative.
5. The Stats Ledger tab label reads "Balance"; the Side Ledger tab and the Overview keep "Pending" (Q-O2 open).
6. Highlights section absent until LR-21 and LR-22 are approved; with them it shows Collection and Expenses with scrub values.
7. Rig name longer than 20 characters ellipsizes; the full name is in the semantics label and the sheet row.
8. Keyboard is not used on this screen; back on a root tab does nothing (Q-O6); back closes the rig sheet.
9. No emoji, no raw colour, no `BackdropFilter` in the scroll content.

### R5. Parity delta

Changed on purpose: P-PORT-2 chip set and order (Day removed unless Q-O1 says otherwise), P-PORT-3 (rig control is the pill and sheet; check also that the four side filters are cleared), "Vehicle" copy becomes "Rig", Stats Ledger tab label "Pending" becomes "Balance", the definitions card becomes a footnote, rupee sign and en-IN grouping, macOS lines DROPPED.
Identical: P-PORT-1 (all six numbers equal `PortfolioCalculator`), P-PORT-4 (toggle, agent filter, expenses and profit hidden with an agent), P-PORT-5 (chart data on the Ledger and Side Ledger tabs).

### R6. Performance and Android notes

- Portfolio is lazy: built on first visit, kept alive afterwards; rig switch refreshes it through providers.
- Remove the tuple of five `ref.watch` calls; each section watches only its data; memoize `PortfolioCalculator.compute` per (source, range, agent) in a provider family.
- MoneyTile caches measurements; insight charts (`fl_chart` `LineChart` with `LineTouchData`) are built only when LR-21 lands, with `RepaintBoundary` and no rebuild during scrub except the legend values (`ValueNotifier`).
- Sheet: `isScrollControlled`, bottom padding `viewPaddingOf.bottom`; the sheet scrim is a plain colour (no blur).
- Dispose `_tabController` and any chart touch notifier; chip row scroll controller disposed.
- Budgets: p90 build and raster under 8 ms, p99 under 16 ms; tab switch under 100 ms.
