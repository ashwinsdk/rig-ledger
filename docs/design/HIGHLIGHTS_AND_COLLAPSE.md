# B4 Collapsing Ledger Header and B5 Highlights Layout

> RECONCILED 2026-10-13: the header is now the Apple-style large title (34 collapsing to a 17 inline title) on `LargeTitleScaffold`; the highlights are the ring card, 2 x 2 metric cards and depth tiles; Android portrait only (360 dp floor), so every medium and expanded width row below is DROPPED. The section "Reconciliation 2026-10-13" at the end replaces the layout details of parts A and B; the fit algorithm, the stress table (use widths 360 and 412) and acceptance logic stay valid.

Scope: main Ledger tab, Side Ledger tab and the Side Bore rig ledger (same Ledger tab), on Android and macOS. Files today: `lib/features/home/combined_home_screen.dart` (header lines 57-445, Side Ledger tab `_buildSideLedgerContent` line 494), `widgets/summary_row.dart`, `widgets/ledger_list.dart`, `widgets/calendar_view.dart`. Spec only. No provider, calculation or label changes.

## Part A. B4: header that hides on scroll

### A.1 Measured problem

Test device: 1080 x 2400 px at 2.625 density = 411 x 914 dp (emulator screenshot 00, docs/design/ref).

| Region (Ledger tab, Month period) | Height (dp, approx) |
|---|---|
| Status bar | 24 |
| App bar row (search, RigLedger plus rig, filter) | 64 |
| Ledger / Side Ledger tab pill | 56 |
| Period chips | 40 |
| Month navigator | 48 |
| Daily / Calendar toggle | 56 |
| Summary card (Total, Received, Balance, Commission) | 112 |
| Feet totals card | 108 |
| Bottom navigation | 80 |
| Fixed total | about 588 |
| LEFT FOR THE LIST | about 326 dp (36 percent of the screen), about two bill cards (card about 170 dp) |

Custom period adds a 40 dp date row; an active search adds 24 dp. The list is "cut off" because everything above it is a non-scrolling `Column` (combined_home_screen.dart:63 `Column` > header `Container` > `Expanded(TabBarView)` > `Column[SummaryRow, Expanded(list)]`).

### A.2 What stays and what collapses

| Part | Behavior | Why |
|---|---|---|
| App bar row: search, title with rig switcher, filter (with active dot), reveal toggle | PINNED always (56 dp) | identity, rig context and the two most used actions must never disappear |
| Ledger / Side Ledger tabs | PINNED (40 dp, underline tabs inside the app bar `bottom`) | switching tabs is a primary navigation; the pill version (56 dp) shrinks to 40 dp |
| Compact status strip (period label + Balance, 36 dp) | appears ONLY when the rest is collapsed; is the reveal control | keeps the one number users check most visible; gives a large, obvious tap target to reveal |
| Period chips, month or year navigator, custom date row, Daily/Calendar toggle | COLLAPSES | secondary controls, used a few times per session |
| Highlights (money tiles and feet tiles) | COLLAPSES | readable on demand; the strip keeps Balance |
| Search-active indicator ("Searching: ...") | PINNED while search is active, as part of the status strip | the user must always see that a filter is on (silent filter = wrong-number risk) |
| Active filter indicator | the dot on the filter icon (pinned) plus a chip in the strip: "Filters on" | same reason |
| Day group headers in the list | sticky (SliverPersistentHeader pinned per group is NOT required; keep as list rows) | avoid per-group sliver cost; revisit after profiling |

Result when collapsed on the test phone: 24 + 56 + 40 + 36 = 156 dp fixed, list gets 914 - 156 - 80 = 678 dp (74 percent, 2.1x today, about four bill cards). Without the strip (search and filter off, strip optional): 96 dp fixed, list 738 dp.

### A.3 Behavior

