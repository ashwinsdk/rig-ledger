> SUPERSEDED IN PART (2026-10-13): the look is now the Apple-inspired Android direction. Read "Reconciliation 2026-10-13" at the end of this file first; where it conflicts with sections 4 to 7 above, it wins.

# pvc_list_screen (PVC Ledger list, entry card, filter sheet)

File: `lib/features/side_ledger/pvc/pvc_list_screen.dart` (766 lines): `PvcListScreen`, `_PvcEntryCard` (lines about 350-585) and `_PvcFilterSheet` (about 587-766) share this doc. Consistency rule: the shell, summary strip, `SideEntryCard` anatomy, filter sheet frame, empty/loading states, delete flow, widths, motion and desktop behavior are exactly those defined in `diesel_list_screen.md` section 4 (called "shared list spec" below). This doc records only what is different for PVC. Near duplicate of diesel/bit/hammer lists: about 85 percent identical code (diff against diesel: type filter, type-count pills, multi-type detail block, storage place).

## 1. Purpose and primary user task

Show PVC pipe purchases of the current rig (not shown on side bore rigs: the Side Ledger tab hides PVC when `isSideBoreProvider` is true) as cards, newest first, with filtered totals (pieces per type, total, paid, pending). Tasks: see what is pending, filter by type and storage place and date, open/edit, add, delete. Reached from the Side Ledger tab (`combined_home_screen.dart:792`).

## 2. Current structure

Same Column as diesel: gradient header ("PVC Ledger", blue), summary card, list/empty state, FAB (blue). Differences:
- Summary card (blue 600 to 800 gradient): a `Wrap` of translucent pills `'<type>: <pieces>'` (one per type, white text w500 14 sp) above a row of [Total, Paid, Pending]. There is no Entries count and no litres.
- Card highlight row: three `Expanded` boxes (gap 8): type label (`entry.displayType`, color from `_getTypeColor(entry.type)` = first type only: 7 inch blue, 8 inch green, 10 inch purple, MS orange, other grey), `'<n> pcs'` (purple), total (`entry.calculatedTotal`, green), each 14 sp bold, vertical padding 8.
- Optional per-type breakdown block when `typeDetails.length > 1`: grey box with lines `'<type>: <count> x Rs <rate> = Rs <total>'` (12 sp).
- Payment row: `Rate: Rs <rate>/pc` (only when there is one type or none; otherwise an empty `SizedBox`), `Paid` and red `Due` chip.
- Optional storage row (warehouse icon + text).
- Filter sheet: a "PVC Type" `Wrap` of `ChoiceChip`s from `static const ['7 inch','8 inch','10 inch','MS']` (tap again to deselect), "Storage Place" text field, date range, Apply (blue).
- Filter semantics: type equals `entry.type` (first stored type only), storage place contains (case-insensitive), dates as diesel.

State sources: `pvcEntriesProvider`, `pvcFilterProvider` (`PvcFilter{type, storagePlace, startDate, endDate}`); writes `pvcEntriesProvider.notifier.deleteEntry`, `pvcFilterProvider.notifier.state`; `refresh()` post-frame. Totals: `totalAmount += entry.calculatedTotal`; paid and pending from stored fields; piece counts by type use `typeDetails` when present else `entry.type` + `entry.count`.

## 3. Problems found

