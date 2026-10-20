> SUPERSEDED IN PART (2026-10-13): the look is now the Apple-inspired Android direction. Read "Reconciliation 2026-10-13" at the end of this file first; where it conflicts with sections 4 to 7 above, it wins.
# cashbook_entry_form_screen.dart (Add / Edit entry) plus cashbook_calculator_sheet.dart and cashbook_items_dialog.dart

Group g2. Sources: lib/features/cashbook/cashbook_entry_form_screen.dart (678 lines), cashbook_calculator_sheet.dart (200), cashbook_items_dialog.dart (200). The calculator sheet and items dialog are opened only from this form and share this doc.

## 1. Purpose and primary user task

Record or edit one Income or Expense entry: type, date and time, amount, notes, optional description, book (edit mode), bills (up to 3) and items. Add mode offers "Save and exit" and "Save and continue"; edit mode offers Delete and Save plus Copy. Parity: PARITY-013..030, 048..052.

## 2. Current structure

`CashbookEntryFormScreen` (form:21, params `entry`, `bookId`, `initialCashIn`, `prefill`). State fields: `_isIn`, `_date`, `_bookId`, controllers `_amount`, `_notes`, `_desc`, focus nodes `_notesFocus`, `_amountFocus`, `_items`, `_attachments`, `_showDesc`, `_saving`. Getters `_isEdit`, `_isLinked` (entry created from a bill payment, `sourceType != null`, type chips locked).

Tree (form:332-651): `Scaffold(appBar: cashAppBar(title, [Copy icon (edit only), PopupMenuButton 'Add/Hide description / Category']))`, body `Column[Expanded(CashPageBody(700, SingleChildScrollView(padding 16, Card(padding 16, Column[...])))), SafeArea(CashPageBody Padding Row of buttons)]`.

