> SUPERSEDED IN PART (2026-10-13): the look is now the Apple-inspired Android direction. Read "Reconciliation 2026-10-13" at the end of this file first; where it conflicts with sections 4 to 7 above, it wins.
# widgets/cashbook_common.dart and widgets/cashbook_period_selector.dart (shared Account Ledger helpers)

Group g2. Sources: lib/features/cashbook/widgets/cashbook_common.dart (329 lines) and widgets/cashbook_period_selector.dart (83 lines). These are not screens; they are the shared helpers every Account Ledger screen imports. They share one doc because their redesign is the mapping to shared components. The other four widget files are documented in cashbook_home_screen.md (header, period_bar, row, totals_strip).

## 1. Purpose and primary user task

Provide the app bar builder, page width wrapper, amount input formatter and parser, snackbar and confirm helpers, sign toggle, date field, date range dialog and single-field text prompt used by all Account Ledger screens; and the period selector (tabs, period bar, range button) used by Summary, Account Summary, Transaction-All and Notebook.

## 2. Current structure

`cashbook_common.dart`:
- `CashColors` (lines 8-13): income #059669, expense #DC2626, balance = `AppColors.primary`.
- `cashAppBar(title, actions, bottom)` (16-46): `AppBar` with gradient flexible space on mobile, white surface and bottom border on desktop.
- `CashPageBody` (49-64): centers and constrains to `maxWidth` (default 900) only when `PlatformHelper.isDesktop`.
- `AmountInputFormatter` (67-89) and `parseAmount` (92-96): digits and one dot only; strips commas.
- `showCashSnack` (98-103): `SnackBar` red when `error`.
- `confirmCashDialog` (106-130): `AlertDialog` with Cancel (text) and confirm (text, always `AppColors.error`).
- `CashSignToggle` (133-151): `SegmentedButton<bool>` "+ Income" / "- Expense".
- `CashDateField` (154-188): `InkWell` + `InputDecorator` (suffix `Icons.calendar_today`), `showDatePicker` 2000-2100, keeps time of day.
- `pickCashDateRange` (192-243): `StatefulBuilder` `AlertDialog` "Select Date Range", two `CashDateField`s; swaps if end < start; returns half-open `CashDateRange(a, b + 1 day)`. Local `start`/`end` are plain variables inside the builder, no controllers.
- `showCashTextPrompt` + `_TextPromptDialog` (249-329): controller owned by State and disposed in `dispose` (correct, the MEMORY.md gotcha is respected).

`cashbook_period_selector.dart`:
- `CashPeriodSel` (9-36): immutable (period, anchor, custom); `range`, `label` (uses `CashbookCalculator.rangeLabel`), `canShift`, `withPeriod`, `shifted`, `withCustom`, `query(bookId)`.
- `CashPeriodSelector` (39-83): Row of `CashbookPeriodTabs` + `IconButton(Icons.date_range)` and `CashbookPeriodBar`.

State sources: none (pure helpers); `PlatformHelper.isDesktop`.

Controller audit (brief item 4): `showCashTextPrompt` owns its controller in State (correct). `pickCashDateRange` has no controllers. No dialog in these two files creates a controller outside State or disposes after `await showDialog`. Full audit of the feature is in the final report and bugs_g2.md (see section "Controller audit" at the end of this file).

## 3. Problems found

1. `cashAppBar` desktop and mobile variants, title sizes and white colors are hard-coded (common:23-45); `PopupMenuButton` icons in actions need manual `iconColor` (entry form:340-341).
2. `CashPageBody` ignores tablets (common:56) and uses widths 600, 700, 800, 900 per screen.
3. `showCashSnack` no duration, not floating, error uses `AppColors.error` with default white text (3.76:1) (common:98-103).
4. `confirmCashDialog` always shows the confirm label in error red and Cancel/confirm have equal weight; destructive action is not distinguished from "Import" (common:121-125). Dialog shape and width are defaults (no 400 max width).
5. `CashSignToggle` labels "+ Income" and "- Expense" read as math signs, no semantics (common:143-144). Default `SegmentedButton` height 40 < 48 on touch.
6. `CashDateField` has no label, icon is the filled `calendar_today` (common:182), `InkWell` radius hard-coded 12, `firstDate/lastDate` 2000-2100 duplicated in the entry form (form:392-397) and home (`_pickDay`, home:65-70).
7. `pickCashDateRange` dialog: Start and End are `Text` labels above fields, end date is not constrained to be >= start in the UI (it silently swaps at the end, common:237-241); default start and end are both today; no preview of the resulting range; the dialog stacks two pickers (tap field, then picker) so a range takes 4 taps minimum. No keyboard entry.
8. `showCashTextPrompt`: `onSubmitted` closes with the text, even for the multi-line (maxLines 4) reporter name where Enter should insert a newline (common:317). With `maxLines > 1`, `onSubmitted` does not fire for the Enter key on mobile, so only the button submits; on desktop Enter in a multi-line field inserts a newline (fine).
9. `CashPeriodSelector`: the date-range icon is a bare `IconButton` after the chip row, 48 dp wide, which reduces the chip row width to about 280 dp on a 360 dp phone, so the chips clip sooner (selector:57-74). Label cannot be tapped.
10. `CashPeriodSel.label` shows "All" or the ASCII-arrow range (selector:21-22): the same inconsistency as the home screen (see cashbook_home_screen.md problem 6).
11. `CashColors.income` white-on-green contrast (3.77:1) problem propagates to every user (see cashbook_home_screen.md).

