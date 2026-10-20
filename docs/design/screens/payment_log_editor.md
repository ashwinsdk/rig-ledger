> SUPERSEDED IN PART (2026-10-13): the look is now the Apple-inspired Android direction. Read "Reconciliation 2026-10-13" at the end of this file first; where it conflicts with sections 4 to 7 above, it wins.
# payment_log_editor (Payments received block, add/edit payment dialog, Earlier received dialog)

File: `lib/features/ledger_form/widgets/payment_log_editor.dart` (466 lines). It contains three pieces that share this doc: `PaymentLogEditor` (the card inside both bill forms), `_BaseDialog` ("Earlier received"), and `showPaymentDialog` / `_PaymentDialog` (add/edit one payment).

## 1. Purpose and primary user task

Let the user record every payment received against one bill (amount, mode Cash/PhonePe on side bore only, date, receiver book, payer name for PhonePe, note), see the running Total Received, and edit older "unlogged" received money. Used by `ledger_form_screen.dart:993` (cash only, `allowPhonePe: false`) and `side_bore_form_screen.dart:681` (`allowPhonePe: true`). Primary task: "add a payment in under 10 seconds, choose who received it, see the total update".

## 2. Current structure

`PaymentLogEditor` (ConsumerWidget, stateless):
`Container` (success 5 percent fill, success 25 percent border, radius 12) > `Column`:
- header row: `Icons.payments_outlined` (success, 20), "Payments received" (14 sp w600), `TextButton.icon("Add payment")`
- optional `ListTile(dense)` "Earlier received" (subtitle "Before payments were logged, no receiver", trailing amount) shown when `baseCash + basePhonePe > 0`; tap opens `_BaseDialog`
- `No payments yet` text (13 sp, `textHint`) when no payments and no base
- per payment `ListTile(dense)`: title `Rs amount  Cash|PhonePe` (w600), subtitle `date | receiver | from payer | note` joined with `  |  ` (2 lines, ellipsis), trailing delete `IconButton` (20 dp icon, `AppColors.error`)
- `Divider(height: 1)`, then "Total Received" row (w500) and amount (18 sp bold, `AppColors.success`)

State sources: `cashBooksProvider` read in `_receiverName` (ref.read inside build helpers, lines 45-51), `cashBooksProvider` watched in `_PaymentDialog.build`, `phonePeNamesProvider` watched in the dialog, `cashBooksProvider.notifier.addBook(name, kind: 1)` for "New receiver". The editor owns no state: the parent holds `payments`, `baseCash`, `basePhonePe` and receives `onChanged(list)` / `onBaseChanged(cash, phonePe)`.

`_BaseDialog`: `AlertDialog` with helper text and 1 or 2 amount fields (`Cash (Rs)`, `PhonePe (Rs)`), controllers in `State` and disposed. Returns a record `(double cash, double phonePe)`.

`_PaymentDialog` (ConsumerStatefulWidget): controllers `_amount`, `_payer`, `_notes` in State, disposed. Fields in order: Amount (autofocus), mode `SegmentedButton` (only if `allowPhonePe`), Date (InkWell + InputDecorator with `showDatePicker`, default theme), "Received by" `DropdownButtonFormField<String>` (No receiver, books sorted receivers first then name, "New receiver"), "PhonePe payer name" `Autocomplete<String>` (only for PhonePe mode), Note (optional). Actions Cancel / Save (`ElevatedButton`).

## 3. Problems found

