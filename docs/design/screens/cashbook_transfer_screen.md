> SUPERSEDED IN PART (2026-10-13): the look is now the Apple-inspired Android direction. Read "Reconciliation 2026-10-13" at the end of this file first; where it conflicts with sections 4 to 7 above, it wins.
# cashbook_transfer_screen.dart (Transfer)

Group g2. Source: lib/features/cashbook/cashbook_transfer_screen.dart (166 lines).

## 1. Purpose and primary user task

Move money between two books: one Expense entry in the From book and one Income entry in the To book, linked by a transfer group. The form stays open and clears after a transfer so several transfers can be entered. Parity: PARITY-057..060.

## 2. Current structure

`CashbookTransferScreen` (ConsumerStatefulWidget, transfer:9). Local state: `_amount`, `_notes` controllers (disposed, transfer:36-40), `_from`, `_to` (book ids, defaults: current book and the first other book, transfer:26-33), `_date`.
Tree: `Scaffold(appBar: cashAppBar('Transfer'))` > `CashPageBody(600)` > `SingleChildScrollView(16)` > `Card(16)` > `Column[amount TextField (prefix "Rs. "), From dropdown, To dropdown, Row[CashDateField (flex 3), time InkWell+InputDecorator (flex 2)], Notes (1 to 3 lines), full-width ElevatedButton 'Transfer' (primary)]`.
`_transfer` (51-74): empty amount or missing book does nothing (PARITY-060); calls `cashEntriesProvider.notifier.transfer(fromBookId, toBookId, amount, date, notes)`; `(ok, error)`; on failure error snackbar (default text 'Transfer failed'); on success clears amount and notes, resets `_date` to now, snackbar 'Transferred'.
State sources: `cashBooksProvider` (watch), `cashSettingsProvider` (watch, formatDate/formatTime), `currentCashBookProvider` (read once in initState), `cashEntriesProvider.notifier.transfer`.

## 3. Problems found

1. No busy flag: double tap can send two transfers (transfer:51-74, 149-157) (G2-B05).
2. Empty amount does nothing and says nothing (PARITY-060 requires no action; no visual cue either) (transfer:54).
3. From and To can be the same book; the provider refuses with an error snackbar (the "To" list does not exclude the From book) (transfer:85-88). Swap control missing.
4. Time picker ignores the 12/24 hour setting (transfer:43-45) (G2-B15).
5. `Card` with default elevation and `AppColors.primary` button override (transfer:99, 152-153); the button is the generic ElevatedButton with no icon; labels "From" and "To" lack icons.
6. Date and time are two different widgets (`CashDateField` vs `InputDecorator`) at flex 3:2 (transfer:117-140): no labels, 20 px suffix icons.
7. No `textInputAction`; Enter in Amount does not move on; amount is not auto-focused on open (transfer:104-111).
8. Success feedback is a default snackbar 'Transferred' with no amount or books in the text; the form clears at once so users cannot verify what was sent.
9. Fixed `CashPageBody(maxWidth: 600)` only on desktop.
10. Dropdown menus use `DropdownButtonFormField` default styling, items are book names only (no balance).

## 4. Redesign

Layout: `RigScaffold(appBar: RigAppBar(title: 'Transfer'), maxContentWidth: 640)`; page padding `s4` (compact) / `s6` (medium and expanded). One `RigCard` (level 1, radius `lg`, padding `s4`) with fields spaced `s3`; below it a pinned `FormActionBar` (SafeArea) with one filled button "Transfer" (`Icons.swap_horiz_rounded`, min 48).

Field order unchanged: Amount, From, To, Date and Time, Notes.
- Amount: `AmountField` label "Amount" with the symbol prefix (L-02), `amountLarge` style, autofocus, `textInputAction: next`, decimal keyboard, `AmountInputFormatter`.
- From and To: `RigDropdownField` with the book name as `bodyLarge`, label "From" / "To", menu capped at 320 high on desktop. Between them a centered `IconButton(Icons.swap_vert_rounded)` tooltip "Swap" that exchanges the two selections locally (UI only). The To list hides the book chosen in From (UI filtering only; if no other book exists the dropdown is disabled and a helper line says "Add another account to transfer", `bodySmall` `onSurfaceVariant`).
- Date: `RigDateField` label "Date"; Time: `RigTimeField` label "Time" applying `settings.use24Hour`. Compact (<400): stack; otherwise Row 60/40.
- Notes: `RigTextField` label "Notes", 1 to 3 lines, `textInputAction: done`.
- Success: `showRigSnack(success, 'Transferred')` (text unchanged); the form clears exactly as today and focus returns to Amount.
- Empty amount: field error "Enter an amount" appears (visual only; no provider call, parity-060 preserved). Q5 covers whether this helper is acceptable.