1. Scroll down: the collapsible region scrolls off together with the list, no jump, until only the pinned part remains.
2. Scroll up by any amount: the collapsible region comes back (floating behavior) and snaps open or closed when the finger lifts (snap). This is the "returns on scroll up".
3. Clear reveal: (a) tap the status strip, (b) tap the chevron toggle in the app bar row (tooltip "Show filters and totals" / "Hide filters and totals"), (c) tap the status bar area is not used. Reveal animates to fully expanded in `RigMotion.base` (200 ms, `curveEnter`).
4. Short lists: when the content fits the viewport nothing scrolls and the header stays fully expanded (no collapse on a list that cannot scroll).
5. Tab switch: the header state is shared by both tabs; switching tabs does not change collapsed state. Each tab keeps its own scroll offset (`PageStorageKey`).
6. Calendar view (Daily/Calendar toggle): the calendar grid is one sliver child; the header collapses with its scroll, and the 36 dp strip shows the month.
7. Data refresh (sync, add, edit, vehicle switch, pull of providers): scroll offset is preserved; see A.5.
8. Reduced motion (`MediaQuery.disableAnimationsOf`): no snap animation, reveal is instant.
9. Desktop (macOS): same mechanism. Mouse wheel and trackpad scroll collapse and reveal the same way. Because the window is wide, the expanded header lays out in two rows (A.4) so it is about 150 dp instead of 380 dp. A persistent toggle button (tooltip, keyboard focusable, Space/Enter) is always shown. No new keyboard shortcut is introduced.
10. State persistence: collapsed or expanded is session-only UI state. It is not stored (no new settings).

### A.4 Layout per width class

| Class | Width | Expanded header content | Expanded height | Collapsed (pinned) |
|---|---|---|---|---|
| Compact (phone) | under 600 | app bar row; tabs; chips (scrollable, fade edge); month navigator; Daily/Calendar segmented; highlights (2x2 money, 3+2 feet wrap) | about 56+40+40+48+48+(2x2: 2 rows x 72 + gap = 152)+(feet 2 rows x 56 = 112) = about 496 | 96 (+36 strip) |
| Medium (tablet or narrow window) | 600 to 900 | same, money tiles 4 in a row, feet 5 in a row | about 56+40+40+48+48+80+64 = 376 | 96 (+36) |
| Expanded (macOS) | over 900 | row 1: app bar row (title bar already holds the rig switcher on macOS, so the in-page title is dropped); row 2: tabs left, chips + navigator + Daily/Calendar inline right; row 3: highlights, money 4 + feet 5 in one 9-column row or two rows | about 48+48+88 = 184 | 48 (+36) |

Content max width on macOS: 1100 dp, centered; the header background stays full width.

### A.5 Implementation plan (must not change logic)

- Container: `NestedScrollView` (`floatHeaderSlivers: true`) with a `SliverAppBar(pinned: true, floating: true, snap: true, bottom: TabBar, flexibleSpace: collapsible content, expandedHeight computed from the width class)`. Body: `TabBarView` whose children are `CustomScrollView`s with `PageStorageKey` and `SliverOverlapInjector`. This keeps the existing `TabController` and `homeTabIndexProvider` write in `_onTabChanged` exactly as is.
- If measuring `expandedHeight` proves fragile (it varies with text scale and the Custom date row), use a `SliverPersistentHeaderDelegate` with `minExtent` and `maxExtent` computed from a `LayoutBuilder` pre-pass, or a `SliverToBoxAdapter` header plus `SliverAppBar(floating)` for the pinned part. Decide by prototype in the first B4 task; acceptance is behavioral (A.7).
- No `setState` per scroll tick. The strip fades by crossing a threshold: a `NotificationListener<ScrollNotification>` updates a `ValueNotifier<bool> collapsed` only when the boolean flips; a `ValueListenableBuilder` rebuilds only the strip. No `Opacity` widget in the scroll path; use `AnimatedSwitcher` / `AnimatedOpacity` on the boolean.
- Split `CombinedHomeScreen.build`: today it watches 9 providers at the top (selectedMonth, selectedYear, customStart, customEnd, isDailyView, searchQuery, filter, timePeriod, currentVehicle), so any change rebuilds the whole header and list host. Move each watch into the leaf widget that needs it (`RigChipRow`, `PeriodNavigator`, `HighlightsPanel`, `StatusStrip`) with `select` where possible. The `TabController` and the scroll controller live in State and are never recreated.
- Scroll position kept on refresh: list items keyed by `ValueKey(entry.id)`; the list is a `SliverList` with `findChildIndexCallback` so edits and inserts above do not shift the offset; `PageStorageKey` per tab; never wrap the body in a widget whose key changes on refresh; never call `jumpTo` on data change.
- FAB: bottom padding of the list sliver = 88 dp so the last card clears the FAB; FAB stays visible while the header is collapsed.
- Calendar tab content (`CalendarViewWidget`): keep as a single sliver child.

