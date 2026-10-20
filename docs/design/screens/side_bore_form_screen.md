> SUPERSEDED IN PART (2026-10-13): the look is now the Apple-inspired Android direction. Read "Reconciliation 2026-10-13" at the end of this file first; where it conflicts with sections 4 to 7 above, it wins.
# side_bore_form_screen (side bore bill form)

File: `lib/features/ledger_form/side_bore_form_screen.dart` (809 lines). Shares `CommissionSection`, `AddressAutocompleteField` (see `ledger_form_screen.md`) and `PaymentLogEditor` (see `payment_log_editor.md`). Written as a delta against the main form doc: everything stated in `ledger_form_screen.md` sections 4.1, 4.5 (desktop) and 4.9 applies here unless this doc says otherwise.

## 1. Purpose and primary user task

Create or edit a bill for a side bore vehicle (isSideBoreProvider true): date, bill number, agent, city, depth (ft) and rate per ft, total (auto = depth x rate or manual), commission (depth only), payments (cash and PhonePe, with payer name), less, balance, notes. No step rate, PVC, MS pipe or extra charges. Opened from the Ledger tab FAB and bill cards when the current rig is a side bore (`main_navigation.dart:61`, `ledger_list.dart:258`). Primary task: "log a short bill and a PhonePe payment quickly".

## 2. Current structure

`Scaffold` > `AppBar` (gradient via `flexibleSpace` with hard-coded hex `0xFF252B49, 0xFF315D9A, 0xFF618DCE`, elevation 0, delete icon when editing) > `AdaptiveContent(700)` > `Form` > `ListView(16)`:

1. Date (same bordered Container as main form)
2. Bill Number (+ warning icon on duplicate, no banner here)
3. Agent (dropdown + add button)
4. Address (City) via `AddressAutocompleteField(hintText 'Enter city name', icon location_city)`
5. Depth Details: row [Depth (ft) | Rate/ft (Rs)], both with 'Required' validators
6. Total: tinted box with "Depth x Rate = Total" caption, big amount (24 sp), a lock toggle text button "Auto"/"Manual", and when manual a "Manual Total" field
7. `CommissionSection(showPvcAndMs: false)` (one rate field + commission result)
8. Payment: `PaymentLogEditor(allowPhonePe: true)`
9. Less (Rs)
10. Balance: tinted box, label and 20 sp amount (amber when > 0, green otherwise)
11. Notes (title above, hint only)
12. Save `ElevatedButton` (explicit colors, 16 padding)

State: `agentsProvider`, `uniqueAddressesProvider` (in autocomplete), `DatabaseService.getAllLedgerEntries()` (duplicate check), `ledgerEntriesProvider.notifier` add/update/delete, `agentsProvider.notifier.addAgent(name)` (no phone here). Listeners: depth, rate (`_recalculate`), less (`_updateBalance`), bill number. `_updateBalance` and `_recalculate` both call `setState` (double rebuild per keystroke).

## 3. Problems found

1. Header: gradient with literal hex (lines 391-399) while the main form uses a flat `AppColors.primary` AppBar (`ledger_form_screen.dart:526-530`): same task, two headers. The 3rd gradient stop #618DCE under white title text is 3.38:1.
2. Field labelling differs from the main form: Depth uses `labelText` + prefix icons (`Icons.straighten`), Rate has `Rate/ft (Rs)`, but Bill, Agent, Address, Notes are hint-only under a section title.
3. Total area (lines 580-653): the amount is a `Text` (24 sp, `primary` on 10 percent primary tint, about 6.0:1) and not a field; the lock `TextButton.icon` label shows the CURRENT state ("Manual"/"Auto") while the icon shows lock/lock_open, so it reads as a status, not an action (line 628-629). Toggling off calls `_recalculate()` inside a `setState` callback (lines 615-619), which nests `setState` calls.
4. Balance box (716-753): amber `AppColors.warning` #F59E0B text on its 10 percent tint is about 2.0:1 (fails); green `AppColors.success` #10B981 about 2.4:1 (fails); both use the same color for a zero and a negative balance (overpaid), so "Rs -500" shows green like "Rs 0". Format is `NumberFormat.currency(locale: 'en_IN')` (line 385) whereas the main form shows plain `#,##0.00` numbers.
5. Date picker range is 2020 to now + 365 days (lines 213-218) while the main form uses 2000 to 2100: an old bill (before 2020) or a bill dated more than a year ahead makes `initialDate` fall outside the range and `showDatePicker` asserts (see bugs_g1.md).
6. Same save/discard problems as main: Save at the bottom of about 2000 dp scroll (lines 770-787), no in-flight guard, no discard guard.
7. Commission on the side bore uses `_unusedRate` dummy controller (line 57) passed twice as the PVC and MS controllers: harmless but a smell that couples the form to the section's API.
8. Add agent dialog (lines 226-262): controller never disposed, no phone field (main has one), empty name closes silently with no feedback (an empty submit returns an empty string and nothing happens), `setState` after `await` without a mounted check (line 257).
9. Delete confirm identical to the main form's, same missing linked-payment note.
10. Layout: Depth and Rate side by side at 360 dp are about 148 dp wide each; the prefix icon (40 dp) leaves about 90 dp for the value: "1,250.5" fits but "Rate/ft (Rs)" label truncates at 130 percent text scale.
11. The `Text('Depth x Rate = Total')` caption uses `TextStyle` without `const` and 12 sp `textSecondary` (4.76:1, passes).
12. No numeric validators besides 'Required' on depth/rate; Less has none.
13. Keyboard: no `textInputAction`; Bill number is free text; Notes hint-only.