## 4. Redesign

Mapping (no new behavior):

| Today | Redesign |
|---|---|
| `cashAppBar(title, actions, bottom)` | `RigAppBar(title, actions, bottom)` inside `RigScaffold`; same signature kept for migration, forwarding to `RigAppBar` |
| `CashPageBody(maxWidth)` | `RigScaffold.maxContentWidth`: 640 for forms and lists on medium, 1100 for dashboards on expanded; applies on every platform, not only desktop |
| `CashColors.income/expense/balance` | `context.rig.moneyIn`, `context.rig.negative`, `colorScheme.primary` |
| `showCashSnack(context, msg, error:)` | `showRigSnack(context, msg, kind: error ? error : success)`; floating, radius `sm`, `inverseSurface`, 4 s, leading icon 20 (`Icons.check_circle_rounded` or `Icons.error_rounded`) |
| `confirmCashDialog` | `ConfirmDialog(title, message, confirmLabel, destructive)`, width max 400, radius `xl`, Cancel left (text button, not default focus), confirm right: `negative` text when destructive, `primary` when not (Import) |
| `CashSignToggle` | `RigSegmented<bool>` min height 48 (40 pointer), labels "Income" and "Expense" with icons `Icons.add_rounded` and `Icons.remove_rounded`; selected Income uses `moneyInContainer`/`moneyIn`, Expense `negativeContainer`/`negative`. Semantics label "Balance is income" / "Balance is expense" for the opening balance dialog. Text of the label stays "+ Income" and "- Expense" only if the developer wants exact copy parity (Q3); default is the icon plus word form |
| `CashDateField` | `RigDateField(label, value, first: 2000, last: 2100)` with trailing `Icons.calendar_month_rounded` 20; keeps hour/minute/second of the original value (callback contract unchanged) |
| `pickCashDateRange` | `RigDialogShell` titled "Select Date Range" (max width 400): two `RigDateField`s labeled "Start Date" and "End Date" stacked (compact) or side by side (>=600); helper line `bodySmall` `onSurfaceVariant` showing the resulting range "12 Oct 2026 - 18 Oct 2026" with the user's date format; End field `first` is not changed (silent swap stays) but a hint appears when end < start: "Dates will be swapped"; actions Cancel (text), OK (filled). Same return value |
| `showCashTextPrompt` | `RigDialogShell` + `RigTextField` (owned controller stays in State; add `textInputAction: done` for single-line, `newline` for multi-line); confirm button label per call |
| `CashPeriodSelector` | `RigChipRow` + trailing `IconButton(Icons.date_range_rounded)` moved into the `PeriodNavigator` row (end slot) so chips use the full width; `PeriodNavigator` as in the home doc |
| `CashPeriodSel.label` | unchanged class; the widget composes a display label from `range` with `settings.formatDate` (home doc 4.2); `label` property kept for any caller |

Layout widths: sheets and dialogs capped at 400 (confirm) and 560 (pickers); on compact `RigDialogShell` uses 16 dp horizontal inset.

Desktop: Esc closes every dialog; Enter confirms single-field dialogs (`onSubmitted`); Tab order top to bottom; the date field opens `showDatePicker` as a dialog (see accounts_daily_date_picker.md for the Daily case).

Tokens: dialog padding `s6` (24), field gap `s3` (12), action gap `s2`, field height 56, radius `md` for fields and `xl` for the dialog shell. Type: dialog title `titleMedium`, message `bodyMedium`, field text `bodyLarge`.

