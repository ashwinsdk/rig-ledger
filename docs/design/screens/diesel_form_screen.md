> SUPERSEDED IN PART (2026-10-13): the look is now the Apple-inspired Android direction. Read "Reconciliation 2026-10-13" at the end of this file first; where it conflicts with sections 4 to 7 above, it wins.

# diesel_form_screen (Add/Edit Diesel Entry)

File: `lib/features/side_ledger/diesel/diesel_form_screen.dart` (462 lines). Same form shell as `pvc_form_screen.md`, `bit_form_screen.md`, `hammer_form_screen.md`; the shell rules (4.1, 4.2, 4.6) defined here apply to all four.

## 1. Purpose and primary user task

Record or edit one diesel bill: date, bill number, litres, rate per litre, paid amount, paid date, bunk details, notes. Total, Pending/Balance are computed live. The primary task is "type bill number, litres, rate and what was paid, see Total and Pending, save". There is NO delete action in this form (delete lives in the list). Opened from the Diesel list (card tap = edit, FAB = new) and from the Add Entry choice sheet (`main_navigation.dart:172`, `desktop_shell.dart:292`).

## 2. Current structure

`Scaffold` > `AppBar` (gradient via `flexibleSpace` with literal hex, white foreground, no leading customization) > `AdaptiveContent(700)` > `Form` > `ListView(16)`:

1. Date: `Card > ListTile` (calendar icon orange, title "Date", subtitle `dd/MM/yyyy`)
2. Bill Number `*`: outlined, `TextInputType.number`, `digitsOnly`, hint "Enter bill number (numeric only)"
3. Row [Litres `*` | Rate/L `*`] decimal fields, outlined, icons
4. Total Amount box (read-only, green tint, 20 sp green)
5. Paid Amount (decimal, default "0")
6. Pending/Balance box: label "Pending" (red) or "Balance (Advance)" (blue)
7. Paid Date (Optional) `Card > ListTile` with a clear (x) trailing button when set
8. Bunk Details (text, outlined)
9. Notes (3 lines, outlined)
10. Save `ElevatedButton` (orange, 16 padding)

State: `dieselEntriesProvider.notifier.addEntry/updateEntry` (lines 176-180); `DatabaseService.currentVehicleId` and `DatabaseService.getDieselEntriesByVehicle(vehicleId)` (called directly in `_isBillNumberUnique`, lines 125-139). Local: 6 controllers, `_selectedDate`, `_paidDate`, `_total`, `_pending`, `_balance`. Three listeners (litre, rate, paid) call `setState` each keystroke.

## 3. Problems found

1. Header: literal gradient hex (lines 199-207) vs the main form's flat app bar; same screen type, different header; inconsistent with the list header (`AppColors.appBarGradient`).
2. Save is at the bottom of a column of about 10 blocks (about 900 dp): on a 360 x 800 phone the user scrolls to Save; with the keyboard open the Save button is under the keyboard (no sticky bar). Total and Pending are scrolled off while typing litres and rate.
3. Date and Paid Date use `Card > ListTile` while the main bill forms use a bordered `Container` + `InkWell` (inconsistent date pattern), format `dd/MM/yyyy`.
4. Required fields use `labelText: '... *'` and `hintText` with the same idea ("Enter bill number (numeric only)") instead of a helper; the asterisk convention is not used in the bill forms.
5. Bill number validation is two-stage: the `validator` only checks empty (line 241-246) and uniqueness is checked after Save in `_saveEntry` and reported as a red snackbar (lines 145-153): the user sees the problem only after tapping Save, and the snackbar can be hidden behind the keyboard.
6. Litres and Rate validators accept "0" and "0.0" (only empty and unparsable are rejected): a 0-litre entry saves with Total 0.
7. Total box and Pending box use `Colors.green`, `Colors.red`, `Colors.blue` (lines 314-316, 333, 362-369, 388): green #4CAF50 on its tint 2.7:1, red #F44336 3.6:1, blue #2196F3 3.0:1 (all fail 4.5 for 18-20 sp bold only 3:1 large text, borderline for the 18 sp one).
8. The Pending box swaps label and meaning with sign: "Pending" when `_pending > 0`, "Balance (Advance)" otherwise, so exactly paid shows "Balance (Advance) Rs 0.00" (line 376). The value uses `_balance.abs()`.
9. Paid Date clear button has no tooltip and is a default 48 dp `IconButton` inside a `ListTile` trailing: OK on size, missing semantics.
10. All `InputDecoration`s set `border: OutlineInputBorder()` locally (about 9 times) while the theme default is used in the bill forms: inconsistent field style.
11. Save has no in-flight guard: a double tap adds two entries with different UUIDs (line 157 creates the id per call).
12. No discard guard on back.
13. `NumberFormat.currency` is created inside `build` (line 194).
14. Date picker range 2020 to now + 365 (lines 101-105, 113-117): editing an entry dated outside the range asserts.
15. Keyboard: `TextInputAction` unset, so Next skips unpredictably; Litres and Rate in a row at 148 dp each leave about 80 dp for the number with icon and outline border (prefix icon 40 dp + padding), which clips "1,250.55" at 130 percent text scale.
16. Alignment: amounts in boxes are right aligned (spaceBetween) but not tabular; inputs are left aligned.

