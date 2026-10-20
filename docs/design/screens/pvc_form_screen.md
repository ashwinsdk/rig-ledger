> SUPERSEDED IN PART (2026-10-13): the look is now the Apple-inspired Android direction. Read "Reconciliation 2026-10-13" at the end of this file first; where it conflicts with sections 4 to 7 above, it wins.

# pvc_form_screen (Add/Edit PVC Entry)

File: `lib/features/side_ledger/pvc/pvc_form_screen.dart` (570 lines). Reference doc for the three multi-type side ledger forms (PVC, Bit, Hammer). Shell, validation timing, save bar, desktop rules and motion are those of `diesel_form_screen.md` section 4 ("shared form spec"); `bit_form_screen.md` and `hammer_form_screen.md` document only differences from this file.

## 1. Purpose and primary user task

Record or edit a PVC purchase that may include several pipe types, each with its own count and rate: date, bill number, type selection (multi), count and rate per selected type, paid amount, storage place, notes. Total (sum of count x rate) and Pending are live. No delete in this form. Opened from the PVC list and the Add Entry sheet (`main_navigation.dart:183`, `desktop_shell.dart:299`). Not offered on side bore rigs (caller hides it).

## 2. Current structure

`Scaffold` > gradient `AppBar` (literal hex) > `AdaptiveContent(700)` > `Form` > `ListView(16)`:
1. Date (`Card > ListTile`, calendar icon blue)
2. Bill Number * (digits only, outlined)
3. "PVC Type * (Select one or more)" label + `Wrap` of `FilterChip`s (7 inch, 8 inch, 10 inch, MS; selected tint from `_getTypeColor`)
4. If any selected: "Count & Rate per Type *" label, then one tinted container per selected type (in the fixed list order): type name in the type color, row [Count (int, digitsOnly) | Rate/pc (decimal)] with dense outlined fields and colored icons
5. Total Amount box (green)
6. Paid Amount
7. Pending box, shown only when `_pending > 0` (red)
8. Storage Place (outlined, warehouse icon)
9. Notes
10. Save (blue `ElevatedButton`)

State: `pvcEntriesProvider.notifier.addEntry/updateEntry`; `DatabaseService.currentVehicleId`, `getPvcEntriesByVehicle` (uniqueness, direct call). Local: `_countControllers` and `_rateControllers` maps (8 controllers created up front for all four types, each with a `_recalculate` listener), `_paidController`, `_selectedTypes` (Set), `_total`, `_pending`.

## 3. Problems found

1. Same header, Save reachability, discard, double-tap, `Colors.x`, snackbar, date-picker-range and `NumberFormat`-in-`build` problems as `diesel_form_screen.md` section 3 items 1, 2, 3, 7, 10 to 14 (blue `Colors.blue` Save, `Colors.green` Total box 2.7:1, `Colors.red` Pending 3.6:1).
2. Type chips: `FilterChip` default tap target is 32 dp visual (the `Wrap` run spacing 8 gives about 40 dp); `labelStyle` colors from `Colors.blue/green/purple/orange` on 20 percent tints: green #4CAF50 on tint about 2.4:1, orange #FF9800 about 2.1:1 (fail 4.5). Selection is signalled by color and a check mark, so it is not color-only, but the label contrast is poor.
3. Per-type blocks appear and disappear below the chips, pushing the whole form down by about 120 dp per type: with all four types selected the block is about 480 dp, so Total, Pending and Save move out of view.
4. Deselecting a type silently clears its Count and Rate (lines 351-355): data typed for that type is lost with no confirmation or undo; a mis-tap on a chip destroys input.
5. Count and Rate have no validators: errors for a missing count or rate are raised after Save as red snackbars ('Please enter count and rate for <type>' and 'Please select at least one PVC type', lines 163-186), not next to the offending field. The snackbar can be covered by the keyboard.
6. Legacy entries whose type is not in `['7 inch','8 inch','10 inch','MS']` (older records, other spelling) are added to `_selectedTypes` (lines 76, 82, 89) but have no controller and no row, so `_recalculate` counts them as 0 and Save fails with 'Please enter count and rate for <type>' that the user cannot fix (UNVERIFIED: depends on existing data; see bugs_g1.md).
7. Pending box exists only when pending > 0; unlike diesel there is no "Balance (Advance)" display for overpayment, so the form is inconsistent with diesel for the same concept.
8. Count is integer-only (digitsOnly) and Rate decimal: correct, but both use `isDense: true` outlined fields (reduced content padding, shorter than the 56 dp fields elsewhere, so the 48 dp target is not guaranteed) inside a 12 dp padded container (lines 403-427) and inconsistent with the 56 dp fields elsewhere.
9. Total is computed but never rounded; display only.
10. Label conventions: "PVC Type * (Select one or more)" and "Count & Rate per Type *" are plain `Text`, not field labels; the asterisk is on non-input labels.
11. Save uses blue; header is the brand gradient; type colors reuse the status palette.

