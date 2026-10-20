> SUPERSEDED IN PART (2026-10-13): the look is now the Apple-inspired Android direction. Read "Reconciliation 2026-10-13" at the end of this file first; where it conflicts with sections 4 to 7 above, it wins.
# ledger_form_screen (main bore bill form)

Files covered by this doc: `lib/features/ledger_form/ledger_form_screen.dart` (1177 lines), `widgets/commission_section.dart` (159), `widgets/address_autocomplete_field.dart` (93). The Payment block (`widgets/payment_log_editor.dart`) has its own doc: `payment_log_editor.md`. The side bore variant is `side_bore_form_screen.md`.

Status: specification only. No code changed. Tokens and components are from DESIGN_SYSTEM.md and COMPONENTS.md.

## 1. Purpose and primary user task

Create or edit one drilling bill (`LedgerEntry`) for a main bore rig: date, bill number, agent, address, depth/PVC/MS pipe quantities and rates, step rate, extra charges, total, commission, payments received, less, balance, notes. Edit mode adds Delete. The primary task is "enter a bill fast in the field, one-handed, and see the Total and Balance before saving". Reached from the Ledger tab FAB (`main_navigation.dart:61`, `desktop_shell.dart:260`) and from a bill card tap (`ledger_list.dart:258`). Returns to the ledger with a snackbar.

## 2. Current structure

Widget tree (`build`, lines 520-1071):
`Scaffold(backgroundColor: AppColors.background)` > `AppBar` (flat `AppColors.primary`, foreground white, title "New Entry"/"Edit Entry", delete IconButton only when editing) > `AdaptiveContent(maxWidth: 700)` (centers only when `PlatformHelper.isDesktop`) > `Form(_formKey)` > one `ListView(padding: 16)` with, in order:

1. Date (section title + bordered tappable Container, `_selectDate`)
2. Bill Number (`TextFormField`, text keyboard, duplicate warning icon + orange banner)
3. Agent (`DropdownButtonFormField<Agent>` + add-agent IconButton)
4. Address (City) (`AddressAutocompleteField`)
5. Depth Details: row [Depth Type dropdown 7inch/8inch | Depth (feet)], row [Rate per feet | Step Rate with edit marker and refresh]
6. PVC Details: row [PVC Type dropdown | PVC (feet)], PVC Rate per feet
7. MS Pipe Details: row [MS Pipe Type dropdown (only 6inch) | MS Pipe (feet)], MS Pipe Rate per feet
8. Extra Charges
9. Calculation Preview (`_buildCalculationPreview`, teal-tinted box)
10. Total (field with "Manually edited" marker and Auto text button)
11. `CommissionSection` (3 rate fields in one Row + Commission field with Auto)
12. Payment title + `PaymentLogEditor` (cash only, `allowPhonePe: false`)
13. Less (Discounts/Deductions)
14. Balance (read-only field, primary color text)
15. Notes (3 lines)
16. Save button (`SizedBox(height: 50)` + `ElevatedButton`), 32 px bottom space

State sources:
- Reads: `agentsProvider` (build, line 521; initState post-frame lookup for the edit agent), `uniqueAddressesProvider` (inside `AddressAutocompleteField.optionsBuilder`), `DatabaseService.getAllLedgerEntries()` directly for the duplicate bill check (line 241), `DatabaseService.currentVehicleId` on save (line 458).
- Writes: `ledgerEntriesProvider.notifier.addEntry/updateEntry/deleteEntry` (lines 462-505), `agentsProvider.notifier.addAgent` (line 393).
- Local state: 17 `TextEditingController`s, `_date`, `_depth`, `_pvc`, `_msPipe`, `_selectedAgent`, `_payments`, `_baseCash`, flags `_isStepRateManuallyEdited`, `_isTotalManuallyEdited`, `_isCommissionManuallyEdited`, `_isBillNumberDuplicate`.
- Calculations (must not change): `LedgerEntry.calculateStepRate`, `calculateTotal`, `calculateBalance`, `calculateCommission` (via `CommissionSection.calculate`), `LedgerPayment.totalCash`.
- 10 text listeners call `setState` on every keystroke (lines 178-187), so the whole 1000+ line tree rebuilds per character.

`CommissionSection`: stateless; container (12 padding, accent 5 percent fill), header row ("Commission", "not added to total"), a `Row` of 1 to 3 `Expanded` rate fields (each with helper text "N ft = Rs X"), then Commission field + Auto button.

`AddressAutocompleteField`: `RawAutocomplete<String>` over `uniqueAddressesProvider`, options list max 200 high and 520 wide, owns a `FocusNode`.

## 3. Problems found

