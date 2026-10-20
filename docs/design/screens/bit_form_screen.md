> SUPERSEDED IN PART (2026-10-13): the look is now the Apple-inspired Android direction. Read "Reconciliation 2026-10-13" at the end of this file first; where it conflicts with sections 4 to 7 above, it wins.

# bit_form_screen (Add/Edit Bit Entry)

File: `lib/features/side_ledger/bit/bit_form_screen.dart` (579 lines). Identical to the PVC form except as listed here. Shell and rules: `diesel_form_screen.md` section 4; multi-type fields, deselect safety, validation messages, state table: `pvc_form_screen.md` section 4. Read those first.

## 1. Purpose and primary user task

Record or edit a bit purchase with several bit types, each with its own count and rate, plus an optional Bit ID: date, bill number, type selection (multi), Bit ID, count and rate per type, paid amount, notes. No storage place field and no delete action. Opened from the Bit list and the Add Entry sheet (`main_navigation.dart:193`, `desktop_shell.dart:305`).

## 2. Current structure

Same as the PVC form with these differences: `static const bitTypes = ['6.5 inch','7.25 inch','7.5 inch','9 inch','9.5 inch']`; date icon green; field order is Date, Bill Number, Bit Type chips, **Bit ID** (optional, `Icons.tag`, hint "Enter unique bit identifier"), Count & Rate per Type blocks, Total, Paid, Pending (only when > 0), Notes, Save (purple). Type colors: teal, blue, indigo, purple, deep purple. State: `bitEntriesProvider.notifier`, `DatabaseService.getBitEntriesByVehicle` (uniqueness), `_bitIdController`.

## 3. Problems found