## 4. Redesign

### 4.1 Fields (order preserved)

| # | Block | Component | Notes |
|---|---|---|---|
| 1 | Date | `RigDateField`, `dateShort` | |
| 2 | Bill Number * | `RigTextField`, digits only, `TextInputType.number`, `next` | error 'Please enter a bill number' |
| 3 | PVC Type * | `RigSection('PVC Type', trailing: 'Select one or more')` + `RigChipRow` of `FilterChip` (multi-select, 48 dp hit target via `MaterialTapTargetSize.padded`, neutral tonal selected state `primaryContainer`, check icon) | chips wrap; at compact two or three per row |
| 4 | Count & Rate per Type * | one `RigCard` (tone `surfaceContainer`) per selected type, titled with the type name (`titleSmall onSurface`, no hue), two 56 dp fields [Count | Rate/pc] side by side (stacked at compact when text scale > 1.3); helper under the row: "<count> x Rs <rate> = Rs <line total>" `bodySmall`, tabular (display only, from the same controllers) | blocks animate in with `AnimatedSize` 200 ms; inline errors under Count and Rate (see 4.3) |
| 5 | Total Amount | `AmountTile` read-only, `amountLarge` neutral | |
| 6 | Paid Amount | `AmountField` | |
| 7 | Pending | `AmountTile`, `outstanding`; visible exactly when `_pending > 0` (same rule) | |
| 8 | Storage Place | `RigTextField`, `words`, leading `Icons.warehouse_rounded`, `next` | |
| 9 | Notes | `RigTextField` multiline 3 to 6 | |
| 10 | Save | `FormSaveBar` (Total, Pending, Save) | |

Because Total and Pending live in the pinned bar, the per-type blocks growing no longer hides them.

### 4.2 Deselect safety (UI only)

When the user deselects a type that has a non-empty Count or Rate, show `RigSnack` "<type> removed" with action "Undo" (4 s) that re-selects it and restores the two texts (kept in a local map in the State). Behavior without tapping Undo is identical to today (values cleared).

### 4.3 Validation timing and messages

Count and Rate rows validate on Save (then `onUserInteraction`): Count empty or 0 shows 'Enter a count' under Count, Rate empty or 0 shows 'Enter a rate' under Rate (copy). These inline messages are shown IN ADDITION to the existing snackbar 'Please enter count and rate for <type>' (kept verbatim, same condition `count <= 0 || rate <= 0`); the validation condition is not changed. 'Please select at least one PVC type' is shown inline under the chips as well as in the snackbar.

### 4.4 Widths

Compact: single column; chips wrap; type blocks stacked. Medium: Date and Bill Number side by side; type blocks in a 2-column grid when 3 or more types are selected. Expanded: same as medium, max width 640. Desktop: `Cmd+S`, `Esc`, Tab order by visual order (chips are focusable and toggle with `Space`).