### A.6 States

| State | Behavior |
|---|---|
| Default expanded | all parts visible |
| Collapsed | pinned part plus strip |
| Empty list (no entries) | header stays expanded (nothing to scroll); `EmptyState` below highlights |
| Loading | highlights show tile skeletons (value placeholder 96 x 20) for the first frame only |
| Search active | strip shows "Search: term" with a clear button (the existing `searchQueryProvider` reset) |
| Filter active | filter icon dot plus "Filters on" chip in the strip |

### A.7 Acceptance criteria

1. On the 411 x 914 dp phone with 30 entries, scrolling the list down by 200 dp hides the chips, navigator, toggle and highlights; the app bar row, tabs and strip remain.
2. Scrolling up by 40 dp starts revealing; lifting the finger completes the reveal (snap).
3. Tapping the strip or the toggle fully expands the header in 200 ms (or instantly with reduced motion).
4. With the header collapsed the list viewport is at least 650 dp on the test phone (current: 326).
5. A list with 3 entries does not collapse.
6. Adding an entry from the FAB and returning keeps the scroll offset within 1 dp; a background sync that adds records keeps the offset.
7. Switching Ledger to Side Ledger and back restores each tab's own offset.
8. Profile mode: no `setState` calls per scroll frame (DevTools shows build count of `CombinedHomeScreen` stays flat while scrolling), frame build under 8 ms and raster under 8 ms at 60 Hz (see PERFORMANCE.md).
9. At text scale 200 percent the pinned part does not overflow and the strip wraps to two lines (strip min height 36, grows).
10. macOS at 900 x 600: the expanded header is at most 190 dp; the toggle is reachable by Tab.
11. TalkBack / VoiceOver: the strip is a single button "Show filters and totals, October 2026, Balance 77000 rupees" (placeholder numbers).

## Part B. B5: highlights that never break

### B.1 Current failures (code facts)

- `summary_row.dart` money card: four `Expanded(_SummaryItem)` in one `Row` (lines 38-85). The value is `FittedBox(scaleDown)` with no minimum, so a long amount shrinks without limit and four values touch each other (visible in screenshot 00: two values adjacent with no gap at 100 percent text).
- Feet card: five `Expanded(_FeetItem)` in one `Row` (lines 120-160). `_FeetItem` value is a plain `Text` with no `FittedBox`, no `maxLines`, no ellipsis; `"12,34,567 ft"` at 12 sp in a 62 dp column wraps or overflows.
- `ledger_list.dart` `_ValueDisplay` (3 columns, 14 sp, no fit) and the `_InfoChip` row (Depth + PVC) have no `Flexible`, so long text overflows the card.
- Side Ledger tab (`_buildMiniStatDouble`, `_buildCategoryCard`) shows quantity plus amount with the same pattern.
- Formats: grouping is western (`#,##0.00`) in these widgets, so 12,34,567.00 displays as 1,234,567.00.

### B.2 Components

