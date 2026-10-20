> SUPERSEDED IN PART (2026-10-13): the look is now the Apple-inspired Android direction. Read "Reconciliation 2026-10-13" at the end of this file first; where it conflicts with sections 4 to 7 above, it wins.

# diesel_list_screen (Diesel Ledger list, entry card, filter sheet)

File: `lib/features/side_ledger/diesel/diesel_list_screen.dart` (656 lines): `DieselListScreen`, private `_DieselEntryCard` (lines 309-495) and `_DieselFilterSheet` (497-656) share this doc.

This is the reference doc for the four side ledger lists. `pvc_list_screen.md`, `bit_list_screen.md` and `hammer_list_screen.md` reuse the same layout, tokens and states defined in section 4 here and only document their differences. The four screens are near-duplicates (about 650 to 770 lines each, 85 percent identical): header, summary card, empty state, FAB, card shell, delete confirm and filter sheet are copy-pasted four times with category colors swapped.

## 1. Purpose and primary user task

Show all diesel purchases of the current rig as cards, newest first, with filtered totals (entries, litres, total, paid, pending). The user's tasks: scan what is unpaid, filter by bunk name or date range, open an entry to edit it, add a new entry (FAB), delete an entry. Reached from the Side Ledger tab category tile (`combined_home_screen.dart:775`) via `Navigator.push`.

## 2. Current structure

`Scaffold(background)` > `Column`:
1. Custom gradient header `Container(AppColors.appBarGradient)` > `SafeArea(bottom:false)` > `Row`: back `IconButton` (white, no tooltip), centered title "Diesel Ledger" (20 sp w600 white), filter `IconButton` in a `Stack` with a 8 dp `AppColors.warning` dot when `filter.hasFilters`.
2. Summary card: margin 16, padding 16, gradient `Colors.orange.shade600 to shade800`, radius 16, shadow blur 8. Two rows of `_buildSummaryItem` (label 12 sp white 80 percent, value 16 sp bold white): [Entries, Total Litres], [Total, Paid, Pending].
3. `Expanded` > empty state (icon 64 `grey.shade400`, message 16 sp `grey.shade600`, "Clear Filters" `TextButton` when filtered) or `ListView.builder(padding: horizontal 16)` of `_DieselEntryCard`.
4. `FloatingActionButton(backgroundColor: Colors.orange)` (icon add) opens `DieselFormScreen()`.

`_DieselEntryCard`: `Card(margin bottom 12)` > `InkWell(onTap: edit)` > padding 16 `Column`: header row [bill chip `#<billNumber>` (orange tint, radius 6) + date `dd/MM/yyyy` 13 sp grey | trailing delete icon button], two highlight boxes (litres in blue, total in green; each `Expanded`, vertical padding 10, radius 8, 16 sp bold), payment row [`Rate: Rs x/L` | `Paid: ...` green and, if pending > 0, a red `Due: ...` chip], optional bunk row (location icon + text).

`_DieselFilterSheet`: bottom sheet (radius 20), `Padding` with `viewInsets.bottom`, title "Filter Entries" + "Clear All", `TextField` Bunk Name (outlined), "Date Range" with two `OutlinedButton.icon` (Start Date, End Date; `dd/MM/yyyy`), full-width `ElevatedButton` "Apply Filters" (orange).

State sources:
- Reads: `dieselEntriesProvider` (list), `dieselFilterProvider` (`DieselFilter{bunk,startDate,endDate}`), both via `ref.watch` in `build`. `initState` post-frame calls `dieselEntriesProvider.notifier.refresh()`.
- Writes: `dieselEntriesProvider.notifier.deleteEntry(entry.id)`, `dieselFilterProvider.notifier.state = ...` (apply, clear, empty-state clear).
- Derived in `build` on every rebuild: `_applyFilters` (filter + sort), totals loop over the filtered list.
- Formatters held as State fields: `DateFormat('dd/MM/yyyy')`, `NumberFormat.currency(locale: 'en_IN', symbol: 'Rs sign')` (lines 17-18).

## 3. Problems found