### 4.5 State table

| State | Rule |
|---|---|
| Default new | no type selected; type blocks hidden; Total Rs 0.00 |
| Default edit | types pre-selected from `typeDetails`, else `types`, else `type` (same fallback chain); counts and rates filled |
| Unknown legacy type | the chip row shows an extra selected, disabled chip with the stored label and a helper "Not an available type, remove it to save" (UI only; save condition unchanged, see logic_g1.md L-02) |
| Saving | Save disabled with spinner |
| Error | inline messages plus snackbar |
| Pending 0 or less | Pending tile hidden |
| Dirty | discard prompt |

### 4.6 Tokens, components

Spacing `s3` inside blocks, `s4` between, radius `lg` blocks, `md` fields; type `titleSmall`, `bodyLarge`, `amountLarge`; colors `primaryContainer` (selected chip), `surfaceContainer`, `outstanding`, `negative`, `categoryPvc` only on the header icon tile. Components: `RigAppBar`, `RigScaffold`, `RigDateField`, `RigTextField`, `AmountField`, `AmountTile`, `RigChipRow`, `RigCard`, `FormSaveBar`, `RigSnack`, `UnsavedChangesGuard`.

### 4.7 Motion

Type blocks `AnimatedSize` 200 ms and fade 150 ms; Pending tile fade 150 ms; reduced motion honored.

## 5. Logic touchpoints that must stay untouched

- `static const pvcTypes = ['7 inch','8 inch','10 inch','MS']` (stored strings).
- `_recalculate`: for each selected type `count = int.tryParse(text) ?? 0`, `rate = double.tryParse(text) ?? 0`, `total += count * rate`; `_pending = _total - paid`.
- Save validation order: form validators (Bill Number), then 'Please select at least one PVC type' (snackbar), then per selected type `count <= 0 || rate <= 0` returns 'Please enter count and rate for <type>', then uniqueness `_isBillNumberUnique` (same vehicle, exact string, ignores self) with 'Bill number "<n>" already exists'.
- Save mapping: `type = typesList.first`, `types = typesList`, `typeDetailsJson = TypeDetail.encodeList(...)` in `_selectedTypes` iteration order, `count = totalCount`, `rate = typeDetails.first.rate`, `total = _total`, `paid`, `pending = _pending`, `balance = paid - _total`, `storagePlace` trimmed, `notes` null when empty, `createdAt` preserved on edit, `vehicleId = currentVehicleId`.
- Loading existing: fallback chain `typeDetails` then `types` then `type` with shared count/rate for the legacy cases.
- Deselect clears both controllers; selecting adds the type (controllers persist for the session).
- Validators: Bill Number 'Please enter a bill number'; digitsOnly on Bill Number and Count; `^\d*\.?\d*` on Rate and Paid.
- Providers: `addEntry`/`updateEntry`; snackbars 'Entry added'/'Entry updated'; pop before snackbar.
- Date picker range 2020 to now + 365 (initial date may be clamped; range not widened).

## 6. Acceptance criteria

1. With types 7 inch (count 10, rate 100) and 8 inch (count 5, rate 200), Total = Rs 2,000.00; Paid 500 gives Pending Rs 1,500.00.
2. Selecting a type shows its block; deselecting removes it and subtracts it from Total; Undo restores texts.
3. Save with no type shows the message inline and as snackbar; with a selected type missing count or rate shows the inline and snackbar messages; nothing is saved.
4. Save with a duplicate bill number in the same rig is rejected with the same message.
5. Saved entry has `type` equal to the first selected type in list order, `count` equal to the sum, `typeDetails` with one item per selected type.
6. Editing a legacy entry (single type) opens with that type selected and the old count and rate; Save keeps total semantics.
7. Total and Pending remain visible in the bar while the 4 type blocks are shown.
8. Chips and fields are at least 48 dp (mobile).
9. Chip label contrast at least 4.5:1; selected state also shows a check icon.
10. No overflow at 200 percent text scale.
11. macOS: width 640, `Cmd+S`, `Esc`, Space toggles chips.
12. Double tap Save creates one entry.