## 4. Redesign

Same shell as `ledger_form_screen.md` section 4.1 (RigAppBar flat `headerSurface`, RigScaffold, pinned `FormSaveBar` with Total and Balance, max width 640, sections via `RigSection`). Differences:

### 4.1 Sections (order preserved)

| # | Section | Compact (<600) | Medium | Expanded |
|---|---|---|---|---|
| 1 | Date | `RigDateField` `dateShort` | same | Date and Bill Number in two columns |
| 2 | Bill Number | `RigTextField` | same | |
| 3 | Agent | `RigDropdownField<Agent>` + 48 dp add button | same | Agent and City in two columns |
| 4 | Address (City) | `AddressAutocompleteField` as `RigTextField`, label "Address (City)", icon `Icons.location_city_rounded` | same | |
| 5 | Depth Details | one row [Depth (ft) | Rate/ft (Rs)] at compact with text scale up to 1.3; STACKED full width at compact when text scale > 1.3 | one row | one row (half width) |
| 6 | Total | `RigCard` tone container: caption "Depth x Rate = Total" `bodySmall`; `AmountText(amountLarge, neutral)` right-aligned value; a `RigSegmented` two-state switch "Auto | Manual" (replaces the lock toggle; selecting Manual reveals the `AmountField` "Manual Total" with `AnimatedSize`; selecting Auto runs the same recalc) | same | same |
| 7 | Commission | `CommissionSection` single-field variant: one full-width "Depth rate (Rs/ft)" field + helper line + Commission field + Auto | same | rate and result side by side |
| 8 | Payment | `PaymentLogEditor` with mode and payer | same | same |
| 9 | Less | `AmountField` "Less (Rs)" | same | half width |
| 10 | Balance | `AmountTile` in `RigCard`: label "Balance", value `amountLarge`; tone `outstanding` if > 0, `moneyIn` if exactly 0, `negative` if < 0 with a caption "Overpaid" (copy) | same | beside Less |
| 11 | Notes | `RigTextField` label "Notes (Optional)", multiline 3 | same | |
| 12 | Save | in `FormSaveBar` | same | same |

Date range for pickers: use the same `pickRigDate` as the main form. The first and last date are logic-adjacent (range limits); keep 2020 and now + 365 as the picker range BUT clamp `initialDate` into that range inside `pickRigDate` (UI helper, no data change). This resolves the assertion without changing which dates the user can pick. If the product wants the wider main-form range, see `logic_g1.md`.

### 4.2 Add agent dialog

`RigDialogShell` max 400; field Agent Name (autofocus, `words`); empty name shows inline error "Agent name is required" (copy reuse from the main form); controller owned by the dialog State. Keeps "no phone field" (field set unchanged).

### 4.3 Desktop

Max width 640, centered; `Cmd+S` saves; `Esc` closes with discard prompt when dirty; Tab order = visual order; pointer cursor on date and toggle; focus ring 2 px `primary`.

### 4.4 State table