State table: Default; Error (`RigTextField` helper text slot reserved, no layout jump); Disabled (confirm disabled while an async call runs, where present); Loading (24 dp indicator inside the confirm button for async confirms); Empty (n/a).

Motion: dialog entrance `slow` 300 ms scale-fade (`curveEnter`); date field focus ring `fast`.

## 5. Logic touchpoints that must stay untouched

- `AmountInputFormatter` behavior (digits and single dot, never negative) and `parseAmount` (strips commas, null for empty or invalid).
- `pickCashDateRange` return contract: `CashDateRange(dateOnly(a), DateTime(b.year, b.month, b.day + 1))` with swap when end < start (common:235-242).
- `CashDateField.onChanged` keeps hour, minute, second of `value` (common:176-177).
- `confirmCashDialog` returns `false` when dismissed (`result ?? false`).
- `showCashTextPrompt` returns the trimmed text or null; controller lifetime owned by State (MEMORY.md gotcha).
- `CashPeriodSel` factories and methods (`today`, `withPeriod` resets anchor to now, `shifted`, `withCustom`, `query`), and `canShift` rule.
- `CashPeriodSelector` shows the chip "All" when `value.custom != null` (selector:62).
- `CashbookPeriodTabs.periods` limit (Account Summary passes All, Weekly, Monthly, Yearly: no Daily).

## 6. Acceptance criteria

1. Every Account Ledger page uses the same app bar, snackbar, confirm dialog and date field; none reads `CashColors` or `Colors.x`.
2. `ConfirmDialog` for Import shows "Import" in `primary`; for Delete flows in `negative`; Cancel is left and not auto-focused.
3. Date range dialog returns the same `CashDateRange` for the same inputs (parity test P-RANGE in parity_g2.md).
4. Date field: tapping opens the picker, the chosen date keeps the previous time of day, label is announced by a screen reader.
5. Snackbars last 4 s, are floating, have an icon, and no longer use #EF4444 with white text.
6. Period selector chips are not narrowed by the range icon; the icon lives in the navigator row.
7. All dialogs lay out at 200 percent text scale with the actions reachable (content scrolls).
8. Esc closes dialogs on macOS; Enter confirms the single-field prompt.

## 7. Performance notes

- `cashAppBar` creates a new gradient `Container` per call; `RigAppBar` is const-configurable.
- `CashDateField` is stateless, fine; `RigDateField` must not allocate a `DateFormat` per build (use the format string from `CashSettings.formatDate` only when the value changes).
- `pickCashDateRange` uses `StatefulBuilder` and rebuilds the full dialog on each pick (small); move to a small `StatefulWidget` (`_RangeDialog`) so the two date rows rebuild separately; no controllers needed.
- `showCashTextPrompt` is already a State-owned controller; keep it.
- `CashPageBody` rebuilds on every parent build; replaced by `RigScaffold` constraints (no per-screen wrapper).

## Controller audit (feature wide, brief item 4)

Checked every `TextEditingController` and `FocusNode` in lib/features/cashbook:
- Owned by State and disposed in `dispose`: `_searchController` (home:33-39), `_amount/_notes/_desc/_notesFocus/_amountFocus` (entry form:47-51, 85-92), `_name/_opening` (book dialogs:25-36), `_controller` (opening balance dialog:184-195), `_name/_qty/_unit/_rate` (items dialog:71-83), `_c` (text prompt dialog:297-304), transfer `_amount/_notes` (transfer:19,36-40), note form `_text` (note_form:21,25-29).
- Created outside State or disposed right after `await showDialog`: NONE found. Dialogs that use local variables instead of controllers: `pickCashDateRange` (plain DateTime variables in `StatefulBuilder`), `showCashReportAllDialog` (plain `range` and `pdf` variables, report_dialog:72-73).
- Risk to watch in the redesign: if `RigDialogShell` or `RigTextField` is adopted, the controller must stay in the dialog's State (not in the caller), as it is today.
- Note: the notes `RawAutocomplete` in the entry form receives `textEditingController: _notes` and `focusNode: _notesFocus` from State (form:475-477) and builds a fresh `TextField` in `fieldViewBuilder` using the supplied controller and focus node: correct, no leak. The old leak pattern (autocomplete listener) noted for the main bore form does not exist here.


## Reconciliation 2026-10-13 (Apple look, Android only)

### R1. Mockup screens and Flutter mapping