## 7. Performance notes

- 8 controllers each add a `_recalculate` listener that calls `setState` on the whole form per keystroke; replace with one `Listenable.merge` of the selected types' controllers + paid driving `_PvcTotals` and `FormSaveBar` via `ListenableBuilder`; keep the type blocks as separate `const`-friendly widgets keyed by type so typing in one block does not rebuild the others.
- Controllers are all created in `initState` and disposed in `dispose` (maps iterated): OK. Creating 8 up front is cheap.
- `NumberFormat.currency` in `build` goes to `RigFormat.money`.
- `getPvcEntriesByVehicle` runs once per Save only.
- List strategy: plain `ListView(children)`; at most about 14 children.


## Reconciliation 2026-10-13 (Apple look, Android only)

Reconciles against `diesel_form_screen.md` "Reconciliation 2026-10-13" (the shared form reconciliation: header row, live card, pinned pill, states, guards). This is the reference for the three multi type forms (PVC, Bit, Hammer). Sources: `slForm`, `togType`, `slTot`, `slSave`.

### R1. Mockup screens and Flutter mapping

| Mockup screen (J label) | Render function | Flutter file | Widgets | Notes |
|---|---|---|---|---|
| Add PVC Entry | `F={date,types:['7 inch'],cnt,rate}` then `slForm({k:'pvc'})` | `lib/features/side_ledger/pvc/pvc_form_screen.dart` | full-height form route, live Total and Pending card (MoneyTile x2), RigGroup + RigFormRow, RigChipRow (multi select), per type RigGroup, UnsavedChangesGuard, RigSnack | the registry preselects `7 inch` with count 10 and rate 850 only to show the filled state; the real new form starts with no type selected |
| (edit, no registry label) | `editSl('pvc', i)` | same | same, title "Edit PVC Entry", button "Update Entry" | |

### R2. What changes in the redesign (supersedes section 4)

Layout (same header row, live card, caption style, pinned pill as the shared form):
1. Live card: "Total" (`accentText`) and "Pending" (`outstandingText`), caption under Total "Sum of count x rate for each type". Pending label rule: "Pending" when `pending > 0`, else "Balance (Advance)" with the absolute value (`moneyInText`), and a muted zero. The old rule "Pending tile only when pending > 0" is CHANGED so all four forms behave like diesel (display only; stored `balance = paid - total` is unchanged).
2. RigGroup: row "Date", RigFormRow "Bill number" (hint "Numbers only").
3. Caption "PVC type, select one or more" then a wrapping RigChipRow of `7 inch`, `8 inch`, `10 inch`, `MS` (multi select, inverse selected chip with `aria` selected state, 48 dp boxes, `FilterChip` semantics). No per type hue (the old blue, green, purple, orange tints are DROPPED).
4. For each selected type, in the fixed list order (not selection order), a caption with the type name and a RigGroup with two rows: "Count" (integer keyboard, digits only, placeholder 0) and "Rate per piece" (rupee prefix, decimal, placeholder 0). Footer text under the group (t13 `labelSecondary`): `<count> x <rate> = <line total>` using the same controllers. Count and rate belong to THAT type, and the live Total is the sum of the line totals; the form never shows an entry level rate or count field. Groups animate in with `AnimatedSize` 200 ms.
5. Caption "Payment", RigGroup row "Paid amount" (rupee prefix, decimal), then a RigGroup row "Paid date" (mockup shows it for PVC; see R3, proposed new item L2-r2-1: omitted until approved).
6. RigGroup row "Storage place" (hint "Where is it stored?", words capitalisation).
7. Caption "Notes", multiline row (3 lines).
8. Pinned "Save Entry" or "Update Entry" pill.