Hierarchy and density
1. The summary card is the heaviest element on the screen (about 150 dp of saturated gradient with 5 numbers at 16 sp) and pushes the first entry to about 320 dp from the top (header about 72 + margin 16 + card 150 + margin 16 + status bar). The screen has 3 competing colors (orange header summary, blue litres box, green total box) plus red Due and green Paid, none of which are tokenised (lines 180, 350, 388-395, 417-420, 430-439).
2. Highlight boxes duplicate information: the card shows litres and total twice (highlight boxes and the Rate/Paid row repeats Rs values), and the bill number appears as a chip, not as the title.
3. The header spends a full custom `Container` (no `RigAppBar`), back button without tooltip, title centered while other lists left align (inconsistent with Material).

Contrast (WCAG 2.x, computed with the sRGB luminance formula)
4. White on `Colors.orange.shade600` #FB8C00 is about 2.4:1 and on `orange.shade800` #EF6C00 about 3.1:1 (fails 4.5 for 12 and 16 sp; 80 percent white label is lower still) (lines 179-181, 291, 299).
5. `Colors.green` #4CAF50 text on white ("Paid", total box) is about 2.8:1; `Colors.red` #F44336 "Due" about 3.7:1 on the 10 percent tint (lines 417-440); `Colors.blue` #2196F3 litres box about 3.1:1; `orange.shade700` #F57C00 bill chip text on its tint about 2.5:1; `grey.shade600` #757575 secondary text 4.6:1 passes; `grey.shade500` location icon about 2.7:1; empty-state icon `grey.shade400` is decorative.
6. Filter dot `AppColors.warning` on the header gradient is a fill (acceptable); it has no text alternative.

Tap targets
7. Delete icon button is 20 dp with `padding: zero, constraints: BoxConstraints()` (lines 371-377), so its hit area is 20 x 20 dp (needs 48), placed in the card's top-right corner next to the large tap-to-edit area: easy mis-tap, destructive. Back and filter `IconButton`s are 48 dp: pass. FAB 56: pass. Filter date buttons are 40 high (OutlinedButton default 40 on material3 can be 48 with tap target padding): pass with padding.

Overflow and text scale
8. Payment row (lines 403-446) is a `Row(spaceBetween)` of `Text('Rate: ...')` and a nested `Row` of `Paid` + `Due` chip with no `Flexible`: at 360 dp (inner width about 296) with large amounts such as "Paid: Rs 1,00,000.00" (about 130 dp) + "Due: Rs 1,00,000.00" chip (about 130 dp) + Rate (about 110 dp) the row exceeds 296 dp and overflows (yellow-black stripe) in debug and clips in release. At 200 percent text scale it overflows with any amounts.
9. Bunk details `Text` (line 459) is not inside `Expanded`: a long bunk name overflows the row. Bill chip + date row: no overflow risk until 200 percent scale.
10. Summary card rows `spaceBetween` of 3 items "Total / Paid / Pending" with 16 sp bold amounts: at 360 dp with Rs 1,00,00,000.00 (about 120 dp each) the 3 values exceed 296 dp.
11. Filter sheet content is a `Column(mainAxisSize.min)` with no `SingleChildScrollView` (lines 561-654): on a short screen with the keyboard open (landscape or 5-inch device) the sheet overflows.

Component and consistency problems
12. 4 near-duplicate list screens, 4 filter sheets, 4 cards (see COMPONENTS.md section 8 item 5).
13. Date format `dd/MM/yyyy` (line 17) differs from the main ledger and the design system `dateShort`; currency is `NumberFormat.currency(en_IN)` here and `#,##0.00` in the main forms.
14. Shadow plus elevation: `Card` default elevation and the summary card shadow; raster cost with long lists is low (cards use plain `Card`), but the gradient summary re-paints on each list rebuild.
15. Delete snackbar has no undo and no color; the confirm dialog uses a `TextButton` with `Colors.red` (line 80) while the bill forms use a filled red `ElevatedButton`.
16. No pull-to-refresh, no sticky filter chips showing the active filter: users only see an 8 dp dot, they cannot tell WHICH filter is active. The empty state "No entries match your filters" does not list them either.

