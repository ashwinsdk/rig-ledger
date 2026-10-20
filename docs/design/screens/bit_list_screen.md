> SUPERSEDED IN PART (2026-10-13): the look is now the Apple-inspired Android direction. Read "Reconciliation 2026-10-13" at the end of this file first; where it conflicts with sections 4 to 7 above, it wins.

# bit_list_screen (Bit Ledger list, entry card, filter sheet)

File: `lib/features/side_ledger/bit/bit_list_screen.dart` (742 lines): `BitListScreen`, `_BitEntryCard`, `_BitFilterSheet`. The shell, summary strip, card anatomy, filter frame, empty/loading states, delete flow, widths, motion and desktop rules are the shared list spec in `diesel_list_screen.md` section 4; the multi-type card, type chips, Details row and pieces-by-type summary are as in `pvc_list_screen.md` section 4. This doc records the differences only. Near duplicate of the PVC list (diff: no storage place, a Bit ID chip, different types and colors, no storage filter).

## 1. Purpose and primary user task

Show drill bit purchases of the current rig as cards, newest first, with filtered totals (pieces per type, total, paid, pending). Tasks: see what is pending, filter by type and date, open/edit, add, delete. Reached from the Side Ledger tab (`combined_home_screen.dart:808`). Available on main bore and side bore rigs.

## 2. Current structure

Gradient header "Bit Ledger" (purple), summary card (`purple.shade600 to shade800`) with type pills and Total/Paid/Pending, list or empty state (`Icons.settings_outlined`, text "No bit entries yet" or "No entries match your filters"), FAB purple. Card highlight row: type (`displayType`, color by first type: 6.5 inch teal, 7.25 inch blue, 7.5 inch indigo, 9 inch purple, 9.5 inch deep purple), `<n> pcs` (indigo), total (`calculatedTotal`, green). Multi-type breakdown block, then a row [Bit ID chip (grey, `Icons.tag`, text `entry.bitId`) or empty | Paid + Due]. No bunk or storage row. Filter sheet: "Bit Type" `Wrap` of `ChoiceChip` (6.5 inch, 7.25 inch, 7.5 inch, 9 inch, 9.5 inch, `runSpacing 8`), date range, Apply (purple). Filter fields: `BitFilter{type, startDate, endDate}` (no text field, so no controller in the sheet).

State: `bitEntriesProvider`, `bitFilterProvider`; writes `deleteEntry`, filter state; `refresh()` post-frame.

## 3. Problems found

