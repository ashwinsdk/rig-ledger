# Mockup notes: Flutter cost of each effect and the cheap alternative (Android only)

Cost scale: S under half a day, M about a day, L several days. "Cheap" keeps the look close at a fraction of the cost or the raster load. Performance budget from PERFORMANCE.md applies: no blur inside scrolling content, no per-frame `setState`, const decorations.

| Effect (where in the mockup) | Flutter implementation | Cost | Cheap alternative |
|---|---|---|---|
| Large title that collapses to a centred inline title with a blurred header and hairline | `CustomScrollView` with `SliverAppBar.large` (or `SliverPersistentHeader` for a custom title row); the collapsed bar background is `BackdropFilter` clipped to the bar | M | `SliverAppBar.large` with a solid `surface` at 94 percent opacity and a hairline `Divider` (the default; blur is behind the Glass blur toggle) |
| Floating tab capsule (`#nav`) | `Stack` over the body; the capsule sits `viewPadding.bottom + 8` above the bottom; `extendBody: true`, list padding = bar height + inset + 24. Default fill: `barSolid` (94 percent) with a hairline border | M | `NavigationBar` themed (pill indicator, `surfaceContainer` at 94 percent) inside a `Padding` with a radius |
| Glass blur, ONE Dev toggle "Glass blur", default OFF | Off: solid surface at about 94 percent plus a hairline (shipped default). On: `BackdropFilter(ImageFilter.blur(sigmaX: 20, sigmaY: 20))` clipped to the bar rect on the tab bar and the collapsed header, never on lists; one saveLayer per frame each. **Blur must be profiled on the reference Android device (frame build and raster time in profile mode, with a long list scrolling under the bars) before it is turned on.** Keep it behind a build flag | M | leave it off |
| Sheet scrim blur (part of the same toggle) | `showModalBottomSheet(barrierColor)` has no blur; blur needs a custom route with `BackdropFilter` | M | plain scrim colour (dark .55, light .35); this is the default and what Android users expect |
| Sheets with grabber and 28 pt top radius, full height form sheets | `showModalBottomSheet(isScrollControlled: true, showDragHandle: true, shape: RoundedRectangleBorder(...))` | S | none needed |
| Alerts (270 dp, stacked 48 dp buttons, destructive in red) | `RigAlertDialog` built on `Dialog` with a `Column` of full-width `TextButton`s and hairlines | S | Material `AlertDialog` with `actionsAlignment: stretch` |
| Continuous corners (squircle) | `RoundedSuperellipseBorder` (recent Flutter) or `ContinuousRectangleBorder` | S | `RoundedRectangleBorder` 20: the difference is barely visible at this size |
| Inset grouped lists and form rows (label left, value right, hairline separators inset 16) | `RigGroup` = `ClipRRect` + `Column` of rows with `Divider(indent: 16, height: 0.5)`; rows are `InkWell` + `Padding` | M | `Card` + `ListTile`s with `Divider`; keep the 48 pt row height |
| Form rows with focus ring and error state | `RigFormRow` around `TextFormField` with `InputDecoration.collapsed` and a `DecoratedBox` border on focus | M | Standard filled `TextField` per row, accent underline on focus |
| Toggle (51 x 31, Apple look) | Flutter `Switch` with `SwitchThemeData` (thumb white, track on = `moneyIn`, off = `fillStrong`, transparent outline, padded tap target). Not a custom widget, not `Switch.adaptive` | S | default Material 3 `Switch` |
| Circular check marks | Flutter `Checkbox` with `CheckboxThemeData(shape: CircleBorder(), side, fillColor, checkColor)` inside a 48 dp target | S | default `Checkbox` |
| Pill buttons 50 pt and tinted secondary | `FilledButton` / `FilledButton.tonal` with `StadiumBorder`, `minimumSize: Size.fromHeight(50)` | S | same |
| Inverse period chips and segmented controls | `ChoiceChip` themed (selected = inverse), `SegmentedButton` themed or a custom `RigSegmented` (the mockup uses a 3 px inset thumb) | M | `SegmentedButton` with default animation |
| Activity ring card (received versus billed) | `CustomPainter` with a round-cap arc and `TweenAnimationBuilder` for the reveal | S | `CircularProgressIndicator` with `strokeCap: StrokeCap.round`, `strokeWidth` 16, no animation |
| Metric cards with tap for full value | `RigMetricCard` + `MoneyText` (below); tap opens a small popover or `RigSheet` | M | `Tooltip`/long press showing the full value (already in HIGHLIGHTS_AND_COLLAPSE.md) |
| `MoneyText`: full, then scale to 75 percent, then compact (L, Cr), last guard shrinks | `LayoutBuilder` + `TextPainter` measuring once per (string, style, scale, width), cached; `FittedBox` as the last guard | M | `FittedBox(fit: BoxFit.scaleDown)` with the compact string when the number is above 1,00,00,000 |
| Inter and tabular figures | bundle Inter (OFL) as an asset font; `TextStyle(fontFamily: 'Inter', fontFeatures: [FontFeature.tabularFigures()])` on every amount style; the mockup loads the same file with `@font-face` | S | none needed |
| Gradient category tiles | `Container` with `LinearGradient` from the category colour to a 62 percent mix with white, black label | S | flat category colour at 100 percent |
| Day groups with sticky headers | `SliverPersistentHeader(pinned: true)` per group | L (cost grows with groups) | not sticky (HIGHLIGHTS_AND_COLLAPSE.md already decided list rows for headers); or `sliver_tools` `SliverStickyHeader` |
| Swipe actions on rows (Edit, Delete) and long press menu | `flutter_slidable` (dependency) or `Dismissible` for one action; long press with `showModalBottomSheet` | M | long press menu only; or `Dismissible` for Delete with the existing confirm |
| Slim summary strip that scrolls sideways (v2.0.1, `.sumstrip`) | `SingleChildScrollView(scrollDirection: Axis.horizontal)` of fixed width items in one rounded `Container` (already built in `summary_row.dart`) | S | none needed |
| Feet drop down with a chip per type (v2.0.1, `.feetbar`) | `InkWell` header row plus a `Wrap` of chips, state in the widget (already built in `summary_row.dart`); no animation needed | S | `ExpansionTile` with the divider colour set to transparent |
| Two large scope pills with icons (v2.0.1, `.scope`) | two `Expanded` `GestureDetector`s in a rounded `Container` (already built as `_ScopeToggle`) | S | `SegmentedButton` with icons |
| Agent detail bottom sheet (v2.0.1) | `showModalBottomSheet(isScrollControlled: true)` with a scrolling `Column` (already built as `_AgentSheet`) | S | none needed |
| Bill line card with remove X and Add line button (v2.0.2, `.lnh`, `.addln`) | a `Column` of cards, each a `Container` (surface, radius 12) with an optional header `Row` (title and `IconButton(Icons.close)`) and the fields (already built as `LinesSection` in `widgets/line_editor.dart`); `TextButton.icon` below | S | none needed |
| Agent view (v2.0.3, `.agh`, `.agp`, `.mtb`, `.agb`, `.agt`, `.agi`) | a `Column` of plain `Container`s inside the Overview `SingleChildScrollView` (already built as `AgentView` in `agent_view.dart`): gradient header with `IconButton(Icons.tune)` and a `TextButton.icon` back button, profit `Container` (green or red at 8 percent with a 30 percent border), two `Row`s of `_kpi` boxes, a month table of `Row`s, a `_BillRow` `InkWell` card per bill, a totals `Wrap` | S | none needed; the mockup stacks the month table rows and the bill amounts at 150 percent text and above, in Flutter use `LayoutBuilder` or let the `Wrap` flow |
| Agent filter pill and sheet (v2.0.2, `.afp`, `#aflist`) | `InkWell` pill with a `Row` (already built as `_AgentFilterPill`); `showModalBottomSheet(isScrollControlled: true)` with a search `TextField` and a `ListView` of `ListTile`s (already built as `_AgentFilterSheet`) | S | none needed |
| Calendar grid (Apple Calendar style, amounts under the day) | `GridView.count(crossAxisCount: 7)` with cells | S | existing `CalendarViewWidget` restyled |
| Insight cards with line chart, scrub marker | `fl_chart` (already ^0.66) `LineChart` with `LineTouchData` tooltip and a vertical indicator | M | `sparkline` `CustomPainter`, no scrub; needs LR-21 and LR-22 either way |
| Donut | `fl_chart` `PieChart` (exists in stats) with `centerSpaceRadius` | S | keep as is |
| Bar chart per category | `fl_chart` `BarChart`, or plain `Container`s in a `Row` (as in the mockup) | S | plain `Container`s |
| Status strip when the header is collapsed | a pinned second row in the same `SliverPersistentHeader`; no per-scroll `setState` (ValueNotifier flip, see HIGHLIGHTS_AND_COLLAPSE.md A.5) | M | omit the strip, keep only the title |
| Skeleton loading | `Shimmer`-like `AnimatedContainer` gradient or a static grey box | S | static grey boxes |
| Light and dark | two `ColorScheme`s + `RigColors` extension; `ThemeMode.system` (Android 10 and up); LR-23 persists the choice; no dynamic colour (`useMaterial3` with hand-built schemes, not `dynamic_color`) | M | follow the system only, no setting |
| Accent preview | one seed in `RigColors`; not needed in the release app | S | ship blue only until the brand is ready |
| Rounded icon set | `Icons.<name>_rounded`; names are identical to the mockup glyph names | S | none needed |
| Press feedback on every tappable row, card, chip and button | `InkWell` inside `Material` with `splashColor`/`highlightColor` from `pressOverlay`; `ThemeData.splashFactory: InkSparkle.splashFactory` for the Android 12 stretch ripple; the mockup shows only the pressed overlay | S | default `InkRipple` |
| 48 dp touch targets | `kMinInteractiveDimension`, `MaterialTapTargetSize.padded`; chips and segments keep a 48 dp box around a smaller visible pill (`Padding` inside `InkWell`) | S | none needed |
| Edge to edge, status bar 28 dp, bottom inset 24 dp (gesture) or 0 (3-button) | `SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge)`, transparent system bars, `MediaQuery.viewPaddingOf` for the tab bar, sticky buttons and list padding; read the inset, never hard-code 24 | M | `SafeArea` around the Scaffold body (loses the content under the bars) |
| Keyboard: field and primary button stay visible | `Scaffold(resizeToAvoidBottomInset: true)`; sheets add `MediaQuery.viewInsetsOf(context).bottom` as bottom padding with `isScrollControlled: true`; `Scrollable.ensureVisible` on focus; the pinned bottom button is a `bottomNavigationBar`-style sibling above the keyboard | M | `SingleChildScrollView` with `padding: viewInsets` |
| Reduced motion | `MediaQuery.disableAnimationsOf(context)` selects zero duration | S | none needed |
| Text scale 200 percent: rows stack, 2 column grids become 1 | `LayoutBuilder` + `textScaler`; rows switch to `Column` above 1.6 | M | allow wrapping and rely on `MoneyText` |

