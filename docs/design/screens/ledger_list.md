> SUPERSEDED IN PART (2026-10-13): the look is now the Apple-inspired Android direction. Read "Reconciliation 2026-10-13" at the end of this file first; where it conflicts with sections 4 to 7 above, it wins.
# Ledger list widgets: ledger_list, summary_row, calendar_view, filter_sheet, search_sheet

Files (all under `lib/features/home/widgets/`): `ledger_list.dart` (356 lines), `summary_row.dart` (263), `calendar_view.dart` (208), `filter_sheet.dart` (239), `search_sheet.dart` (133). Used by `combined_home_screen.dart` (live) and `home_screen.dart` (dead). Highlights behavior is specified in `HIGHLIGHTS_AND_COLLAPSE.md`.

## 1. Purpose and primary user task

Show the bills of the selected period grouped by day, let the user open one, see money and feet totals, switch to a month calendar of day totals, search by text, and filter by bill number, address, agent, depth type and PVC type.

## 2. Current structure

- `LedgerList` (ConsumerWidget): watches `groupedLedgerEntriesProvider` (Map day -> entries), sorts keys descending in `build`, `ListView.builder(padding bottom 100)` of `_DateGroup` (header row with `EEE, dd MMM yyyy` and day total, then `...entries.map(_LedgerEntryCard)`).
- `_LedgerEntryCard` (ConsumerWidget): `Container(margin 16/4, radius 16, BoxShadow blur 10) > Material > InkWell > Padding 16`; row 1 bill chip `#number` + agent name; row 2 `_InfoChip` Depth and PVC; row 3 three `_ValueDisplay` (Total, Received, Balance); commission `_InfoChip` when above zero. Tap opens `SideBoreFormScreen` or `LedgerFormScreen` by vehicle type.
- `SummaryRow` (ConsumerWidget): two cards (money, feet) described in HIGHLIGHTS_AND_COLLAPSE.md B.1.
- `CalendarViewWidget` (ConsumerWidget): month grid with day totals from `calendarDayTotalsProvider`, legend.
- `FilterSheet` (ConsumerStatefulWidget): transparent-background modal sheet, text fields (bill number, address), three `DropdownButtonFormField`s (agent, depth type, PVC type), Clear All, Cancel, Apply; writes `ledgerFilterProvider`.
- `SearchSheet`: modal sheet with an autofocus `TextField`, writes `searchQueryProvider` on change and on submit, Clear.

## 3. Problems found