1. Remove payment has no confirmation and no undo (lines 144-152): one tap on a 20 dp glyph removes the row. If the payment was linked to a receiver book, saving the bill later trashes the linked Income entry (PaymentLinkService), so a mis-tap can cascade. The `IconButton` itself is 48 dp (default padding) but sits flush against the trailing edge next to a tap-to-edit row, so mis-taps on the row edge are likely.
2. Title string `'Rs amount  Cash'` uses two spaces and mixes amount and mode in one run (line 131); the amount is not tabular and not right aligned, so a column of payments does not line up. Subtitle packs 4 facts into one line with pipes, truncating the receiver (the most important fact) at 2 lines on 360 dp.
3. Colors: `AppColors.success` #10B981 on the 5 percent tint is about 2.4:1 for the 18 sp bold Total Received (fails 3:1 large text; line 163-167) and for the 20 dp icon. Hint text 13 sp `textHint` #94A3B8 is 2.56:1 (line 124). Delete icon `AppColors.error` #EF4444 is 3.76:1 (passes icon 3:1).
4. Currency and date formatting use file-level `NumberFormat('#,##0.00')` and `DateFormat('dd MMM yyyy')` (lines 12-13) and the Rs sign is concatenated in 4 places.
5. `_receiverName` uses `ref.read` inside `build` (line 47), so a renamed or deleted book is not reflected until a parent rebuild; "Deleted book" is shown when the id is missing (correct but not styled as a warning).
6. Dialog problems:
   - The same `_error` field is used for the Amount validation and for `addBook` errors (lines 308-309, 358), so a "book already exists" error shows under Amount.
   - Amount validation uses `amount == null || amount <= 0` and only shows after tapping Save; no inline feedback while typing; keyboard action is not `done`, so Enter does not submit.
   - Date row uses a raw `InkWell` + `InputDecorator`; the date picker is not themed (the bill forms theme theirs, line 320 of the main form), range 2000-2100.
   - The "New receiver" row is a dropdown item with an inline icon; selecting it opens a second dialog while the dropdown overlay is closing (focus flicker). Row uses `AppColors.primary` directly.
   - `AlertDialog` has no max width control; on macOS it is as wide as the default (about 280 dp content) which makes the 4 stacked fields cramped; the content `SingleChildScrollView` is correct for the keyboard.
   - Payer autocomplete: the options list shows all names on focus (empty query matches all), unlimited length with no max height specified.
   - Dropdown helper "Adds the amount to this book in Account Ledger" is shown even for "No receiver".
7. Tap targets: tile `onTap` rows are `dense: true` (48 dp min is not guaranteed; dense list tile is 48 high with one line and 64 with two, so passes); "Add payment" `TextButton.icon` is 48 high.
8. Missing empty/error states: "No payments yet" has no call to action besides the header button; no error state when the bill's Total Received exceeds Total (the Balance goes negative in the parent without a hint here).
9. Number alignment: Total Received amount is right aligned (Spacer) but not tabular.
10. Semantics: delete button has a tooltip ("Remove payment"), but the list rows have no combined `Semantics` label, so TalkBack reads each tile piecemeal.

## 4. Redesign

### 4.1 PaymentLogEditor card

`RigCard` (level 1, padding 0 so rows can be full bleed), header `RigListRow`-style bar, rows, footer.

- Header (padding `s4` left, `s2` right): `Icons.payments_rounded` 20 dp `moneyIn`, "Payments received" `titleSmall`, `TextButton.icon(Icons.add_rounded, "Add payment")` 48 high.
- Payment row (`RigListRow`, min height 72, padding `s4` horizontal, divider inset `s4`):
  - leading none (rows are dense); title line: left `bodyLarge` mode label "Cash" or "PhonePe" with a `labelSmall` chip (tonal, `surfaceContainer`) and right `AmountText(amountMedium, tone: moneyIn)` right aligned, tabular;
  - subtitle line 1: date `dateShort` in `bodySmall onSurfaceVariant`, and the receiver name with `Icons.account_balance_wallet_rounded` 16 dp, `bodySmall`, `onSurface`, `maxLines: 1`, ellipsis, flexible;
  - subtitle line 2 (only if present): "from <payer>" and the note, `bodySmall onSurfaceVariant`, `maxLines: 2`.
  - trailing: `IconButton(Icons.delete_outline_rounded, tooltip: 'Remove payment')` 48 x 48 in `negative`; separated from the row tap area by a 8 dp gutter.
  - whole row is the tap target (edit); `Semantics(label: '<mode> <amount> on <date> received by <receiver>')` merges the row.