## 4. Redesign

### 4.1 Shell (all four side ledger forms)

`RigScaffold(appBar: RigAppBar(title: isEditing ? 'Edit Diesel Entry' : 'Add Diesel Entry', leading: back))`; body a single `ListView` max width 640 centered (medium and expanded), horizontal padding `s4`/`s6`/`s8`; pinned `FormSaveBar` at the bottom: left a two-line live summary (Total `amountMedium`, Pending `amountMedium` tone), right the filled primary button "Save Entry"/"Update Entry" (48 dp min, `md` radius). The category identity color is used only on the leading icon tile of the header block, never on buttons (primary for actions, DESIGN_SYSTEM rule 3).

### 4.2 Fields (order preserved)

| # | Field | Component | Keyboard / action | Notes |
|---|---|---|---|---|
| 1 | Date | `RigDateField` label "Date", `dateShort`, leading `Icons.calendar_today_rounded` | n/a | opens themed `pickRigDate` |
| 2 | Bill Number * | `RigTextField` label "Bill Number", helper "Numbers only", leading `Icons.receipt_long_rounded` | `TextInputType.number`, `digitsOnly`, `next` | inline error 'Please enter a bill number' |
| 3 | Litres * / Rate/L * | two `AmountField`s in one row at >= 360 dp and text scale <= 1.3, else stacked | decimal, `next` | validators 'Required' / 'Invalid' |
| 4 | Total Amount | `AmountTile` (read-only), `amountLarge` neutral, caption "Litres x Rate" | none | recalculated live |
| 5 | Paid Amount | `AmountField`, default "0" | decimal, `next` | no validator |
| 6 | Pending / Balance | `AmountTile` tone `outstanding` for Pending, `moneyIn` for Balance (Advance) and a muted tone for exactly 0 | none | label text per existing rule |
| 7 | Paid Date (Optional) | `RigDateField` with a clear suffix `Icons.close_rounded` (tooltip "Clear paid date"), placeholder "Not set" | n/a | |
| 8 | Bunk Details | `RigTextField`, `TextCapitalization.words`, `next` | text | |
| 9 | Notes | `RigTextField` multiline min 3 max 6, `sentences`, action `newline` | | |

Compact: single column. Medium: Date and Bill Number side by side; Litres and Rate side by side; Total and Pending side by side (tiles); everything else full width. Expanded: same as medium (max width 640).

### 4.3 Validation timing

`AutovalidateMode.onUserInteraction` after the first Save attempt (DS 12). Bill-number uniqueness remains a Save-time check, but its message is shown inline under the Bill Number field (error text) in addition to the existing snackbar (RigSnack, error). The text is unchanged: 'Bill number "<n>" already exists'.

### 4.4 State table

| State | Rule |
|---|---|
| Default new | Date today, Paid "0", Total and Pending Rs 0.00 |
| Default edit | all fields prefilled, Paid Date shown if set |
| Saving | Save disabled with 20 dp spinner |
| Error | inline required/invalid; uniqueness error under Bill Number |
| Pending > 0 | tile label "Pending", `outstanding` |
| Pending <= 0 and Balance > 0 | label "Balance (Advance)", `moneyIn` |
| Exactly paid (pending = 0) | keep the existing text rule: label "Balance (Advance)", value Rs 0.00, styled `textMuted` (copy parity) |
| Dirty | back/Esc discard prompt |

### 4.5 Desktop