## System back mapping (Android)

The Dev button "System back" and Escape run `sysBack()`: keyboard first, then a popover, then the top dialog or sheet, then the top screen, then on a root tab the app is left (Android default; decided 2026-10-13, the mockup shows a snackbar). In Flutter:

| Mockup step | Flutter |
|---|---|
| hide the keyboard | default Android behaviour: the first back press closes the IME |
| close the top dialog or sheet | `showDialog` and `showModalBottomSheet` are routes: back pops them with no extra code (`barrierDismissible` true for sheets) |
| pop the top screen | `Navigator` pop; forms with unsaved input wrap the page in `PopScope(canPop: !dirty, onPopInvokedWithResult: ...)` and show the discard alert |
| leave the app on a root tab | no root `PopScope`: Flutter and Android default send the app to the background |
| predictive back (Android 13 and up), DECIDED: enable in the first Android build | set `android:enableOnBackInvokedCallback="true"` in the manifest, use `PredictiveBackPageTransitionsBuilder` in `pageTransitionsTheme`, and use `PopScope` (not the deprecated `WillPopScope`). Sheets and dialogs animate with the system gesture automatically once the flag is on |

No in-app navigation depends on an edge swipe. Row swipe actions (Edit, Delete) remain, with a long press menu as the non-gesture path.