- Earlier received row: same row anatomy, title "Earlier received" `bodyLarge`, subtitle "Before payments were logged, no receiver", amount right.
- Empty: `bodyMedium onSurfaceVariant` "No payments yet" with a tonal button "Add payment" (replaces the dead text).
- Footer (padding `s4`, top border `outlineVariant`): label "Total Received" `bodyMedium`, value `AmountText(amountLarge, tone: moneyIn)` right aligned. Remove-payment shows `RigSnack` "Payment removed" with action "Undo" that re-inserts the same item in the parent's list through the same `onChanged` callback (UI-level undo in local form state only, no data call; see logic note: persistence still happens on bill Save).

### 4.2 Payment dialog (compact: bottom sheet; medium and expanded: dialog)

Per DESIGN_SYSTEM 13.4 this is a 5 to 6 field form with Save, so on compact it opens as a full-height `RigSheet` (title "Add payment"/"Edit payment", Save pinned in the sheet footer); on expanded it is a `RigDialogShell` max width 480. Field order unchanged:

1. Amount (Rs): `AmountField`, autofocus, `textInputAction.next`, decimal keyboard, same filter.
2. Mode (side bore only): `RigSegmented` Cash / PhonePe.
3. Date: `RigDateField` (themed `pickRigDate`, 2000-2100 kept).
4. Received by: `RigDropdownField<String>` same items; helper line only when a receiver or a book is selected; "New receiver" last item with `Icons.add_rounded` in `primary`.
5. PhonePe payer name (PhonePe only): `RigTextField` with an options panel capped at 5 rows (240 dp), `words`.
6. Note (optional): `RigTextField`, `done`, Enter submits.

Errors: Amount error under the Amount field only (`negative`); a separate `ErrorBanner` slot at the top of the sheet for `addBook` errors. Buttons: Cancel (text), Save (filled, min 48). Enter on desktop submits when focus is not in a multi-line field; Esc cancels.

Earlier received dialog: `RigDialogShell` max 400, same fields, helper `bodySmall`.

### 4.3 Widths

| Width | Behavior |
|---|---|
| Compact (<600) | Card full width of the form column; dialog as bottom `RigSheet` |
| Medium (600-900) | Card inside the 640 column; dialog as `RigDialogShell` 480 |
| Expanded (>900) | Same as medium; hover `surfaceContainerHigh` on payment rows; right-click a row shows Edit and Remove (same two actions as tap and the trash button) |

### 4.4 Tokens and components

Spacing `s4`/`s2`, radius `lg` card, `md` fields, type `titleSmall`, `bodyLarge`, `bodySmall`, `amountMedium`, `amountLarge`. Color roles: `moneyIn`, `negative`, `onSurfaceVariant`, `surfaceContainer`, `outlineVariant`. Components: `RigCard`, `RigListRow`, `AmountText`, `AmountField`, `RigDateField`, `RigDropdownField`, `RigTextField`, `RigSegmented`, `RigSheet`, `RigDialogShell`, `RigSnack`, `ErrorBanner`, `EmptyState`-lite (inline).

### 4.5 State table

| State | Rule |
|---|---|
| Default | rows in list order as today (new payments are appended at the end; order unchanged) |
| Empty | "No payments yet" plus tonal Add button |
| Loading | none (local) |
| Error (dialog) | Amount invalid: 'Enter an amount' under the field; book add error in the banner |
| Disabled | Save disabled never; Add payment never disabled |
| Hover (desktop) | row `surfaceContainerHigh`, trash icon fully opaque |
| Focus | 2 px `primary` ring on rows and buttons |
| Linked-receiver deleted | receiver text "Deleted book" in `negative` with `Icons.warning_amber_rounded` |