1. Entry card values (`_ValueDisplay`, ledger_list.dart:~268-323) are plain `Text` in `Expanded` columns, 14 sp, no fit, no `maxLines`: a 10-digit amount wraps or overflows at 100 percent; at 200 percent three columns of "Total / Received / Balance" cannot fit a 343 dp card.
2. `_InfoChip` rows (Depth and PVC) have no `Flexible` or wrap; long depth text overflows the card at 130 percent and above.
3. Depth is printed as `'${entry.depthInFeet}ft'` straight from a double (ledger_list.dart:~175): shows `500.0ft` or any floating noise; summary uses `#,##0`. Mismatched number formatting between card and summary (BUGS_FOUND.md B-09).
4. Received uses `AppColors.success` (#10B981, 2.54:1) and Balance `AppColors.warning` (#F59E0B, 2.15:1) as text on white; both fail WCAG AA. The Balance color switches to green when balance is zero or below, so a credit looks identical to "received".
5. Card shape: radius 16 and blurred shadow per card (27 shadow sites app-wide); in a long list each card has its own `BoxShadow` raster layer cost.
6. Bill number chip uses `accentLight` at 30 percent with `primaryDark` 12 sp text: small and low contrast on white (about 1.2:1 background to surface); tap area is the whole card (fine) but the chip adds no meaning beyond the number.
7. The manual-total indicator is an 10 dp `Icons.edit` in `AppColors.warning` next to the "Total" label (no text, no tooltip, no semantics).
8. Empty state is always "No entries yet / Tap + to add your first entry" even when a search or filter produced the empty result (ledger_list.dart:20-45).
9. `LedgerList` sorts keys in `build` on every rebuild and `...entries.map` builds every card of a day eagerly (fine for 5 to 20 bills a day, costly for a day with 100).
10. `FilterSheet`: `ref.watch(ledgerFilterProvider)` in build although only read in `initState` (rebuilds the open sheet when the filter changes, harmless), the sheet gives no result count, dropdown labels "7 inch / 8 inch" differ from the form labels `7"` and `8"`, text fields have no keyboard action `done`, and Apply is the only way to commit (no live preview).
11. `SearchSheet` writes the query on every keystroke (list refilters per key) and autofocuses; on macOS a modal sheet for a one-line search is heavy (Cmd+F is registered and does nothing, desktop_shell.dart:362).
12. Icons: filled `Icons.edit`, outlined `Icons.straighten`, `Icons.format_paint_outlined` for PVC, `Icons.handshake_outlined`: three styles in one card.
13. No swipe, no long-press menu: the only action is the whole-card tap; delete lives inside the form.
14. Calendar (calendar_view.dart:104-131): day total is 9 sp white text on `cardGradient` (contrast about 3.7:1 and below the 11 sp floor), no `FittedBox` (overflow for totals above about 6 digits), cells have no semantics and no tap behavior, grid uses `shrinkWrap` with `NeverScrollableScrollPhysics`.
15. Day header total (`₹dayTotal`) is `primary` 14 sp w600 and not aligned with card values below it.

## 4. Redesign

### 4.1 `LedgerEntryCard` (replaces `_LedgerEntryCard`)

`RigCard` level 1 (no shadow, 1 px `outlineVariant`, radius `lg` 16, padding 16 compact / 12 dense on expanded), margin horizontal 16 vertical 4 (list gap 8).
- Row 1: bill chip `#<number>` (`labelMedium`, `primaryContainer` fill, `onPrimaryContainer` text, radius sm, padding 8 x 4) + agent name (`titleMedium`, `onSurface`, `maxLines: 1`, ellipsis) + trailing "edited" marker if `isTotalManuallyEdited` (`Icons.edit_rounded` 14 with tooltip "Total edited manually" and semantics).
- Row 2: `Wrap(spacing: 12, runSpacing: 4)` of info chips: Depth (`Icons.straighten_rounded` 16) and PVC (`Icons.format_paint_rounded` 16, hidden for side bore, existing rule), text `bodySmall`, `onSurfaceVariant` label and `onSurface` value, `feet()` formatter for depth (card and summary use one format; see B-09 for the decision).
- Row 3: three `AmountTile`-lite columns in a `Row` (equal flex) when width allows (each at least 96 dp) else a stacked list of label-value rows: Total (`primary`, `amountMedium`), Received (`moneyIn`), Balance (`outstanding` when above zero, `moneyIn` when zero or credit with the label unchanged, `negative` never used for Balance because the app does not define negative balance as an error). Each value fitted per B5 (min 12 sp, then compact).
- Row 4 (when commission above zero): `commission` chip with `Icons.handshake_rounded` 16 and amount, label "Commission".
- Whole card is one `InkWell` (min height 96); hover `surfaceContainerHigh` (desktop); focus ring.
- Semantics: one node: "Bill <n>, <agent>, depth <x> feet, total <t> rupees, received <r>, balance <b>".

### 4.2 `DayGroupHeader`

Sticky is not required. Row `[dateGroup label titleSmall onSurfaceVariant] [spacer] [day total amountSmall primary]`, padding 16 x 8, background `background`, total right aligned and baseline aligned with card totals.

### 4.3 List

`SliverList.builder` over a flattened list of (header or entry) rows built from the same grouped map, items keyed by id. Bottom padding 88. Day groups no longer built eagerly. Pull-to-refresh is not added (no new behavior).

### 4.4 Highlights, calendar, sheets

- Highlights: `HighlightsPanel` (B5), replaces `SummaryRow`.
- Calendar: `CalendarViewWidget` becomes a sliver child (`SliverGrid`, 7 columns). The day cell keeps today's content (day number and the day total) but the total uses `AmountText` compact policy inside `FittedBox` (cells are about 46 dp wide at 411 dp; today's 9 sp white text on a gradient chip is 3.7:1 and overflows for large totals); chip becomes `primaryContainer` with `onPrimaryContainer` text at `labelSmall` 11 sp. Cells are NOT interactive today (no `onTap` in calendar_view.dart) and stay non-interactive (a tap behavior would be a new feature, listed in LOGIC_REQUESTS.md); the only addition is a long-press or hover tooltip showing the full day total (UI only). Today is outlined `primary` 2 px as now; legend becomes text rows.
- `FilterSheet` becomes `EntryFilterSheet`: `RigSheet` titled "Filter" with `RigTextField`s, `RigDropdownField`s (labels `7"` / `8"` aligned to form labels, option text unchanged: "All Agents", "All Depths", "7 inch", "8 inch", "All PVC"), result hint "Apply to see results", actions `Clear All` (text), `Cancel` (outlined), `Apply` (filled, one per screen). On expanded widths it opens as a dialog (max 560). Keyboard: `textInputAction.next`, Enter applies.
- `SearchSheet`: compact keeps the sheet, `RigSearchField` autofocus, debounce 250 ms is NOT added (logic: it would delay the existing write); the write on change stays. Expanded: an inline `RigSearchField` in the app bar row that expands on click or Cmd+F focus. Cmd+F wiring itself is a bug fix tracked in BUGS_FOUND.md (B-05) and needs approval because it adds a handler body.