Max width 640 centered, `Cmd+S` saves, `Esc` closes (discard prompt if dirty), Tab order = visual order, focus ring 2 px, pointer cursor on date fields.

### 4.6 Motion

`AnimatedSwitcher` 150 ms on the Pending/Balance tile label and tone; `AnimatedSize` 200 ms none else; honors reduced motion.

### 4.7 Tokens and components

Spacing `s4` between fields, `s3` pair gap, `s6` before notes; radius `md` fields, `lg` tiles; type `bodyLarge` input, `labelMedium` labels, `amountLarge` tile values; color `surface`, `surfaceContainer`, `outstanding`, `moneyIn`, `negative`, `categoryDiesel`. Components: `RigAppBar`, `RigScaffold`, `RigDateField`, `RigTextField`, `AmountField`, `AmountTile`, `FormSaveBar`, `RigSnack`, `UnsavedChangesGuard`.

## 5. Logic touchpoints that must stay untouched

- Validators (exact): Bill Number empty returns 'Please enter a bill number'; Litres and Rate empty return 'Required', non-parsable return 'Invalid' (`double.tryParse(value) == null`); Paid has none. `FilteringTextInputFormatter.digitsOnly` on Bill Number; `RegExp(r'^\d*\.?\d*')` on decimals.
- `_recalculate`: `_total = litre * rate`; `_pending = _total - paid`; `_balance = paid - _total` (no rounding).
- `_isBillNumberUnique`: exact string equality (case-sensitive), same vehicle, ignores the entry being edited; checked only in `_saveEntry` after validation, snackbar 'Bill number "<n>" already exists' and abort.
- Save mapping (lines 156-174): `id` reuses the edited id else a new UUID v4; `vehicleId = DatabaseService.currentVehicleId`; `bunkDetails` trimmed; `notes` null when empty; `createdAt` preserved on edit; `updatedAt = now`; `paidDate` nullable.
- `addEntry` / `updateEntry` calls; pop then snackbar 'Entry added' / 'Entry updated'.
- Pending box rule: label 'Pending' when `_pending > 0`, else 'Balance (Advance)' with `_balance.abs()`.
- Date pickers: `firstDate` 2020, `lastDate` now + 365 (range). A UI helper may clamp `initialDate` into the range but must not widen the range.

## 6. Acceptance criteria

1. Litres 100 x Rate 90 shows Total Rs 9,000.00; Paid 4,000 shows Pending Rs 5,000.00; Paid 9,500 shows "Balance (Advance)" Rs 500.00.
2. Empty Bill Number, Litres or Rate blocks Save with the same messages; letters cannot be typed into Bill Number.
3. A duplicate bill number (same rig) blocks Save and shows the uniqueness message under the field.
4. Save is visible at 360 x 800 without scrolling and stays above the keyboard.
5. Total and Pending are visible in the bar while typing any field.
6. Paid Date can be set and cleared; cleared date saves as null.
7. Double tap on Save creates one entry.
8. Edit loads every stored value and Save updates the same entry id.
9. Back with edits asks to discard; without edits closes immediately.
10. No overflow at 200 percent text scale; every tap target at least 48 dp.
11. All colors through tokens; no hex, no `Colors.x`.
12. macOS: width 640, `Cmd+S`, `Esc`.

## 7. Performance notes

- 3 listeners call `setState` per keystroke over a 10-block `ListView`; replace with `ValueListenableBuilder` on the three controllers feeding a small `_DieselTotals` widget and the `FormSaveBar`, leaving fields untouched.
- `NumberFormat.currency` inside `build` becomes `RigFormat.money` (static).
- `_isBillNumberUnique` scans `getDieselEntriesByVehicle` once per Save (not per keystroke): fine.
- All 6 controllers are disposed; listeners are removed implicitly with disposal (no cross-widget leak).
- Plain `ListView(children)` is acceptable (about 10 children).


## Reconciliation 2026-10-13 (Apple look, Android only)

This section is the form reference for all four side ledger forms. `pvc_form_screen.md`, `bit_form_screen.md` and `hammer_form_screen.md` reconcile against it. Sources: `slForm`, `slTot`, `slSave`, `fscr`, `fld`, `ftl`, `grp`, `live`, registry group "Side ledger".

### R1. Mockup screens and Flutter mapping

