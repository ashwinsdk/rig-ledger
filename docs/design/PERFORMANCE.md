# Performance Plan

> RECONCILED 2026-10-13: Android only. Section R at the end replaces the budgets in section 1, resolves decision D-1 and drops every macOS and desktop item. Sections 2, 3 and 5 stay valid except where R says otherwise.

Spec only. Budgets are proposals for approval (final question group Performance targets). Facts below come from grep and file reads on 2026-10-12; nothing was profiled yet (macOS and a release Android build were not run in this pass, see PROGRESS.md), so every budget is a target to be measured in the first migration task, not a measured result.

## 1. Targets (proposed)

| Metric | Android mid-range (60 Hz) | macOS (60 Hz, 120 Hz where available) |
|---|---|---|
| Frame build time, 99th percentile while scrolling the longest list | 8 ms or less | 6 ms or less |
| Frame raster time, 99th percentile | 8 ms or less | 6 ms or less |
| Janky frames (over 16.6 ms) during a 10 s fling | under 1 percent | under 0.5 percent |
| Cold start to first interactive Ledger frame (release/profile build) | under 1.5 s | under 1.2 s |
| Tab switch (bottom nav, sidebar) to first painted frame | under 100 ms | under 100 ms |
| Open a bill form from a list card to first frame | under 250 ms | under 200 ms |
| Header collapse or reveal | 60 fps, no frame over 16.6 ms | same |
| Memory after 5 minutes of use, five tabs visited | under 250 MB | under 400 MB |

"Longest list" = the Ledger list with the All period and about 2,000 synthetic bills; Account Ledger list with about 5,000 synthetic entries.

## 2. Rules (apply to every task in MIGRATION_PLAN.md)

1. `const` constructors and `const` subtrees wherever possible. Enable the lints `prefer_const_constructors`, `prefer_const_literals_to_create_immutables` (210 analyzer infos today, mostly these and `withOpacity`).
2. Lists: `ListView.builder`/`SliverList.builder` only; no `ListView(children: [...map])` and no `...entries.map(...)` inside a builder item for unbounded children (`_DateGroup` does this, `ledger_list.dart:~92`). Give items `ValueKey(id)` and `findChildIndexCallback`. Set `itemExtent` or `prototypeItem` only for fixed-height rows (cashbook rows).
3. Watch narrowly: `ref.watch(provider.select((s) => s.field))`. Today there are 122 `ref.watch(` calls in `lib/features` and 11 `.select(` uses. `CombinedHomeScreen.build` watches 9 providers; `StatsScreen.build` watches 5 only to force rebuilds (`final _ = (...)`, `stats_screen.dart:49-55`).
4. Cache formatters: `NumberFormat` and `DateFormat` are created inside `build` in about 33 and 39 places (e.g. every bill card). Move them into `RigFormat` as `static final` instances (locale `en_IN` is expensive to construct).
5. No heavy work in `build`: sorting day keys (`ledger_list.dart:16-17`), filtering four side-ledger lists (`combined_home_screen._filterByTimePeriod`, called in `build`), `PortfolioCalculator.compute(...)` (`portfolio_view.dart:36-46`), chart data series (`stats_screen.dart`) move to memoized providers or `didUpdateWidget`/`initState` caches keyed on inputs. This does not change the calculations, only when they run.
6. Avoid `Opacity` (125 `withOpacity` color uses are fine; the `Opacity` widget is not), `BackdropFilter`, `ShaderMask`, `saveLayer` clips. Prefer `AnimatedOpacity` on small leaves, colors with alpha, `ClipRRect` only on images. Current counts: `ClipRRect`/`BackdropFilter`/`ShaderMask` 2 uses in lib (low risk).
7. Shadows: remove per-card blurred `BoxShadow` in lists (27 shadow sites); use the 1 px border. Keep one shadow on FAB, menus, dialogs.
8. `RepaintBoundary` only where DevTools shows repaint cost (candidates: `CalendarViewWidget` grid, chart widgets, collapsing header content). Do not add by default.
9. Split files and screens over 400 lines into small private widgets: `pdf_export_screen.dart` 1595, `stats_screen.dart` 1421, `combined_home_screen.dart` 1274, `ledger_form_screen.dart` 1177, `settings_screen.dart` 809, `side_bore_form_screen.dart` 809, `desktop_shell.dart` 807, four side list screens 650 to 770 each. Extracted widgets take values, not providers, wherever practical so they can be `const` and skipped.
10. `setState` scope: keep it in leaf `StatefulWidget`s. `ledger_form_screen.dart` has 22 `setState` calls on one 1177-line state: extract `_PaymentsSection`, `_CommissionSection` (exists), `_TotalsSection` into separate widgets with their own state or `ValueListenable`s so typing in one field does not rebuild the whole form. Calculations stay where they are.
11. No `setState` per scroll tick (B4). Scroll-linked UI uses slivers or a `ValueNotifier<bool>` that flips at a threshold.
12. Controllers: every `TextEditingController`, `ScrollController`, `TabController`, `AnimationController`, `FocusNode` created in `initState` and disposed in `dispose` (about 94 creations and 109 `dispose()` calls in features: audit for leaks in the first task; dialogs own their controllers per MEMORY.md).
13. Images and assets: `assets/images/logo.png` is 420 KB and `assets/icons/app-icon.png` 632 KB; the logo is shown at about 40 to 120 dp (`about_screen.dart:45`, `settings_screen.dart:168`). Use `Image.asset(..., cacheWidth: 240)` (2x of the largest displayed size) or ship a 256 px copy; a pending brand logo (final question) will replace it anyway. No network images exist. Use `SvgPicture` only if the new logo is SVG (flutter_svg is already a dependency).
14. Fonts: bundle only the used weights (Regular, Medium, SemiBold); no runtime font fetch; keep the Tamil fallback file (about the size of one font) lazy by `fontFamilyFallback`.
15. Do not call `DatabaseService` from widgets in new code. Today 10 feature files do (export screens 22 + 22 uses, settings 4, side forms 3 each, ledger forms 2 each); that is a convention breach and prevents memoization. Fixing it touches data access paths and is listed in BUGS_FOUND.md for approval, not done in the UI revamp.