### 4.6 Motion

Row insert/remove: `AnimatedList`-free: use `AnimatedSwitcher` fade 150 ms on the Total Received value; sheet entrance 300 ms `curveEnter`; undo snackbar 4 s.

## 5. Logic touchpoints that must stay untouched

- `PaymentLogEditor` constructor and callbacks: `payments`, `baseCash`, `basePhonePe`, `allowPhonePe`, `onChanged(List<LedgerPayment>)`, `onBaseChanged(double cash, double phonePe)`.
- `total` getter: `baseCash + basePhonePe + LedgerPayment.totalCash + LedgerPayment.totalPhonePe`.
- `showPaymentDialog({initial, allowPhonePe})` returns `LedgerPayment?`; `_save` rules: amount must parse and be > 0 else 'Enter an amount'; amount rounded `(amount * 100).round() / 100`; mode is PhonePe only if `allowPhonePe && _mode == modePhonePe`; `payerName` only for PhonePe and non-empty after trim; `notes` null when empty; `id` reuses `initial.id` else new UUID v4; `receiverBookId` null for "No receiver" (value `''`); sentinel `'__new__'`; `validReceiver` falls back to `''`.
- Date change keeps the previous hour and minute (lines 388-389).
- `_newReceiver`: `showCashTextPrompt` then `cashBooksProvider.notifier.addBook(name: name, kind: 1)`; on success set `_receiverId`; `kind: 1` marks a receiver.
- Receiver sort: receivers first, then name case-insensitive. Receiver label: `isReceiver ? name : '<name> (book)'`.
- Base dialog returns `(double.tryParse(cash) ?? 0, double.tryParse(pe) ?? 0)` and the editor passes `allowPhonePe ? pe : 0`.
- `phonePeNamesProvider` as the payer suggestion source; `_money`/`_dateFmt` are display only.
- Dialogs own and dispose their controllers (MEMORY.md gotcha): keep that in the redesigned sheet and dialog State classes.
- Linked Income entries are created, updated or trashed by `PaymentLinkService` on bill save, not here; removing a row here must still only edit the local list.

## 6. Acceptance criteria

1. Adding a cash payment (any amount > 0) appends one row and increases Total Received by exactly that amount; the parent Balance updates.
2. Amount 0, empty or "." blocks Save and shows 'Enter an amount' under Amount only.
3. Main bore never shows the mode selector or payer field; side bore shows both, and the payer field only for PhonePe.
4. Choosing "New receiver" creates a book (receiver) and selects it; a duplicate-name error appears in the banner, not under Amount.
5. Editing a payment keeps its id; saving the bill keeps the receiver link behavior unchanged (parity with PaymentLinkService tests).
6. Removing a payment shows an Undo snackbar for 4 s; Undo restores the same payment at the same index; no data call is made by the editor.
7. Rows align amounts to the right edge, tabular, at 100, 130 and 200 percent text scale without overflow.
8. Row, trash button and Add button hit areas are at least 48 x 48 dp.
9. Receiver name is never truncated before date: on 360 dp it ellipsizes after the receiver, not before it.
10. Enter saves the dialog on desktop when the Note field has focus; Esc cancels.
11. "Earlier received" appears only when base > 0 and edits only the base amounts (cash only on main bore).
12. No hard-coded colors or Rs strings in the file; all through `RigFormat` and tokens.
13. Keyboard focus inside the dialog is trapped and returns to the "Add payment" button on close.

## 7. Performance notes