## What the mockup deliberately does not do

- Swipe uses CSS scroll snap, so it works with touch and mouse but has no spring physics.
- The `field-sizing: content` rule that keeps the rupee sign next to an amount in a form row is Chrome only. In Flutter use a `Row` with an `IntrinsicWidth` text field.
- Charts are static SVG with a pointer scrub, data computed in the page (flagged needs logic).
- No keyboard avoidance, no real pickers (date range, camera, file picker): they show a snackbar.
- Icons are a webfont. In Flutter they are `Icon` widgets; names map one to one.

## QA tooling (qa/)

| Script | Purpose |
|---|---|
| `smoke.mjs` | open every J screen, fail on script errors |
| `token-audit.mjs` | no raw colours outside tokens |
| `logic-diff.mjs` | logic block identical to `qa/logic-baseline-v2.0.4.txt` (v2.0.1, v2.0.2, v2.0.3 and v2.0.4 changed it on purpose), plus hand-computed numbers (multi-line bill totals, step rate and commission, Portfolio numbers with and without an agent filter, feet by type over all lines, the 3 month agent view figures, the commission recalculation after a price edit); `--update` rewrites the baseline |
| `flows.mjs` | click-through checks (v2.0.2, v2.0.3 and v2.0.4; the 2.0.4 part reloads the page first because the 2.0.3 part edits agent prices): Step Rates (labels, live example, add and remove bracket, empty and non-number snack, save, reset dialog, a saved bill keeps its step rate, a new bill uses the new table), the feet and commission card, the entry rig (row, locked linked entry, sheet, Save and add another, Copy, report footnote), add and remove bill lines, totals and commission after typing, agent choice and type change fill the line rate, bill card chips, filters match any line, Portfolio agent filter (search, choose, reset), agent view (header, profit card, month table, bill cards, back, row tap, info icon, empty state), agent edit with the commission recalculation and its snack texts, agent delete |
| `shoot.mjs` | screenshots (light and dark) and checks: overflow and clipping, text under 11 px, touch targets under 48 dp, contrast under 4.5:1 (3:1 for large text), keyboard visibility (every field and the primary button above the simulated keyboard); flags `--stress`, `--ts 2`, `--width 360`, `--nav3`, `--blur`, `--no-kb` |
| `contact.py` | contact sheets per theme |
| `peek.mjs` | quick screenshots of chosen screens |