## 3. Per-screen budget (rebuild scope and structure)

| Screen | Largest known cost today | Budget and plan |
|---|---|---|
| Ledger tab (`combined_home_screen`, `ledger_list`, `summary_row`) | whole-screen rebuild from 9 watches; per-card shadow; eager day groups; formatter creation per card | build under 4 ms per frame during scroll; header leaf consumers; sliver list; static formatters; shadows removed |
| Side Ledger tab | four list filters per build; `Row(spaceAround)` stats | filters memoized once per input change; tiles `const` where possible |
| Calendar view | `GridView shrinkWrap` inside a scroll view, 31 containers with gradient chips | `SliverGrid`, flat chip color; raster under 4 ms |
| Portfolio Overview | `PortfolioCalculator.compute` in `build` on every rebuild and every provider tick; `allRigs` reads all Hive boxes | memoize per (source, range, agent); `select` the five source lists |
| Portfolio and Stats charts | `fl_chart` data built inside `build`, 5 provider watches that force rebuild | chart data built once per input change; chart widgets in `RepaintBoundary` only if profiling shows repaint |
| Agents | rebuilds list on any agent or ledger change (commission totals provider) | `ListView.builder`, rows keyed by id, totals via `select` |
| Account Ledger home | Hive-backed derived providers keyed by `CashQuery` record | list `SliverList.builder`, `itemExtent` 64 for rows, no per-row `NumberFormat` creation (settings-driven formatter cached per settings change) |
| Forms (main, side bore, side ledger) | 22 `setState` on one state | section widgets; amount fields use `ValueListenableBuilder` for totals only if the calculation is already a listener, otherwise unchanged |
| Settings | long `Column`, sync status, backups | `ListView`; sync status leaf consumer |
| Export screens (PDF 1595 lines, CSV) | 22 `DatabaseService` reads each; PDF build on UI isolate | PDF generation stays as is (content frozen); show progress, do not block input; consider `compute` only if profiling shows a UI stall (it is a logic-adjacent change, so listed under LOGIC_REQUESTS.md) |
| Shells | `IndexedStack` of 5 live screens; shell watches 3 to 4 providers | see D-1 |

## 4. Decision D-1: IndexedStack keeps all five tabs alive

Both shells use `IndexedStack` (`main_navigation.dart:44`, `desktop_shell.dart:~775`).

| | Keep IndexedStack | Replace with lazy page switch |
|---|---|---|
| Scroll position and in-progress UI state per tab | retained (the user comes back to the same place; period chips, filters, search retained) | lost unless state is hoisted (providers already hold periods and filters, but scroll offsets and form-like local state such as `_agentId`, `_allRigs` in Portfolio would reset) |
| Memory and rebuild cost | all five trees exist; hidden tabs still rebuild when providers change (Portfolio and Agents rebuild on every ledger edit) | only the visible tab is alive |
| Startup | all five built at launch (cold start cost) | only the first tab |
| Risk | none (current behavior) | behavior change; logic freeze says navigation outcomes must not change |

Recommendation: keep `IndexedStack` for the revamp (no behavior change), but make hidden tabs cheap: wrap each tab body in a widget that stops listening when not current (`TickerMode` is already handled by `IndexedStack`; add `Visibility`-aware providers is NOT possible without logic changes), so rely on narrow `select` watches. Revisit after profiling: if cold start or memory misses the targets, a lazy build for Portfolio, Agents and Settings only (first visit builds, then retained, via `AutomaticKeepAliveClientMixin`) keeps state and removes startup cost. Needs approval (final questions, Performance targets).

## 5. How to measure