### 4.5 State table

| State | Behavior |
|---|---|
| Default | cards as above |
| Loading | 6 skeleton cards (96 dp) if the first load takes over 200 ms |
| Empty, no data | `EmptyState` icon `Icons.receipt_long_rounded` 48, "No entries yet", hint "Tap + to add your first entry" |
| Empty, filtered | `EmptyState` "No entries match", hint "Clear the search or filters", tonal `Clear` |
| Error | not applicable |
| Pressed or hover or focus | `surfaceContainerHigh`, ring |

### 4.6 Motion

Card press ripple only. New or removed rows animate 200 ms with `SliverAnimatedList` is NOT used (keeps list simple and key-stable); no list entrance animation.

## 5. Logic touchpoints that must stay untouched

`groupedLedgerEntriesProvider`, `ledgerFilterProvider` (`LedgerFilter` fields `billNumber`, `address`, `agentId`, `depthType`, `pvcType`, `hasFilters`), `searchQueryProvider`, `agentsProvider`, `isSideBoreProvider`, `currentVehicleProvider`, `LedgerEntry` getters (`total`, `received`, `balance`, `commission`, `depthInFeet`, `depth`, `pvc`, `isTotalManuallyEdited`, `billNumber`, `agentName`), `calendarDayTotalsProvider`, `selectedMonthProvider`, navigation `LedgerFormScreen(entry:)` and `SideBoreFormScreen(entry:)`, filter option string values (`'7inch'`/`'8inch'` or whatever the provider compares; keep the exact value strings, only labels may change), `_openEditForm`.

## 6. Acceptance criteria

1. A bill with total 12,34,56,789.00 (synthetic) renders its three values without overflow at 360 dp and 100, 130, 200 percent text scale (stack layout at 200).
2. A bill with a 40-character agent name truncates with ellipsis and never pushes the bill chip off screen.
3. Depth text of a bill shows one consistent number format in the card and the summary (per the decision in B-09), with no `.0` noise.
4. Tapping anywhere on a card opens the edit form for that bill (Side Bore opens the side bore form).
5. The manual-total marker has a tooltip and semantic label.
6. Empty list with no data and empty list with a search show different messages.
7. Filter sheet: Apply sets exactly the same `LedgerFilter` as before for the same selections; Clear All resets; Cancel makes no change; the filter icon dot appears iff `hasFilters`.
8. Search: typing filters live; Clear empties the query.
9. Calendar: day totals match `calendarDayTotalsProvider`; cells remain non-interactive except the tooltip with the full total; a total of 12,34,567.89 (synthetic) does not overflow a 46 dp cell.
10. Keyboard (macOS): Tab reaches each card, Enter opens it, Esc closes sheets.
11. No `BoxShadow` on list cards (grep), card radius 16 (`RigRadius.lg`).