State problems
17. `_applyFilters` mutates provider state: when no filter is set, `filtered = entries` aliases the provider list and `filtered.sort(...)` (line 51) sorts the shared list in place, inside `build` (see bugs_g1.md).
18. Whole list, totals and sort recompute on every rebuild (including rebuilds caused by `ref.watch(dieselFilterProvider)`, not only data changes).
19. No loading state: `refresh()` runs after the first frame, so the empty-state message "No diesel entries yet" can flash for a frame before data appears (UNVERIFIED: depends on whether the notifier loads synchronously in its constructor).
20. Back navigation from the form returns with no scroll restoration issue (same widget), but the list jumps because the card order changes after an edit that alters the date: no highlight of the changed entry.

## 4. Redesign

### 4.1 Layout (shared by all four lists)

Page = `RigScaffold(appBar: RigAppBar(title: 'Diesel Ledger', leading: back, actions: [filter button with badge]))`, body = `Column`: `SummaryStrip`, optional `ActiveFilterBar`, list. FAB `FloatingActionButton.extended(Icons.add_rounded, 'Add diesel entry')` on compact and medium; standard FAB label hidden below 360 dp; on expanded a filled button "Add entry" in the app bar actions instead of a FAB.

Summary strip (replaces the gradient card):
- `RigCard` tone `surfaceContainer` (level 2, no shadow), padding `s4`, margin `s4`, with a 4 dp leading edge accent in `categoryDiesel` (identity color, never text).
- Content: `AmountGrid(minTileWidth: 140)` of `AmountTile`s: Entries (count, neutral), Total Litres (`bodyLarge`/`amountMedium`, 1 decimal, unit "L"), Total (neutral), Paid (`moneyIn`), Pending (`outstanding`). Tiles flow 2 columns at compact (<600), 3 at medium, 5 in one row at expanded (>900). Labels `labelMedium onSurfaceVariant`, values `amountMedium`. Each value `FittedBox`-free: if the full value does not fit, `AmountTile` switches to `moneyCompact` and shows the full value on tap (COMPONENTS `fullValueOnTap`).
- Pending tile shows `moneyIn` "Rs 0.00" in `textMuted` when 0.

Active filter bar (new, UI only): when `filter.hasFilters`, a `RigChipRow` of removable chips below the strip: "Bunk: <text>", "From dd MMM yyyy", "To dd MMM yyyy", plus "Clear all". Removing a chip writes the same `dieselFilterProvider` state with that field cleared.

List: `ListView.builder` with padding horizontal `s4` (compact) / `s6` (medium) / centered 720 max (expanded), gap `s2` (8) between cards, bottom padding 88 for the FAB.

### 4.2 `SideEntryCard` (kind: diesel)

`RigCard` (level 1, radius `lg`, padding `s3` = 12, whole card tap target, press `surfaceContainerHigh`), anatomy:

```
[leading 40 dp category icon tile (categoryDiesel container, icon local_gas_station_rounded)]  [title: "#<bill>"  titleMedium] [trailing: AmountText total, amountMedium, right aligned]
[subtitle: date (dateShort) | bunk details with location icon, maxLines 1 ellipsis]                 [overflow menu 48 dp: more_vert_rounded]
[meta row: "<litres> L at Rs <rate>/L" bodySmall onSurfaceVariant]                                [status chip: "Paid" moneyInContainer / "Due Rs x" outstandingContainer]
```

- Row min height 72; the amount column is right aligned and tabular, never wraps: title and subtitle are `Expanded` with ellipsis, the status chip wraps to the next line below the amount at 200 percent text scale (use `Wrap`).
- Delete moves into the 48 dp overflow menu (`PopupMenuButton`: Edit, Delete). Tapping the card still opens the form (unchanged outcome). On desktop, right-click opens the same menu; hover shows `surfaceContainerHigh`.
- Status: `Paid` when `entry.pending <= 0` (same predicate), otherwise `Due` with `entry.pending`. Paid amount is shown in the meta row as "Paid Rs x" in `bodySmall`, with `moneyIn`.

### 4.3 Filter (`EntryFilterSheet`)