`HighlightsPanel` hosts `AmountGrid` (money) and `FeetWrap` (feet). Tiles: `AmountTile` and `FeetTile` (COMPONENTS.md). Labels are unchanged: Total, Received, Balance, Commission (main Ledger summary labels today; the user calls the second one "total received", the app label is "Received", keep "Received"), `7" Depth`, `8" Depth`, `7" PVC`, `8" PVC`, `MS Pipe`; side bore: `Total Depth` only (no PVC, existing rule).

### B.3 Layout rules

Let `w` = inner width of the panel, `s` = `MediaQuery.textScalerOf(context)` scale at 16 sp.

Money tiles (4): columns = 4 if `w >= 720`, else 2 if `s <= 1.3`, else 1. Gap 8. Tile padding 12 horizontal, 8 vertical. Tile min height 72 (label row 16 + value 28). Tile is a `RigCard` tone `surfaceContainer` (no shadow, no inner borders).
Feet tiles (5): `Wrap` with balanced rows: `perRow = clamp(floor((w + 8) / (104 + 8)), 1, 5)`, then rebalance so row sizes differ by at most one (5 on 3 columns renders 3 + 2, on 2 columns 2 + 2 + 1, at 5 columns 5). Tile min width 104, min height 56, label 12 sp, value `amountSmall`.
Side Ledger tab category tiles: 2 columns when `s <= 1.3`, else 1; each tile has quantity line and amount line, both fitted.

### B.4 Fit algorithm (deterministic, per value)

1. Start with the full formatted string (`RigFormat.money` or `RigFormat.feet`) at the tile's base style (`amountMedium` 16 sp for money, `amountSmall` 14 sp for feet), tabular figures, `maxLines: 1`, `softWrap: false`.
2. Measure with `TextPainter` once per (string, style, textScale, available width); cache in the tile's State (not in build of a list). If the natural width fits, render as is.
3. Else compute `scale = available / natural`. If `scale >= 0.75` (minimum readable: money 12 sp, feet 10.5 sp rounded up to 11 sp floor) render with `FittedBox(fit: BoxFit.scaleDown)` at that scale.
4. Else switch to the compact string (`RigFormat.moneyCompact`: K for thousands, L for lakhs, Cr for crores, 2 significant decimals; feet use K) at the base size, again with `FittedBox` as a last guard.
5. A compact tile shows a small "full value" affordance: the tile is tappable and long-pressable (min 48 dp tall hit area). Tap opens `RigSheet` (mobile) or a popover (desktop) titled with the tile label, showing the exact full value in `displayAmount`, selectable, with a Copy button (clipboard only, no data change). Long press does the same on mobile; desktop shows a tooltip with the full value on hover (`Tooltip`, 500 ms).
6. A full-format tile that was scaled is also tappable with the same sheet, so a user can always read the exact figure.
7. Negative values: minus sign inside the fitted text, color `negative`. Zero: `₹0.00`, tile tone unchanged.
8. `semanticsLabel` is always the full plain value ("127000 rupees"), never the compact string.

Compact thresholds: below 1,00,000 never compact; compact allowed only through step 4 above (so most phones keep full values up to about 12 characters, `1,27,000.00`).

### B.5 Text scale behavior

| Scale | Money tiles on a 360 dp phone (w about 296) | Feet tiles | Height of panel |
|---|---|---|---|
| 100 percent | 2 columns, full value up to `₹99,99,999.00` (12 chars), longer values use scale then compact | 3 + 2 | about 264 |
| 130 percent | 2 columns, compact kicks in 1 character earlier | 2 + 2 + 1 | about 330 |
| 200 percent | 1 column (4 stacked), full values fit up to 12 chars at 24 px effective | 2 + 2 + 1 or 1 per row if label does not fit | about 640 (header collapses away on scroll, which is why A is required) |
Labels may wrap to two lines at 200 percent (label `maxLines: 2`); values never wrap.

### B.6 Stress table (every row must render with no overflow, no clipped glyphs and no exception)