| State | Rule |
|---|---|
| Default new | numeric fields "0" as today, Total Auto |
| Default edit | prefilled, manual total restored from `isTotalManuallyEdited` |
| Saving | Save disabled with spinner |
| Error | Required fields: inline 'Required' under Depth and Rate (existing validator text), bill, agent, address as main form |
| Disabled | Balance read-only |
| Manual total | segmented control on Manual, field visible, Balance recomputes live |
| Dirty | discard prompt |

### 4.5 Tokens, components

Spacing/type as main form. Components: `RigAppBar`, `RigScaffold`, `RigSection`, `RigCard`, `RigTextField`, `RigDropdownField`, `RigDateField`, `AmountField`, `AmountText`, `AmountTile`, `RigSegmented`, `RigDialogShell`, `ConfirmDialog`, `RigSnack`, `FormSaveBar`, `UnsavedChangesGuard`.

### 4.6 Motion

`AnimatedSize` 200 ms for the Manual Total field; 150 ms color cross-fade on the Balance tone; reduced motion honored.

## 5. Logic touchpoints that must stay untouched

- Validators (exact): Bill Number 'Bill number is required' / 'Bill number already exists' (`side_bore_form_screen.dart:464-472`); Agent 'Please select an agent' (501-506) and the snackbar copy in `_saveEntry` (267-272); Address 'Address is required' (autocomplete widget); Depth 'Required' when text empty (546-551); Rate 'Required' when text empty (568-573).
- Calculations: total = depth x rate when not manual (`_recalculate`, 161-171, `toStringAsFixed(2)`); balance = total - received - less (`_updateBalance`, 173-180, equals `LedgerEntry.calculateBalance`); `_cashReceived`, `_phonePeReceived`, `_totalReceived`; commission via `CommissionSection.calculate(showPvcAndMs: false)`; `_applyAgentCommissionDefaults` copies only `depthCommissionRate` (empty text when 0).
- Save mapping (283-321): stepRate 0, pvc/ms 0, `depth: '7inch'`, `pvc: '7inch'`, `msPipe: '6inch'`, `extraCharges: 0`, `phonePeName: lastPayer ?? widget.entry?.phonePeName` where `lastPayer` is the last non-cash payment with a non-empty payer, `received`, `receivedCash`, `receivedPhonePe`, `paymentsJson`, commission fields, `vehicleId`.
- Duplicate check identical to main (current vehicle, trimmed, case-insensitive, excludes self).
- Manual total semantic: `_isTotalManuallyEdited` toggled by the lock button; turning it off recalculates; `onChanged` of Manual Total calls `_updateBalance`.
- Provider calls: `ledgerEntriesProvider.notifier.addEntry/updateEntry/deleteEntry`, `agentsProvider.notifier.addAgent(result)`.
- Snackbar copy and pop order: "Entry added"/"Entry updated"/"Entry deleted"; save pops then snackbars, delete snackbars then pops (keep the order or unify to pop then snackbar, because `RigSnack` is shown on the root messenger either way; unify is allowed since it is not a navigation outcome change).
- Controller/flag names and `_unusedRate` coupling may be refactored, but `CommissionSection.calculate` signature may not.

## 6. Acceptance criteria

1. Field order, labels and copy match the table in section 2 (parity P-SB-01..30).
2. Depth 100, Rate 50 shows Total 5,000.00 in Auto; switching to Manual lets the user type a different total and Balance follows; switching back to Auto restores 5,000.00.
3. Balance = Total - cash - PhonePe - Less to 2 decimals in every combination; sign colors: positive outstanding, zero moneyIn, negative negative with "Overpaid".
4. Save is visible without scrolling at 360 x 800 and above the keyboard.
5. PhonePe payments require nothing extra; the payer name appears in the payer suggestion list on the next payment.
6. Old bill dated before 2020 opens the date picker without an assertion and keeps its date if the user cancels.
7. Add agent with an empty name shows an inline error; with a name selects the new agent and copies its default depth commission rate (new bills only).
8. Double tap on Save creates one bill.
9. Delete confirm and result identical to the main form.
10. No literal hex or `Colors.x`; header identical to the main form header.
11. 200 percent text scale: no overflow in Depth row, Total card and Commission block.
12. macOS: width 640, `Cmd+S`, `Esc` behavior as main form.

## 7. Performance notes