All problems 1 to 20 of `diesel_list_screen.md` section 3 apply (header, saturated summary, 20 dp delete target, payment row overflow, no active-filter display, in-place sort of the provider list at the equivalent of line 51, contrast failures of `Colors.green/red/orange`, `grey.shade500` icon). PVC-specific:
1. Three highlight boxes in one row at 360 dp are about 93 dp wide each (296 - 2 x 8) / 3. `Rs 1,00,000.00` at 14 sp bold needs about 100 dp: it wraps to two lines or clips; `displayType` for a multi-type bill ("7 inch, 8 inch, 10 inch", about 150 dp) wraps to 3 lines, producing three boxes of unequal height in one row (lines about 431-445).
2. Type color uses only `entry.type` (the first of the selected types) so a mixed bill shows one type's color: color suggests a single type.
3. Type colors (blue, green, purple, orange, grey) are decorative and clash with status colors green (Paid) and red (Due) used on the same card. White pills on `blue.shade600` #1E88E5: 3.7:1 for 14 sp (fails).
4. The `Rate` text is replaced by an empty `SizedBox` for multi-type bills, which shifts `Paid` and `Due` to the left edge because of `spaceBetween` with a zero-width left child (it lands at the start, not the end).
5. The per-type breakdown block is hidden unless there are 2 or more types, so the user cannot see pieces per type for a single-type bill beyond the highlight boxes; consistent but dense. Text uses `toStringAsFixed(0)` for rates, so a rate such as 12.50 shows as 13 (display only, see logic_g1.md L-08).
6. Piece-count pills in the summary sum `detail.count` per type but do not show the grand total of pieces.
7. Filter by type matches only the first stored type: a bill with types 7 inch and 8 inch is invisible when filtering "8 inch" (line about 31-33; `e.type == filter.type`). This is a logic gap; see bugs_g1.md and logic_g1.md L-09.
8. Filter sheet `Wrap` of 4 chips plus two fields plus date row plus button: about 440 dp tall; with the keyboard open on a 640 dp screen it overflows (no scroll).
9. Storage place appears only on the card; the filter field is called "Storage Place" while the form says "Storage Place": consistent, but the placeholder in the filter says "Search by storage location..." (copy mismatch).

## 4. Redesign

Use the shared list spec (diesel_list_screen.md 4.1 to 4.8) with these PVC specifics.

### 4.1 Summary strip