| Mockup screen (J label) | Render function | Flutter file | Widgets | Notes |
|---|---|---|---|---|
| Add Diesel Entry | `newSl('diesel')` then `slForm({k:'diesel'})` | `lib/features/side_ledger/diesel/diesel_form_screen.dart` | full-height form route (close button, inline title, pinned bottom RigButton), live Total and Pending card (MoneyTile x2), RigGroup + RigFormRow, section captions, UnsavedChangesGuard, RigSnack, DatePickerSheet or `pickRigDate` | the edit case is `editSl('diesel', i)` (no registry label, title "Edit Diesel Entry", button "Update Entry") |

### R2. What changes in the redesign (supersedes section 4)

Layout top to bottom, 412 dp and 360 dp, flat `canvas` (the mockup uses a sheet-like full screen, `fscr`):
1. Header row 56 dp: close button (`close`, 48 dp, tooltip "Close") at the left, inline title 17 600 centred ("Add Diesel Entry" or "Edit Diesel Entry"), empty 48 dp slot at the right (the form has no Delete). Close runs the same path as Android back (UnsavedChangesGuard, see R3).
2. Live card (`live`): margin 20, gap 12, padding 16, radius 20, `surface1`, two equal columns. "Total" (t12 `labelSecondary`, value t22 700 `accentText`) and "Pending" (t12, value t22 700 `outstandingText`). Values use the MoneyTile fit pipeline (compact allowed here because it is a highlight tile; tap shows the full value) and update every keystroke. Under Total a t12 caption "Litres x rate per litre".
3. RigGroup: row "Date" (label left, value `d MMM yyyy` right, calendar icon 18 dp `labelSecondary`, tap opens the picker), RigFormRow "Bill number" (hint "Numbers only", `TextInputType.number`, digits only, action next).
4. Caption "FUEL" (13 sp uppercase, `labelSecondary`, 20 + 16 dp inset) then RigGroup: "Litres" (decimal, numeric keyboard, right aligned input), "Rate per litre" (rupee sign prefix, decimal).
5. Caption "PAYMENT" then RigGroup: "Paid amount" (rupee prefix, decimal, default empty shows as 0). Then a RigGroup with one row "Paid date" (value "Not set" in `labelSecondary`; a clear button 48 dp "Clear paid date" shown only when set).
6. RigGroup "Bunk details" (hint "Name or location", words capitalisation).
7. Caption "NOTES" then RigGroup with a multiline row (3 lines, hint "Optional notes", sentences, action newline).
8. Pinned bottom area: RigButton filled pill 50 dp "Save Entry" or "Update Entry", `accentButton` fill with `onAccent` label, margin 20 sides, bottom = `viewPaddingOf.bottom + 12`, a gradient fade from `canvas` behind it. The body bottom padding is 130 dp so the last row clears the button. With the keyboard open the bar moves above it and the system inset is 0.
9. Each form row is 48 dp minimum with a visible focus ring (accent, 2 dp) and an inline error line (t12 `moneyOutText`) under the group.

Field label copy follows the mockup casing (RigFormRow labels): Date, Bill number, Litres, Rate per litre, Paid amount, Paid date, Bunk details, Notes. Validation messages, snackbars and the stored fields are unchanged.

States:

| State | Rule |
|---|---|
| Default new | Date today, empty fields, live card shows Total ₹0 and Pending ₹0 |
| Default edit | all fields prefilled, Paid date shown when set |
| Loading | none (synchronous) |
| Empty | not applicable |
| Error | inline text under the row: 'Please enter a bill number', 'Required', 'Invalid'; duplicate bill message under Bill number and as RigSnack |
| Saving | Save disabled for the duration of the call (LR-32 guard), ink spinner 20 dp |
| Pending > 0 | label "Pending", `outstandingText` |
| Pending < 0 | label "Balance (Advance)", absolute value, `moneyInText` |
| Pending = 0 | label "Balance (Advance)", value ₹0 in `labelSecondary` (copy parity) |
| Dirty | close, Android back and the system gesture show the discard alert |