Desktop: max width 640, Cmd+Enter submits, Esc goes back, Tab order top to bottom, focus ring 2 px `primary`.

Tokens: radius `md` fields, `lg` card; type `bodyLarge` fields, `labelLarge` button; colors `primary` button, `onSurfaceVariant` helper, `negative` error text.

State table:

| State | Rule |
|---|---|
| Default | form filled with current book as From |
| Loading | button shows 24 dp indicator, fields disabled while `_busy` (new local flag) |
| Empty | only one book: To disabled with helper |
| Error | provider error string in `showRigSnack(error)` (default text 'Transfer failed') |
| Disabled | Transfer button disabled while busy |

Motion: success snackbar `base`; swap icon rotates 180 degrees in `fast`.

## 5. Logic touchpoints that must stay untouched

- `cashEntriesProvider.notifier.transfer(fromBookId:, toBookId:, amount:, date:, notes:)` and its `(ok, error)` result; notes format and linked-pair creation (PARITY-058) are provider-side.
- Empty amount or null books: return without calling (transfer:54).
- After success: clear `_amount`, `_notes`, reset `_date` to now (PARITY-059); the form stays open.
- Default `_from` (current book else first) and `_to` (first other book) in `initState`.
- `_amount`, `_notes` controllers disposed in `dispose`.
- Same-book transfer is refused by the provider (error string unchanged).

## 6. Acceptance criteria

1. Transfer of 500 from Book A to Book B creates an Expense of 500 in A noted "To <B>" and an Income of 500 in B noted "From <A>" (plus user notes after a newline); both balances change by 500.
2. Empty amount: nothing is created, no navigation; the field shows the helper.
3. Same book in both fields is impossible to select from the UI; if forced, the provider error appears in a snackbar.
4. After success the form clears and the amount field has focus; the date resets to now.
5. Double activation (double tap or double Enter) creates only one pair.
6. Time field follows the Account Ledger 12/24 hour setting.
7. Layout has no overflow at 360 dp width and 200 percent text scale; all controls >= 48 dp.
8. Swap exchanges From and To selections.

## 7. Performance notes

- Small screen; `ref.watch(cashBooksProvider)` rebuilds when books change only; wrap dropdown fields in a `Consumer` if the amount field typing causes dropdown rebuilds (it does not today).
- `picker(...)` is a local function that builds a new `DropdownButtonFormField` per build; extract `_BookDropdown` as a const-constructible widget.
- Controllers State-owned and disposed (transfer:36-40); no per-frame setState.


## Reconciliation 2026-10-13 (Apple look, Android only)

### R1. Mockup screens and Flutter mapping

| Mockup screen (J registry) | Mockup render function | Flutter file | Widgets | Notes |
|---|---|---|---|---|
| Transfer | `SC.cbTransfer` | lib/features/cashbook/cashbook_transfer_screen.dart | LargeTitleScaffold (pushed, title "Transfer"), RigGroup of RigFormRows (Amount with rupee prefix, From and To selectors, Date, Time, Notes), pinned RigButton "Transfer", UnsavedChangesGuard | Mockup has no swap button and no "Transfer" success text beyond the snackbar "Transferred". |

### R2. What changes in the redesign (supersedes section 4)

Transfer (pushed from the drawer):
1. LargeTitleScaffold, title "Transfer", back chevron at left.
2. RigGroup 1: Amount row (label left, value right, rupee prefix, hint "0", decimal keyboard, `AmountInputFormatter`).
3. RigGroup 2: From and To RigFormRows with a selector sheet each (RigSheet listing the books with a check mark on the current one); From defaults to the current book, To to the first other book (unchanged).
4. RigGroup 3: Date row (`dFull`, opens the DatePickerSheet) and Time row (12 or 24 hour, opens the time picker).
5. RigGroup 4: Notes row (multi-line, hint "Optional").
6. Pinned bottom RigButton "Transfer" (50 dp pill, `accentButton`), above the keyboard and the inset; content bottom padding inset + 110 dp. A `_busy` flag disables the button and shows a 20 dp spinner while the transfer runs (LR-32 guard).
7. Discard prompt (LR-25): when amount or notes hold text, or the selections or date differ from their opening values, the back button and Android back show RigAlertDialog "Discard changes?" (Keep Editing default, Discard in `moneyOutText`). A clean form closes at once. After a successful transfer the form clears and is clean again.
8. Success: RigSnack "Transferred" (text unchanged); the form stays open as today.