Old section 4 item by item: 4.1 Fields CHANGED (RigFormRow groups; Total and Pending in the live card; Paid date only with L2-r2-1); 4.2 Deselect safety KEPT (RigSnack "<type> removed" with Undo, 4 s); 4.3 Validation messages KEPT (inline plus snackbar copy identical); 4.4 Widths and desktop DROPPED; 4.5 State table CHANGED (Pending tile always shown, label rule above; unknown legacy type chip KEPT: an extra selected disabled chip with helper "Not an available type, remove it to save"); 4.6 Tokens CHANGED; 4.7 Motion CHANGED (200 ms, reduced motion).

States: default new (no type selected, no per type groups, Total ₹0), default edit (types from `typeDetails`, else `types`, else `type`), saving (Save disabled), error (inline under the offending row plus snackbar), dirty (discard alert), empty and loading not applicable.

### R3. Logic touchpoints and LR items

Untouched: `pvcTypes` strings, `_recalculate` (`count = int.tryParse ?? 0`, `rate = double.tryParse ?? 0`, `total += count * rate`, `pending = total - paid`), save validation order and messages ('Please enter a bill number', 'Please select at least one PVC type', 'Please enter count and rate for <type>' when `count <= 0 || rate <= 0`, 'Bill number "<n>" already exists'), save mapping (`type` first selected, `types`, `typeDetailsJson`, `count` = sum, `rate` = first rate, `total`, `paid`, `pending`, `balance = paid - total`, trimmed storage place, null notes), the load fallback chain, deselect clears both controllers, uniqueness check, picker range 2020 to now + 365 (clamped initial date, B-G1-02), 'Entry added' and 'Entry updated'.

LR dependencies: LR-25 approved (discard guard), LR-32 approved (double tap, Phase 1), LR-24 approved, LR-13 and LR-30 not involved (no feet). Proposed, new: L2-r2-1 (Paid date on the PVC form). Not scheduled: g1 L-02 (legacy types), L-09. 

### R4. Acceptance criteria delta

1. Types 7 inch (10 x 100) and 8 inch (5 x 200) give Total ₹2,000; Paid 500 gives Pending ₹1,500; Paid 2,500 gives "Balance (Advance)" ₹500; Paid 2,000 gives "Balance (Advance)" ₹0 muted.
2. Selecting a type adds its Count and Rate group in list order; deselecting removes it, the total drops and Undo restores the texts.
3. Each group footer reads `<count> x <rate> = <line total>` and the live Total is the sum of those footers.
4. No `Entry rate` or `Entry count` field exists; the saved entry has `count` = sum and `rate` = the first type's rate (unchanged).
5. With no type or a type with count or rate 0, nothing is saved and both the inline text and the snackbar show the existing messages.
6. Save is visible at 360 x 800 and above the keyboard; chips and rows are at least 48 dp; no overflow at text scale 130 and 200 percent with 4 types selected.
7. Back, close and Android back show the discard alert only when dirty; keyboard closes first.
8. A stored entry dated outside 2020 to now + 365 opens the picker without an assertion.

### R5. Parity delta

Intentional: P-PF-01 order (Total and Pending in the live card; Pending always visible); per type footer lines are new; Paid date for PVC only with L2-r2-1; sentence case labels; Rs. becomes the rupee sign. Identical: P-PF-02 to P-PF-07 (totals, deselect clears, messages, duplicate message, saved mapping, edit of a single type entry), P-PF-08 (no Delete).

### R6. Performance and Android notes

- Merge listenable over the selected types' count and rate controllers plus paid drives the live card and the footers; groups are keyed by type so typing in one does not rebuild the others. Controllers (up to 8 plus bill, paid, storage, notes) are owned and disposed by the State.
- `PopScope` via UnsavedChangesGuard; keyboard insets via `viewInsets.bottom`; bottom pill uses `viewPaddingOf`. No blur in scroll content. Targets: p90 build and raster under 8 ms.