Compact: `RigSheet` (radius `xl` top, drag handle, scrollable body, Apply pinned in the footer above the keyboard). Medium and expanded: same content as a dialog max width 480. Content order unchanged: "Bunk Name" `RigSearchField`-style `RigTextField` (clear suffix), "Date Range" with two `RigDateField`s (labels "Start Date", "End Date", pattern `dateShort`), footer: "Clear All" text button left, "Apply Filters" filled right. A date range where start is after end shows the inline error "Start date must be before end date" (copy; Apply stays enabled because the provider logic is unchanged, see logic_g1.md L-04 for blocking it).

### 4.4 Empty, loading, error

| State | Rule |
|---|---|
| Default | strip + list |
| Loading (first frame) | 3 skeleton cards (72 dp) for at most 200 ms, only if the provider list is empty AND `refresh()` has not completed (UI flag set in the post-frame callback) |
| Empty (no data) | `EmptyState(icon: Icons.local_gas_station_rounded 48 dp, title: 'No diesel entries yet', hint: 'Add your first fuel bill.', action: tonal 'Add entry')` |
| Empty (filtered) | `EmptyState(title: 'No entries match your filters', action: 'Clear Filters' text button)`, active filter chips remain above |
| Error | `ErrorBanner` only if a provider ever exposes an error (none today; reserved) |
| Disabled | none |
| Delete in progress | the row fades 150 ms and the strip updates after `deleteEntry` completes |

### 4.5 Deletion flow (unchanged outcome)

Card menu > Delete > `ConfirmDialog(destructive)`: title "Delete Entry", message 'Are you sure you want to delete diesel entry #<bill>?', Cancel (left, focused) and Delete (text button, `negative`). After success: `RigSnack` "Entry deleted" (kind info, 4 s, no Undo because there is no soft delete; see logic_g1.md L-01).

### 4.6 Widths

| Width | Layout |
|---|---|
| Compact <600 | full-width list, 2-column summary grid, FAB extended, filter as sheet |
| Medium 600-900 | list padded `s6`, 3-column summary grid, filter as dialog |
| Expanded >900 (macOS) | content max width 720 centered with `RigAppBar` 48 dp, 5-tile summary row, "Add entry" button in the app bar, hover and context menu on cards, scrollbar visible, `Cmd+N` adds an entry, `Cmd+F` opens the filter |

### 4.7 Tokens and components

Spacing `s2`, `s3`, `s4`; radius `lg` cards, `md` chips and fields, `xl` sheet; type `titleMedium` (bill), `bodySmall` (meta), `amountMedium` (amounts), `labelMedium` (labels); colors `surface`, `surfaceContainer`, `onSurfaceVariant`, `moneyIn`, `outstanding`, `negative`, `categoryDiesel` (+ container), `outlineVariant`. Components: `RigAppBar`, `RigScaffold`, `AmountGrid`, `AmountTile`, `AmountText`, `SideEntryCard`, `EntryFilterSheet`, `RigChipRow`, `RigListRow`, `EmptyState`, `ConfirmDialog`, `RigSnack`, `RigDateField`, `RigTextField`, `RigSheet`.

### 4.8 Motion

Card press ripple only; list item removal 150 ms fade; filter chip add/remove 150 ms `AnimatedSwitcher`; sheet 300 ms; honors reduced motion.

## 5. Logic touchpoints that must stay untouched

- `_applyFilters` semantics: bunk filter is case-insensitive `contains` on `bunkDetails`; start date keeps entries NOT before `startDate`; end date keeps entries not after 23:59:59 of `endDate`; result sorted by date descending. (A redesign may move this into a provider or a `select`, but the results must be identical.)
- Totals: `totalLitre += litre`, `totalAmount += total`, `totalPaid += paid`, `totalPending += pending` over the filtered list; Pending is summed raw (can include negatives for overpaid entries).
- `isPaid = entry.pending <= 0` drives the Due chip.
- Provider calls: `dieselEntriesProvider.notifier.refresh()` (post-frame in `initState`) and `.deleteEntry(entry.id)`; `dieselFilterProvider.notifier.state = DieselFilter(bunk, startDate, endDate)`; empty strings become `null` for the bunk (line 545); "Clear All" and the empty-state button set `const DieselFilter()`.
- Navigation: card tap pushes `DieselFormScreen(entry: entry)`; FAB pushes `DieselFormScreen()`; back pops.
- Delete confirm copy "Are you sure you want to delete diesel entry #<billNumber>?" and snackbar "Entry deleted".
- Filter sheet date pickers: range 2020 to now + 365; sheet owns and disposes `_bunkController`.
- `DieselFilter.hasFilters` drives the dot and the empty-state copy.