## 7. Performance notes

- `const` constructors on all static children; `LedgerEntryCard` takes plain values, so `ListView` item rebuilds are cheap and `const` can skip work.
- Replace per-card `BoxShadow` (raster cost grows with visible cards) with a border.
- Sort once: the provider already groups; sort the keys in a derived provider or memoize in a `ConsumerStatefulWidget` keyed on the map identity, not in every build.
- Use `ValueKey(entry.id)` and `findChildIndexCallback`.
- Cache `NumberFormat` and `DateFormat` (today `NumberFormat('#,##0.00')` is created in every card build, ledger_list.dart:~120 and summary_row.dart:17).
- `SearchSheet`/`FilterSheet`: controllers are created in `initState` and disposed (verified for FilterSheet lines 32-36); keep.


## Reconciliation 2026-10-13 (Apple look, Android only)

Mockup source: `billRow`, `billList`, `rowMenu`, `calView`, `searchSheet`, `filterSheet`, `delBillDlg` in `docs/design/mockup/rigledger_apple_mockup.html`. Dropped from sections 1 to 7: macOS, expanded widths, hover, Cmd+F, right-click, two-column grids, desktop tooltips. The per-card shadow, bordered card and bill chip of section 4.1 are REPLACED by grouped rows.

### R1. Mockup screens and Flutter mapping

| Mockup screen (J label) | Render function | Flutter file | Widgets | Notes |
|---|---|---|---|---|
| Home (Ledger, Daily) | `billList`, `billRow` | `widgets/ledger_list.dart` | RigGroup, RigRow (bill row), RowActions, MoneyText | day header sticky |
| Calendar view | `calView` | `widgets/calendar_view.dart` | RigCard grid | cells 48 dp min, amount under the day |
| Calendar view with selected day | `calView` + `UI.calSel` | `widgets/calendar_view.dart` | RigGroup of RigRow | LR-03 proposed |
| Bill row actions (long press) | `rowMenu` | `ledger_list.dart` | RowActions, RigSheet, RigRow | Edit and Delete only |
| Delete entry alert | `delBillDlg` | `ledger_list.dart` | RigAlertDialog | existing delete flow |
| Search sheet | `searchSheet` | `widgets/search_sheet.dart` | RigSheet, RigFormRow | |
| Filter sheet | `filterSheet` | `widgets/filter_sheet.dart` | RigSheet, RigFormRow, RigButton | |
| Ledger empty / Ledger no search match | `emptyUI` | `ledger_list.dart` | EmptyState, RigButton | |
| Ledger loading | `skelList` | `ledger_list.dart` | Skeleton | first frame after a rig switch or restore |

### R2. What changes in the redesign (supersedes section 4)

Bill row (`RigRow` inside the day `RigGroup`, min height 96 dp, padding 16, separators 0.5 dp `sep` inset 16, press feedback ink `pressOverlay`):
- Line 1: agent name (17, 600, ellipsis, flex) left; total right (17, 700, tabular `MoneyText`, scales to 75 percent then 11 sp, never compact).
- Line 2 (13, `lb2`, wraps): `#<bill number>`, address, depth `ftq` and the depth type in brackets ("(7 in)"); PVC feet shown when above zero and the rig is main bore (the mockup omits it, see conflicts_r1.md C2); the manual-total marker `edit_rounded` 14 dp in `outstandingText` with the text "Total edited" (the mockup omits it, C3).
- Line 3: status pills (`pillsm`: 8 dp dot + text, 36 dp, radius full, `fill` background, wraps): "Received" + `money` (dot `moneyIn`), "Balance" + `money` (dot `outstanding`) when above zero, otherwise "Settled" (dot `moneyIn`); "Commission" + `money` (dot `commission`) when above zero. Overpaid (balance below zero) shows "Overpaid" + `money` (dot `moneyIn`) instead of "Settled" (copy only, mockup shows Settled, C4). Text colours use the `-Text` roles (`moneyInText`, `outstandingText`, `commissionText`).
- No bill chip, no card border, no per-row shadow.
- Whole row is the tap target (opens `LedgerFormScreen` or `SideBoreFormScreen` by rig type).
- Semantics: one node "Bill N, agent, depth X feet, total T rupees, received R, balance B".