- Two `setState` calls per keystroke (`_recalculate` then `_updateBalance`): replace with `ValueListenableBuilder`s on `_totalController` and `_balanceController`; keep a single `setState` only for the manual flags.
- `NumberFormat.currency(locale: 'en_IN', ...)` is created in `build` (line 385): hoist to `RigFormat.money`.
- `ref.watch(agentsProvider)` in `build` rebuilds the whole form; scope it to the Agent field widget.
- `_checkBillNumberDuplicate` scans the box per keystroke; debounce 250 ms in the widget layer.
- Dispose: 8 controllers disposed; the add-agent dialog controller is not (fix by owning it in the dialog State). `_unusedRate` is disposed.
- List strategy: about 12 children, plain `ListView(children)` is fine.


## Reconciliation 2026-10-13 (Apple look, Android only)

Mockup source: `SC.sideBoreForm`, `liveCard`, `commissionBox(true)`, `payLog(true)`, `payDlg(true)`, `addAgentDlg(true)` in `docs/design/mockup/rigledger_apple_mockup.html`. This is a delta against the main form: everything in `ledger_form_screen.md` "Reconciliation 2026-10-13" R2 (sheet shell, live total card, RigGroup and RigFormRow, pinned pill, discard prompt, states) applies here unless stated below. Dropped from sections 1 to 7: macOS, expanded and medium columns, Cmd+S, Esc, hover, gradient header with literal hex, `FormSaveBar`.

### R1. Mockup screens and Flutter mapping

| Mockup screen (J label) | Render function | Flutter file | Widgets | Notes |
|---|---|---|---|---|
| Side Bore - New Entry | `SC.sideBoreForm` (new) | `lib/features/ledger_form/side_bore_form_screen.dart` | form sheet scaffold, UnsavedChangesGuard, live total card (RigCard + MoneyTile x2), RigGroup, RigFormRow, RigSegmented (Auto, Manual), CommissionSection (single rate), PaymentLogEditor (`allowPhonePe: true`), RigButton (pill), RigAlertDialog | title "New Entry" |
| Side Bore - Edit Entry | `SC.sideBoreForm` (edit) | same | same plus Delete icon button | title "Edit Entry", pill "Update Entry" |
| Add payment dialog | `payDlg(true)` | `widgets/payment_log_editor.dart` | RigSheet with Mode and Payer name | see payment_log_editor.md |
| Add agent dialog (form) | `addAgentDlg(true)` | `side_bore_form_screen.dart` | RigSheet, one RigFormRow (Name), RigButton | no phone field here (unchanged field set) |
| Delete entry dialog | `delBillDlg` | same | RigAlertDialog | same text as the main form |

### R2. What changes in the redesign (supersedes section 4)

Same shell as the main form R2 items "Screen shell", "Rows", "Discard prompt", "Delete alert" and the pinned pill. Differences in the body (order and labels preserved):
1. Live total card: Total (`accentText`) and Balance (`outstandingText` above zero, `moneyInText` at zero, `moneyOutText` below zero with a 13 dp "Overpaid" caption, copy only).
2. RigGroup: Date row and Bill Number row (hint "Required"). RigGroup: Agent, "Add new agent", Address (City) via `AddressAutocompleteField` (hint "Enter city name", icon `location_city`). Location suggestions from earlier bills of this rig work as in the main form.
3. "Depth": RigGroup of Depth (ft) and Rate per ft (₹ prefix), both with the existing "Required" validator text.
4. "Total" (REPLACES the lock toggle of 4.1 row 6): RigGroup with a read-only row "Depth x rate" (value `MoneyText`), a row "Total mode" whose value is a `RigSegmented` "Auto | Manual" (max 200 dp wide, 48 dp high; selecting Manual reveals a "Manual total" row, ₹ prefix, with `AnimatedSize` 200 ms; selecting Auto runs the existing recalculation and clears the manual value).
5. "Commission": depth only (one rate row "Depth rate per ft" with helper "N ft = ₹X", then the Commission row with Auto) and the footer "Commission is not added to the bill total.".
6. "Payments": `PaymentLogEditor(allowPhonePe: true)` then the footer "Total received". Payment sheet shows Mode (Cash, PhonePe) and, for PhonePe, Payer name.
7. RigGroup: Less (₹ prefix) and read-only Balance row.
8. "Notes": one multi-line row, hint "Optional notes". Pinned pill "Save Entry" or "Update Entry".
No PVC, MS pipe, step rate, extra charges, depth type or calculation preview card on this form (existing rule).