- `_PaymentDialog` watches `cashBooksProvider` and `phonePeNamesProvider` in `build`; `phonePeNamesProvider` rebuilds over the whole ledger list. Use `ref.watch(provider.select(...))`-style narrowing or read once in `initState` (the lists cannot change while a modal sheet is open except through "New receiver", which already goes through `cashBooksProvider`).
- `_money` and `_dateFmt` are top-level `final`s (good); keep them as `RigFormat` statics.
- `PaymentLogEditor` is rebuilt on every parent keystroke because the parent `setState` runs per keystroke; make it `const`-friendly by passing only `payments` (immutable list identity) and let it skip rebuild when `identical`. It is a `ConsumerWidget` that only needs `cashBooksProvider` for names; narrow with `select` to a `Map<String,String>` of id to name.
- Payment lists are short (under 20): `Column` of rows is fine, no builder.
- Controllers are in State and disposed; `_BaseDialog` the same.


## Reconciliation 2026-10-13 (Apple look, Android only)

Mockup source: `payLog`, `earlyDlg`, `payDlg`, `payDlgRender`, `savePay`, `grp`, `ri`, `fld` in `docs/design/mockup/rigledger_apple_mockup.html`. Dropped from sections 1 to 7: macOS and expanded widths (4.3 Expanded row, right-click menu, hover, `RigDialogShell` 480 and 400, Enter and Esc, focus trap), the bordered success-tinted card, `ListTile` rows, `RigSheet` as a full-height sheet (the mockup uses a content-height sheet).

### R1. Mockup screens and Flutter mapping

| Mockup screen (J label) | Render function | Flutter file | Widgets | Notes |
|---|---|---|---|---|
| Main Bore - Edit Entry (Payments block) | `payLog(false)` | `lib/features/ledger_form/widgets/payment_log_editor.dart` | RigGroup, RigRow (payment rows), RigRow ("Add payment"), footer line | cash only |
| Side Bore - Edit Entry (Payments block) | `payLog(true)` | same | same | mode and payer available |
| Add payment dialog | `payDlg`, `payDlgRender`, `savePay` | `payment_log_editor.dart` (`showPaymentDialog`, `_PaymentDialog`) | RigSheet "Add payment" / "Edit payment", RigGroup of RigFormRow, RigSegmented (Cash, PhonePe), RigButton pill "Save" | content-height sheet, `isScrollControlled: true` |
| (inside Add payment dialog, not a J entry) Earlier received | `earlyDlg` | `payment_log_editor.dart` (`_BaseDialog`) | RigSheet "Earlier received", RigFormRow Cash (and PhonePe on side bore), pill "Save" | footer "Amount received before payments were logged. It has no receiver." |
| (inside Add payment dialog, not a J entry) New receiver | `savePay` branch `__new` | `payment_log_editor.dart` (`_newReceiver`) | RigSheet "New receiver", RigFormRow Name, pill "Add" | footer "Creates a book in Account Ledger." |

### R2. What changes in the redesign (supersedes section 4)

Editor block (REPLACES 4.1): inside the form it is a "Payments" section title (13, 600, `lb2`) and one `RigGroup` (radius 20, hairline separators inset 16, no border, no tint). Rows, top to bottom:
1. "Earlier received" row (only when base amounts are above zero, or in edit mode with no logged payments): title "Earlier received" (17, 600), subtitle "Before payments were logged, no receiver" (13, `lb2`), value right (`MoneyText`, `moneyInText`), chevron; tap opens the Earlier received sheet.
2. One row per payment, in list order (new payments appended at the end, unchanged): title line `₹amount` (17, 700, `MoneyText`, full value scaled to 75 percent, never compact) followed by the mode in `lb2` ("Cash" or "PhonePe"); subtitle (13, `lb2`, wraps, up to 2 lines): `dFull(date)` | receiver name or "No receiver" | "from <payer>" when present | note when present (the receiver comes before the payer so it is not the part that gets cut). The row body is the tap target for Edit (kept from today; the mockup draws no tap); a separate trailing delete button (`delete_outline` 22 dp, `moneyOutText`, 48 x 48 dp hit area, 8 dp gap from the row body, tooltip "Remove payment").
3. When there are no rows: a muted row "No payments yet" (`lb2`).
4. Last row always: "Add payment" (`add_circle` 22 dp `accent` leading, text 17/600 `accentText`), 48 dp.
Footer under the group: "Total received" + value (`moneyInText`, bold, `MoneyText`), 13 dp label. Receiver deleted: the receiver text becomes "Deleted book" in `moneyOutText` with a `warning_amber_rounded` 16 dp icon (kept from 4.5).
Semantics: each payment row is one node "<mode> <amount> on <date> received by <receiver>"; delete button "Remove payment".