Swipe and long press (RowActions): swipe left reveals two 72 dp action buttons, Edit (`accentButton`, white label) and Delete (`moneyOutButton`, white label); Edit opens the same form route as a tap, Delete opens RigAlertDialog "Delete Entry" / "Are you sure you want to delete this entry? This action cannot be undone." with Cancel (default) and Delete (destructive), then runs the same delete call as the form. Long press (520 ms) opens a RigSheet titled "Bill #N" with the same two rows (Delete in `moneyOutButton`). Swipe is the gesture path, long press is the non-gesture path; the package decision is Q-O7 (`flutter_slidable` or `Dismissible` for Delete plus the long-press menu). Footnote under the list: "Swipe a row left for Edit and Delete, or press and hold for the same actions."

Day header (sticky): `dGroup` ("Mon, 12 Oct 2026", 15/600, `lb2`) left, day total right (15/600, `accentText`, `MoneyText`, no compact), solid `canvas` background, 10 dp top, 6 dp bottom, margin 20.

Calendar: 7 column grid (margin 8), weekday initials (12, 600, `lb2`), cell min height 48 dp (aspect .8), day number in a 30 dp circle (today: `accentButton` fill with `onAccent` text; selected: `fill2`), day total under the number (11 dp minimum, `qty`, fitted, never wraps), cell `aria-label` "<dGroup>, <money>". Totals: LR-33 (selected month only). Tap on a day (selection plus a RigGroup of that day's bills below the grid) is LR-03, proposed; until it is approved cells stay non-interactive and the footer reads "Days with bills show the billed total." (as today) and only shows the tap hint after LR-03.

Search sheet: RigSheet "Search Entries", one RigFormRow with a `search` icon and the placeholder "Bill number, address, agent, notes", footnote "Search looks at bill number, address, agent name and notes.", bottom buttons Clear (tonal) and Search (filled, closes the sheet; the query is already written on each keystroke as today, no debounce, LR-05 not scheduled).

Filter sheet: RigSheet "Filter Entries", RigGroup of rows Bill number, Address, Agent (All Agents, then names), Depth type (All Depths, 7 inch, 8 inch), PVC type (hidden for side bore), top-right text button Clear All, bottom Cancel (tonal) and Apply (filled). Stored option values unchanged (`'7inch'`, `'8inch'`). Labels keep the existing case.

States: Default as above. Loading: 4 Skeleton rows (first frame after a rig switch or restore). Empty with no data: EmptyState (icon 52, "No entries yet", "Tap + to add your first entry.", RigButton "Add entry"). Empty with search or filter: "No entries match", "Try a different search or clear the filters.", RigButton "Clear search and filters". Error: not built (LR-34). Disabled: none. Pressed: ink overlay.

Old section 4 mapping: 4.1 card CHANGED (grouped row), 4.2 day header CHANGED (sticky now), 4.3 list KEPT (flattened `SliverList.builder`, keys by id), 4.4 highlights CHANGED (see combined_home_screen.md R2), calendar CHANGED (cells, tooltip DROPPED because hover is gone, long press tooltip replaced by the full value in the semantics label), sheets CHANGED (RigSheet, dialog variant DROPPED), 4.5 state table CHANGED, 4.6 motion KEPT (ink only; no list entrance animation; swipe open 200 ms ease-out; sheet 300 ms; instant under reduced motion).

### R3. Logic touchpoints and LR items

Untouched: the list in section 5 above (`groupedLedgerEntriesProvider`, `ledgerFilterProvider` and `LedgerFilter` fields, `searchQueryProvider`, `agentsProvider`, `isSideBoreProvider`, `LedgerEntry` getters, `calendarDayTotalsProvider`, option value strings, `_openEditForm`).

| Item | Status |
|---|---|
| LR-03 calendar day tap | proposed |
| LR-05 search debounce | not scheduled |
| LR-06 undo after delete | not scheduled (high risk, sync); the Delete alert is the safety net |
| LR-13 / LR-30 feet one decimal | decided display rule; input limit proposed |
| LR-33 calendar day totals | approved, Phase 1 |
| LR-34 list loading and error | proposed, default skeleton only |
| Proposed, new | none |

### R4. Acceptance criteria delta

1. A bill with total 12,34,56,789.00 (synthetic) renders in the row at 360 dp and text scale 100, 130, 200 percent with no overflow: the value scales to 75 percent, then to 11 sp, then moves to its own line; it is never abbreviated in the row or the day header.
2. Depth text uses the feet rule: 350 and 350.5, never 350.0; the same number appears in the card, the summary and the form pre-fill.
3. A 40-character agent name ellipsizes on line 1 and the total stays visible.
4. Tapping the row opens the edit form; Swipe left shows Edit and Delete; long press opens the sheet with the same two actions; Delete asks for confirmation and Cancel changes nothing.
5. A horizontal swipe on a row does not switch the Ledger and Side Ledger tab.
6. The manual-total marker has the text "Total edited" and a semantic label; commission pill appears only when commission is above zero.
7. Empty with no data and empty with search or filter show different messages and different buttons.
8. Filter: Apply sets the same `LedgerFilter` as before for the same selections; Clear All resets; Cancel makes no change; PVC type hidden for side bore.
9. Calendar: a total of 12,34,567.89 (synthetic) does not overflow a 360 dp cell (about 46 dp wide); totals are for the selected month only (LR-33).
10. Keyboard open in the Search or Filter sheet: the focused field and the primary button stay above the keyboard; Android back closes the keyboard first, then the sheet.
11. Light and dark: text on `canvas` and `surface1` uses the `-Text` roles (contrast at least 4.5:1 per TOKENS.md section 5).
12. 48 dp hit area on the row, the swipe buttons, the sheet rows and the calendar cells; no `BoxShadow` per row (grep).

### R5. Parity delta

Changed on purpose: P-LED-6 calendar totals (LR-33), depth display (feet rule), "Settled" and "Overpaid" status copy on the row (balance colours become pills), P-LED-9 stays but the card becomes a row, filter and search sheets get new chrome only. Cmd+F lines are DROPPED with macOS.
Identical: P-LED-1 (grouping and order: newest day first, newest bill first), P-LED-4, P-LED-7, P-LED-8 (filter semantics), P-LED-9 (tap opens the edit form), P-LED-10, P-LED-11, P-LED-13, P-LED-14.

### R6. Performance and Android notes

- `SliverList.builder` over flattened (header or row) items, `ValueKey(entry.id)`, `findChildIndexCallback`; sort day keys once in a derived value, not in `build`.
- RowActions use one gesture recogniser per row only while a drag is active; no per-row `AnimationController` at rest.
- Cache `NumberFormat` and `DateFormat` in `RigFormat`; `MoneyText` caches measurements.
- Sticky header cost: measure in profile mode against p99 under 16 ms; fallback `sliver_tools`.
- Sheets use `isScrollControlled: true` and bottom padding `viewInsetsOf.bottom` plus `viewPaddingOf.bottom`; controllers of Search and Filter are created in `initState` and disposed (kept).
- No `BackdropFilter` in the list; the glass bar is solid 94 percent by default.