Test values are synthetic. Widths: narrow phone 320 dp, phone 360 dp, test phone 411 dp, narrow macOS window 900 x 600 (content 640 dp after the 220 dp sidebar). Scales 100, 130, 200 percent.

| # | Input | Full format | Expected rendering |
|---|---|---|---|
| 1 | 0 | `₹0.00` | full |
| 2 | 0.01 | `₹0.01` | full |
| 3 | 0.005 (rounds) | `₹0.01` or `₹0.00` per `NumberFormat` rounding (unchanged) | full |
| 4 | 1234.5 | `₹1,234.50` | full |
| 5 | 1234567.891 | `₹12,34,567.89` | full at 100 percent; fitted at 200 percent |
| 6 | 99999999.99 | `₹9,99,99,999.99` | fitted >= 0.75 or compact `₹10.00 Cr` |
| 7 | 1000000000 | `₹1,00,00,00,000.00` | compact `₹100 Cr` on phones |
| 8 | 999999999999.99 (12 digits) | `₹99,99,99,99,999.99` | compact `₹99,999.99 Cr` is longer than the tile at 200 percent: step 4 fits via `FittedBox` last guard |
| 9 | 1e15 | `₹1,00,00,00,00,00,000.00` | compact; tap shows full |
| 10 | -450000 | `-₹4,50,000.00` | `negative` color, sign preserved |
| 11 | -99999999.99 | `-₹9,99,99,999.99` | sign never lost to scaling |
| 12 | -0.0 | `₹0.00` (no negative zero: format `value == 0 ? 0 : value`) | full |
| 13 | NaN or infinity (defensive) | `--` | `textMuted`, no exception |
| 14 | 123.456789 ft | `123 ft` in summary tiles (`#,##0`, unchanged) | full |
| 15 | 0.5 ft | `0 ft` or `1 ft` per current `#,##0` rounding (unchanged; flagged in BUGS_FOUND.md B-09) | full |
| 16 | 9999999 ft | `99,99,999 ft` | fitted or compact `99.99 L ft` |
| 17 | feet with 3 digits and label `8" PVC` at 200 percent | `100 ft` | label wraps to 2 lines, value on one line |
| 18 | Four money tiles all at row 8 values simultaneously | | 2 x 2 with every tile fitted independently; tiles in a row keep equal width and equal height |
| 19 | Side Bore rig with `Total Depth` only | `99,99,999 ft` | single wide tile, left aligned |

Pass criteria for the widget test (added at implementation time): `tester.takeException()` is null for all 19 inputs x 4 widths x 3 scales (228 cases); no `RenderFlex overflowed` log; the rendered font size of each full-format value is at least 12 sp (11 sp feet) or the value is compact; every tappable tile has a hit area of at least 48 x 48 dp; goldens at 320 dp 200 percent and 900 px macOS 100 percent.

### B.7 Logic touchpoints (must stay untouched)

`monthlyStatsProvider` keys `total`, `received`, `balance`, `commission`; `feetTotalsProvider` keys `depth7inch`, `depth8inch`, `pvc7inch`, `pvc8inch`, `msPipeTotal`; `isSideBoreProvider` / `currentVehicleProvider` for the side bore variant; `groupedLedgerEntriesProvider`; `LedgerEntry.total/received/balance/commission/depthInFeet`. The panel receives already computed numbers; it formats them and nothing else.

## Reconciliation 2026-10-13 (Apple look, Android only)


Status: proposal only. HIGHLIGHTS_AND_COLLAPSE.md is NOT edited by this group; the lead merges the sections below. Source: `docs/design/mockup/rigledger_apple_mockup.html` (`scr`, `onSc`, `ledgerTab`, `mcard`, `ringSvg`, `fitAll`, `mfit`, `qfit`), TOKENS.md sections 4, 4b, 7, DESIGN_DIRECTION_APPLE.md section 7 (answers 3, 11, 16). Android only, portrait, 360 dp minimum. Scope reduction: every macOS, medium and expanded item (A.3 item 9, A.4 rows Medium and Expanded, A.7 item 10, B.3 4-column rule, widths 320 and 900 in B.6) is deleted.