Remove (4.1 last line KEPT, mockup differs, conflicts_r1.md C10): the trash button removes the row from the form's local list at once and shows RigSnack "Payment removed" with an "Undo" action for 4 s that re-inserts the same item at the same index through the same `onChanged` callback. This is in-memory form state only (no data call; persistence still happens on bill Save), so it is not LR-06.

Payment sheet (REPLACES 4.2): `RigSheet` titled "Add payment" or "Edit payment" (grabber, 28 dp top radius, close button left, 48 dp), body is one RigGroup of RigFormRows in the existing order, then a footer line "Payments with a receiver also appear as Income in that receiver book." (13, `lb2`), then the pinned pill "Save" (50 dp, `accentButton`) in the sheet footer above the keyboard:
1. Amount (₹ prefix, hint "0", decimal keyboard, same filter, autofocus, `textInputAction.next`).
2. Mode (side bore only): `RigSegmented` Cash | PhonePe, max 200 dp, right aligned in the row.
3. Date: read-only value `dFull` with `calendar_today` 18 dp icon; tap opens the date picker (range 2000 to 2100 kept, `initialDate` clamped; keeps the previous hour and minute).
4. Received by: row with the selected name; tap opens a `RigSheet` "Received by" listing "No receiver", receiver books first then other books (suffix "(book)", sorted by name), a check on the current one, and last "New receiver..." (`add` icon in `accentText`). The mockup uses a native select; the list content, order and values are unchanged.
5. Payer name (PhonePe only): row with the existing autocomplete; options panel RigCard level 3, at most 5 rows (240 dp), words capitalization.
6. Note (optional, hint "Optional", `done`, submits).
Errors: an empty or zero amount shows 'Enter an amount' as a 13 dp `moneyOutText` line under the Amount row only and the sheet stays open (the mockup shows a snackbar instead, C11); a book-add error (existing name) is shown in an `ErrorBanner` at the top of the New receiver sheet, never under Amount.
Earlier received sheet: rows Cash (and PhonePe when `allowPhonePe`), footer text as above, pill "Save".
New receiver sheet: Name row (hint "Receiver name", words, autofocus), footer "Creates a book in Account Ledger.", pill "Add". After success the Received by value is the new book and the payment sheet is shown again with its entered values kept.
Android back inside sheets closes the keyboard first, then the top sheet; dismissing the payment sheet discards the entered values (unchanged, not part of LR-25).

States:

| State | Rule |
|---|---|
| Default | rows in list order, Total received below |
| Empty | "No payments yet" row plus the "Add payment" row |
| Loading | none (local) |
| Error (sheet) | 'Enter an amount' under Amount; book-add error in the banner |
| Disabled | none; Save and Add payment are never disabled |
| Pressed | ink overlay on rows and the pill |
| Linked receiver deleted | "Deleted book" in `moneyOutText` with a warning icon |

Old section 4 mapping: 4.1 card CHANGED (RigGroup, trailing delete, footer, Undo KEPT); 4.2 dialog CHANGED (content-height RigSheet on every width, dialog variant DROPPED, pill instead of text buttons); 4.3 widths DROPPED except compact; 4.4 tokens CHANGED; 4.5 states CHANGED; 4.6 motion: sheet rise 300 ms ease-out, Total received value `AnimatedSwitcher` 150 ms, Undo snackbar 4 s, ink press, instant under reduced motion.

### R3. Logic touchpoints and LR items