## v2.0.1 notes (what the mockup does and does not claim)

- The mockup now follows app 2.0.1: four tabs (the Agents tab is gone; agents live in Portfolio), Ledger Types, Other expenses, per-type agent prices, commission breakdown, slim Ledger header. `SCREEN_MAP.md` has the screen by screen list.
- The Apple look is a restyle target. The 2.0.1 Flutter screens keep the older Material look (gradient app bars, cards). Where the app and the mockup differ only in style, the mockup wins for the later restyle; where they differ in behaviour, the app (read from the code) wins.
- Not shown on purpose: the Ledger home mini stat row of the Side Ledger (the mockup uses category tiles for every category, the "Other expenses" tile carries the entries and total), custom step brackets (not editable in 2.0.1), real pickers (snackbar), the Android file save dialog.
- `qa/logic-diff.mjs` no longer compares with the v1 file: the data and derived logic changed on purpose in 2.0.1 (see MOCKUP_PROGRESS.md), so its baseline is `qa/logic-baseline-v2.0.1.txt`, plus hand-computed checks. `qa/shoot.mjs` treats `.hscroll` like `.chips` and `.swp` (a sideways scroller may extend past the screen edge).

## v2.0.2 notes (what the mockup does and does not claim)

- The mockup now follows app 2.0.2+7: a bill has several lines per category (depth, PVC, MS pipe), the Portfolio agent chip row is one pill that opens a searchable sheet, and the agent Edit and Delete work. `SCREEN_MAP.md` has the v2.0.2 section.
- Bill lines are data, not fields: `BILLS[i].L` is a list of lines `{c, t, f, r, k}` (category, type, feet, rate, commission rate). Every bill number (total, step rate, commission, feet by type, Portfolio, card chips, filters, export samples) is computed from those lines in the logic block. The step rate is the sum over the depth lines of each line worked out alone (own type table, feet from 0), as in `LedgerEntry.calculateLinesStepRate`; side bore bills have none. The old flat fields (`dt`, `d`, `dr`, `pt`, `p`, `pr`, `m`, `mr`, `cr`) are gone.
- The mockup keeps one line per category on an old bill that had one (as the app does) and adds one empty line for a category a bill had no line in (PVC and MS pipe on the edit form), like the app form. Saving does nothing in the mockup (snackbar), as before.
- Agent edit and delete change the dummy data for real (name, prices, removal, bills deleted or reassigned) so the click-through shows the result; nothing is stored, a reload restores the dummy data.
- Not shown on purpose: per-line step rate editing (the step rate field is one number for all depth lines, as in the app), the CSV import of lines (the app keeps one line per category), a PDF with a per-line column (the app has none).
- `qa/logic-diff.mjs` compares with `qa/logic-baseline-v2.0.2.txt`; `qa/flows.mjs` is new.