### 1. Banner for the top of the file

> SUPERSEDED IN PART (2026-10-13): the look is now the Apple-inspired Android direction. Part A is replaced by "A. B4: large title and status strip" below, Part B sections B.2 to B.6 by the "B. B5" text below. A.1 (the measured problem) stays as history.

### 2. Replacement for Part A (B4): large title and status strip

#### A.2 What stays and what collapses (REPLACES the table)

| Part | Behaviour | Why |
|---|---|---|
| Large title "Ledger" (34, 700) with three 48 dp glass buttons (Search, Filter with dot, Add) | sits in the 56 dp bar row below the status bar; scrolls away with the content | identity and the primary actions; the buttons stay in the pinned bar after the title collapses |
| Collapsed bar | after the content scrolls 6 dp (root tab) or 34 dp (pushed screen): solid `barSolid` (94 percent surface) with a 0.5 dp `sep` hairline and a centred 17 dp title, fade 200 ms | iOS style collapse; blur only when the Glass blur toggle is ON (default OFF) |
| Status strip (48 dp, below the bar, Ledger tab only) | appears only while the bar is collapsed: period label, "Balance <money>" in `outstandingText`, "Filters on" badge, "Search on" badge; tap scrolls to the top in 250 ms | keeps the number users check most visible; the tap is the reveal |
| Rig pill, Ledger and Side Ledger segmented control, period chips, navigator, Daily and Calendar segmented control, highlights | normal scroll content, they scroll away like any row; NOT floating, NOT snapping | the list gets the whole screen; the reveal is scrolling up or tapping the strip |
| Day group headers | sticky (pinned per group) | decision C-5; fallback `sliver_tools` if profiling misses p99 |

#### A.3 Behaviour (REPLACES)

1. Scroll down: the title row scrolls out; at the threshold the bar surface, hairline, centred title and strip fade in (200 ms). No jump.
2. Scroll up to the top: the bar returns to transparent and the large title is visible again. There is no floating or snap behaviour and no chevron toggle.
3. Tap on the strip: smooth scroll to offset 0 in 250 ms (instant under reduced motion).
4. Short lists: the content does not scroll, so the bar never collapses.
5. Tab switch (Ledger, Side Ledger): each sub-tab keeps its own scroll offset (`PageStorageKey`); the strip exists only on the Ledger sub-tab. Horizontal tab swipe is disabled (row swipe actions use horizontal drags).
6. Data refresh keeps the offset (keys by id, `findChildIndexCallback`, no `jumpTo`).
7. Reduced motion: no fades, instant scroll to top.
8. State is not persisted (LR-07 closed: there is no collapsed state to store).

#### A.4 Layout (REPLACES the width table)

One width class (compact, 360 to 412 dp, portrait). Pinned part when collapsed = top inset + 56 + 48 (strip). At 412 x 892 with a 28 dp inset: 132 dp, list viewport 760 dp (the floating tab bar covers the last 94 dp only at the list end through padding `62 + bottom inset + 8 + 24`). Expanded heights are not budgeted: the content scrolls.

#### A.5 Implementation (REPLACES)

`LargeTitleScaffold`: `CustomScrollView` with a pinned `SliverPersistentHeader` for the bar (height `viewPaddingOf.top + 56`) and a second pinned header for the strip (height 48) built only when `collapsed` is true. `collapsed` is a `ValueNotifier<bool>` flipped by a `ScrollNotification` listener when the offset crosses the threshold; only the bar background, the centred title and the strip listen to it. No `setState` per scroll tick, no `Opacity` in the scroll path (`AnimatedOpacity` on the boolean), no `BackdropFilter` unless the blur toggle is on. The existing `TabController` and the `homeTabIndexProvider` write stay. `NestedScrollView`, `floatHeaderSlivers` and `SliverAppBar(floating, snap)` are NOT used.

