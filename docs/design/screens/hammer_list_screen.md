> SUPERSEDED IN PART (2026-10-13): the look is now the Apple-inspired Android direction. Read "Reconciliation 2026-10-13" at the end of this file first; where it conflicts with sections 4 to 7 above, it wins.

# hammer_list_screen (Hammer Ledger list, entry card, filter sheet)

File: `lib/features/side_ledger/hammer/hammer_list_screen.dart` (731 lines): `HammerListScreen`, `_HammerEntryCard`, `_HammerFilterSheet`. Shell, summary strip, card anatomy, filter frame, states, delete flow, widths, motion and desktop rules are the shared list spec in `diesel_list_screen.md` section 4; multi-type card and pieces-by-type summary are as in `pvc_list_screen.md` section 4; this list is a line-for-line twin of `bit_list_screen.md` (diff: types, colors, `hammerName` instead of `bitId`, icons). Differences only below.

## 1. Purpose and primary user task

Show hammer purchases of the current rig as cards, newest first, with filtered totals (pieces per type, total, paid, pending). Tasks: see what is pending, filter by type and date, open/edit, add, delete. Reached from the Side Ledger tab (`combined_home_screen.dart:824`); available on main bore and side bore rigs.

## 2. Current structure

Gradient header "Hammer Ledger" (brown), summary card (`brown.shade600 to shade800`) with type pills and Total/Paid/Pending, list or empty state (`Icons.hardware_outlined`, "No hammer entries yet"), FAB brown. Card highlight row: type (`displayType`, color by first type: 6.5 inch brown, 7 inch deep orange, other grey), `<n> pcs` (deep orange), total (`calculatedTotal`, green). Multi-type breakdown block; row [Hammer name chip (grey, `Icons.hardware`, `entry.hammerName`) or empty | Paid + Due]. Filter sheet: "Hammer Type" `Wrap` of `ChoiceChip`s from `['6.5 inch','7 inch']`, date range, Apply (brown). Filter: `HammerFilter{type, startDate, endDate}`.

State: `hammerEntriesProvider`, `hammerFilterProvider`; writes `deleteEntry`, filter state; `refresh()` post-frame.

## 3. Problems found

All items of `diesel_list_screen.md` section 3 and `pvc_list_screen.md` section 3 items 1 to 8, and `bit_list_screen.md` items 2 and 5 apply. Hammer-specific:
1. Icon collision: the empty state and the name chip use `Icons.hardware` family, which the Side Ledger home uses for Bit (and the dead `side_ledger_screen.dart` tile uses `Icons.gavel` for Hammer): Bit and Hammer share one glyph in the list flow.
2. Category color: `Colors.brown` family matches the design system's Hammer identity (brown #8B4513) but the dead `SideLedgerScreen` tile uses `AppColors.accent` (teal): an identity mismatch only inside dead code. Deep orange `pcs` box and brown type box are close in hue.
3. `Colors.brown.shade600` #6D4C41 with white text is 7.4:1 (passes); `deepOrange` #FF5722 `pcs` text on its tint about 3.2:1 (fails 4.5 for 14 sp bold).
4. Only two types exist; the filter's chip row is two chips yet occupies the same 80 dp block and heading as the other lists.
5. The name chip can overflow the Paid/Due row (same pattern as Bit, `Row(spaceBetween)`, no `Flexible`).

## 4. Redesign

Shared + PVC + Bit specs with Hammer specifics:
- Identity token `categoryHammer` (brown family, text-safe tone at least 4.5:1) for the accent edge and header icon tile; actions use `primary`.
- Icons: header/empty `Icons.gavel_rounded`? Rounded variants must exist at implementation: if `Icons.gavel_rounded` exists use it for Hammer (matching the Side Ledger tile), keep `Icons.hardware_rounded` for Bit; the name chip uses `Icons.tag_rounded`. (Icon swap is visual only.)
- Summary strip: Total, Paid, Pending tiles + pieces-by-type chips + "All" chip.
- `SideEntryCard` (kind: hammer): leading tile, title `#<bill>`, right total, subtitle date and the hammer name chip (`Flexible`, ellipsis), neutral type chips, status row.
- Filter sheet: "Hammer Type" `RigChipRow` of the 2 options; scrollable.
- Empty: `EmptyState(title: 'No hammer entries yet' | 'No entries match your filters')`.

## 5. Logic touchpoints that must stay untouched