## 6. Acceptance criteria

1. With N entries and no filter, N cards show newest first; the summary Entries equals N and Litres, Total, Paid, Pending equal the sums of the cards.
2. Applying a bunk filter "xyz" shows only entries whose bunk contains "xyz" in any case; totals recompute for those entries only.
3. A date range includes entries dated on the end date at any time of day.
4. Active filters are visible as chips; removing one chip updates the list and totals; "Clear all" restores the unfiltered list.
5. Delete: icon/menu opens the confirm; Cancel changes nothing; Delete removes exactly that entry and shows "Entry deleted".
6. The delete control is at least 48 x 48 dp and is separated by 8 dp from the card's tap area.
7. No overflow at 360 dp with amounts up to Rs 9,99,99,999.99 and at text scale 200 percent; amounts are right aligned and tabular.
8. Card tap opens the form with the entry loaded; FAB opens an empty form; back returns to the list at the same scroll offset.
9. Contrast of every text at least 4.5:1; category color is never the only status signal (Paid/Due text present).
10. On macOS the content is centered at max 720; `Cmd+N` and right-click menu work; hover is visible.
11. Filter sheet scrolls when the keyboard is open and Apply stays reachable.
12. The provider list is not mutated by display (the same entries list instance order is untouched after build).

## 7. Performance notes

- Move filtering, sorting and totals out of `build`: compute in a derived `Provider` (or `select`) keyed by `(entries, filter)` so a rebuild caused by anything else does not re-sort. Copy before sorting (`[...entries]`) to stop mutating provider state.
- `ref.watch(dieselEntriesProvider)` and `ref.watch(dieselFilterProvider)` both in the screen `build`: split into `SummaryStrip` (watches the derived totals only) and the list (watches the derived list), so the summary does not rebuild on list item taps.
- `ListView.builder` with `itemExtent` unknown (variable height); give each card a `ValueKey(entry.id)`; use `const` for static parts of `SideEntryCard` and one shared `SideEntryCard` class for all 4 lists.
- `DateFormat` and `NumberFormat` are State fields now; move to `RigFormat` statics so the card does not receive formatter objects as constructor arguments (which defeats `const` and equality checks).
- Gradient summary removed: no per-frame gradient repaint; cards have no blurred shadow (level 1 uses border only).
- Controllers: the filter sheet owns `_bunkController` and disposes it (good); the post-frame `refresh()` runs once.


## Reconciliation 2026-10-13 (Apple look, Android only)

This section is the reference for all four side ledger lists. `pvc_list_screen.md`, `bit_list_screen.md` and `hammer_list_screen.md` reconcile against it and only add their differences. Sources: mockup functions `slList`, `slFilter`, `slDel`, `editSl`, registry group "Side ledger", states group "Apple direction: states".

### R1. Mockup screens and Flutter mapping

| Mockup screen (J label) | Render function | Flutter file | Widgets | Notes |
|---|---|---|---|---|
| Diesel Ledger | `slList({k:'diesel'})` via `SC.diesel` | `lib/features/side_ledger/diesel/diesel_list_screen.dart` | LargeTitleScaffold (title "Diesel Ledger", trailing filter and add buttons), CategoryTile (gradient summary card, `catDiesel`), MoneyTile fit pipeline (Total hero, Paid, Pending), RigGroup + RigRow (entry rows), RowActions (swipe Edit and Delete), EmptyState, RigAlertDialog, RigSnack | `DieselListScreen`, `_DieselEntryCard`, `_DieselFilterSheet` stay in the file until the shared `SideEntryRow` is extracted (T-U57) |
| Diesel Ledger empty | `slList` with `UI.state=='empty'` | same | EmptyState (`local_gas_station`, "No diesel entries yet", "Tap + to add one.", tonal "Add entry") | summary card still shows zeros |
| Side Ledger loading (state) | `skelList(3)` under the summary card | same | Skeleton x3 | only the first frame after a rig switch or restore (C-3); no provider state added |
| (no registry label) Filter Entries sheet | `slFilter('diesel')` opened by the filter button | same (`_DieselFilterSheet`) | RigSheet (title "Filter Entries", right text button "Clear All", pinned "Apply Filters" RigButton), RigGroup + RigFormRow (Bunk name, Start date, End date) | open from the Diesel Ledger filter button |
| (no registry label) Delete Entry alert | `slDel('diesel', bill)` | same | RigAlertDialog (radius 14, destructive) | opened from the row swipe action or long press menu |