#### A.6 States (REPLACES)

Default (expanded), Collapsed (bar and strip), Empty (no strip because nothing scrolls), Loading (skeleton rows for the first frame after a rig switch or restore, LR-34), Search active ("Search: <q>" pill row in the content plus a "Search on" badge in the strip), Filter active (dot on the Filter button and "Filters on" in the strip).

#### A.7 Acceptance criteria (REPLACES)

1. On 412 x 892 dp with 30 entries, scrolling 6 dp shows the bar, hairline, centred title and strip; scrolling back to the top removes them.
2. Collapsed pinned height equals top inset + 104 dp.
3. Tapping the strip scrolls to the top in 250 ms.
4. A list with 3 entries does not collapse.
5. Adding an entry and returning keeps the offset within 1 dp; a background sync keeps it.
6. Switching Ledger and Side Ledger restores each offset; swiping horizontally on a row does not switch the tab.
7. Profile mode: build count of the host screen stays flat while scrolling; build and raster p90 under 8 ms, p99 under 16 ms.
8. Text scale 200 percent: the strip wraps to two lines (min height 48, grows), the bar does not overflow.
9. TalkBack: the strip is one button "Show filters and totals, October 2026, Balance 77000 rupees" (placeholder numbers).

### 3. Replacement for Part B (B5): highlights

#### B.2 Components (REPLACES)

`RigCard` + `RigRing` (ring card), `RigMetricCard` x4 with `MoneyTile`, `DepthTile` x5 (x1 for side bore), `MoneyText` (fit pipeline). Labels unchanged: Total, Received, Balance, Commission; `7" Depth`, `8" Depth`, `7" PVC`, `8" PVC`, `MS Pipe`; side bore `Total Depth` only.

#### B.3 Layout rules (REPLACES)

- Ring card: `RigCard` padding 16, a wrapping row (spacing 12): ring size `128 * (1 + (scale - 1) * 0.7)` dp (128 at 100 percent, 155 at 130, 218 at 200), stroke 18, round cap, track `moneyIn` at 22 percent, progress `moneyIn`, fraction `received / total` clamped to 0..1 (0 when total is 0), centre `NN%` (22, 700) and "collected" (11, `lb2`), `NN = round(received / total * 100)` (not clamped, so 120 percent can show); right block min width 200 dp: "Received" (15, 600), `MoneyTile` 28/700 `moneyInText`, "of <MoneyTile Billed> billed" 13 `lb2`. Reveal 900 ms ease-out, off under reduced motion.
- Metric cards: 2 columns, gap 12, card padding 14, radius 20, min width 0; 1 column when text scale is 1.9 or more. Card: label (15, 600), value (26, 700, letter spacing -0.5, one line), caption (13, `lb2`). Colours: Total `accentText`, Received `moneyInText`, Balance `outstandingText` ("still to collect"), Commission `commissionText` ("not part of total"). At 360 dp each card is 154 dp wide, at 412 dp 180 dp.
- Depth tiles: 3 columns (gap 12, padding 12 x 10, label 12 `lb2`, value 17/600); 5 tiles wrap 3 + 2 left aligned; 2 columns when text scale is 1.9 or more (2 + 2 + 1). Side bore: 1 column, one full width tile. At 360 dp a tile is about 99 dp wide.
- Side Ledger tab: `CategoryTile` 2 columns (1 at scale 1.9 or more), each with a fitted amount line.

#### B.4 Fit algorithm (REPLACES steps 1 to 8)