Visual hierarchy and density
1. Single 16-section column of about 2400 dp on a 360 x 800 phone; Save is only reachable after scrolling past Notes (lines 1057-1064). Totals the user cares about (Total, Balance) are mid-page and bottom-page, never visible together.
2. Section titles are 14 sp `textSecondary` captions above fields (lines 1073-1085) while some fields use `labelText` (depth, PVC, MS) and others use `hintText` only (bill number, agent, address, total, notes). Total field has neither label nor hint, only a rupee icon (line 932): screen readers announce an unlabeled field.
3. Three cards use three different tints and borders: Calculation Preview (`accentLight` 20 percent, primary 30 percent border, lines 1103-1109), Commission (`accent` 5 percent), Payment (`success` 5 percent). No tokenised tone.
4. Commission rate row (`commission_section.dart:109-120`) puts three `Expanded` fields in a row. At 360 dp the field width is about (360 - 32 - 24 - 16) / 3 = 96 dp, so labels "Depth rate (Rs/ft)" truncate and the helper text "1,250 ft = Rs 1,25,000" wraps or clips (helper has no maxLines override, helper slot is one line by default and it ellipsizes).
5. Rate + step rate row (lines 721-787): the step rate field plus a conditional 48 dp refresh IconButton inside half of the row leaves about 60 dp for the text when manual, truncating the label "Step Rate (Rs)".
6. Number alignment: all numeric fields are left aligned with no tabular figures; the Calculation Preview values are right aligned but not tabular and use a bare `Text` (lines 1166-1172).