1. Build and run in profile mode on a physical Android device and on macOS: `flutter run --profile -d <device>` (the emulator is not representative for raster time; use it only for functional checks).
2. DevTools Performance tab: record a 10 s fling of the longest list; read frame build and raster times (target above) and the jank count; use "Track widget builds" in the Performance overlay settings to confirm `CombinedHomeScreen` does not rebuild while scrolling.
3. `flutter run --profile --trace-startup` and read `build/start_up_info.json` (`timeToFirstFrameMicros`) for cold start; repeat 5 times, take the median.
4. DevTools Memory: snapshot after visiting all tabs; look for leaked controllers or retained route widgets.
5. Seed data: a throwaway synthetic dataset generator in a developer-only script outside the repo (never real data in the repo): 2,000 bills over 3 years, 5,000 cash entries, 12 agents, 3 rigs.
6. Record the baseline BEFORE the first migration task and store the numbers in `docs/design/PERF_BASELINE.md` (numbers only, no data), then re-measure after each task that touches a list, header or shell (listed in each MIGRATION_PLAN.md task).
7. For every list screen the acceptance line is: profile-mode fling with the seed dataset shows no frame over 16.6 ms apart from the first frame after navigation.

## R. Reconciliation 2026-10-13 (Android only, answers 11, 12, 21, 22)

### R1. Targets (not gates until a baseline exists)

Until Phase 0 records a profile-mode baseline on the reference device, these are TARGETS and nothing is blocked by them. After the baseline, each screen task records its numbers and a regression of more than 20 percent against the baseline needs an explanation in the commit body.

| Metric | Target |
|---|---|
| Frame build time, p90 | under 8 ms |
| Frame raster time, p90 | under 8 ms |
| Frame build and raster, p99 | under 16 ms |
| Janky frames (over 16.6 ms) on the longest list scroll (10 s fling, 2,000 bills; 5,000 Account Ledger entries) | under 2 percent |
| Cold start to first interactive Ledger frame (profile or release) | under 2 s, goal 1.5 s |
| Tab switch to first painted frame | under 100 ms |
| Header collapse and reveal | no frame over 16.6 ms |
| Memory after visiting all tabs for 5 minutes | record in the baseline, no target yet |

The macOS column of section 1 is dropped.

### R2. Reference device
Answer 22 was left as the template placeholder. Claude's delegated answer (DESIGN_DIRECTION_APPLE.md Q-O4): PROVISIONAL reference = the attached emulator `sdk_gphone64_arm64` (Google), Android 16 (API 36), about 2 GB RAM, arm64, 1080 x 2400 at 420 dpi (411 x 914 dp), read with `adb` on 2026-10-13. Emulator raster and frame times are not representative of a phone, so every baseline number is marked PROVISIONAL until T-B01 repeats it on a physical mid-range Android phone that the developer names.

| Metric | Baseline (profile mode, reference device) | Date |
|---|---|---|
| Cold start | TBD | |
| Ledger list scroll p90 build / raster, p99, janky percent | TBD | |
| Account Ledger list scroll | TBD | |
| Tab switch | TBD | |
| Header collapse | TBD | |

### R3. Decision D-1 resolved: lazy tabs
Answer 12: Portfolio, Agents and Settings are built on first visit and kept alive afterwards. Implementation: a lazy stack wrapper that builds a child the first time its index is selected and then keeps it in an `IndexedStack` (or `AutomaticKeepAliveClientMixin` per tab). Ledger and Accounts stay built at launch (Q-O3 asks about Accounts). Expected effect: cold start and memory improve; first visit to the three tabs pays their build once. Verification: parity lines in PARITY_CHECKLIST.md section "Lazy tabs and theme"; compare cold start and the first-visit tab switch against the baseline.

### R4. New costs from the Apple look and their budget rules
- Blur: `BackdropFilter` is OFF by default (solid 94 percent bar with a hairline). Enabling it needs a profile-mode comparison on the reference device with a long list scrolling under the bars; accept only if p99 stays under 16 ms. One blur layer per bar, never in scrolling content.
- Sticky day headers (decision: ship): one `SliverPersistentHeader(pinned: true)` per day group. Watch layout cost with 2,000 bills over about 700 days; fallback is a single sticky header driven by the first visible group.
- Large title collapse: `CustomScrollView` slivers, no `setState` per scroll tick; the status strip fades on a `ValueNotifier<bool>` flip at the threshold.
- Gradient tiles (4 on Side Ledger home): one `LinearGradient` each, static, no animation.
- Ring and bar reveal animations: `TweenAnimationBuilder` once per screen entry, skipped under `MediaQuery.disableAnimationsOf`.
- Shadows: only in light mode and only on cards in non-scrolling areas; list rows are flat (`RigGroup` rows have hairlines, no shadow). Dark mode has no shadows.
- Row actions: long press plus a trailing more button only (Q-O7: no swipe, no new dependency), so no per-row drag detector.
- Fonts: Inter 4 weights; prefer the variable file only if all four weights render identically and tabular figures work (acceptance in T-F02).
- Floating tab bar overlays the body: list padding = 62 + inset + 8 + 24 dp; no `Opacity`.

### R5. Dropped
Every macOS and desktop item: window size, 900 px layouts, sidebar and title bar costs, the macOS memory target, the macOS profile command in section 5 (use `flutter run --profile -d <android device>` only).