## v2.0.3 notes (what the mockup does and does not claim)

- The mockup now follows app 2.0.3+8 (`docs/v2.0.3-review.md`): editing an agent's prices updates the commission of the agent's existing bills, and Portfolio shows an agent view when an agent is chosen. `SCREEN_MAP.md` has the v2.0.3 section.
- The price edit really changes the dummy data in the page (`recalcAgentBills` in the logic block mirrors `CommissionRecalc.changedBills`): a bill whose commission total was typed by hand is skipped; every other bill of that agent has each line follow the new price only when the line rate equals the agent's OLD price of that line type (type price, else the kind default); a line with another rate keeps it (bill 1036 has a PVC line with a hand-typed rate of 8); side bore bills use the default depth rate and only their depth lines; the bill commission is the sum of feet x line rate, rounded to paise. The snack says "Agent updated" or "Agent updated. Commission changed on N bills" (one bill: "bill"). The ledger cards, the summary strip, Portfolio and the agent view all read the same data, so they change together. Nothing is stored, a reload restores the dummy data.
- The agent view opens from the pill sheet or from a tap on an agent row of the Agents section (the info icon button next to the row, tooltip "Prices and details", opens the details sheet; the chevron is gone). It replaces the profit card, the metric cards, the expenses card, the Agents section and the definitions. The back button "All agents", choosing "All agents" in the sheet, a This rig / All rigs change or a rig change return to the normal Overview.
- Period text: the mockup clips the end of the period at the mockup date (13 Oct 2026), like the app clips at today ("01 Aug 2026 to 13 Oct 2026"); "All time" for the All range.
- Dummy data added so a 3 month period shows three months for one agent: bill 1036 (Karthik, 18 Aug 2026, depth 250 ft 7inch, PVC 90 ft 7inch with the hand-typed commission rate 8). Karthik now has bills in Aug, Sep and Oct.
- Not shown on purpose: the Flutter agent view does not clip long agent names with a tooltip (ellipsis only), the mockup does the same; the tap on a bill opens the bill form (the mockup form, saving shows a snackbar).
- `qa/logic-diff.mjs` compares with `qa/logic-baseline-v2.0.3.txt`.

## v2.0.4 notes (what the mockup does and does not claim)

- The mockup now follows app 2.0.4+9 (`docs/v2.0.4-review.md`): Step Rates per rig, "Feet and commission by type" in the agent view, an optional rig on Account Ledger entries. `SCREEN_MAP.md` has the v2.0.4 section, `TOKENS.md` section 11 the new components.
- Step tables are data (`STEPR[rigId] = {t7, t8}`, each `{th, ex, bey}`), the formula `stepCalc` mirrors `StepTable.calculate`: 0 up to the start; bracket i charges the feet inside it times `ex[i]`; beyond the last bracket the k-th further 100 ft (and the remaining part) costs last + growth x k per ft. Ledger Types still chooses which table a depth type uses ('7inch', '8inch' or none). Saving on the Step Rates screen really changes the page data; nothing is stored, a reload restores the standard tables.
- Saved bills store their step rate (`b.stp`, worked out once with the standard tables when the page loads). Editing a table never changes a saved bill, a ledger card or a Portfolio number (`logic-diff.mjs` proves it). The bill form of a saved bill shows its stored step rate and recalculates with the CURRENT tables only after a depth line is added, removed or its type or feet are changed (unless the step rate was typed by hand); a new bill always uses the current tables of the form's rig. Side bore bills have no step rate.
- The dataset has one main bore rig, so the Rig dropdown on Step Rates lists one rig. Account Ledger entries have an optional rig `v` (a Vehicle id): the linked income of bills 1039 and 1042 has the rig 'main'; three hand-typed entries have one (two on Main Rig, one on Side Rig 1); transfers have none. The Flutter dropdown is a native menu; the mockup shows the choices as a sheet. The rig is a label: it does not change any total or balance and search does not look at it.
- Copy on the entry form now really adds the copy to the data (with the rig, never linked); Save still only shows a snack, as before.
- The Account Ledger "Report" sheets only describe the Rig column (CSV) and the Rig line (PDF notes); there is no preview screen in the app either.
- Not shown on purpose: a filter by rig on the Account Ledger (not in the app yet), a second main bore rig.
- `qa/logic-diff.mjs` compares with `qa/logic-baseline-v2.0.4.txt`.