- `_applyFilters`: type equality on `entry.type` (first stored type), date rules, descending sort.
- Totals and pieces-by-type (`typeDetails`, `calculatedTotal`, `totalCount`), `isPaid = entry.pending <= 0`, `entry.hammerName`.
- `hammerFilterProvider.notifier.state = HammerFilter(type, startDate, endDate)`; clear sets `const HammerFilter()`.
- `hammerEntriesProvider.notifier.refresh()`, `.deleteEntry(id)`; delete message 'Are you sure you want to delete hammer entry #<bill>?' (`hammer_list_screen.dart:69`); snackbar 'Entry deleted'.
- Navigation: card to `HammerFormScreen(entry: entry)`, FAB to `HammerFormScreen()`.

## 6. Acceptance criteria

1. Pieces-by-type chips and Total/Paid/Pending equal sums over shown entries.
2. Filtering "7 inch" shows entries whose first stored type is "7 inch".
3. Hammer name chip shown only when non-empty; never overflows at 360 dp with a 30-character name.
4. Hammer has one identity color and one icon in list, form and tile; Bit and Hammer icons differ.
5. Delete flow, 48 dp target, confirm text as shared.
6. No overflow at 200 percent; contrast at least 4.5:1.
7. macOS: centered max 720, context menu, `Cmd+N`, `Cmd+F`.
8. Filter sheet scrolls under the keyboard.

## 7. Performance notes

Identical to `bit_list_screen.md` section 7: derived provider (copy before sort), memoized `typeDetails` decode, keyed cards, shared `SideEntryCard`, `RigFormat` statics; no controller in the sheet.


## Reconciliation 2026-10-13 (Apple look, Android only)

Reconciles against `diesel_list_screen.md`, `pvc_list_screen.md` and `bit_list_screen.md` "Reconciliation 2026-10-13". Differences only. Sources: `slList({k:'hammer'})`, `slFilter('hammer')`.

### R1. Mockup screens and Flutter mapping

| Mockup screen (J label) | Render function | Flutter file | Widgets | Notes |
|---|---|---|---|---|
| Hammer Ledger | `slList({k:'hammer'})` via `SC.hammer` | `lib/features/side_ledger/hammer/hammer_list_screen.dart` | LargeTitleScaffold, CategoryTile (`catHammer` pink), MoneyTile fit pipeline, RigGroup + RigRow, RowActions, RigChipRow, RigSheet, EmptyState, RigAlertDialog | available on main bore and side bore rigs |
| (no registry label) Filter Entries sheet | `slFilter('hammer')` | same (`_HammerFilterSheet`) | RigSheet, RigChipRow (Hammer type), date rows | |

### R2. What changes in the redesign (supersedes section 4)

- Identity colour is `catHammer` (pink, `#FF2D55` light, `#FF375F` dark, text `#CB0027` / `#FF6F8D`), replacing brown (answer 8). Pink and the `moneyOut` red are close in hue: the pink appears only as the summary gradient, the icon and the empty state, never as a status colour, and every amount keeps its words (Paid, Due, Settled).
- Icon `hardware` (mockup SLC.hammer.icn). The old doc's `gavel` suggestion is DROPPED because the mockup registry uses `hardware` for Hammer and `circle` for Bit.
- Summary card, rows, pills as the PVC and Bit lists. The Hammer name (stored as `hammerName`, shown by the mockup in line 2 beside the date) ellipsises and is omitted when empty.
- Filter sheet: caption "Hammer type", chips `6.5 inch`, `7 inch`, then the date rows.
- Empty: "No hammer entries yet", "Tap + to add one.", tonal "Add entry".
- Old section 4: identity CHANGED (brown to pink); card and filter CHANGED; icon wording CHANGED; widths and desktop DROPPED.

### R3. Logic touchpoints and LR items

Untouched: first stored type filter, totals, pieces by type, `isPaid`, delete copy `Are you sure you want to delete hammer entry #<bill>?`, "Entry deleted", providers, navigation. LR: LR-24, LR-29 proposed, LR-34 proposed, LR-06 not scheduled. Nothing new.

### R4. Acceptance criteria delta

1. Hammer uses `catHammer` pink on the card, icon and empty state in light and dark; text on the gradient is `onTile` at 5.76 : 1 (light) or better.
2. Rows show `<n> pcs` and one `<type>: <count> x <rate>` span per type; totals equal the sums.
3. The Hammer name never overflows at 360 dp with 30 characters.
4. Bit (`circle`) and Hammer (`hardware`) glyphs differ everywhere.
5. Shared list criteria apply.

### R5. Parity delta

Intentional: P-HL-01 summary gains "N entries", colour pink; P-HL-02 name moves from a chip to line 2 text; "Settled" when nothing is due. Identical: type options 6.5 inch and 7 inch, delete text, empty copy, first type filter.

### R6. Performance and Android notes

Identical to the Bit list reconciliation: derived list provider, memoised `typeDetails`, keyed rows, no blur in scroll content, bottom inset from `viewPaddingOf`, no controllers in the sheet.