1. Full formatted string (`RigFormat.money` or `ftq`), tabular figures, `maxLines: 1`, `softWrap: false`.
2. Measure once per (string, style, textScale, width) and cache.
3. If it does not fit and `available / natural >= 0.75`, scale to that ratio (`FittedBox(scaleDown)` or a font size factor).
4. Else switch to the compact string: money `L` from 1,00,000, `Cr` from 1,00,00,000, `L Cr` from 1e12, up to 2 decimals and none from 1,000 (no K); feet compact is the same with the suffix ` ft` (`99.99 L ft`). Then shrink with a last guard to 11 sp minimum.
5. Compact is allowed ONLY inside `MoneyTile` (ring card values, metric cards, Profit card, Purchases card, category tiles) and `DepthTile`. Rows, day headers, the strip, legends and the Account Ledger totals strip never compact: they scale to 75 percent, then 11 sp, then the value moves to its own line.
6. Any tile whose value was scaled or compacted is tappable (48 dp) and shows the full value in a small popover (2.6 s, tap elsewhere closes) with the tile label; `semanticsLabel` is always the full plain value.
7. Negative: minus before the sign (`-₹4,50,000`), `moneyOutText`; zero `₹0`; never negative zero; non-finite `--` in `lb2`.
8. Money shows two decimals only when the value has paise.

#### B.5 Text scale (REPLACES)

| Scale | Metric cards at 360 dp | Depth tiles | Ring |
|---|---|---|---|
| 100 | 2 columns | 3 + 2 | 128 dp |
| 130 | 2 columns, compact one character earlier | 3 + 2 | 155 dp, ring card wraps below the ring |
| 200 | 1 column (4 stacked) | 2 + 2 + 1 | 218 dp, text below the ring |

Labels may wrap to two lines at 200 percent; values never wrap.

#### B.5b Feet rule (NEW, answer 16, LR-13)

`ftq(n)`: round to one decimal, hide a trailing `.0`, en-IN grouping, suffix ` ft` (350 ft, 350.5 ft, 1,250 ft). Sums are rounded to one decimal first (0.1 + 0.2 shows 0.3). Same in the bill card, the summary tiles, the commission helper lines and the form pre-fill (`350`, not `350.0`). A value typed with two decimals displays rounded (350.25 shows 350.3) while calculations use the stored double; restricting input to one decimal is LR-30 (proposed, Q-O5). The mockup `qty` allows two decimals and is not the rule.

#### B.6 Stress table (REPLACES widths and counts)

Widths 360 and 412 dp (320 and 900 dropped). Scales 100, 130, 200 percent. Rows 1 to 13 and 18 unchanged except the compact strings follow B.4 (no K, no negative zero). Rows replaced:

| # | Input | Expected |
|---|---|---|
| 14 | 123.456 ft | `123.5 ft` |
| 15 | 0.5 ft | `0.5 ft` |
| 15b | 350.0 ft | `350 ft` |
| 15c | 350.25 ft | `350.3 ft` (display rounding, Q-O5) |
| 15d | 0.1 + 0.2 ft (sum) | `0.3 ft` |
| 16 | 9999999 ft | `99,99,999 ft`, scaled or compact `99.99 L ft` |
| 17 | `8" PVC` at 200 percent | label wraps to 2 lines, value on one line |
| 19 | side bore, `Total Depth` only | single full width tile |
| 20 | ring: billed 0, received 0 | ring empty, `0%`, "of ₹0 billed" |
| 21 | ring: received above billed (120 percent) | ring full, label `120%` |
| 22 | ring: received 1e12, billed 2e12 | 50 percent, values compact in the ring card |

Pass criteria for the widget test: `tester.takeException()` null for 22 inputs x 2 widths x 3 scales (132 cases); no `RenderFlex overflowed`; full-format values render at 12 sp or more (feet 11 sp) or are compact; every tappable tile has a 48 x 48 dp hit area; goldens at 360 dp 200 percent light and dark.

#### B.7 Logic touchpoints (UNCHANGED)

`monthlyStatsProvider` keys `total`, `received`, `balance`, `commission`; `feetTotalsProvider` keys `depth7inch`, `depth8inch`, `pvc7inch`, `pvc8inch`, `msPipeTotal`; `isSideBoreProvider`; `groupedLedgerEntriesProvider`; `LedgerEntry` getters. The ring percent and fraction are derived in the widget from `received` and `total`; no provider change.