All items of `pvc_form_screen.md` section 3 (1 to 11) apply. Bit-specific:
1. Bit ID sits between the type chips and the per-type blocks, interrupting the "choose types then fill their counts" flow (the type chips and their count/rate blocks are the same task but separated by an unrelated field). Moving it would change the field order, which parity pins, so it stays; the redesign makes the relationship clear with a section heading instead.
2. Hint says "Enter unique bit identifier" but uniqueness is not validated anywhere: the field accepts duplicates and empty (copy promises more than the code does).
3. Mixed identity colors: date icon `Colors.green`, header/Save/FAB/type pills purple (same inconsistency as `bit_list_screen.md` problem 1).
4. Five chips in a `Wrap` and up to five per-type blocks (about 600 dp when all selected) push Save far below; Total and Pending scroll away.
5. `Colors.teal`, `blue`, `indigo`, `purple`, `deepPurple` type tints with labels at 2.3 to 5.1:1 (teal #009688 text on its tint about 3.0:1).
6. Legacy types not in the 5 options: same stuck-save risk as PVC (UNVERIFIED).

## 4. Redesign

PVC form layout with these Bit specifics (order preserved):

| # | Block | Notes |
|---|---|---|
| 1 | Date | `RigDateField` |
| 2 | Bill Number * | digits only |
| 3 | Bit Type * | `RigChipRow` multi-select, options `['6.5 inch','7.25 inch','7.5 inch','9 inch','9.5 inch']` |
| 4 | Bit ID | `RigTextField` label "Bit ID", helper "Optional. Use an identifier you can recognize" (replaces the "unique" claim; copy only), leading `Icons.tag_rounded`, `next`. Placed under the chips inside a `RigSection('Bit details')` that also holds the chips so the grouping reads as one block |
| 5 | Count & Rate per Type * | per-type cards as PVC |
| 6 | Total Amount | `AmountTile` |
| 7 | Paid Amount | `AmountField` |
| 8 | Pending | `AmountTile`, only when pending > 0 |
| 9 | Notes | multiline |
| 10 | Save | `FormSaveBar` |

Identity: header icon tile `categoryBit`; no type hues; Save in `primary`. Widths: compact single column; medium and expanded: Date + Bill Number side by side, type cards in 2 columns when 3 or more are selected, max width 640. Desktop, motion, state table: as PVC form.

## 5. Logic touchpoints that must stay untouched

- `bitTypes` list and strings; the save mapping, validation order and messages of the PVC form with `Bit` wording ('Please select at least one Bit type', 'Please enter count and rate for <type>', 'Bill number "<n>" already exists'); `bitId: _bitIdController.text.trim()` (no validator, empty allowed); no storage field.
- `_recalculate`, deselect-clears-values, load fallback chain (`typeDetails`, `types`, `type`), `type = first selected`, `count = sum`, `rate = first rate`, `balance = paid - total`.
- Uniqueness via `getBitEntriesByVehicle` (exact string match, ignores self).
- Providers `bitEntriesProvider.notifier.addEntry/updateEntry`; snackbars 'Entry added'/'Entry updated'.

## 6. Acceptance criteria

1. Two types (6.5 inch count 4 rate 500; 9 inch count 2 rate 1,500) give Total Rs 5,000.00.
2. Bit ID is optional: saving with it empty works; entered ID is stored trimmed and shown on the list card.
3. Field order is exactly Date, Bill Number, Bit Type, Bit ID, Count & Rate, Total, Paid, Pending, Notes.
4. Messages, uniqueness, deselect behavior, Undo snackbar as the PVC form criteria 3 to 6.
5. Save visible without scrolling; Total and Pending visible in the bar.
6. One identity color for Bit in list, form and tile; no `Colors.x`.
7. 200 percent text scale without overflow; 48 dp targets.
8. macOS: width 640, `Cmd+S`, `Esc`.

## 7. Performance notes

Same as the PVC form: merge-listenable driven totals, per-type blocks keyed by type, no whole-form `setState` per keystroke, controller maps disposed (`_bitIdController` too), `RigFormat` statics. Five count + five rate controllers are created up front (10 controllers, 10 listeners): acceptable, but attach listeners only for selected types in a future refactor.


## Reconciliation 2026-10-13 (Apple look, Android only)

Reconciles against `diesel_form_screen.md` (shared form) and `pvc_form_screen.md` (multi type groups) "Reconciliation 2026-10-13". Differences only. Sources: `slForm` with `k=='bit'`.

### R1. Mockup screens and Flutter mapping

| Mockup screen (J label) | Render function | Flutter file | Widgets | Notes |
|---|---|---|---|---|
| Add Bit Entry | `newSl('bit')` then `slForm({k:'bit'})` | `lib/features/side_ledger/bit/bit_form_screen.dart` | same set as the PVC form | edit title "Edit Bit Entry" |

### R2. What changes in the redesign (supersedes section 4)

- Order in the mockup: live card, RigGroup (Date, Bill number), RigGroup with one row "Bit ID" (hint "Unique identifier"), caption "Bit type, select one or more" with chips `6.5 inch`, `7.25 inch`, `7.5 inch`, `9 inch`, `9.5 inch`, per type Count and Rate per piece groups, caption "Payment" with "Paid amount", caption "Notes", pinned Save. No storage place and no Paid date. The Bit ID row sits BEFORE the chips, whereas the old order (P-BF-01) is chips then Bit ID. Decision: follow the mockup (the identifier reads as part of the bill header and no longer splits the chips from their count and rate groups, which was problem 1). This is a parity delta, see R5 and conflict C-r2-2.
- Hint copy: the mockup says "Unique identifier" but uniqueness is not validated (problem 2); use "Optional. Use an identifier you can recognize" to keep the claim honest (copy only).
- Identity `catBit` purple appears on the header icon only if the lead adds one; the form itself is neutral. Save is `accentButton`, never purple.
- Everything else (live card, per type groups with footer `<count> x <rate> = <line total>`, deselect Undo, state rules, pinned pill) as the PVC form. Old section 4 items: field table CHANGED (order above), identity KEPT as header icon only, widths DROPPED.

### R3. Logic touchpoints and LR items

Untouched: `bitTypes`, messages ('Please select at least one Bit type', 'Please enter count and rate for <type>', duplicate), `bitId: text.trim()` with no validator, save mapping, uniqueness, load fallback chain. LR: LR-25, LR-32 (approved), LR-24. Nothing new.

### R4. Acceptance criteria delta

1. Two types (6.5 inch 4 x 500, 9 inch 2 x 1,500) give Total ₹5,000.
2. Bit ID is optional; stored trimmed; the list shows it in line 2.
3. Field order is Date, Bill number, Bit ID, Bit type, per type groups, Paid amount, Notes.
4. PVC form criteria 2 to 8 apply (footers, no entry level rate or count, pinned Save, 48 dp, scale 130 and 200 percent, discard alert, clamped picker).

### R5. Parity delta

Intentional: P-BF-01 order (Bit ID before the chips; Total and Pending in the live card). Identical: P-BF-02, P-BF-03.

### R6. Performance and Android notes

As the PVC form: merged listenables for totals, keyed per type groups, `_bitIdController` and all others disposed, `PopScope` guard, `viewPaddingOf` for the pill. 10 count and rate controllers exist up front; attach listeners for selected types only if profiling shows a cost.