Untouched: all of section 5 above: constructor and callbacks (`payments`, `baseCash`, `basePhonePe`, `allowPhonePe`, `onChanged`, `onBaseChanged`), `total` getter, `showPaymentDialog` result and `_save` rules (amount rounding, mode rule, payer rule, notes null, id reuse, `receiverBookId` null for "No receiver", sentinel `'__new__'`), date keeps the time, `_newReceiver` with `kind: 1`, receiver sort and label, base dialog result, `phonePeNamesProvider`, dialogs own and dispose their controllers, linked Income entries are created by `PaymentLinkService` on bill save only.

| Item | Status |
|---|---|
| LR-24 rupee sign (replaces concatenated `Rs`) | approved |
| LR-25 discard prompt (applies to the bill form, not to these sheets) | approved for forms only |
| LR-06 undo after delete of bills and payments | not scheduled; the local Undo here is form state only |
| LR-32 double-tap guard | applies to the sheet Save pill too (`_saving`), approved |
| Proposed, new | none |

### R4. Acceptance criteria delta

REPLACES 6 items 6, 7, 8, 10, 13; ADDS the rest. 360 and 412 dp, light and dark, text scale 100, 130, 200 percent, keyboard open.
1. Adding a cash payment with amount above zero appends one row and raises Total received by exactly that amount; the form Balance and the live card update.
2. Amount 0, empty or "." blocks Save and shows 'Enter an amount' under Amount only; no snackbar.
3. Main bore never shows Mode or Payer; side bore shows Mode, and Payer only for PhonePe.
4. "New receiver" opens its own sheet, creates a receiver book and returns to the payment sheet with it selected and the other fields intact; a duplicate name shows the error in the banner.
5. Removing a payment shows "Payment removed" with Undo for 4 s; Undo restores the same payment at the same index; no data call is made by the editor.
6. Amounts are right aligned, tabular, full values at 100 and 130 percent and scaled to 75 percent then 11 sp at 200 percent, never compact; the receiver name is never cut before the date.
7. The row body, the delete button and the Add payment row each have a 48 x 48 dp hit area, with the delete button separated from the row body.
8. With the keyboard open the Save pill stays above it and the focused row is visible; first Android back closes the keyboard, the second closes the sheet.
9. Earlier received appears only when base is above zero or in edit mode with no payments, and edits only the base amounts (cash only on main bore).
10. Editing a payment keeps its id; saving the bill keeps the receiver link behaviour (PaymentLinkService tests unchanged).
11. No `Rs` string and no raw colour in the file; money through `RigFormat`, dates through `dFull`.

### R5. Parity delta

Changed on purpose: P-PL-03 (inline message, no snackbar, wording unchanged), P-PL-08 (removal shows an Undo snackbar), P-PL-02 look (sheet, same field order), receiver pick is a list sheet instead of a dropdown, "Rs" becomes the rupee sign, macOS lines DROPPED.
Identical: P-PL-01, P-PL-04 (1,234.567 saves 1,234.57), P-PL-05 (receiver list order and "(book)" suffix), P-PL-06, P-PL-07 (same id), P-PL-09, P-PL-10, P-PL-11.

### R6. Performance and Android notes

- `_PaymentDialog` reads `cashBooksProvider` and `phonePeNamesProvider` once in `initState` or with `select` (the lists cannot change while the sheet is open except through New receiver, which goes through `cashBooksProvider`).
- `PaymentLogEditor` takes the immutable payments list and a `Map<String,String>` of book id to name (`select`), and skips rebuild when identical; payment lists are short (under 20), a `Column` of rows, no builder.
- Sheets: `isScrollControlled: true`, bottom padding `viewInsetsOf.bottom`, pill above the keyboard, `viewPaddingOf.bottom` when the keyboard is closed.
- Controllers live in each sheet State and are disposed there (never right after `await showModalBottomSheet`, MEMORY.md gotcha); the base and New receiver sheets the same.
- Formatters are `RigFormat` statics; no blur on the scrim (plain `scrim`).