`AmountGrid`: tiles in this order: Total (neutral), Paid (`moneyIn`), Pending (`outstanding`), then a full-width `RigChipRow` (non-selectable `labelMedium` chips, `surfaceContainerHigh` fill) "7 inch: 12 pcs" per type plus a final chip "All: <sum> pcs" (sum of the shown numbers; display arithmetic only). Accent edge `categoryPvc`. Compact: 3 tiles in one row if each fits 96 dp else 2 + 1; medium: 3; expanded: 3 tiles + chips on the same row. No Entries tile (parity with today's summary; do not add).

### 4.2 `SideEntryCard` (kind: pvc)

```
[40 dp categoryPvc container tile, icon plumbing_rounded]  [#<bill> titleMedium] [AmountText calculatedTotal amountMedium right]   [menu 48]
[date dateShort . storage place (warehouse_rounded 16, maxLines 1)]
[type chips: one tonal chip per type "7 inch x 12" (neutral surfaceContainerHigh, no per-type hue)]
[status row: "Paid Rs x" (moneyIn) | Due chip (outstandingContainer)]  [Rate: Rs x/pc when single type]
```

- The three highlight boxes are replaced by the right-aligned total plus the type chips (no horizontal squeeze).
- Multi-type breakdown stays, as a collapsible "Details" row (`RigListRow` expandable, closed by default) listing `<type>: <count> x Rs <rate> = Rs <total>` in `bodySmall`, amounts right aligned tabular, 8 dp row gap. The rate is formatted by `RigFormat` without changing the stored value or rounding of totals.
- Type chips use neutral tokens (not `Colors.blue/green/purple/orange`) so color stays reserved for status.
- Total shows `entry.calculatedTotal` exactly as today.

### 4.3 Filter sheet

Shared frame. Content order: "PVC Type" `RigChipRow` (ChoiceChip, single select, tap again to deselect, options `['7 inch','8 inch','10 inch','MS']`), "Storage Place" `RigTextField` with placeholder "Search by storage place", date range. Scrollable.

### 4.4 Empty state

`EmptyState(icon: Icons.plumbing_rounded, title: 'No PVC entries yet'/'No entries match your filters')`.

### 4.5 Widths, motion

As the shared spec. Expanded: card meta row and type chips share one line to use the 720 width; "Details" stays collapsed by default; keyboard `Enter` toggles it when focused.

## 5. Logic touchpoints that must stay untouched

- `_applyFilters`: type equality on `entry.type`, storage place case-insensitive contains, start/end date rules and descending sort (identical results required, including the first-type-only match).
- Totals: pieces by type from `typeDetails` (else `entry.type` and `entry.count`); `totalAmount += entry.calculatedTotal`; `totalPaid`, `totalPending` from stored fields.
- Card: `entry.displayType`, `entry.totalCount`, `entry.calculatedTotal`, `entry.typeDetails`, `entry.rate` (shown only with one type), `entry.paid`, `isPaid = entry.pending <= 0`, `entry.storagePlace`.
- `pvcFilterProvider.notifier.state = PvcFilter(type, storagePlace, startDate, endDate)`; empty storage text becomes null; clear sets `const PvcFilter()`.
- `pvcEntriesProvider.notifier.refresh()` and `.deleteEntry(id)`; delete message 'Are you sure you want to delete PVC entry #<bill>?'; snackbar 'Entry deleted'.
- Navigation: card to `PvcFormScreen(entry: entry)`, FAB to `PvcFormScreen()`.
- PVC is hidden on side bore rigs by the caller (`isSideBoreProvider`), not by this screen; keep that.

## 6. Acceptance criteria

1. Type pills equal the sum of piece counts per type over the filtered entries; "All" equals their sum.
2. Total, Paid, Pending equal the sums of `calculatedTotal`, `paid`, `pending` of shown entries.
3. Filtering "8 inch" shows exactly the entries whose FIRST stored type is "8 inch" (same as today).
4. A multi-type bill shows one chip per type and a Details row with the exact per-type lines.
5. No highlight box wraps or clips at 360 dp with `Rs 9,99,99,999.99` and 200 percent text scale.
6. Delete control at least 48 x 48 dp, separated from the tap area; confirm text identical.
7. Type chips are neutral in color; Paid and Due are the only semantic colors on the card.
8. Empty and filtered-empty messages identical to today.
9. Contrast at least 4.5:1 for all text.
10. macOS: centered max 720, context menu Edit/Delete, `Cmd+N`, `Cmd+F`.
11. Filter sheet scrolls with the keyboard open; Apply reachable.

## 7. Performance notes

Same as diesel list section 7. Additional: the per-type accumulation loop (`typeDetails` getter decodes JSON per entry on every `build`, via `entry.typeDetails`) is the heaviest part: the `typeDetails` getter decodes JSON on every access (`pvc_entry.dart:90`), and `displayType`, `totalCount` and `calculatedTotal` each call it again, so one card costs about 4 decodes plus the totals loop adds 2 more per entry on every rebuild. Cache with a derived provider (memoized per `(entries)`), or compute once per entry in the derived list. Card keys `ValueKey(entry.id)`; one shared `SideEntryCard`.


## Reconciliation 2026-10-13 (Apple look, Android only)

Reconciles against `diesel_list_screen.md` "Reconciliation 2026-10-13" (call it the shared list reconciliation). Only the PVC differences are written here. Sources: `slList({k:'pvc'})`, `slFilter('pvc')`.

### R1. Mockup screens and Flutter mapping

| Mockup screen (J label) | Render function | Flutter file | Widgets | Notes |
|---|---|---|---|---|
| PVC Ledger | `slList({k:'pvc'})` via `SC.pvc` | `lib/features/side_ledger/pvc/pvc_list_screen.dart` | LargeTitleScaffold, CategoryTile (`catPvc` teal), MoneyTile fit pipeline, RigGroup + RigRow, RowActions, RigChipRow (type filter), RigSheet, EmptyState, RigAlertDialog | not offered on a side bore rig (caller hides it through `isSideBoreProvider`); the mockup also hides it |
| (no registry label) Filter Entries sheet | `slFilter('pvc')` | same (`_PvcFilterSheet`) | RigSheet, RigChipRow (PVC type), RigGroup + RigFormRow (Storage place), date rows | |

### R2. What changes in the redesign (supersedes section 4)

Same page structure as the shared list (large title "PVC Ledger", trailing filter and add, gradient CategoryTile, "Entries" group, swipe or long press Edit and Delete, no FAB). PVC specifics:
- Category colour is `catPvc` (teal, `#30B0C7` light, `#40C8E0` dark; text variant `#1E6F7D` / `#40C8E0`). Today PVC is blue; the blue is dropped.
- Summary card: icon `plumbing` 26 dp, "PVC", "N entries" (list length; the old "no Entries tile, do not add" rule is CHANGED, the mockup shows it on all four lists and it is the length of the shown list), Total hero, Paid, Pending, then a wrapping row of pieces by type "7 inch: 12" (t13, gap 8) built from `typeDetails` (else `type` and `count`), unchanged arithmetic. The old extra "All: N pcs" chip is DROPPED (not in the mockup; a grand total of pieces is not required).
- Entry row (count and rate are per TYPE, the entry level `count` is a legacy sum and `rate` the first type's rate): line 1 `#<bill>  <totalCount> pcs` (the sum over types, t17 600) and the total (`calculatedTotal`) right; line 2 date and storage place (ellipsis, omitted when empty); line 3 one span per type `7 inch: 10 x ₹850` (count x per type rate, t13, wraps; shown for every entry including single type entries, replacing the old "Details only for 2+ types" block and the old single Rate line); line 4 pills "Paid" and "Due" or "Settled".
- The entry level `rate` is never shown. The per type line is the only place a rate appears, so a mixed bill cannot show a misleading first type rate. Rates use `money` (paise only when present); this replaces the old `toStringAsFixed(0)` rounding in the card text (display only, g1 L-08).
- Filter sheet (RigSheet): chips "PVC Type" (7 inch, 8 inch, 10 inch, MS, single select, tap again to deselect, RigChipRow with inverse selected chip, 48 dp boxes), RigGroup row "Storage place" (placeholder "Any"; the old copy "Search by storage location..." is replaced), rows "Start date" and "End date". Clear All and pinned Apply as in the shared list. The same chip order and strings as today; stored strings unchanged.
- Old section 4: 4.1 CHANGED (CategoryTile, no AmountGrid, "All" chip dropped); 4.2 CHANGED (neutral type chips DROPPED, replaced by per type text spans; the collapsible Details row DROPPED because per type text is always visible); 4.3 CHANGED (RigSheet); 4.4 CHANGED (EmptyState icon `plumbing`, "No PVC entries yet", "Tap + to add one."); 4.5 widths and expanded behaviour DROPPED (macOS).
- States: as the shared list; empty copy "No PVC entries yet" and "No entries match your filters".

### R3. Logic touchpoints and LR items

Untouched: `_applyFilters` (type equals the FIRST stored type, storage place case-insensitive contains, date rules, sort), totals (`calculatedTotal`, stored paid and pending, pieces by type), card getters (`displayType`, `totalCount`, `calculatedTotal`, `typeDetails`), delete message `Are you sure you want to delete PVC entry #<bill>?` (the mockup prints `pvc` in lower case: the code copy wins), snackbar "Entry deleted", provider calls and navigation, PVC hidden on side bore by the caller.

LR dependencies: LR-24 (money format), LR-29 proposed (Pending netting; same handling as the shared list, plus the same "Advances" line), LR-34 proposed (no error state), LR-06 not scheduled (no Undo). g1 L-09 (filter matches any type) is not scheduled: the filter sheet keeps single select first type semantics and the sheet does not hint at it. Per type data is read through the memoised `typeDetails` getter. Nothing new (see `temp/design_wip/logic2_r2.md`).

### R4. Acceptance criteria delta

1. Category colour is teal (`catPvc`) on the summary card and nowhere is `Colors.blue` used.
2. Pieces-by-type text in the card equals the per type sums over the shown entries.
3. Every row shows one `<type>: <count> x <rate>` span per stored type, and `N pcs` equals the sum of the counts.
4. A mixed type entry never shows a single rate in the row title or the pills.
5. Filtering 8 inch shows entries whose first stored type is 8 inch (unchanged).
6. At 360 dp, 412 dp, text scale 130 and 200 percent, the per type spans wrap and the total is never clipped.
7. The shared list criteria R4 of the diesel list apply (swipe actions 48 dp, back closes the sheet first, light and dark contrast).

### R5. Parity delta

Intentional: P-PL2-01 adds "N entries" to the summary and drops nothing else; P-PL2-02 changes: the per type lines show for single type entries too and the old "Rate per piece for one type" line goes away (the same rate is in the per type span); "Settled" appears when nothing is due. Must stay identical: P-PL2-03 (first type only filter), P-PL2-04, empty copy, totals, sort.

### R6. Performance and Android notes

As the shared list. The `typeDetails` getter decodes JSON on each access; compute the per type list once per entry in the derived list provider (memoised) rather than in each row build. Keys `ValueKey(entry.id)`. The filter sheet owns and disposes its storage place controller. No blur in the scroll area. Bottom inset from `viewPaddingOf`.