All problems of `diesel_list_screen.md` section 3 (items 1 to 20) and `pvc_list_screen.md` section 3 items 1 to 8 apply. Bit-specific:
1. Category color mismatch: the live Side Ledger tiles and the form date icon use green for Bit (`bit_form_screen.dart` date icon `Colors.green`; DESIGN_SYSTEM and CONVENTIONS name Bit = green) but this list, its FAB, summary card, bill chip and Save button are purple. Two identities for one category in one flow.
2. Bit ID chip (`entry.bitId`) is a grey chip in a `Row(spaceBetween)` with the Paid/Due row: with a long ID plus `Paid` and `Due` it overflows (no `Flexible`); when the ID is empty an empty `SizedBox.shrink()` pushes the Paid row to the left edge (lines about 475-540).
3. Pill text white on `purple.shade600` #8E24AA is 7.0:1 (passes) but the translucent pill (20 percent white) lowers it to about 5.6:1: acceptable; the filter dot `AppColors.warning` has no text alternative.
4. Type color of an indigo `pcs` box next to a type-colored box: two similar hues (indigo, deep purple, purple) distinguish 5 types by hue only; hard to tell apart for color-blind users (type name is also shown in text: partially mitigated).
5. Filter sheet: single `Wrap` of 5 chips, scroll missing (same as diesel #11).
6. The ID has no filter or search; with many bits the user cannot find "bit by ID" (feature gap, not added; see logic_g1.md L-10 if wanted).

## 4. Redesign

Per shared and PVC specs. Bit specifics:
- Accent edge and header icon tile use `categoryBit` (resolved to a green-family identity token, matching the home tile and the form). FAB and Save use `primary`.
- Summary strip: Total, Paid, Pending tiles + pieces-by-type chips + "All" chip (same rule as PVC).
- `SideEntryCard` (kind: bit): leading tile `Icons.hardware_rounded` (not settings), title `#<bill>`, right total, subtitle date, then type chips (neutral), then a status row; the Bit ID appears as a `labelMedium` chip with `Icons.tag_rounded` in the subtitle line (`maxLines: 1`, ellipsis, `Flexible`), never in the Paid/Due row. When the ID is empty the chip is omitted without moving other items.
- Filter sheet: "Bit Type" `RigChipRow` ChoiceChips `['6.5 inch','7.25 inch','7.5 inch','9 inch','9.5 inch']`, date range, scrollable body.
- Empty state: `EmptyState(icon: Icons.hardware_rounded, title: 'No bit entries yet' | 'No entries match your filters')`. (Existing copy is lower case "bit"; keep.)

State table, widths, motion and desktop behavior: identical to the shared spec.

## 5. Logic touchpoints that must stay untouched

- `_applyFilters`: type equality on `entry.type` (first stored type), date rules, descending sort.
- Totals and pieces-by-type rules as PVC (`typeDetails`, `calculatedTotal`, `totalCount`).
- Card data: `displayType`, `totalCount`, `calculatedTotal`, `typeDetails` breakdown for 2 or more types, `entry.bitId`, `entry.paid`, `isPaid = entry.pending <= 0`.
- `bitFilterProvider.notifier.state = BitFilter(type, startDate, endDate)`; clear sets `const BitFilter()`.
- `bitEntriesProvider.notifier.refresh()`, `.deleteEntry(id)`; delete message 'Are you sure you want to delete bit entry #<bill>?' (lower case "bit", `bit_list_screen.dart:68`); snackbar 'Entry deleted'.
- Navigation: card to `BitFormScreen(entry: entry)`, FAB to `BitFormScreen()`.

## 6. Acceptance criteria

1. Pieces-by-type chips and Total/Paid/Pending equal the sums over shown entries.
2. Filtering by "9 inch" shows entries whose first stored type is "9 inch".
3. Bit ID chip is shown only when `bitId` is non-empty and never overflows at 360 dp with a 30-character ID (ellipsis).
4. Bit uses one identity color across list, form and Side Ledger tile.
5. Delete flow, 48 dp delete target and confirm text as shared spec.
6. No overflow at 200 percent text scale; text contrast at least 4.5:1.
7. macOS: centered max 720, context menu, `Cmd+N`, `Cmd+F`.
8. Filter sheet scrolls under the keyboard.

## 7. Performance notes

As diesel and PVC lists: derived provider for filtered list and totals (copy before sort), memoized `typeDetails` decode (the getter decodes JSON on each access), keyed cards, one `SideEntryCard`, `RigFormat` statics. The sheet has no controller to dispose (type chips + dates only).


## Reconciliation 2026-10-13 (Apple look, Android only)

Reconciles against `diesel_list_screen.md` (shared list) and `pvc_list_screen.md` (multi type rows) "Reconciliation 2026-10-13". Differences only. Sources: `slList({k:'bit'})`, `slFilter('bit')`.

### R1. Mockup screens and Flutter mapping

| Mockup screen (J label) | Render function | Flutter file | Widgets | Notes |
|---|---|---|---|---|
| Bit Ledger | `slList({k:'bit'})` via `SC.bit` | `lib/features/side_ledger/bit/bit_list_screen.dart` | LargeTitleScaffold, CategoryTile (`catBit` purple), MoneyTile fit pipeline, RigGroup + RigRow, RowActions, RigChipRow, RigSheet, EmptyState, RigAlertDialog | available on main bore and side bore rigs |
| (no registry label) Filter Entries sheet | `slFilter('bit')` | same (`_BitFilterSheet`) | RigSheet, RigChipRow (Bit type), date rows | no text field, so no controller |

### R2. What changes in the redesign (supersedes section 4)

- Identity colour is `catBit` (purple, `#AF52DE` light, `#BF5AF2` dark, text `#9928D2` / `#D17FF6`) on the summary card gradient, the icon and the empty state. This ends the green versus purple split noted in problem 1: list, form and the Side Ledger tile all use purple (answer 8). Today the form date icon is green and the old docs named Bit green; both are replaced.
- Icon: `circle` in the mockup registry (SLC.bit.icn). The old doc asked for `hardware_rounded` for Bit; the mockup gives `hardware` to Hammer and `circle` to Bit, so the two glyphs are distinct. Use the mockup glyphs (`circle` for Bit, `hardware` for Hammer).
- Summary card and rows as `pvc_list_screen.md`: "N entries", Total hero, Paid, Pending, pieces by type ("7.25 inch: 4"), rows `#<bill>  <totalCount> pcs`, total, date and the Bit ID (the mockup puts `e.place`, which for Bit is the Bit ID, in line 2 next to the date; ellipsis, omitted when empty), per type spans `<type>: <count> x <rate>`, pills. The Bit ID never shares a line with the Paid and Due pills, which fixes the overflow in problem 2.
- Filter sheet: caption "Bit type" then a wrapping RigChipRow of `6.5 inch`, `7.25 inch`, `7.5 inch`, `9 inch`, `9.5 inch` (single select, tap again to clear), then the two date rows. No ID search (g1 L-10 not scheduled).
- Empty: icon `circle`, "No bit entries yet" (lower case kept), "Tap + to add one.", tonal "Add entry".
- Old section 4: accent and icon CHANGED (green wording DROPPED, now purple); card CHANGED as above; filter CHANGED (RigSheet); empty copy KEPT; widths and desktop DROPPED.
- States, motion, tokens: as the shared list.

### R3. Logic touchpoints and LR items

Untouched: `_applyFilters` (first stored type, date rules, sort), totals and pieces by type, `bitId` display, `isPaid`, delete copy `Are you sure you want to delete bit entry #<bill>?` (lower case, code wins; the mockup also prints `bit`), "Entry deleted", provider calls and navigation.

LR: LR-24, LR-29 proposed (same as the shared list), LR-34 proposed, LR-06 not scheduled. Nothing new.

### R4. Acceptance criteria delta

1. Bit uses `catBit` purple on the summary card, icon and empty state in light and dark; no green or `Colors.*`.
2. Pieces by type, rows and totals equal the sums over shown entries; each row shows count x rate per type.
3. A 30 character Bit ID ellipsises in line 2 at 360 dp and does not move the pills.
4. Filtering 9 inch shows entries whose first stored type is 9 inch.
5. Shared list criteria (swipe, back, scale 130 and 200 percent, contrast) apply.

### R5. Parity delta

Intentional: P-BL-01 summary gains "N entries"; P-BL-02 the Bit ID moves from a grey chip to line 2 text, per type lines show for single type entries, "Settled" when nothing is due; colour purple. Identical: type options, messages, delete text, empty copy, first type filter.

### R6. Performance and Android notes

As the shared list and the PVC list: memoised `typeDetails`, derived list provider, keyed rows, no blur in scroll content, bottom inset from `viewPaddingOf`, sheet without controllers.