Date picker: range stays 2020 to now + 365 (logic-adjacent) and `initialDate` is clamped into the range inside the shared `pickRigDate` helper so an older bill cannot assert (UI only); the cell and sheet look follows DatePickerSheet when the shared helper is built, with the same range per form.

States: as the main form table, plus "Manual total": the segmented control shows Manual, the Manual total row is visible and Balance recomputes live; "Error: required": Depth and Rate show the existing text "Required" in `moneyOutText`; the Agent and Address messages are as in the main form; duplicate bill note as in the main form.

Old section 4 mapping: 4.1 table CHANGED (grouped rows, Medium and Expanded columns DROPPED); 4.2 add agent CHANGED (sheet; empty name keeps the sheet open with "Agent name is required"); 4.3 desktop DROPPED; 4.4 states CHANGED; 4.5 tokens and components CHANGED (see main form R2); 4.6 motion KEPT (`AnimatedSize` 200 ms, Balance tone cross-fade 150 ms, instant under reduced motion).

### R3. Logic touchpoints and LR items

Untouched: section 5 above (validator strings, total = depth x rate with `toStringAsFixed(2)`, balance formula, received sums, commission rule with `CommissionSection.calculate(showPvcAndMs: false)`, save mapping, duplicate check, manual total semantics, provider calls, snackbar copy and pop order).

| Item | Status |
|---|---|
| LR-25 discard prompt | approved |
| LR-32 `_saving` guard | approved, Phase 1 |
| LR-13, LR-30 feet | display rule decided, input limit proposed (Q-O5) |
| LR-24 rupee sign (`NumberFormat.currency(locale: 'en_IN')` replaced by `RigFormat.money`) | approved |
| Date range 2020 to now + 365 versus main form 2000 to 2100 | unchanged; changing it is logic (L-03 in logic_g1.md), not requested |
| Proposed, new | none |

### R4. Acceptance criteria delta

REPLACES 6 items 4, 10, 11, 12; ADDS the rest. 360 and 412 dp, light and dark, text scale 100, 130, 200 percent, keyboard open.
1. The pinned pill and the live total card are visible on open at 360 x 800; with the keyboard open the pill stays above it.
2. Depth 100, Rate 50: the "Depth x rate" row and Total show ₹5,000 in Auto; Manual lets the user type another total and Balance follows live; back to Auto restores ₹5,000 and clears the manual value.
3. Balance = Total - cash - PhonePe - Less to 2 decimals; tones: positive `outstandingText`, zero `moneyInText`, negative `moneyOutText` with "Overpaid".
4. Add agent with an empty name keeps the sheet open with the inline message; with a name it selects the agent and copies only the depth commission rate.
5. An entry dated before 2020 opens the date picker without an error; cancelling keeps the date.
6. Discard prompt, Save guard, Delete alert and keyboard behaviour are identical to the main form (main form R4 items 5 to 8).
7. At 200 percent text the Depth rows, the Total group and the Commission rows wrap without overflow.
8. No PVC, MS pipe, step or extra row is present.
9. No raw colour, no `Rs` string; amounts through `RigFormat`.

### R5. Parity delta

Changed on purpose: P-SB-08 (Balance tones now `outstandingText`, `moneyInText`, `moneyOutText` plus "Overpaid"), P-SB-11 (empty agent name shows an inline message, kept), P-SB-14 to P-SB-30 where they repeat the main form changes (discard prompt, pill, feet rule, macOS lines DROPPED), the Auto and Manual control (segmented instead of a lock text button), "Rs" becomes the rupee sign.
Identical: P-SB-01 (order and labels), P-SB-02 to P-SB-07, P-SB-09, P-SB-10, P-SB-12, P-SB-13.

### R6. Performance and Android notes

- Two `setState` calls per keystroke become `ValueListenableBuilder`s on the total and balance controllers; one `setState` stays for the manual flag.
- Hoist money formatting to `RigFormat`; scope `agentsProvider` to the Agent row; debounce the duplicate scan 250 ms in the widget layer before the existing call.
- Insets, keyboard, PopScope and controller disposal as the main form R6 (8 controllers plus `_unusedRate`; the add-agent sheet owns its controller).
- List strategy: about 12 children, plain `ListView(children)`; no blur in scrolling content.