### R2. What changes in the redesign (supersedes section 4)

Layout top to bottom (412 dp and 360 dp, flat `canvas`):
1. `LargeTitleScaffold` pushed route: back chevron 48 dp at the left, large title "Diesel Ledger" 34 collapsing to a 17 inline title (solid bar at 94 percent with a hairline, blur off), trailing two glass buttons 48 dp: filter (`filter_list`, tooltip "Filter") and add (`add`, tooltip "Add entry"). There is no FAB.
2. Summary card (CategoryTile, kind diesel): radius 28, padding 18, margin 20 sides, linear gradient 135 degrees from `catDiesel` to `catDiesel` mixed 62 percent with white, all text `onTile` (black, 9.55 : 1 light, 10.22 : 1 dark per TOKENS.md section 5). Row: icon 26 dp + "Diesel" t20 bold, spacer, "N entries" t13 (singular "1 entry"). Total as hero (44 bold, MoneyTile fit pipeline, tap shows the full value), a row of two columns "Paid" and "Pending" (label t12, value t17 bold, same fit pipeline), then "N L in total" t13 (qty format, up to 2 decimals, en-IN grouping). Entries = filtered list length (display of the existing list, not a new calculation).
3. Section title "Entries" (t22 bold, margin 20) then an inset RigGroup (radius 20, margin 20, gap to the summary 12). Rows are lazy (SliverList with per row corner rounding on the first and last row; never one big Column).
4. Entry row (RigRow, min 48 dp, padding 12 x 16, whole row tappable = open edit form): line 1 `#<bill>  <litres> L at <rate>` t17 600 ellipsis (litres via `qty`, rate via `money`), total t17 700 right aligned, tabular, max 58 percent of the row. Line 2 (t13, `lb2`): date `dFull` (`d MMM yyyy`) and bunk details (ellipsis, omitted when empty). Line 3: pills (radius 10, fill `fill`, t12 600): dot `moneyIn` + "Paid <money>", then dot `outstanding` + "Due <money>" when `pending > 0`, else dot `moneyIn` + "Settled". Pill text is `lb`; the dot never carries meaning alone because the words Paid, Due, Settled are always present.
5. Row actions (RowActions): swipe left reveals two 76 dp x row height buttons, Edit (`accentButton`, white label) and Delete (`moneyOutButton`, white label); long press opens the same two items in a menu so TalkBack and keyboard users reach them (custom accessibility actions "Edit" and "Delete"). Edit opens `DieselFormScreen(entry)`, Delete opens the alert. The 20 dp icon delete button of the old card is removed. Swipe mechanism depends on Q-O7 (`flutter_slidable` or `Dismissible` plus menu); the visible result is the same.
6. Filter button badge: when `filter.hasFilters` an 8 dp `accent` dot sits on the filter button and a removable RigChipRow ("Bunk: <text>", "From d MMM yyyy", "To d MMM yyyy", "Clear all") shows under the summary card. The mockup does not draw this bar; it is KEPT from old section 4.1 because the old screen could not say WHICH filter is active (UI only, same provider writes).
7. Bottom padding: list ends at `viewPaddingOf(context).bottom + 62 + 8 + 24` (tab bar not shown on a pushed route, so `bottom inset + 24`).