Fields in order: type chips Income / Expense (`ChoiceChip`, selected color #059669 or #DC2626), date row (bordered Row: chevron left, tappable date text, chevron right) and time box, amount `TextField` (autofocus in add mode, 20 sp colored by type, prefix "Rs. ", calculator suffix icon), notes `RawAutocomplete<String>` (suggestions from `cashNoteSuggestionsProvider`, max 5, `maxLines: 3`), optional Description / Category, edit-only book `DropdownButtonFormField`, Add Bills `PopupMenuButton` (Camera on mobile, Gallery, PDF; max 3), Add Items button, attachment `InputChip`s. Footer: edit = Delete (outlined red) + Save; add = "Save and exit" (outlined) + "Save and continue" (filled).

Behavior: `_buildForSave` returns null when the amount is empty and focuses the amount field (silent, PARITY-018); `_save` guards with `_saving`; edit mutates `widget.entry` then `updateEntry`; add calls `addEntry`; "continue" clears amount, notes, items and attachments, shows "Saved" and refocuses amount; `_delete` confirms then `moveToTrash`; `_copy` offers same/different account then pushes a prefilled form.

Calculator sheet (`showCashCalculatorSheet`, calc:69-76): `showModalBottomSheet(isScrollControlled)` with expression display (22 sp) and live result (30 sp), 4x5 key grid (`ElevatedButton` 52 high, operators and "=" in primary), "Use" button disabled when `evaluateCashExpression` is null. Pure evaluator `evaluateCashExpression` (calc:8-65).

Items dialog (`showCashItemsDialog`): `AlertDialog` width 420, fields Item, Quantity, Unit, Rate, "Add" text button, count and total row, `ListTile`s with remove icon, Cancel / OK. Model `CashItem` (total = round(quantity x rate)).

State sources: `cashSettingsProvider` (watch: formatting, showDescription, notesSuggestion, use24Hour), `cashBooksProvider` (watch), `cashNoteSuggestionsProvider` (watch when enabled), `currentCashBookProvider` (read), `cashEntriesProvider.notifier` (`addEntry`, `updateEntry`, `moveToTrash`).

## 3. Problems found

Header and structure
1. `cashAppBar` plus `PopupMenuButton` without tooltip or color token (form:339-352; `iconColor` by platform). Overflow only holds one command ("Add description / Category"), which could be a switch row.
2. The whole form lives inside one `Card` inside a scroll view inside a column with a pinned footer (form:354-651); on desktop the card is 700 wide with no hierarchy between sections (identity, money, notes, attachments).
3. Type chips are 32 dp visual with `ChoiceChip` default padding; selected fill #059669 with white 14 sp text is 3.77:1 (form:303-317).

Fields and friction
4. No `textInputAction` anywhere; after the amount, Enter does not move to Notes (form:452-473). Amount keyboard is decimal (good). Notes field uses `maxLines: 3` and `TextCapitalization.sentences` (good).
5. Amount field: `prefixText: 'Rs. '` (form:465) while the stored value is the plain number; the calculator icon (24 dp, `IconButton` default 48) fine; font 20 sp not on scale (form:461).
6. Date block is a hand-built bordered Row with chevrons (form:378-422); the tappable date text has 12 dp vertical padding giving a 40 dp hit height; time box vertical padding 14 gives about 48; they do not match `RigDateField` anywhere else. No label on either field, so screen readers read only the value.
7. Empty amount blocks saving silently (PARITY-018) with no visual cue except focus (form:178-183). Accessibility users get no message. (Parity line demands no message; the redesign adds a non-blocking visual error state on the field, see 4.)
8. Autocomplete suggestion list width is `maxWidth: 460` regardless of field width (form:495-516): on a 360 dp phone the list is wider than the field area; it also overlays the keyboard area without scrolling to stay visible.
9. Edit mode only: the "Accounts" dropdown label is plural for a single selection (form:533), and appears after the optional description, far from the date.
10. Add Bills: the control is a `PopupMenuButton` wrapping a custom bordered box (form:547-563); keyboard users on desktop cannot focus it (child is not a button). Chips for bills show a name derived by splitting on `_` (form:586-591) and delete without confirmation or undo.
11. "Save and exit" is outlined and "Save and continue" is filled in add mode, so the visually primary action is the less common one (form:630-645); in edit mode Delete (outlined red) shares equal width with Save, making a destructive control as large as the primary one.
12. Delete confirm and Copy dialog are default dialogs (form:252-299).
13. Edit save mutates the live entry before the provider call (form:205-217) (see bugs G2-B09).
14. Bill files are copied into app storage at pick time and never removed when the chip is deleted or the form closed (form:139-147, 592-593) (G2-B10).
15. PARITY-050: back discards without a prompt; no unsaved indicator. (Kept; see L-07.)
16. Time picked via `showTimePicker` drops seconds (form:118-119) while date-only change keeps them (form:99-103). Harmless but inconsistent.

Calculator sheet
17. No keyboard entry on desktop; no width cap, the sheet spans the whole window on macOS (calc:71-76). Keys are `ElevatedButton`s with white (surface) fill and default elevation; the "00" and "000" keys are 3-char labels at 20 sp. "DEL" icon button has no tooltip or semantics. Pressing "=" with an invalid expression does nothing and gives no feedback (calc:104-108). `Use` disabled with no hint.
18. Operators `+-*/` use ASCII characters rather than the proper symbols (display only).
19. Display shows expression at 22 sp `textSecondary` and result 30 sp; not scaled; no semantics for the result.

Items dialog
20. Remove icon 18 dp, no confirm (items:178-182); typed but not added row is lost on OK (items:85-103, 194-196) (G2-B11); validation message appears as a snackbar behind the dialog? `showCashSnack(context, ...)` uses the dialog's context which resolves to the root `ScaffoldMessenger`; the snackbar appears under the dialog barrier at the bottom of the screen, partially hidden (items:89). UNVERIFIED but typical.
21. Quantity, Unit and Rate in one row at flex 3:2:3 in a 420 dp dialog: at 200 percent text each field is about 90 dp, labels truncate.
22. List and total are inside `SingleChildScrollView` with a shrink-wrapped `Column` (items:112-187): long item lists scroll the whole dialog including the input fields out of view.

## 4. Redesign

### 4.1 Form page

- `RigScaffold(appBar: RigAppBar(title, actions), body, bottomBar: FormActionBar)`; content max width 640; compact/medium padding `s4`; expanded: centered 640 column. Title text unchanged: "Add Income", "Add Expense", "Edit Transaction". Actions: Copy (`Icons.content_copy_rounded`, tooltip "Copy", edit only), overflow `RigMenuButton` with the single item "Add description / Category" / "Hide description / Category" (same toggle `_showDesc`).
- Sections as `RigCard`s (level 1, radius `lg`, padding `s4`, gap `s3`) in this order, same field order as today:
  1. Card "Type and date": `RigSegmented` Income / Expense (min 48, Income selected `moneyInContainer` + `moneyIn` label, Expense `negativeContainer` + `negative`; locked with a `Icons.lock_rounded` 16 caption "Linked to a bill payment" when `_isLinked`; `onChanged` same as today), then `RigDateField` label "Date" with prev/next day icon buttons as prefix and suffix inside the field (`Icons.chevron_left_rounded`, `Icons.chevron_right_rounded`, tooltips "Previous day", "Next day", each 48 dp), and `RigTimeField` label "Time" (applies `use24Hour`). Compact: date full width, time below it (stack) at widths < 400, otherwise Row 60 / 40 percent; expanded: Row 60 / 40.
  2. Card "Amount": `AmountField` label = "Income" or "Expense" (as today `amountLabel`), prefix shown as part of the field (symbol per the L-02 decision, "Rs." until decided), style `amountLarge` colored `moneyIn` or `negative`, trailing calculator `IconButton` (`Icons.calculate_rounded`, tooltip "Calculator", 48 dp), keyboard decimal, `textInputAction: next`, autofocus in add mode. Empty amount on Save: field shows a helper/error text "Enter an amount" and keeps focus (visual only; the save is still blocked silently in logic terms, i.e. no navigation, no provider call, parity-018 behavior preserved; the extra helper text is a deliberate copy addition, Q5).
  3. Card "Details": Notes `RigTextField` (autocomplete overlay width = field width, max height 220, `RigCard` level 3 look, rows 48 dp, `textInputAction: next`), optional Description / Category `RigTextField`, edit-only "Account" `RigDropdownField` (label singular "Account", placed after Notes, same as before), keyboard `TextCapitalization.sentences` for notes.
  4. Card "Bills and items": two `OutlinedButton.icon`s in a Row (compact stacks under 360 dp): "Add Bills" / "Bills (n)" (`Icons.add_a_photo_rounded`, opens `RigMenuButton` with Camera (mobile only), Gallery, PDF) and "Add Items" / "Items (n)" (`Icons.list_alt_rounded`); both min 48 high and keyboard focusable. Attachment `InputChip`s below with delete (same behavior, tooltip "Remove bill"), 48 dp hit target via `MaterialTapTargetSize.padded`.
- `FormActionBar` (SafeArea, above keyboard, level 3 surface when content scrolls): add mode = [outlined "Save and exit"] [filled "Save and continue"]; labels, callbacks and which button is filled stay as today (the filled one is the repeat-entry action); both min 48 dp. Edit mode = [text button "Delete" in `negative` with `Icons.delete_rounded`, width wrap] [filled "Save" with `Icons.check_rounded`, flex 1]. During `_saving` the Save button shows a 24 dp indicator and is disabled.
- Delete and Copy dialogs: `ConfirmDialog` (destructive) and `RigChoiceDialog` ("Copy to same account", "Copy to different account", then "Select account" list); same results.
- Keyboard and desktop: Cmd+Enter = Save (edit) / Save and exit (add); Esc = back (no prompt, PARITY-050); Tab order follows the card order; `Enter` in Amount moves to Notes; focus ring 2 px `primary`.

### 4.2 Calculator sheet

- `RigSheet` (title "Calculator", max width 420, centered on expanded; compact full width). Display: `RigCard` tone `container`, expression `bodyLarge` `onSurfaceVariant` right-aligned, result `displayAmount` right-aligned, `Semantics(liveRegion: true)` for the result.
- Keypad 4 x 5 grid, gap `s2`, `CalcKey` min 56 dp (touch) / 48 (pointer), radius `md`; digits `surfaceContainer` fill with `onSurface`; operators `primaryContainer` with `primary`; "=" filled `primary`; "C" and DEL `surfaceContainerHigh`, DEL icon `Icons.backspace_rounded` tooltip "Delete". Operator keys keep the ASCII characters `+`, `-`, `*`, `/` as the strings inserted into the expression; `*` and `/` carry `Semantics(label: 'times')` and `Semantics(label: 'divide')`.
- Keyboard: on desktop digits, operators, Enter (=), Backspace, Esc are handled via `CallbackShortcuts`; no change to `evaluateCashExpression`.
- Feedback: "=" with an invalid expression shakes the display for `fast` and announces "Invalid expression" (no state change). "Use" shows the numeric result; disabled state shows helper "Enter a valid expression".

### 4.3 Items dialog

- `RigDialogShell` max width 480, title "Add Items", content split: fixed input block on top (Item full width; Quantity, Unit, Rate in a Row at >= 400, in a 2 x 2 grid below) with "Add" `FilledButton.tonal` (`Icons.add_rounded`) full width on compact, and a scrollable list below (own `ListView`, `Flexible`), so inputs never scroll away. Count and total row sticky between them: "Item (n)" and "Total <n>" (`titleSmall`, `amountSmall`).
- Rows: `RigListRow` dense (title name, subtitle "qty unit x rate", trailing total plus remove `IconButton` 48 dp `Icons.close_rounded` tooltip "Remove item", `negative` icon).
- Validation message shows inline (`ErrorBanner` or helper text "Enter item, quantity and rate") instead of a snackbar behind the dialog.
- OK with a half-typed row: a non-blocking inline hint "You have an item that is not added" and OK still returns the current list (behavior preserved, G2-B11 fix needs approval: Q2).

### 4.4 Tokens and state table

Spacing `s4` page, `s3` between fields, `s4` card padding. Radius `lg` cards, `md` fields and keys, `xl` sheet top. Type: `bodyLarge` inputs, `amountLarge` amount, `labelLarge` buttons.

| State | Rule |
|---|---|
| Default | as above |
| Loading | Save button 24 dp indicator while `_saving` |
| Empty amount | helper "Enter an amount", no save |
| Error | provider error string via `showRigSnack(kind: error)` |
| Disabled | type segmented locked when linked; Save disabled while saving; Delete only in edit mode |
| Attachments full | snackbar "Up to 3 bills per entry" (unchanged text) |

Motion: keypad press `fast`; card section entrance none; helper text fade `fast`.

## 5. Logic touchpoints that must stay untouched

- `_buildForSave` (amount parse, null blocks save), `_save(exit:)` branching (edit pops with true; add exit pops; continue clears `_amount`, `_notes`, `_items`, `_attachments`, shows "Saved", refocuses amount, keeps date, type, description, book).
- `cashEntriesProvider.notifier.addEntry(...)`, `updateEntry(e)`, `moveToTrash(id)`; field mapping (description null when empty; attachments null when empty; `itemsJson: CashItem.encodeList`).
- `_amount.text = _plain(result)` after calculator and `_plain(total)` after items (items total applies only when > 0, form:134-135).
- `_isLinked` locks type chips; `_maxAttachments = 3`; storage under `cashbook_bills` with uuid prefix; the chip label parsing (skip first `_` segment).
- `_shiftDay` keeps the time; picking a date keeps hour, minute and second; picking time keeps the date.
- Notes suggestions use `cashNoteSuggestionsProvider` only when `settings.notesSuggestion`; `_showDesc = settings.showDescription || _desc.text.isNotEmpty`.
- `evaluateCashExpression` and `CashItem` (model, JSON, total) exact behavior.
- Controllers and focus nodes disposed in State (form:85-92; items:76-83).
- Copy opens `CashbookEntryFormScreen(bookId: target, prefill: copy)`.

## 6. Acceptance criteria

1. Add Income from the ledger opens with type Income, date today, time now, amount focused; typing "1234.5" and Save and exit creates an Income of 1234.50 in the current book (rounded to 2 decimals on save).
2. Save with an empty amount does not close, does not create, focuses the amount; the field shows the helper text.
3. Zero amount can be saved. Negative sign and letters cannot be typed.
4. Save and continue clears amount, notes, items, bills only; shows the snackbar "Saved".
5. Date chevrons move one day across month ends and keep the time; future dates allowed.
6. Linked entries (from a bill payment): type control is locked, other fields editable.
7. Add Bills offers Camera only on mobile; maximum 3; a 4th shows the existing message.
8. Calculator: "12+3.5*2" shows result 19 and Use fills the amount with 19; division by zero gives no result and Use disabled.
9. Items: Add rows, remove rows, OK sets the amount to the total when total > 0; Cancel changes nothing.
10. All controls have >= 48 dp touch height; labels announced by a screen reader; all dialogs usable at 200 percent text scale on 360 dp width.
11. Cmd+Enter saves on macOS; Esc leaves without prompt.
12. No `Colors.x`, hex, `CashColors`, `AppColors` direct reads.
13. Delete in edit mode asks confirmation, moves to trash, closes the form.
14. Copy to same account opens a prefilled add form (same date, time, amount, notes); to a different account asks the account first.

## 7. Performance notes

- `build` watches `cashSettingsProvider`, `cashBooksProvider` and `cashNoteSuggestionsProvider` at the top: every settings change or suggestion refresh rebuilds all fields. Use `select`: `books` only when `_isEdit` (wrap the dropdown in a `Consumer`), suggestions inside the notes field `Consumer`.
- `setState` is used per tap on chips and date arrows; fine (small form). Avoid `setState` in `onChanged` of text fields (none today).
- The `RawAutocomplete` `optionsBuilder` filters the suggestions list on each keystroke (`.where().take(5)`, form:481-485): acceptable; compute lowercase list once per provider value if the list exceeds ~2000 notes (logic-free: do it inside the `Consumer`).
- Extract section cards into `const`-able widgets (`_TypeDateCard`, `_AmountCard`, `_DetailsCard`, `_BillsItemsCard`) so a keystroke in Notes does not rebuild the date card.
- `FocusNode`s and controllers remain State-owned and disposed.
- Calculator: `setState` per key on a tiny widget is fine; the `evaluateCashExpression` call in `build` (calc:117) is O(length of expression); cache per `_expr` change.
- Items dialog: use `ListView.builder` for the item list; `CashItem.totalOf(_items)` is recomputed in `build` each time (items:162); trivial.


## Reconciliation 2026-10-13 (Apple look, Android only)

### R1. Mockup screens and Flutter mapping

| Mockup screen (J registry) | Mockup render function | Flutter file | Widgets | Notes |
|---|---|---|---|---|
| Add Income form | `cbForm`, `SC.cbEntry` (via `fscr`) | lib/features/cashbook/cashbook_entry_form_screen.dart | Full-height form screen (grabber, close button, title), RigSegmented, RigCard (amount), RigGroup of RigFormRows, RigRow (Bills, Items), RigButton pair, UnsavedChangesGuard | Presented as a full-screen sheet style page (`fscr`): grabber and a close X at left, not a back chevron. Keep the push route, add the styling. |
| Edit Transaction form | `cbForm(null, id)`, `SC.cbEntry` | same file | same plus Account RigFormRow, Copy and More glass buttons, Delete tonal RigButton, linked-entry hint | Linked type lock: segmented disabled at 55 percent with the hint "Linked to a bill payment. The type cannot be changed." |
| Calculator sheet | `cbCalcSheet`, `calcRender`, `calcKey` | lib/features/cashbook/cashbook_calculator_sheet.dart | RigSheet "Calculator", display block, 4 x 5 grid of round keys, pinned RigButton "Use" | Round keys 62 dp tall, radius 31, gap 10; key order differs from the code (conflicts_r3.md C-05). |
| Add Items dialog | `cbItemsDlg`, `itemAdd` | lib/features/cashbook/cashbook_items_dialog.dart | full-height RigSheet "Add Items": RigGroup of four RigFormRows plus an "Add item" row, caption with count and total, RigGroup of item RigRows, pinned RigButton "OK", RigAlertDialog for the half-typed row (LR-26) | Half-typed row warning is not drawn in the mockup; spec below. |
| Add Bills sheet (inside Add Income form) | `cbBillMenu`, `cbBill` | cashbook_entry_form_screen.dart (`PopupMenuButton` today) | RigSheet "Add Bills" with RigRows Camera, Gallery, PDF | Camera hidden where not available; maximum 3 bills (snackbar "Up to 3 bills per entry"). |
| Copy sheet | `cbCopyDlg`, `cbSelAcct` | cashbook_entry_form_screen.dart | RigSheet "Copy" (two RigRows), RigSheet "Select account" | Same results as today. |
| Account Ledger date picker (B2) | `datePick` | cashbook_entry_form_screen.dart (date row) | DatePickerSheet (B2) | Reference only (screens/accounts_daily_date_picker.md, group r1). |

### R2. What changes in the redesign (supersedes section 4)

Entry form (Add Income, Add Expense, Edit Transaction), presented as a full-height form screen:
1. Top row (56 dp): close button at left (X glyph, 48 dp), centred 17 sp title ("Add Income", "Add Expense", "Edit Transaction"), trailing glass buttons: Copy (edit mode only) and More (toggles the Description / Category row).
2. Linked hint (only when the entry is linked to a bill payment): footer text 13 sp `label2` above the segmented control.
3. RigSegmented Income and Expense (3 px inset thumb, 48 dp boxes); locked and at 55 percent opacity when linked.
4. Amount card: RigCard (radius 20, centred): label "Income" or "Expense" (13 sp `label2`), then the rupee sign at 34 sp `label2` and the amount field at 44 sp weight 700 centred, coloured `moneyInText` or `moneyOutText`; below it a text button "Calculator" (calculator glyph) opening the calculator sheet. Input rules unchanged (digits and one dot, no minus).
5. Date group (RigGroup): row with previous-day chevron, the date centred (`dFull`, tap opens the DatePickerSheet), next-day chevron (each 48 dp); row "Time" with the 12 or 24 hour value and a clock glyph (opens the time picker).
6. Details group: Notes (multi-line, hint "What was this for?", suggestions overlay at field width, rows 48 dp), Description / Category row only when shown (setting or More toggle), Account row (edit mode only) opening a selector.
7. Attachments group: RigRow "Add Bills" or "Bills (n)" with subtitle "Camera, gallery or PDF. Up to 3 per entry." and chevron; RigRow "Add Items" or "Items (n)" with chevron. Attached bills appear as removable chips below ("bill_1.jpg  x").
8. Pinned bottom bar (inset + 12 dp above the system inset, above the keyboard): add mode = tonal pill "Save and exit" and filled pill "Save and continue" side by side (gap 12, 50 dp); edit mode = tonal destructive pill "Delete" and filled pill "Save". Filled uses `accentButton` with `onAccent`. Content bottom padding inset + 110 dp.
9. Discard prompt (LR-25): when the form is dirty (amount, notes, description, items, bills, date, time, type or book differ from the opening values) the close button and Android back show RigAlertDialog "Discard changes?" with "Keep Editing" (default) and "Discard" (`moneyOutText`). An untouched form closes at once. Save and continue resets the baseline to the cleared form.

Calculator sheet: RigSheet (28 radius, grabber, title "Calculator"); display block right aligned: expression 22 sp `label2` (placeholder 0), result 44 sp weight 700 (hero) hidden when invalid; keypad 4 columns by 5 rows, gap 10, margin 20: C, DEL, 000, / then 7 8 9 *, 4 5 6 -, 1 2 3 +, 0 00 . = in the mockup order. Keys are round (62 dp tall, radius 31): digits `fill` (surface s3), C, DEL and 000 `fill2`, operators and "=" `accentButton` with `onAccent`. DEL is a backspace glyph with the label "Delete". Pinned RigButton "Use" at 40 percent opacity when the expression is invalid (disabled). `evaluateCashExpression` unchanged.

Add Items sheet: full-height RigSheet "Add Items": RigGroup with Item (hint "Name"), Quantity, Unit (hint "kg, pcs"), Rate (rupee prefix) and a row "Add item" (add glyph, `accentText`, bold); caption "Item (n)   Total <amount>" (`dFull`-style caption, 13 sp `label2`); RigGroup of added rows (name bold, "qty unit x rate" small, line total at right, a 48 dp remove button in `moneyOutText`); pinned RigButton "OK" (sets the amount from the total only when the total is above zero, unchanged). Half-typed row (LR-26): when OK is pressed and any of item, quantity or rate holds text that has not been added, show RigAlertDialog "Add this row or discard it" with "Add" (adds it if valid, else keeps the sheet open and shows the field error) and "Discard" (clears the fields and continues). A complete half-typed row added by "Add" counts in the total. The existing validation message "Enter item, quantity and rate" shows as an inline ErrorBanner row inside the sheet (a SnackBar would hide behind the sheet).


Old section 4 items:

- Old 4.1 RigScaffold with a FormActionBar and max width 640: CHANGED to the full-height form screen with the pinned bottom bar; max width DROPPED.
- Old 4.1 cards (Type and date, Amount, Details, Bills and items): CHANGED to the mockup order: segmented, amount card, date group, details group, attachments group. The "Type and date" card is split; field order inside the groups is the code order (type, date, time, amount, notes, description, account, bills, items) except amount moves above the date as in the mockup (see conflicts_r3.md C-09).
- Old 4.1 AmountField symbol "Rs." until L-02 decision: CHANGED to the rupee sign (LR-24).
- Old 4.1 Cmd+Enter, Esc, Tab order, expanded centred column: DROPPED. "Esc leaves without prompt (PARITY-050)": CHANGED by LR-25 (prompt only when dirty).
- Old 4.1 icons on Bills and Items buttons and a RigMenuButton for Bills: CHANGED to RigRows and the Add Bills sheet.
- Old 4.1 Delete and Copy as ConfirmDialog and RigChoiceDialog: CHANGED to RigAlertDialog and RigSheets; results KEPT.
- Old 4.2 calculator RigSheet with 56 dp rectangular keys, "shake on invalid" and desktop keyboard handling: CHANGED to round 62 dp keys; the shake and desktop shortcuts are DROPPED; "Use" disabled when invalid KEPT.
- Old 4.3 items dialog (RigDialogShell, 2 x 2 grid, non-blocking hint, Q2): CHANGED to a full-height sheet and the blocking warning of LR-26 (approved), which supersedes "OK still returns the list".
- Old 4.4 tokens and state table: CHANGED; Loading (Save spinner while `_saving`) KEPT, with the LR-32 guard.


States:

| State | Rule in the new look |
|---|---|
| Default | as above |
| Loading | Save pill shows a 20 dp spinner and ignores taps while saving (LR-32) |
| Empty amount | Save and continue / Save do nothing visible except focusing the amount; helper "Enter an amount" under the card (unchanged logic) |
| Error | provider error string in RigSnack above the pinned bar |
| Disabled | type segmented locked when linked; Delete only in edit mode; "Use" in the calculator when invalid |
| Dirty | close or back raises the discard alert (LR-25) |
| Attachments full | RigSnack "Up to 3 bills per entry" |


Motion: sheets rise 250 ms ease-out; key press by ink (`pressOverlay`, `pressOnFilled` on filled keys); error text fades 150 ms; alerts fade and scale 200 ms; zero duration under reduced motion.


### R3. Logic touchpoints and LR items

Untouched: `_buildForSave`, `_save(exit:)` branching, `addEntry`, `updateEntry`, `moveToTrash`, field mapping, amount after calculator and items, `_isLinked` lock, `_maxAttachments = 3`, storage under `cashbook_bills`, `_shiftDay` keeping the time, notes suggestions, `evaluateCashExpression`, `CashItem`, State-owned controllers and focus nodes, copy via `CashbookEntryFormScreen(prefill:)`.


- LR-25 (approved): dirty check from the controllers and fields versus their opening values; `PopScope(canPop: !dirty)`; shared alert. Replaces PARITY-050.
- LR-26 (approved): items dialog half-typed row warning (G2-B11).
- LR-32 (approved, Phase 1): `_saving` guard on Save and exit, Save and continue, Save, Delete.
- LR-24 (approved for the rupee sign): prefix and item rates show the rupee sign; date shown with `dFull`.
- LR-02 (approved): not used by the form; the DatePickerSheet here only returns a date to the form.
- No new logic item.


### R4. Acceptance criteria delta

1. Dirty rule: opening an Add form and pressing close or Android back closes without a prompt; after typing anything in amount, notes, description or after adding an item or bill or changing type, date, time or account, close and back show "Discard changes?"; Keep Editing stays, Discard closes.
2. Save and continue clears amount, notes, items and bills, keeps date, type, description and book, shows RigSnack "Saved", and the form is clean again (no prompt on close).
3. Items OK with a half-typed row shows the LR-26 alert: Add adds the valid row then OK applies the total; Discard clears the fields; a row with only one of the three fields shows the field error and stays open.
4. The calculator keypad uses the mockup order (C DEL 000 /, 7 8 9 *, 4 5 6 -, 1 2 3 +, 0 00 . =); "12+3.5*2" gives 19; division by zero gives no result and "Use" is disabled; keys are at least 48 dp and 62 dp tall at scale 100 percent.
5. Pinned bottom pills are 50 dp, above the keyboard and the inset; with the keyboard open the amount field and the primary pill are both visible at 360 dp.
6. At text scale 130 and 200 percent the amount (44 sp base) shrinks with the fit rule but stays fully visible; rows grow; nothing is clipped.
7. Linked entries: the type segmented is disabled at 55 percent and the hint is shown; other fields stay editable.
8. Delete in edit mode shows "Move this transaction to Deleted Transactions?" in RigAlertDialog; Copy offers same account or a different account (then Select account); both open a prefilled add form.
9. Tapping the date opens the DatePickerSheet; the chevrons move one day across month ends and keep the time.
10. Light and dark at 360 dp and 412 dp: the amount colour is `moneyInText` or `moneyOutText` with at least 4.5:1 contrast on the card; the pinned pills use `accentButton` with `onAccent`.


### R5. Parity delta

Change on purpose:

- PARITY-050: back from the edit form shows the discard prompt when the form is dirty (LR-25); no prompt when clean.
- PARITY-029: OK with a half-typed row warns before closing (LR-26).
- PARITY-035 and 084: prefix and amounts show the rupee sign.
- PARITY-026: keypad key positions change to the mockup layout; the key set and results are identical.
- PARITY-022 and 023: date shown as `d MMM yyyy` by default.


Must stay identical:

- PARITY-013 to 021 (entry points, fields, defaults, type, amount rules, empty amount blocks save, zero saves, two decimals), PARITY-024 and 025 (Save and exit, Save and continue), PARITY-027 and 028 (suggestions, description), PARITY-030 (bills, max 3), PARITY-048 and 049 (edit, delete to trash), PARITY-051 (copy).


### R6. Performance and Android notes

- Edge to edge: status bar transparent; bottom inset from `MediaQuery.viewPaddingOf(context).bottom`. Pushed screens have no floating tab bar; content ends at inset + 24 dp, or inset + 110 dp when a pinned bottom pill is present.
- Keyboard: `resizeToAvoidBottomInset: true`; a pinned bottom pill sits above the keyboard; sheets add `MediaQuery.viewInsetsOf(context).bottom`; the focused field scrolls to the centre.
- Keyboard: the amount field is auto-focused on Add; a numeric keyboard with decimal; the pinned bar uses the keyboard inset; the Notes suggestion overlay respects `viewInsetsOf`.
- PopScope: `UnsavedChangesGuard` wraps the page with `canPop: !dirty`; the dirty flag is a `ValueNotifier<bool>` updated from controller listeners, not a `setState` per keystroke.
- Rebuild scope: split into `_TypeSegment`, `_AmountCard`, `_DateGroup`, `_DetailsGroup`, `_AttachGroup` so a Notes keystroke does not rebuild the amount card; use `select` on settings, books (only in edit mode) and suggestions.
- Controllers: `_amount`, `_notes`, `_desc`, `_notesFocus`, `_amountFocus` are State-owned and disposed (verified, entry form 47-91). Items sheet controllers `_name`, `_qty`, `_unit`, `_rate` are State-owned and disposed (verified, items 71-82); when the dialog becomes a sheet they stay in the sheet State. The calculator sheet has no controllers.
- Calculator: key press `setState` on a small widget only; cache the evaluated value per expression change; no `IntrinsicHeight` in the keypad.
- Cache `NumberFormat` and `DateFormat` objects in RigFormat; do not allocate in `build`.