Old section 4 item by item:
- 4.1 Shell: CHANGED (`FormSaveBar` with live summary DROPPED; the live card sits at the top of the scroll body as in the mockup; pinned bottom pill kept). 640 max width and padding tiers DROPPED.
- 4.2 Fields: CHANGED to RigFormRow groups (labels, order below). Order is Date, Bill number, Litres, Rate per litre, Paid amount, Paid date, Bunk details, Notes; Total and Pending are in the live card above instead of between Rate and Paid (P-DF-01 delta).
- 4.3 Validation timing: KEPT (after first Save attempt, `onUserInteraction`); uniqueness message under Bill number plus RigSnack.
- 4.4 State table: CHANGED (above).
- 4.5 Desktop (Cmd+S, Esc, focus ring pointer cursor): DROPPED.
- 4.6 Motion: CHANGED to 200 ms on the Pending label and tone, press ink, reduced motion honoured.
- 4.7 Tokens: CHANGED (names above).

Date and Paid date use `pickRigDate` (system picker themed to the Apple look, or DatePickerSheet B2 if the lead reuses it): range stays 2020 to now + 365, `initialDate` clamped into the range (B-G1-02).

### R3. Logic touchpoints and LR items

Untouched: validators ('Please enter a bill number', 'Required', 'Invalid', `digitsOnly` on Bill number, `^\d*\.?\d*` on decimals), `_recalculate` (`total = litres x rate`, `pending = total - paid`, `balance = paid - total`, no rounding), `_isBillNumberUnique` (exact, case-sensitive, same rig, ignores self), save mapping (id reuse else UUID v4, `vehicleId = currentVehicleId`, trimmed bunk, null notes when empty, `createdAt` kept, `updatedAt = now`), `addEntry`/`updateEntry`, pop then snackbar 'Entry added' or 'Entry updated', picker range 2020 to now + 365.

LR dependencies:
- LR-25 approved: UnsavedChangesGuard (`PopScope(canPop: !dirty)`), dirty = any controller or date differs from its initial value; the close button uses the same path.
- LR-32 approved (Phase 1): `_saving` flag, one entry per double tap.
- LR-24 approved: rupee sign, no `Rs.`.
- g1 L-04 (block Apply on start after end) and L-03 (widen pickers) remain unscheduled.
- No new logic required (see `temp/design_wip/logic2_r2.md`).

### R4. Acceptance criteria delta

1. Litres 100 and rate 90 show Total ₹9,000 in the live card; Paid 4,000 shows Pending ₹5,000; Paid 9,500 shows "Balance (Advance)" ₹500; Paid 9,000 shows "Balance (Advance)" ₹0 in the secondary colour.
2. Save is the pinned pill, visible at 360 x 800 without scrolling, above the keyboard when it is open; the last row is not covered (130 dp body padding).
3. The live card is the first item and updates on every keystroke without rebuilding the rows; total and pending are not visible while editing Notes unless the sticky variant is approved (conflict C-r2-1).
4. Back and the close button on a form with edits show the discard alert; on a pristine form they close at once; Android back with the keyboard open closes the keyboard first.
5. Double tap on Save adds one entry (LR-32).
6. Paid date can be set and cleared; a cleared date saves as null.
7. At text scale 130 and 200 percent no row overflows; the live card values scale down (never below 75 percent before the 11 px guard) and stay on one line or wrap to their own line.
8. Every tap target is at least 48 dp; light and dark pass 4.5 : 1 for text.
9. A stored entry dated outside 2020 to now + 365 opens its date picker without an assertion.

### R5. Parity delta

Intentional: P-DF-01 field order (Total and Pending move to the live card; Paid date stays after Paid amount); P-DF-09 and P-DF-10 are now satisfied (discard prompt, pinned Save); labels are sentence case (Bill number, Rate per litre and so on); Rs. becomes the rupee sign. Must stay identical: P-DF-02 to P-DF-08 and P-DF-11 (no Delete in the form), the duplicate message text, 'Entry added' and 'Entry updated'.

### R6. Performance and Android notes

- Edge to edge; `viewPaddingOf` for the pinned button; the form is a `CustomScrollView` or `ListView` with bottom padding for the button plus keyboard (`viewInsets.bottom`); a focused field scrolls into view.
- `PopScope` through UnsavedChangesGuard; controllers (bill, litres, rate, paid, bunk, notes) are owned and disposed by the State.
- Three listeners drive a `ListenableBuilder` that rebuilds only the live card; fields are not rebuilt per keystroke. `NumberFormat` moves to `RigFormat` statics.
- No blur and no gradient inside the scroll area; the fade behind the button is a static `DecoratedBox`. Targets: p90 build and raster under 8 ms, p99 under 16 ms.