Tokens used: `canvas`, `surface1` (RigGroup), `labelPrimary`, `labelSecondary`, `separator` (hairline 0.5 dp), `fill`, `catDiesel` (+ text variant), `onTile`, `moneyIn`, `moneyInText`, `outstanding`, `outstandingText`, `accentButton`, `moneyOutButton`, spacing 20 margin and 12 gap, radii 28 tile, 20 group, 14 alert, 10 pill. Type: Inter 400/500/600/700, tabular figures on every amount; all sizes multiplied by the system text scale.

Money in rows never compacts (answer 3): the fit pipeline is full value, then scale to 75 percent, then 11 px guard, then the value moves to its own line. Compact `L`/`Cr` is allowed only in the summary card (highlight tile).

States:

| State | Rule (mockup) |
|---|---|
| Default | summary card + Entries group |
| Loading | summary card + 3 Skeleton cards, first frame after a rig switch only (C-3) |
| Empty (no data) | summary card with zeros, EmptyState 52 dp icon, bold title, "Tap + to add one." and tonal "Add entry" button |
| Empty (filtered) | EmptyState title "No entries match your filters", text button "Clear Filters"; chip row stays |
| Error | not reachable (Hive reads are synchronous); mockup `errUI('Could not load entries')` is not built (LR-34 proposed) |
| Disabled | none |
| Delete in progress | row fades 150 ms, summary updates after `deleteEntry` |

Motion: 200 to 350 ms ease-out; press feedback is ink (`pressOverlay`, no scale); swipe snap 200 ms; sheet rise 300 ms; all off when `MediaQuery.disableAnimationsOf` is true.

Old section 4 item by item:
- 4.1 Layout: CHANGED (gradient `RigScaffold` header gone; neutral `RigCard` strip replaced by the category gradient CategoryTile because the mockup shows it; FAB replaced by the trailing add button; the 2/3/5 column `AmountGrid` DROPPED, a single hero + two columns). Active filter bar KEPT.
- 4.2 SideEntryCard: CHANGED (40 dp icon tile and overflow menu DROPPED; the row is a RigRow; delete moves to swipe and long press; pills replace the Paid/Due chip; "Settled" is new display copy for `pending <= 0`).
- 4.3 Filter: CHANGED to RigSheet (EntryFilterSheet becomes a RigSheet, see below).
- 4.4 Empty, loading, error: CHANGED (mockup wording and Skeleton rule above).
- 4.5 Deletion flow: KEPT (same texts), alert becomes RigAlertDialog.
- 4.6 Widths: DROPPED (medium and expanded columns, 720 max, Cmd shortcuts, hover, context menu on right click, macOS window rules). One compact layout, 360 dp minimum.
- 4.7 Tokens and components: CHANGED to the names in this section.
- 4.8 Motion: CHANGED to 200 to 350 ms, ink press feedback, reduced motion honoured.

Filter sheet (EntryFilterSheet becomes RigSheet):
- `RigSheet`: grabber, radius 28 top, scrim `scrim` (no blur), scrollable body, bottom pinned `Apply Filters` RigButton (50 dp pill, filled) above the keyboard inset, title "Filter Entries" centred, "Clear All" text button on the right (`accentText`).
- Diesel body: RigGroup with RigFormRow "Bunk name" (placeholder "Any", `TextCapitalization.words`), then RigGroup with two rows "Start date" and "End date" (value right aligned `labelSecondary`, "Any" when empty, tap opens the date picker, clear affordance when set).
- Kept behaviour: empty bunk becomes `null`; `_bunkController` owned and disposed by the sheet State; Apply writes `dieselFilterProvider`; Clear All writes `const DieselFilter()`.
- Date pickers: allowed range stays 2020 to now + 365 (not widened); `initialDate` is clamped into the range by the shared `pickRigDate` helper so an out of range stored value no longer asserts (B-G1-02, UI only, scheduled with the Phase 2 bug batch in MIGRATION_PLAN.md). When start is after end the sheet shows an inline caption "Start date must be before end date" under the rows; Apply stays enabled (blocking it is g1 L-04, not scheduled).

### R3. Logic touchpoints and LR items

Untouched (still valid, section 5): `_applyFilters` semantics (bunk case-insensitive contains, start inclusive, end through 23:59:59, descending date), the totals loop (`totalLitre`, `totalAmount`, `totalPaid`, `totalPending` summed raw), `isPaid = pending <= 0`, provider calls (`refresh()`, `deleteEntry(id)`, filter state writes), navigation targets, delete and snackbar copy, picker range 2020 to now + 365.