| Mockup screen (J registry) | Mockup render function | Flutter file | Widgets | Notes |
|---|---|---|---|---|
| Add Income form, Edit Transaction form (snackbar, confirm, date field) | `cbForm`, `SC.cbEntry`, `confirmUI`, `snack`, `datePick` | lib/features/cashbook/widgets/cashbook_common.dart | RigSnack (floating capsule), RigAlertDialog, RigSegmented (sign toggle), DatePickerSheet (B2), RigFormRow, RigSheet | Mapping of the shared helpers to the new components; no screen of its own. |
| Account Ledger date picker (B2) | `cbDatePick`, `datePick`, `datePickRender` | cashbook_common.dart (`CashDateField`), widgets/cashbook_period_selector.dart | DatePickerSheet (B2) | Spec in screens/accounts_daily_date_picker.md (group r1); only referenced here. |
| Home (All) period controls | `cbPeriodChips`, `cbPbar`, `cbRangeDlg` | widgets/cashbook_period_selector.dart (`CashPeriodSelector`) | RigChipRow (periods plus Range), period navigator, RigSheet "Select Date Range" with two RigFormRows | Used by Summary, Account Summary, Transaction-All, Notebook and Home. |
| Overflow menu (Notes search) | `cbNotesDlg`, `cbAddrDlg` | cashbook_common.dart (`showCashTextPrompt`) | RigSheet with one RigFormRow and a pinned RigButton | Controller stays in the sheet State. |

### R2. What changes in the redesign (supersedes section 4)

Mapping of the shared helpers to the new components, in the order of the old section 4 table:
- `cashAppBar(title, actions, bottom)` becomes LargeTitleScaffold (large title 34 collapsing to 17; solid 94 percent bar with hairline); the helper keeps its signature for migration and forwards to it. Gradient and desktop variants are DROPPED.
- `CashPageBody(maxWidth)` is DROPPED (single phone width, 20 dp margins); no per-screen width wrapper.
- `CashColors.income/expense/balance` become `moneyInText`, `moneyOutText` (text) and `moneyInButton`, `moneyOutButton` (filled controls, white label), `accentText` for balance.
- `showCashSnack` becomes RigSnack: floating capsule above the tab bar or pinned button, `inverse` surface, 4 s, no icon; error uses the same capsule (message text carries the meaning).
- `confirmCashDialog` becomes RigAlertDialog: radius 14, stacked 48 dp full-width buttons with hairlines, Cancel as the default (bold) action, destructive action in `moneyOutText`; the Import confirm uses `accentText` (not red).
- `CashSignToggle` becomes RigSegmented with the labels "Income" and "Expense" (plain words, 48 dp boxes, 3 px inset thumb). Disabled (linked entry) at 55 percent opacity.
- `CashDateField` becomes a RigFormRow whose value opens the DatePickerSheet (B2) instead of `showDatePicker`; the callback keeps hour, minute and second.
- `pickCashDateRange` becomes a RigSheet titled "Select Date Range" with two RigFormRows (Start date, End date, each opening the DatePickerSheet) and a pinned RigButton "OK"; the swap-if-end-before-start and half-open return contract are unchanged.
- `showCashTextPrompt` becomes a RigSheet with one multi-line RigFormRow and a pinned RigButton (label per call); the controller stays in the sheet State.
- `CashPeriodSelector` becomes RigChipRow (All, Daily, Weekly, Monthly, Yearly, Range) plus the period navigator below it; the date-range icon is replaced by the Range chip.


Old section 4 items:

- Old 4 mapping row `cashAppBar`: CHANGED (LargeTitleScaffold); desktop forwarding DROPPED.
- Old row `CashPageBody`: DROPPED (macOS widths, medium, expanded).
- Old row `CashColors`: CHANGED to the new colour roles.
- Old row `showCashSnack`: CHANGED to RigSnack; icons and 4 s kept only as duration, icons DROPPED.
- Old row `confirmCashDialog` (max 400, radius xl): CHANGED to RigAlertDialog (270 dp wide, radius 14, stacked buttons).
- Old row `CashSignToggle` with icons: CHANGED, icons DROPPED (mockup shows text only).
- Old row `CashDateField` with `RigDateField`: CHANGED to RigFormRow plus DatePickerSheet.
- Old row `pickCashDateRange` (dialog, preview line, side by side at 600): CHANGED to a sheet; the preview line and side-by-side layout are DROPPED.
- Old row `showCashTextPrompt`: CHANGED to a sheet; `textInputAction` rule (done single line, newline multi-line) KEPT.
- Old row `CashPeriodSelector`: CHANGED (Range chip replaces the trailing icon).
- Old desktop paragraph (Esc, Enter, Tab order): DROPPED. Old layout widths (400, 560, 16 dp inset): DROPPED.
- Old tokens (s6 dialog padding, xl radius, field height 56): CHANGED to alert radius 14, sheet top radius 28, form row 48 dp minimum.