Old section 4 items:

- Old 4 layout (RigScaffold, max width 640, one RigCard): CHANGED to four RigGroups and the pinned pill.
- Old amount `AmountField` with `amountLarge` style: CHANGED to a normal form row (the big amount style is only on the entry form); the symbol is the rupee sign (LR-24).
- Old swap button between From and To (rotate animation): DROPPED. The mockup does not show it; a local swap would be harmless UI-only, so it may be added later without an LR if the developer asks.
- Old Date and Time as a Row 60/40 and `RigTimeField`: CHANGED to two form rows.
- Old field error "Enter an amount" (visual only): KEPT as a row error text; no provider call, PARITY-060 preserved.
- Old desktop paragraph (Cmd+Enter, Esc, Tab order): DROPPED.
- Old state table: KEPT; Empty (only one book: To disabled with helper) KEPT.


States:

| State | Rule in the new look |
|---|---|
| Default | filled with the current book as From |
| Loading | Transfer pill with a 20 dp spinner; rows disabled while `_busy` |
| Empty | only one book: To row disabled with the helper "Add another account" (new copy) |
| Error | provider error string in RigSnack (default "Transfer failed") |
| Disabled | pill disabled while busy |
| Dirty | back raises the discard alert |


Motion: ink press on rows and the pill; sheet rise 250 ms ease-out; snackbar 200 ms; reduced motion removes durations.


### R3. Logic touchpoints and LR items

Untouched: `cashEntriesProvider.notifier.transfer(fromBookId:, toBookId:, amount:, date:, notes:)` and its `(ok, error)` result, notes format and linked pair creation, empty amount or null books returns without calling, clear after success, default From and To, same-book refusal by the provider, State-owned controllers.


- LR-25 (approved): discard prompt on the Transfer form (named in the LR).
- LR-32 (approved, Phase 1): double-tap guard on Transfer.
- LR-24 (approved): rupee sign prefix and `d MMM yyyy` default.
- No new logic item.


### R4. Acceptance criteria delta

1. Typing an amount then pressing back or Android back shows "Discard changes?"; an untouched form closes silently; after a successful transfer back closes without a prompt.
2. Double tap or double Enter on Transfer creates exactly one linked pair.
3. Transfer of 500 from A to B creates an Expense in A noted "To <B>" and an Income in B noted "From <A>"; both balances change by 500.
4. Empty amount creates nothing and shows the row error; the form does not close.
5. The pinned pill is above the keyboard at 360 dp; From, To, Date, Time and Notes stay reachable at text scale 200 percent.
6. Light and dark; targets at least 48 dp; selectors list every book once with a check mark on the selected one.


### R5. Parity delta

Change on purpose:

- PARITY-060 (empty amount): a row error text is shown in addition to doing nothing (already specified in section 4; stays).
- New: discard prompt when dirty (LR-25); PARITY lines 057 to 059 are unchanged.
- PARITY-035 and 084: the amount prefix shows the rupee sign.


Must stay identical:

- PARITY-057 to 059: linked pair, notes format, same-book refusal, the form clears and stays open after success.


### R6. Performance and Android notes

- Edge to edge: status bar transparent; bottom inset from `MediaQuery.viewPaddingOf(context).bottom`. Pushed screens have no floating tab bar; content ends at inset + 24 dp, or inset + 110 dp when a pinned bottom pill is present.
- Keyboard: `resizeToAvoidBottomInset: true`; a pinned bottom pill sits above the keyboard; sheets add `MediaQuery.viewInsetsOf(context).bottom`; the focused field scrolls to the centre.
- PopScope with `UnsavedChangesGuard`; dirty from `_amount.text`, `_notes.text`, selections and date versus the initial values via a `ValueNotifier<bool>`.
- Controllers: `_amount` and `_notes` are State-owned and disposed (verified, transfer 19-39).
- Use `ValueListenableBuilder` for the busy button state; no full-screen `setState`.