LR dependencies:
- LR-24 approved: rupee sign, en-IN grouping, two decimals only with paise, compact only in the summary card.
- LR-25 approved: discard prompt lives on the form, not on this list.
- LR-29 proposed: the summary Pending nets advances today (a row with `pending < 0` lowers the total). The mockup shows the same netting (`sum(e.pend)`), so the first pass ships the code behaviour unchanged. If LR-29 is approved the Pending column shows the sum of entries with `pending > 0` and a new line "Advances <money>" (`moneyInText`, t12) appears under it only when advances exist; per row pending (total minus paid) is unchanged. The layout reserves one extra t12 line in the summary card for this; no space change otherwise.
- LR-06 not scheduled: no Undo after delete (no soft delete), snackbar "Entry deleted" only.
- LR-34 proposed: no error state is built.
- LR-32 approved (Phase 1) applies to the form, not here.
- No new logic found for this screen (see `temp/design_wip/logic2_r2.md`).

### R4. Acceptance criteria delta

1. Summary card gradient uses `catDiesel` (orange); label contrast of `onTile` text at least 4.5 : 1 in light and dark.
2. Total, Paid and Pending in the card equal the sums over the shown rows; "N entries" equals the row count; "N L in total" equals the litres sum.
3. A row shows `#<bill>  <litres> L at <rate>`, the total, date, bunk (only when non-empty) and exactly one of "Due <money>" or "Settled" next to "Paid <money>".
4. No row overflows at 360 dp and 412 dp, text scale 130 and 200 percent, with a total of 9,99,99,999.99: the value shrinks to 75 percent, then 11 px, then wraps to its own line; it is never compacted in a row.
5. Swipe left (or long press) offers Edit and Delete; targets are 48 dp tall and 76 dp wide; Delete shows the alert with the unchanged text and "Entry deleted" after confirming.
6. Android back from the list pops to the Side Ledger tab; with the filter sheet open it closes the sheet first.
7. Filter sheet: Apply stays above the keyboard; the body scrolls; the Bunk row is focusable; Clear All empties the fields and the list.
8. A stored entry dated before 2020 or after now + 365 opens its date picker without an assertion (clamped initial date).
9. Light and dark: no raw hex or `Colors.*` in the file; every colour is a RigColors or ColorScheme role.
10. The provider list is not mutated by display (sort on a copy).

### R5. Parity delta

Intentional changes: P-DL-01 summary shows Entries, Total Litres, Total, Paid, Pending, now as one gradient card (Entries and litres as secondary text, same values). P-DL-03 gains "Settled" when nothing is due (old: nothing shown). P-DL-04 the filter indicator is the dot plus chips. P-DL-07 the FAB is replaced by the trailing add button (same empty form). P-DL-08 Delete is reached by swipe or long press, no longer by a 20 dp icon (same dialog text and snackbar). Rs. becomes the rupee sign everywhere.

Must stay identical: P-DL-02, P-DL-05, P-DL-06 (copy "No diesel entries yet", "No entries match your filters", "Clear Filters"), delete message `Are you sure you want to delete diesel entry #<bill>?`, snackbar "Entry deleted", sort order, totals.

### R6. Performance and Android notes

- Edge to edge; the scroll body pads the bottom with `MediaQuery.viewPaddingOf(context).bottom + 24`; the sheet uses `viewInsets.bottom` for the keyboard and ends with the pinned Apply button above it.
- `PopScope` is only on forms; the list relies on the default back.
- Move filter, sort and totals to a derived provider or `select` keyed by `(entries, filter)`; sort a copy. Cards keyed `ValueKey(entry.id)`; one shared row widget for the four lists.
- Gradient summary card is a static decoration (no blur, no saveLayer); no `BackdropFilter` in the scrolling content. Targets: p90 build and raster under 8 ms, p99 under 16 ms, janky frames under 2 percent.
- `DateFormat` and `NumberFormat` become `RigFormat` statics (`dFull`, `money`, `qty`). `_bunkController` is disposed in the sheet State.
