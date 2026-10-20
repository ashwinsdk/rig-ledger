> SUPERSEDED IN PART (2026-10-13): the look is now the Apple-inspired Android direction. Read "Reconciliation 2026-10-13" at the end of this file first; where it conflicts with sections 4 to 7 above, it wins.

# hammer_form_screen (Add/Edit Hammer Entry)

File: `lib/features/side_ledger/hammer/hammer_form_screen.dart` (567 lines). Line-for-line twin of `bit_form_screen.dart` (diff: types `['6.5 inch','7 inch']`, field `hammerName`, brown identity). Shell and rules: `diesel_form_screen.md` section 4; multi-type fields and messages: `pvc_form_screen.md` section 4; field placement: `bit_form_screen.md` section 4. Differences only below.

## 1. Purpose and primary user task

Record or edit a hammer purchase with up to two types, each with count and rate, plus an optional Hammer Name: date, bill number, type selection (multi), Hammer Name, count and rate per type, paid amount, notes. No storage place, no delete. Opened from the Hammer list and the Add Entry sheet (`main_navigation.dart:203`, `desktop_shell.dart:311`).

## 2. Current structure

Same as the Bit form: Date (icon brown), Bill Number *, "Hammer Type * (Select one or more)" chips (`6.5 inch` brown, `7 inch` deep orange), **Hammer Name** (`Icons.hardware`, hint "Enter hammer name/identifier", optional), per-type count/rate blocks, Total (green), Paid, Pending (only when > 0, red), Notes, Save (brown). State: `hammerEntriesProvider.notifier`, `DatabaseService.getHammerEntriesByVehicle`, `_hammerNameController`.

## 3. Problems found

All items of `pvc_form_screen.md` section 3 (1 to 11) and `bit_form_screen.md` items 1, 4 and 6 apply (Hammer Name sits between the chips and the per-type blocks; legacy types outside the 2 options could block save). Hammer-specific:
1. Only 2 types, so the per-type area is at most 240 dp: the form is the shortest of the multi-type forms, yet Save still sits at the bottom with no pinned bar.
2. Hint "Enter hammer name/identifier" is the only guidance; a hammer entered with an empty name saves silently and shows no name chip on the list (acceptable but undocumented).
3. `deepOrange` #FF5722 chip label on its tint about 3.0:1 (fails); brown on brown tint passes.
4. Same hue-only distinction between two types (brown vs deep orange).

## 4. Redesign

PVC/Bit form layout with: Hammer Type chips `['6.5 inch','7 inch']` neutral tonal; Hammer Name `RigTextField` label "Hammer Name", helper "Optional", leading `Icons.tag_rounded`, grouped with the chips under `RigSection('Hammer details')`; per-type cards in a 2-column grid at medium and expanded (always at most 2); Total and Pending in `FormSaveBar`; identity token `categoryHammer` on the header icon tile only; Save in `primary`. Compact single column; expanded max width 640. State table, motion, desktop (`Cmd+S`, `Esc`, Space toggles chips) as the PVC form.

## 5. Logic touchpoints that must stay untouched

- `hammerTypes` list and strings; save mapping, validation order and messages as PVC with Hammer wording ('Please select at least one Hammer type', 'Please enter count and rate for <type>', 'Bill number "<n>" already exists'); `hammerName: _hammerNameController.text.trim()` (no validator).
- `_recalculate`, deselect-clears-values, load fallback chain, `type = first selected`, `count = sum`, `rate = first rate`, `balance = paid - total`.
- Uniqueness via `getHammerEntriesByVehicle` (exact string, ignores self).
- `hammerEntriesProvider.notifier.addEntry/updateEntry`; snackbars 'Entry added'/'Entry updated'; pop before snackbar.
- Date picker range 2020 to now + 365 (initial date may be clamped).

## 6. Acceptance criteria

1. 6.5 inch count 3 rate 2,000 and 7 inch count 1 rate 2,500 give Total Rs 8,500.00.
2. Hammer Name optional; stored trimmed; shown on the list card only when non-empty.
3. Field order: Date, Bill Number, Hammer Type, Hammer Name, Count & Rate, Total, Paid, Pending, Notes.
4. Messages, uniqueness, deselect and Undo behavior as PVC criteria 3 to 6.
5. Save and totals visible in the bar without scrolling.
6. No `Colors.x`; one identity color; 48 dp targets; 200 percent text scale without overflow.
7. macOS: width 640, `Cmd+S`, `Esc`.
8. Double tap Save creates one entry.

## 7. Performance notes

As Bit/PVC forms: merge-listenable totals, keyed per-type blocks, `RigFormat` statics, all controllers (4 count/rate + paid + name + notes + bill) disposed.


## Reconciliation 2026-10-13 (Apple look, Android only)

Reconciles against `diesel_form_screen.md`, `pvc_form_screen.md` and `bit_form_screen.md` "Reconciliation 2026-10-13". Differences only. Sources: `slForm` with `k=='hammer'`.

### R1. Mockup screens and Flutter mapping

| Mockup screen (J label) | Render function | Flutter file | Widgets | Notes |
|---|---|---|---|---|
| Add Hammer Entry | `newSl('hammer')` then `slForm({k:'hammer'})` | `lib/features/side_ledger/hammer/hammer_form_screen.dart` | same set as the PVC form | edit title "Edit Hammer Entry" |

### R2. What changes in the redesign (supersedes section 4)

- Order in the mockup: live card, RigGroup (Date, Bill number), RigGroup with one row "Hammer name" (hint "Name or identifier"), caption "Hammer type, select one or more" with chips `6.5 inch`, `7 inch`, per type groups (at most 2), "Paid amount", "Notes", pinned Save. The name row sits before the chips (same decision as Bit, see `bit_form_screen.md`). No storage place and no Paid date.
- Hint "Name or identifier" is kept; the field is optional and an empty name saves silently (documented, copy only: add helper "Optional").
- Per type groups, footers, deselect Undo, live card rules, pinned pill and guards as the PVC form. Old section 4: order CHANGED, identity brown to pink (header icon only, if used), widths and desktop DROPPED.

### R3. Logic touchpoints and LR items

Untouched: `hammerTypes`, messages ('Please select at least one Hammer type', 'Please enter count and rate for <type>', duplicate), `hammerName: text.trim()` with no validator, save mapping, uniqueness, load fallback chain. LR: LR-25, LR-32 (approved), LR-24. Nothing new.

### R4. Acceptance criteria delta

1. 6.5 inch 3 x 2,000 and 7 inch 1 x 2,500 give Total ₹8,500.
2. Hammer name optional, stored trimmed, shown in the list row line 2 only when non-empty.
3. Order is Date, Bill number, Hammer name, Hammer type, per type groups, Paid amount, Notes.
4. PVC form criteria 2 to 8 apply.

### R5. Parity delta

Intentional: P-HF-01 order (name before chips; Total and Pending in the live card). Identical: P-HF-02 (messages, totals).

### R6. Performance and Android notes

As the Bit form: merged listenables, keyed groups (at most 2), all controllers disposed, `PopScope` guard, `viewPaddingOf` for the pill, no blur in scroll content.