Contrast (WCAG 2.x, computed)
7. Rupee text in the Calculation Preview Total uses `AppColors.primary` #315D9A on a 20 percent tint: about 6.2:1, passes. Step Rate edit marker and Total edit marker icon use `AppColors.warning` #F59E0B on white: 2.15:1 fails 3:1 for icons (lines 757, 938, commission_section.dart:138).
8. Duplicate-bill banner uses `Colors.orange.shade800` text on `orange.shade50` (lines 603-627): about 4.6:1 passes, but icon `orange.shade700` on the tint is about 2.9:1.
9. Placeholder/hint text uses the theme default (`textHint` #94A3B8 2.56:1 fails).

Tap targets
10. Date row is 56 dp tall: passes. Add-agent `IconButton` default 48: passes. Step rate refresh `IconButton` has `size: 20` icon but default padding, 48 dp: passes. Payment-remove icon is covered in `payment_log_editor.md`.
11. "Auto" `TextButton` for Total and Commission is 48 high but only about 48 wide with 8 dp gap, tight on 360 dp next to the field (lines 953-962).

Form friction
12. Keyboard: all numeric fields use `numberWithOptions(decimal: true)` (good), but no `textInputAction`: pressing the keyboard Next key does not advance reliably, and the last field (Notes) is multi-line. Bill Number uses `TextInputType.text` (bills are alphanumeric here, unlike side ledger forms which are digits only). Bill number, address and notes have no `textCapitalization` except address (`words`).
13. Validation fires only on Save (no `autovalidateMode`). The duplicate bill message appears twice at once: inline validator text after Save plus the orange banner while typing.
14. Numeric fields have no validators at all (only bill number, agent, address); an empty Depth text is read as 0 silently.
15. Agent dropdown validator and a second check in `_saveEntry` (lines 409-414) show the same message as a snackbar; the snackbar is redundant after the inline validator already blocks.
16. No discard guard: pressing back with entered data loses everything with no prompt.
17. Save has no in-flight guard (lines 406-476): a double tap before the `await` completes creates two bills with different UUIDs (see bugs_g1.md B-G1-01).
18. Delete confirm text (lines 478-500) does not say that linked receiver-book income entries are trashed with the bill, and the confirm button is a filled red `ElevatedButton` that can be the first focus target on desktop.

Consistency and components
19. 19 hand-written `InputDecoration` blocks, 11 repeated `FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))` blocks, direct `Colors.orange` and `AppColors.warning/success/error` use (lines 589, 607-620, 472, 494, 512).
20. Date format `EEE, dd MMM yyyy` (line 522) differs from the payment log (`dd MMM yyyy`) and the side lists (`dd/MM/yyyy`).
21. The rupee sign is hard-coded in 12 labels plus `NumberFormat('#,##0.00')` created inside `build` helpers (line 1097) and in `CommissionSection._rate` (line 64) on every rebuild (allocation per keystroke).
22. The screen calls `DatabaseService.getAllLedgerEntries()` directly (lines 241) against CONVENTIONS.md "never call DatabaseService from a screen" and does a full box scan per keystroke in Bill Number.

Missing states
23. No loading state is needed (all local), but there is no saving state (no disabled/progress on Save), no error state if `addEntry` throws (the `await` is not wrapped), and no empty-agent state: when there are zero agents the dropdown opens an empty menu with no hint to use the add button.
24. Calculation Preview Total is always the computed total, even when the Total field is manually overridden (lines 1131-1143), so the two numbers can disagree on screen with no explanation.

Text scale 200 percent
25. Row pairs (type dropdown | feet field) at 2x text: dropdown labels clip ("7inch" fits, label "Depth Type" does not), commission three-up row cannot fit.

## 4. Redesign

Principles: keep field order, labels, calculations and callbacks; change only layout, tokens and components. The form becomes a `RigScaffold` page with a pinned bottom bar.

### 4.1 Structure (all widths)

- `RigAppBar` (title "New Entry"/"Edit Entry", back, action `Icons.delete_outline_rounded` with tooltip "Delete" only when editing). Mobile: flat `headerSurface`, 56 dp, `headlineSmall`. Desktop: 48 dp surface with `outlineVariant` bottom border.
- Body: `ListView` with `RigSection` blocks in the existing order (see 4.2). Horizontal padding `RigSpace.s4` compact, `s6` medium, `s8` expanded; content max width 640 (DS 12) centered at medium and expanded.
- Pinned `SaveBar` (new widget, `_FormSaveBar`, put in `components_g1.md`): `Material` level 3 floating, `SafeArea(top:false)`, height 72, padding `s4`. Left: two stacked `AmountText` (Total `amountMedium` neutral, Balance `amountMedium` tone outstanding when > 0, moneyIn when 0, negative when below 0). Right: filled `FilledButton` "Save Entry"/"Update Entry", min height 48, radius `md`, shows a 20 dp `CircularProgressIndicator` and disabled while saving. Sits above the keyboard (`resizeToAvoidBottomInset: true`, bar is `bottomNavigationBar`). Values come from the existing controllers via a `ValueListenableBuilder` on `_totalController` and `_balanceController` (no new calculations).

### 4.2 Sections (order preserved)

Each section header is `RigSection(title)`: `titleSmall`, color `onSurfaceVariant`, gap `s2` below, `s6` between sections.

| # | Section | Compact (<600) | Medium (600-900) | Expanded (>900, macOS) |
|---|---|---|---|---|
| 1 | Date | `RigDateField` (label "Date", pattern `dateShort`, leading `Icons.calendar_today_rounded`, 56 dp) | same | same |
| 2 | Bill Number | `RigTextField`, label "Bill Number", leading `Icons.receipt_long_rounded`, `TextInputAction.next`, duplicate state: suffix `Icons.warning_amber_rounded` in `outstanding` and the field error text (see state table); the orange banner becomes an `ErrorBanner`-style tonal inline note (`outstandingContainer`) | same | Date and Bill Number side by side (2 columns, gap `s4`) |
| 3 | Agent | `RigDropdownField<Agent>` with trailing `IconButton(Icons.add_circle_outline_rounded, tooltip: 'Add new agent')`, 48 dp; empty list shows menu item "No agents. Use + to add" (disabled item, copy only) | same | Agent and Address in 2 columns |
| 4 | Address (City) | `AddressAutocompleteField` restyled as `RigTextField`; options panel `RigCard` level 3, max height 240, item height 48 | same | same, panel width = field width |
| 5 | Depth Details | row 1: `RigDropdownField` Depth Type (flex 1) + `AmountField` Depth (feet) (flex 1); row 2: Rate per feet + Step Rate (flex 1 each). Step Rate suffix: when manual, `Icons.edit_rounded` 18 dp `outstanding` plus a 48 dp refresh `IconButton` placed in the helper row beneath the field, not inside the half-width row | same as compact | one row of four: Depth Type, Depth, Rate, Step Rate |
| 6 | PVC Details | row: Type + feet; below: PVC Rate per feet (full width) | same | one row of three |
| 7 | MS Pipe Details | same as PVC; Type dropdown remains a single option "6inch" | same | one row of three |
| 8 | Extra Charges | `AmountField` full width | same | half width |
| 9 | Calculation Preview | `RigCard` tone `surfaceContainer` (level 2, no border), title `titleSmall` "Calculation Preview", rows `MoneyLabelValueRow` (label `bodyMedium onSurfaceVariant`, value `amountSmall` tabular right aligned). The final row label "Total" stays (value is the computed total). If the Total field is manually edited and differs, add a caption row "Total field is set manually" in `bodySmall` `outstanding` (copy only) | same | same |
| 10 | Total | `AmountField` with label "Total" (fixes the unlabeled field), leading `Icons.currency_rupee_rounded`, manual marker `Icons.edit_rounded` `outstanding`; Auto as `TextButton` below the field, right aligned, 48 dp | Auto inline right of the field | same as medium |
| 11 | Commission | see 4.3 | | |
| 12 | Payment | `PaymentLogEditor` (see its doc) | same | same |
| 13 | Less | `AmountField` label "Less (Discounts/Deductions)" | same | half width, Balance beside it |
| 14 | Balance | read-only `AmountTile` (label "Balance", `amountLarge`, tone: outstanding if > 0, moneyIn if 0, negative if < 0; the field remains the source `_balanceController`, shown via `ValueListenableBuilder`) in a `RigCard` tone container; keeps the read-only semantics | same | beside Less |
| 15 | Notes | `RigTextField` multiline min 3 max 6, `TextCapitalization.sentences` | same | same |

Rule: the Rs symbol and number format come from `RigFormat.money`; field labels keep "(Rs)" text where today shows the rupee sign because the label is business copy ("Rate per feet", "Step Rate", "Less" keep their words).

### 4.3 Commission block (layout)

`CommissionSection` becomes a `RigCard` (padding `s4`, tone: `commission` at 8 percent as `surfaceContainer` tint, border `outlineVariant`). Header row: `Icons.handshake_rounded` 20 dp `commission`, "Commission" `titleSmall`, and "not added to total" as a `bodySmall` `onSurfaceVariant` chip aligned right (wraps below at 200 percent text scale).
- Compact (<600): the three rate fields STACK vertically, each full width, 56 dp, helper text slot reserved and always visible ("1,250 ft = Rs 1,25,000", tabular). Side bore (depth only) shows one field.
- Medium and expanded: three equal columns (gap `s3`) with the same helper line below each field, `maxLines: 2`.
- Commission result: full-width `AmountField` "Commission (Rs)" with manual marker and an "Auto" `TextButton` row beneath it (right aligned). Computed value shown in `commission` color and `amountMedium` when read; it stays editable.
- The result field is placed after the rates with `s4` gap, matching today.

### 4.4 Agent add dialog and delete confirm

- Add agent: `RigDialogShell` (max width 400) owning both controllers in a `State`, fields Agent Name * (autofocus, `words`) and Phone (Optional, `phone`), name error shown inline under the field (replaces the snackbar that appears behind the dialog); actions Cancel (text) and Add (filled).
- Delete: `ConfirmDialog(destructive: true)`: title "Delete Entry", message "Are you sure you want to delete this entry? This action cannot be undone." plus second sentence "Payments linked to receiver books will also be removed." only if the form's payments list contains a payment with a receiver (copy; see logic touchpoints). Cancel on the left and focused first, Delete text button in `negative`.

### 4.5 Desktop specifics

- Max width 640 (DS 12); today 700, so the macOS form shrinks by 60 px, parity check P-FL-30.
- `Tab` order follows the section order; first focus on Bill Number (Date is a button). `Esc` pops with the discard prompt if dirty. `Cmd+S` triggers Save (`Shortcuts` + `CallbackShortcuts`, same callback as the button). Pointer cursor on the date field. Focus ring 2 px `primary`.
- Hover on rows in the payment list uses `surfaceContainerHigh`.
- No context menu on this screen.

### 4.6 Tokens

Spacing: field gap `s4` (16), pair gap `s3` (12), section gap `s6` (24), card padding `s4`. Radius: fields `md` (12), cards `lg` (16), chips `sm`. Type: labels `labelMedium`, inputs `bodyLarge`, section titles `titleSmall`, amounts `amountMedium/Large`. Color: surface `surface`, page `background`, markers `outstanding`, destructive `negative`, commission `commission`, received `moneyIn`.

### 4.7 Components

`RigAppBar`, `RigScaffold`, `RigSection`, `RigCard`, `RigTextField`, `RigDropdownField`, `RigDateField`, `AmountField`, `AmountText`, `AmountTile`, `MoneyLabelValueRow`, `RigDialogShell`, `ConfirmDialog`, `RigSnack`, plus new `FormSaveBar`, `UnsavedChangesGuard` (see components_g1.md).

### 4.8 State table

| State | Rule |
|---|---|
| Default (new) | Fields as today (numeric controllers start with "0"), Save enabled, Delete hidden |
| Default (edit) | Prefilled from `entry`, agent resolved after first frame (field shows skeleton line until resolved, <1 frame) |
| Loading (saving) | Save button disabled with 20 dp spinner, fields not disabled, back disabled; cleared if the future throws |
| Empty agents | Dropdown menu shows one disabled item "No agents. Use + to add" |
| Error: required | Inline error under field (bill, agent, address) with `negative` text and 2 px `negative` border, helper slot reused, no layout jump |
| Error: duplicate bill | Field error "Bill number already exists" plus `outstandingContainer` inline note; Save still blocked by the existing validator |
| Error: save throws | `RigSnack` error "Could not save entry" (new copy, no logic change) and Save re-enabled |
| Disabled | Balance (read-only, `surfaceContainer` fill, not focusable but selectable) |
| Manual override | Total, Step Rate, Commission show `Icons.edit_rounded` marker and "Auto" action |
| Dirty | Back/Esc opens "Discard changes?" (`ConfirmDialog`, confirm "Discard", Cancel focused) |

### 4.9 Motion

`RigMotion.fast` 150 ms fade for the manual-edit marker and Auto button; `base` 200 ms `AnimatedSize` for the duplicate note and the Commission helper; Save button content cross-fade 150 ms; honors `disableAnimationsOf`. No scroll animations.

## 5. Logic touchpoints that must stay untouched

- Validators (exact): Bill Number: empty after trim returns 'Bill number is required'; `_isBillNumberDuplicate` returns 'Bill number already exists' (`ledger_form_screen.dart:592-600`). Agent: null returns 'Please select an agent' (655-660) and `_saveEntry` repeats it as a snackbar (409-414). Address: empty after trim returns 'Address is required' (`address_autocomplete_field.dart:59-61`). No numeric validators exist.
- Duplicate check: `_checkBillNumberDuplicate` (230-251): trimmed, case-insensitive, current vehicle only (`DatabaseService.getAllLedgerEntries` filters by `currentVehicleId`), excludes the entry being edited.
- Input filters: `RegExp(r'^\d*\.?\d*')` on every numeric field; `numberWithOptions(decimal: true)`.
- Calculations and their trigger wiring: listeners at 178-187; `_updateStepRate`, `_updateCalculatedTotal`, `_updateBalance`, `_updateCommission`, `_applyAgentCommissionDefaults` (only for new bills, `isEditing` guard); manual flags `_isStepRateManuallyEdited`, `_isTotalManuallyEdited`, `_isCommissionManuallyEdited`; Auto actions re-run `_updateStepRate` / `_updateCalculatedTotal` / `_updateCommission`; Depth Type change calls `_updateStepRate` (693-700); changing `_pvc`/`_msPipe` does not recalc.
- `LedgerEntry.calculateStepRate/calculateTotal/calculateBalance/calculateCommission`, `LedgerPayment.totalCash`; `receivedPhonePe: 0`, `phonePeName: null`, `received == receivedCash == _totalReceived` (416-444).
- Save mapping (419-459): `id`, `createdAt` kept on edit, `updatedAt`, `vehicleId: widget.entry?.vehicleId ?? DatabaseService.currentVehicleId`, `notes` null when empty, `paymentsJson: LedgerPayment.encodeList`.
- Provider calls: `addEntry`/`updateEntry`/`deleteEntry`, `agentsProvider.notifier.addAgent(name, phone: ...)` (returns the agent, then `_applyAgentCommissionDefaults`).
- Callbacks and keys: `CommissionSection(onChanged, onManualChanged)`, `PaymentLogEditor(onChanged, onBaseChanged)`, `_formKey`, controller ownership in the State (dialogs own theirs), snackbar copy "Entry added"/"Entry updated"/"Entry deleted", navigation `Navigator.pop` after save (before the snackbar) and after delete.
- Navigation outcome: save pops one route, delete pops one route.
- Dropdown option lists: Depth and PVC `['7inch','8inch']`, MS pipe `['6inch']` (stored strings; labels may be styled but values stay).

## 6. Acceptance criteria

1. Field order, labels and copy of sections 1 to 15 are identical to the current screen (parity P-FL-01..40).
2. At 360 x 800 the Save button is visible without scrolling; at 360 x 800 with the keyboard open it stays above the keyboard and Total and Balance remain visible in the bar.
3. Commission rate fields are never narrower than 280 dp at compact width (stacked) and the helper text "N ft = Rs X" is fully visible at 100, 130 and 200 percent text scale.
4. No numeric field loses its decimal keyboard or its `^\d*\.?\d*` filter; pasting "1,000" or "1.2.3" yields the same text as today.
5. Typing Depth, Rate, PVC, MS, Extra, Less changes Total and Balance exactly as today to 2 decimals; manual Total persists until Auto is pressed.
6. Total field has a visible label "Total" and an accessibility label.
7. Double tap on Save creates exactly one bill (new bill) and calls the provider once.
8. Back with no edits closes immediately; back after any edit shows the discard prompt; Cancel keeps the form.
9. Delete shows the confirm dialog; Cancel changes nothing; Delete removes the bill, shows the snackbar and returns to the ledger.
10. A new bill with agent defaults prefills commission rates; editing an old bill never overwrites its stored rates.
11. All six semantic color roles resolve through tokens; no `Colors.x` or hex in the screen files.
12. Every tappable target is at least 48 x 48 dp (mobile) and 40 dp (desktop pointer).
13. Contrast of every text and marker is at least 4.5:1 (icons 3:1).
14. At text scale 200 percent no overflow warning is thrown on any section.
15. macOS: content max width 640, centered; `Cmd+S` saves, `Esc` closes (with discard prompt when dirty), Tab visits fields in visual order.
16. Address suggestions open below the field, keyboard-selectable (Up, Down, Enter), at most 200-240 dp tall.

## 7. Performance notes

- Today: 10 listeners call `setState` per keystroke, rebuilding the full form, including 19 `InputDecoration`s and a new `NumberFormat` per rebuild (lines 1097, `commission_section.dart:64`). Plan: keep the controllers in the State, but drive the derived widgets (Calculation Preview, Save bar totals, Balance tile, commission helper lines) with `ValueListenableBuilder`/`ListenableBuilder` on the relevant controllers so a keystroke rebuilds only those small widgets. The `setState` in `_onCalculationFieldChanged` can then be limited to the manual-flag markers.
- Extract each section into a `const`-constructible widget taking controllers (e.g. `_DepthSection`, `_PvcSection`, `_MsPipeSection`, `_CalcPreview`, `CommissionSection`), so the unchanged ones skip rebuild.
- `RigFormat` instances are `static final`; no `NumberFormat`/`DateFormat` construction in `build`.
- `ref.watch(agentsProvider)` in `build` rebuilds the whole form on any agent change; move it into the Agent field widget (`Consumer`) with `select` on the list identity.
- The duplicate-bill check scans the whole vehicle box per keystroke through `DatabaseService`; if any data layer change is allowed later, see `logic_g1.md` (debounce is UI-only and allowed: debounce 250 ms before calling the existing function).
- List strategy: about 16 section children, so a plain `ListView(children: [...])` is acceptable (no builder needed); keep sections as separate widgets so offscreen ones are not rebuilt.
- Controller disposal is complete for the 17 form controllers; the two dialog controllers in `_showAddAgentDialog` are never disposed (move into the dialog State, see bugs). `AddressAutocompleteField` disposes its `FocusNode`.
- No per-frame `setState` besides keystrokes; the date picker and dropdowns do not animate the parent.


## Reconciliation 2026-10-13 (Apple look, Android only)

Mockup source: `SC.billForm`, `fscr`, `liveCard`, `previewHtml`, `commissionBox`, `payLog`, `payDlg`, `addAgentDlg`, `delBillDlg`, `fld`, `grp` in `docs/design/mockup/rigledger_apple_mockup.html`. Dropped from sections 1 to 7: macOS and expanded layouts (4.1 widths, the Expanded column of 4.2, 4.5 desktop specifics, Cmd+S, Esc, hover, focus rings, `AdaptiveContent`), `RigAppBar` gradient or flat bar, `FormSaveBar` at the bottom with two stacked amounts (replaced by the live total card plus the pinned pill), Noto Sans, `Rs` labels.

### R1. Mockup screens and Flutter mapping

| Mockup screen (J label) | Render function | Flutter file | Widgets | Notes |
|---|---|---|---|---|
| Main Bore - New Entry | `SC.billForm` (new) | `lib/features/ledger_form/ledger_form_screen.dart` | form sheet scaffold (RigSheet grabber and header, no large title), UnsavedChangesGuard, live total card (RigCard + MoneyTile x2), RigGroup, RigFormRow, RigCard (Calculation), CommissionSection (restyled), PaymentLogEditor (see payment_log_editor.md), RigButton (pinned pill), RigAlertDialog | title "New Entry"; no Delete |
| Main Bore - Edit Entry | `SC.billForm` (edit) | same | same plus trailing Delete icon button | title "Edit Entry", pill "Update Entry" |
| Add payment dialog | `payDlg`, `payDlgRender`, `earlyDlg`, new receiver step | `lib/features/ledger_form/widgets/payment_log_editor.dart` | RigSheet (see payment_log_editor.md) | not owned by this doc |
| Add agent dialog (form) | `addAgentDlg` | `ledger_form_screen.dart` (`_showAddAgentDialog`) | RigSheet "Add New Agent", RigGroup of RigFormRow (Name, Phone), RigButton "Add" | dialog State owns its controllers |
| Delete entry dialog | `delBillDlg` | `ledger_form_screen.dart` | RigAlertDialog (destructive) | "Delete Entry" |
| Delete entry alert (overlay) | `delBillDlg` | same | same | same widget |

### R2. What changes in the redesign (supersedes section 4)

Screen shell (REPLACES 4.1): the form stays a pushed route (the navigation outcome is unchanged: save pops one route, delete pops one route) but looks like a full height sheet: edge to edge, `sheet` background, a grabber at the top, a header row 56 dp below the status bar: Close button (X, 48 dp, left), centred title "New Entry" or "Edit Entry" (17, 600), trailing Delete icon button (`delete_outline`, 48 dp, `moneyOutText`) only when editing. Use `PageRouteBuilder` or `MaterialPageRoute(fullscreenDialog: true)` so it rises from the bottom (300 ms ease-out, instant under reduced motion). The tab bar is not shown. Margins 20, group gap 12.

Body order (field order and labels are unchanged, only grouped):
1. Live total card (REPLACES the SaveBar amounts): `RigCard` (padding 16) with two equal cells: "Total" (12, `lb2`) over the value (22/700, `accentText`) and "Balance" over the value (22/700, `outstandingText`); values are `MoneyTile`s (tap shows the full value; compact only here), updated from the controllers through `ValueListenableBuilder`. At text scale 190 percent and above the two cells stack.
2. RigGroup: Date row (label left, `dFull` value right, `calendar_today` 18 dp icon, opens the existing themed date picker, 2000 to 2100) and Bill Number row (hint "Required").
3. RigGroup: Agent row (select), "Add new agent" row (`add_circle` 22 dp `accent`, text `accentText` bold) and Address (City) row with the existing `AddressAutocompleteField` (suggestion panel is a RigCard level 3, max 240 dp, rows 48 dp).
4. Section title "Depth" (13, 600, `lb2`, uppercase not used) and RigGroup: Type (7inch, 8inch), Depth (ft), Rate per ft (₹ prefix), Step rate (₹ prefix; when manual an "Auto" text button in the row, 48 dp).
5. "PVC": Type, PVC (ft), Rate per ft. 6. "MS pipe": Type (6inch only), MS pipe (ft), Rate per ft. 7. "Extra": Extra charges.
8. "Calculation": RigCard with preview rows (15, `lb2` label left, `MoneyText` right, tabular): `Depth (350 ft x ₹100)`, Step rate, `PVC (20 ft x ₹40)`, `MS pipe (10 ft x ₹60)`, Extra charges, then a hairline and Total (17, 700). Feet in these labels follow the feet rule. The computed Total stays here even when the Total field is manual; when they differ a 13 dp caption "Total field is set manually" in `outstandingText` is added (copy only).
9. RigGroup: Total row (₹ prefix; manual marker, and an "Auto" text button when manual).
10. Commission (REPLACES 4.3): section title "Commission", RigGroup of rows: "Depth rate per ft", helper line "350 ft = ₹700" (13, `lb2`, tabular, `ftq` and `money`, always visible, padding 0 16 8), "PVC rate per ft" + helper, "MS rate per ft" + helper, then the "Commission" row (₹ prefix, "Auto" text button when manual, value in `commissionText`), footer "Commission is not added to the bill total." (13, `lb2`). The rate rows are stacked full width at every width (no three-up row). The header chip "not added to total" of 4.3 is replaced by the footer.
11. "Payments": `PaymentLogEditor` (payment_log_editor.md) then a footer line "Total received" + value (`moneyInText`).
12. RigGroup: Less (Discounts/Deductions) row and a read-only Balance row (value `outstandingText` when above zero, `moneyInText` at zero, `moneyOutText` below zero with a 13 dp "Overpaid" caption, copy only).
13. "Notes": RigGroup with one multi-line row (3 lines, hint "Optional notes").
14. Pinned pill: `RigButton` filled, 50 dp high, full radius, `accentButton` fill, `onAccent` label 17/600, text "Save Entry" or "Update Entry", margin 20, bottom = `viewPaddingOf.bottom + 12` (12 when the keyboard is open), on a gradient fade from `sheet` (62 percent) to transparent. It never scrolls. While saving it shows a 20 dp progress indicator and is disabled (LR-32). The scroll area ends with bottom padding 130.

Rows (RigFormRow): min height 48 dp, padding 0 16, label (17, left, flex), value or input right aligned (17, tabular), ₹ prefix as a leading `Text` next to the input (a `Row` with `IntrinsicWidth`), hairline separators inset 16, focus = 2 dp `accent` ring around the row group item, error = value and helper in `moneyOutText`. At text scale 190 percent and above rows wrap: label on top, value below, 6 dp padding. Inputs keep `numberWithOptions(decimal: true)`, the `^\d*\.?\d*` filter, `textInputAction.next` (last field `done`). The edit pre-fill shows feet by the feet rule (`350`, not `350.0`); the stored double is unchanged. Typing is never reformatted with grouping.

Discard prompt (LR-25, NEW): `UnsavedChangesGuard` wraps the form in `PopScope(canPop: !dirty, onPopInvokedWithResult: ...)`. `dirty` = any controller text differs from its initial value, or date, agent, payments, base amounts or a manual flag differs from the initial state; a saved or deleted form is not dirty. The Close button and Android back both go through it. When dirty: `RigAlertDialog` title "Discard changes?", message "You have unsaved changes. If you leave now they will be lost.", buttons "Keep Editing" (default) and "Discard" (destructive, `moneyOutButton`). The first back press with the keyboard open only closes the keyboard. Save success and Delete success pop without asking. The payment and Earlier received sheets are not covered by LR-25 (unchanged: dismissing discards).

Delete alert (4.4 delete CHANGED, add-agent CHANGED): `RigAlertDialog` (270 dp wide, radius 14, stacked 48 dp buttons) "Delete Entry" / "Are you sure you want to delete this entry? This action cannot be undone." plus the second sentence "Payments linked to receiver books will also be removed." only when a payment has a receiver; Cancel (default) and Delete (destructive). Add agent: RigSheet "Add New Agent", rows Name (hint "Required", autofocus, words) and Phone (hint "Optional"), bottom pill "Add"; an empty name shows the inline message "Agent name is required" and keeps the sheet open.

States:

| State | Rule |
|---|---|
| Default (new) | numeric controllers start as today, pill enabled, Delete hidden |
| Default (edit) | prefilled; the agent resolves after the first frame (row shows a skeleton line for under one frame) |
| Loading (saving) | pill disabled with spinner, fields stay enabled, Close and back blocked until the future finishes |
| Empty agents | Agent row value "Select agent"; opening it shows a disabled item "No agents. Use Add new agent" |
| Error: required | row value and helper in `moneyOutText`, helper text under the group in a 13 dp line; messages unchanged |
| Error: duplicate bill | the Bill Number row is in the error state and a footer line "This bill number already exists. Please use a unique bill number." (13, `moneyOutText`) appears while typing; Save shows the validator text "Bill number already exists" (unchanged) |
| Error: save throws | RigSnack "Could not save entry", pill enabled again |
| Disabled | Balance row (read-only) |
| Manual override | Step rate, Total and Commission rows show an "Auto" text button |
| Dirty | Close or back shows "Discard changes?" |

Old section 4 mapping: 4.1 CHANGED (sheet look, live card, pill, no `RigAppBar`, no max width 640); 4.2 table: compact column KEPT in spirit (field order and labels identical) but rendered as grouped rows, Medium and Expanded columns DROPPED; 4.3 CHANGED; 4.4 CHANGED; 4.5 DROPPED; 4.6 tokens CHANGED (spacing 20 and 12, radius 20 groups, pill full); 4.7 components CHANGED (RigGroup, RigFormRow, RigAlertDialog, RigSheet, RigButton, UnsavedChangesGuard); 4.8 states CHANGED (above); 4.9 motion KEPT with new values (route rise 300 ms, Auto button fade 150 ms, `AnimatedSize` 200 ms for the duplicate note and the manual caption, pill content cross-fade 150 ms, press feedback by ink, instant under reduced motion).

### R3. Logic touchpoints and LR items

Untouched: the whole of section 5 above (validators and their strings, duplicate check, input filters, calculation wiring, `calculateStepRate/Total/Balance/Commission`, `LedgerPayment.totalCash`, save mapping, provider calls, callbacks and keys, snackbar copy, navigation outcome, option value strings).

| Item | Status |
|---|---|
| LR-25 discard prompt, also on Android back | approved |
| LR-32 `_saving` guard against double Save | approved, Phase 1 |
| LR-13 feet rule (display), LR-30 input limit to one decimal | display decided; LR-30 proposed (Q-O5) |
| LR-10 duplicate check reading `DatabaseService` directly | needs approval; a 250 ms debounce before the existing call is UI only and allowed |
| LR-24 rupee sign | approved |
| Proposed, new | none |

### R4. Acceptance criteria delta

REPLACES 6 items 2, 3, 12, 15 and 16; ADDS the rest. 360 and 412 dp, light and dark, text scale 100, 130, 200 percent, keyboard open.
1. The pinned pill is visible without scrolling on open at 360 x 800; with the keyboard open it stays above the keyboard and the focused field is scrolled to the vertical centre.
2. The live total card shows Total and Balance on open; their values equal the Total and Balance rows at all times (single source: the controllers). When the card has scrolled off screen the values remain readable in the Total and Balance rows (open question: sticky strip, conflicts_r1.md C8).
3. Rate rows in Commission are full width at 360 dp; the helper line "N ft = ₹X" is fully visible at 100, 130 and 200 percent.
4. Feet in the pre-fill, the preview labels and the helper lines follow the feet rule (350, 350.5); the stored value is unchanged.
5. Double tap on the pill creates one bill and calls the provider once (LR-32).
6. Close or Android back with no edits closes at once; after any edit it shows "Discard changes?"; "Keep Editing" keeps the form with all values; "Discard" closes without saving; after Save or Delete no prompt appears.
7. First Android back with the keyboard open closes only the keyboard.
8. Delete asks "Delete Entry"; Cancel changes nothing; Delete removes the bill, shows "Entry deleted" and returns to the ledger.
9. Add agent with an empty name keeps the sheet open and shows "Agent name is required"; with a name it selects the agent and copies its default commission rates (new bills only).
10. Every tappable control is at least 48 x 48 dp; text on `sheet` and group surfaces uses `-Text` roles (at least 4.5:1).
11. At 200 percent text the rows wrap (label above value) with no overflow warning on any section.
12. No `Rs` string and no raw colour in the screen files; money through `RigFormat`.

### R5. Parity delta

Changed on purpose: P-FL-28 (the discard prompt now exists; wording "Discard changes?"), P-FL-29 (pinned pill and live card), P-FL-30 (macOS lines DROPPED), P-FL-27 (guard, already planned), the duplicate note copy, labels "Rs" become the rupee sign (calculation preview and helper lines), pre-fill and feet display (P-FL-11 shows `100 ft` not `100.0 ft`), Balance "Overpaid" caption, empty-agent menu text.
Identical: P-FL-01 (order and labels), P-FL-03 to P-FL-10, P-FL-11 to P-FL-26 (all values, messages, validators, saved data), P-FL-31, P-FL-33 to P-FL-40.

### R6. Performance and Android notes

- Keep the controllers in the State; drive the live card, the preview, the helper lines and the Balance row with `ValueListenableBuilder`/`ListenableBuilder`, so a keystroke rebuilds only those leaves (the current 10 `setState` listeners shrink to the manual flags).
- Sections are separate `const`-friendly widgets; `ref.watch(agentsProvider)` moves into the Agent row; `RigFormat` statics replace per-build `NumberFormat`.
- Insets: `MediaQuery.viewPaddingOf` for the top header and the pill's bottom; `viewInsetsOf.bottom` decides the pill padding (12 when the keyboard is open). `Scaffold(resizeToAvoidBottomInset: true)` with the pill as `bottomNavigationBar`; focus scrolls with `Scrollable.ensureVisible(alignment: 0.5)`.
- PopScope: `canPop: !dirty` with `onPopInvokedWithResult` showing the alert; predictive back works because the route uses `PopScope`.
- Dispose all 17 controllers; the add-agent sheet owns and disposes its two controllers in its State (never right after `await`, MEMORY.md gotcha).
- List strategy: about 16 section children, plain `ListView(children)`; no `BackdropFilter`; the pill fade is a gradient, not a blur.