States:

| State | Rule in the new look |
|---|---|
| Default | component at rest |
| Loading | pinned RigButton shows a 20 dp spinner while an async call runs (Report, Import) |
| Empty | not applicable |
| Error | RigSnack with the message text; field error text in `moneyOutText` under the row, space reserved |
| Disabled | RigButton 40 percent opacity; RigSegmented 55 percent when locked |


Motion: sheets rise 250 ms ease-out, alerts fade and scale 200 ms, RigSnack slides 200 ms; ink press only; zero duration when animations are disabled.


### R3. Logic touchpoints and LR items

Untouched: `AmountInputFormatter` and `parseAmount`, the `pickCashDateRange` return contract, `CashDateField.onChanged` keeping the time of day, `confirmCashDialog` returning false when dismissed, `showCashTextPrompt` returning trimmed text or null with a State-owned controller, `CashPeriodSel` factories and `canShift`, the All chip when a custom range is set, the period list limits.


- LR-24 (approved for the rupee sign): amount fields show the rupee sign as the prefix in place of "Rs.".
- LR-25 (approved): the shared guard `UnsavedChangesGuard` is used by the forms that import these helpers; the alert is RigAlertDialog.
- LR-02 (approved): DatePickerSheet needs `setAnchor` only on the home screen.
- No new logic item.


### R4. Acceptance criteria delta

1. Every Account Ledger page uses LargeTitleScaffold, RigSnack, RigAlertDialog and the date row; no file reads `CashColors` or `Colors.x`.
2. RigAlertDialog: destructive confirms show the action in `moneyOutText`, Import shows it in `accentText`; Cancel is the default; the alert is 270 dp wide at 360 dp and 412 dp.
3. The date row opens the DatePickerSheet; the chosen date keeps the earlier time of day; the row is labelled for a screen reader ("Change date").
4. Select Date Range returns the same `CashDateRange` for the same inputs (parity P-RANGE) and swaps reversed dates.
5. Snackbars last 4 s, float above the pinned pill or tab bar, and are not hidden behind a sheet (see R6).
6. Android back closes the top sheet or alert first; a sheet with a dirty field does not prompt (only the three forms do, LR-25).
7. At text scale 200 percent every sheet scrolls and its pinned button stays reachable; 360 dp and 412 dp, light and dark.


### R5. Parity delta

Change on purpose:

- PARITY-084 and PARITY-035: field prefix and every amount show the rupee sign (LR-24).
- Dialog form factor changes (alert, sheets); contents and results are the same, so PARITY lines stay valid.


Must stay identical:

- Date range semantics (half-open, swap), amount input rules (PARITY-017, 019, 020), 12/24 hour handling, the empty period selector rules.


### R6. Performance and Android notes

- Edge to edge: status bar transparent; bottom inset from `MediaQuery.viewPaddingOf(context).bottom`. Pushed screens have no floating tab bar; content ends at inset + 24 dp, or inset + 110 dp when a pinned bottom pill is present.
- Keyboard: `resizeToAvoidBottomInset: true`; a pinned bottom pill sits above the keyboard; sheets add `MediaQuery.viewInsetsOf(context).bottom`; the focused field scrolls to the centre.
- Controller audit (verified by grep over lib/features/cashbook): every `TextEditingController` and `FocusNode` is created in a `State` and disposed in its `dispose` (book dialogs 25-35 and 184-194, home 33-38, items dialog 71-82, entry form 47-91, note form 21-28, text prompt 298-303, transfer 19-39). No dialog creates a controller outside State and none disposes right after `await showDialog`. `pickCashDateRange` has no controllers.
- Risk when sheets replace dialogs: the controllers must move with the dialog body into the sheet widget State, never into the caller (MEMORY.md gotcha).
- RigSnack inside a sheet: Flutter SnackBar renders behind a modal route. Show the message with a RigSnack hosted in the sheet own `Scaffold` or as an inline ErrorBanner row (conflicts_r3.md C-07).
- No `BackdropFilter` in sheets by default (scrim colour only, blur toggle OFF).

