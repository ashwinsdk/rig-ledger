> SUPERSEDED IN PART (2026-10-13): the look is now the Apple-inspired Android direction. Read "Reconciliation 2026-10-13" at the end of this file first; where it conflicts with sections 4 to 7 above, it wins.
# cashbook_settings_screen.dart (Account Ledger settings, and showReporterNameDialog)

Group g2. Source: lib/features/cashbook/cashbook_settings_screen.dart (172 lines).

## 1. Purpose and primary user task

Change how the Account Ledger formats and shows data: date format (6 patterns), Show Time, Time Format 12 or 24 hour, Currency Format (number style), display switches (date in each entry, Previous Balance, balance after each transaction, description field, notes suggestion, time in reports) and "Your Name and Address" printed on reports. Parity: PARITY-027, 028, 035, 039, 040, 076, 079.

## 2. Current structure

`CashbookSettingsScreen` (ConsumerWidget). Providers: `cashSettingsProvider` (watch) and `cashSettingsProvider.notifier.updateSettings(s.copyWith(...))` on every change. `_numberStyles` map: 'Grouped (1,234)' (true,false), 'Plain (1234)' (false,false), 'Two decimals (1,234.00)' (true,true). `_choose<T>` shows a `SimpleDialog` with a check icon beside the current value. Tree: `Scaffold(cashAppBar('Settings'))` > `CashPageBody(700)` > `ListView[ListTile Format Date, SwitchListTile Show Time, ListTile Time Format, ListTile Currency Format, Divider, 6 SwitchListTiles, Divider, ListTile Your Name and Address (dialog via showReporterNameDialog), disabled ListTile 'Labels: Income / Expense']`. `showReporterNameDialog` wraps `showCashTextPrompt` (4 lines, sentences).

## 3. Problems found

1. Flat list of 14 rows with only two `Divider`s: no section titles; "Format Date", "Show Time", "Time Format", "Currency Format" (display) are mixed with behavior switches ("Previous Balance", "Notes suggestion", "Add description / Category") and report settings (settings:65-153).
2. No preview of the effect: Format Date shows today formatted (good) but Currency Format shows the style name only; "Show time in reports", "Show date in each entry" give no example.
3. Disabled 'Labels' tile (settings:149-153) is a non-interactive row that looks broken (grayed ListTile with subtitle). It explains a fixed decision (Income and Expense) but no text says so.
4. Mixed icon-less rows; `ListTile` default density; the check icon in the choice dialog is `Icons.check` size 18 `AppColors.primary` (settings:32).
5. `SwitchListTile`s have no semantics for the grouped meaning; subtitles exist for only one (Previous Balance).
6. Real bug: the Format Date options are keyed by the formatted text of today's date (`{ s.copyWith(dateFormat: f).formatDate(now): f }`, settings:73-75). The patterns 'dd-MM-yyyy' and 'MM-dd-yyyy' produce the same string on any day where day equals month (for example 10 Oct, 11 Nov, 12 Dec, 1 Jan), so the map drops one key and the dialog shows 5 options instead of 6: that pattern cannot be chosen on those days (bugs G2-B22).
7. Each switch triggers `updateSettings` and a whole-screen rebuild (acceptable) with no feedback; changes apply instantly without a save step (clear but undocumented on the screen).
8. Number style label 'Two decimals (1,234.00)' etc. use ASCII; fine.
9. The app bar is `cashAppBar` (gradient on mobile); the macOS two-pane layout pushes this screen full window.
10. The reporter name row shows the full multi-line text as subtitle without `maxLines` (settings:138-140): a 4-line address makes a tall row.

## 4. Redesign

- `RigScaffold(appBar: RigAppBar('Settings'), maxContentWidth 640)`. Title text unchanged.
- Sections with `RigSection` (title `titleSmall`) each a `RigCard` of `RigListRow`s/`RigSwitchRow`s with `RigDivider` inset `s4`:
  1. "Display": Format Date (row, value shown right in `bodyMedium` `onSurfaceVariant`: today's date in the chosen pattern), Currency Format (value: style name), Show Time (switch), Time Format (row, always enabled because it also controls the time pickers in forms).
  2. "Ledger": Show date in each entry, Previous Balance (existing subtitle kept), Show balance after each transaction.
  3. "Entry form": Add description / Category, Notes suggestion.
  4. "Reports": Show time in reports, Your Name and Address (value: first line only, `maxLines: 1`, or "Printed at the top of reports" when empty).
  5. Footer info row (replaces the disabled tile): `Icons.info_rounded` 20 `info` + `bodySmall` "Labels are fixed as Income and Expense." (new sentence explaining the existing disabled row, copy added).
- Preview card on top (`RigCard` tone `container`, padding `s4`): a sample row built from the current settings: date text, time (when Show Time), a sample amount through `settings.formatMoney(1234.5)`, so the user sees the Currency Format and Show Time effect live (static sample numbers, not real data). Sample uses placeholder text "Sample entry".
- Choice rows open `RigChoiceDialog` (sheet on compact, dialog on expanded) with `Icons.check_rounded` 20 `primary` on the current option; each option shows its pattern name and an example formatted from a fixed sample date whose day and month differ (25 Dec 2026), keyed by the pattern (not by the formatted text), so all 6 patterns are always selectable; behavior identical (`updateSettings` with `copyWith`).
- `RigSwitchRow`: 56 dp min height, title `bodyLarge`, subtitle `bodySmall`, switch trailing; whole row toggles.
- Desktop: two-column layout is not needed (single column, max 640); Tab order top to bottom; Space toggles focused switch.

Tokens: `s4` page, `s2` section gap 24 (`s6`) between sections; radius `lg`; type `titleSmall`, `bodyLarge`, `bodyMedium`, `bodySmall`; colors `onSurfaceVariant`, `primary`, `info`, `surfaceContainer`.

State table: Default; Loading none; Empty n/a; Error none; Disabled none (all rows enabled); Applying: switch moves immediately (no spinner).

Motion: switch thumb `fast`; preview card text changes with a `fast` cross-fade.

## 5. Logic touchpoints that must stay untouched

- `cashSettingsProvider.notifier.updateSettings(s.copyWith(dateFormat | showTime | use24Hour | groupDigits + fixedDecimals | showDateInEntry | showPreviousBalance | showBalancePerEntry | showDescription | notesSuggestion | showTimeInReports | reporterName))` and persisted keys `cashbook.*`.
- Date format options from `CashSettings.dateFormats` (6 patterns), number styles map values `(groupDigits, fixedDecimals)`.
- Defaults live in `CashSettings` (not in the screen).
- `showReporterNameDialog(context, current)` returns trimmed text or null; used also by the ledger home overflow ("Your Name and Address").
- Labels fixed to Income and Expense (no editor).

## 6. Acceptance criteria

1. Every setting changes the corresponding behavior immediately: date format on rows and forms, Show Time on rows and reports, 12/24 hour on rows and pickers, number style on all amounts, each switch on its screen (parity-039, 040, 027, 028, 037).
2. The preview card reflects date format, time and number style changes live.
3. Settings persist after app restart.
4. The reporter name saves and appears on reports; empty text clears it.
5. Rows are >= 56 dp; whole row toggles for switches.
6. 200 percent text: no overflow; long reporter name truncates to one line.
7. The info row replaces the disabled "Labels" tile; no tile appears disabled.
8. No `Colors.x`, hex or `AppColors` direct reads.

## 7. Performance notes

- `build` watches the whole `CashSettings` and rebuilds all rows per toggle: acceptable (14 rows) but extract `RigSwitchRow` per setting using `ref.watch(cashSettingsProvider.select((s) => s.showTime))` so a toggle rebuilds only its row and the preview.
- `_numberStyles` is a static const map; the date-format options map is rebuilt per tap only (dialog open), fine.
- `updateSettings` persists on each toggle (provider concern); no debounce needed.
- No controllers in this screen; the reporter dialog's controller is State-owned in `showCashTextPrompt`.


## Reconciliation 2026-10-13 (Apple look, Android only)

### R1. Mockup screens and Flutter mapping

| Mockup screen (J registry) | Mockup render function | Flutter file | Widgets | Notes |
|---|---|---|---|---|
| Account Ledger settings | `SC.cbSettings`, `fmtDlg`, `cbAddrDlg` | lib/features/cashbook/cashbook_settings_screen.dart | LargeTitleScaffold (pushed, title "Settings"), RigGroup x3, RigRow (value and chevron), RigSwitch rows, RigSheet (Format Date, Your Name and Address) | Mockup has three groups and no preview card; the old design had four sections plus a preview card. |

### R2. What changes in the redesign (supersedes section 4)

Account Ledger Settings (pushed from the drawer):
1. LargeTitleScaffold, title "Settings", back chevron.
2. RigGroup 1: Format Date (value = today in the chosen pattern, chevron, opens a RigSheet "Format Date" with check mark and the footer "The date format applies inside Account Ledger lists and reports."), Show Time (RigSwitch), Time Format (value "12 hour" or "24 hour", opens a two-option sheet with a check mark), Currency Format (value from the style label, chevron, opens a sheet; see L2-r3-1).
3. RigGroup 2: Show date in each entry, Previous Balance (subtitle "Carry the balance before the period into period tabs"), Show balance after each transaction, Add description / Category, Notes suggestion, Show time in reports (all RigSwitch rows, 56 dp minimum, whole row toggles).
4. RigGroup 3: Your Name and Address (subtitle "Printed at the top of reports", chevron, opens a RigSheet with a four-line field and pinned "Save"), Labels (value "Income / Expense", not tappable, no chevron).
5. Bottom padding inset + 24 dp. Switches apply immediately (no Save).


Old section 4 items:

- Old 4 appbar and max width: CHANGED to LargeTitleScaffold; width DROPPED.
- Old four captioned sections (Display, Ledger, Entry form, Reports): CHANGED to the mockup three untitled groups (the order of rows inside is the code order).
- Old preview card at the top: DROPPED (not in the mockup). It would need no logic, so it may return later as a visual only addition.
- Old footer info row replacing the disabled Labels tile: CHANGED to the "Labels" row with the value "Income / Expense" (mockup); the extra sentence is DROPPED.
- Old RigChoiceDialog (sheet on compact, dialog on expanded): CHANGED to RigSheets.
- Old RigSwitchRow 56 dp: KEPT, themed `Switch` with transparent outline, white thumb, track on `moneyIn`.
- Old two-column and desktop notes: DROPPED.
- Old date format option samples from a fixed date: KEPT, the mockup sample patterns are illustrative (`d MMM yyyy` default, see L2-r3-2).


States:

| State | Rule in the new look |
|---|---|
| Default | three groups |
| Loading | not applicable |
| Empty | not applicable |
| Error | not applicable |
| Disabled | Labels row is read-only text, not drawn disabled |
| Applying | switch moves immediately |


Motion: switch thumb 150 ms; sheet rise 250 ms; ink press; reduced motion removes durations.


### R3. Logic touchpoints and LR items

Untouched: `cashSettingsProvider.notifier.updateSettings(s.copyWith(...))` for every key, the six date format patterns of `CashSettings.dateFormats` (plus the new default, see L2-r3-2), number style values `(groupDigits, fixedDecimals)`, defaults live in `CashSettings`, `showReporterNameDialog` returning trimmed text or null, labels fixed to Income and Expense.


- LR-24 (approved for the rupee sign; date default `d MMM yyyy` still to confirm): changes default values of existing settings (number style and date format) with a one-time migration if the owner wants to keep a stored choice.
- L2-r3-1 (proposed, new): fate of the Currency Format row (group digits and fixed decimals) when the formatter is the single en-IN rupee `money()`.
- L2-r3-2 (proposed, new): add `d MMM yyyy` (and the day header `EEE, d MMM yyyy`) to `CashSettings.dateFormats` as the default; keep the six old patterns as choices.
- LR-16 (closed): Rs. versus the rupee sign is decided; the symbol is not a setting.


### R4. Acceptance criteria delta

1. Every row changes its behaviour immediately: date format on rows, forms, headers and ranges; Show Time on rows and reports; 12 or 24 hour on rows and pickers; each switch on its screen (PARITY-039, 040, 027, 028, 076).
2. The default date shown in a fresh install is `12 Oct 2026` style (`d MMM yyyy`); a user who chose another pattern keeps it (migration rule from LR-24 once confirmed).
3. No amount on any Account Ledger screen or report shows "Rs." after the formatter change; the rupee sign and en-IN grouping apply (PDF and CSV exports keep their own formats, section 7 of TOKENS.md).
4. Rows are at least 56 dp; the whole row toggles for switches; the settings persist after restart.
5. The reporter name saves from the sheet with the keyboard open and Save above the keyboard; an empty value clears it.
6. Text scale 200 percent: rows grow; subtitles wrap; no clipping; 360 dp and 412 dp, light and dark.


### R5. Parity delta

Change on purpose:

- PARITY-035 and PARITY-084: the Rs. prefix is replaced by the rupee sign; "Currency Format" meaning is open (L2-r3-1).
- PARITY-076: the settings list loses the old preview card and sections (visual only); the settings themselves are unchanged.
- PARITY-036 and 031: default date pattern becomes `d MMM yyyy`.


Must stay identical:

- PARITY-039 and 040 (balance per entry, date in entry), PARITY-027 and 028, PARITY-079 name and address on reports, labels fixed to Income and Expense (PARITY-078).


### R6. Performance and Android notes

- Edge to edge: status bar transparent; bottom inset from `MediaQuery.viewPaddingOf(context).bottom`. Pushed screens have no floating tab bar; content ends at inset + 24 dp, or inset + 110 dp when a pinned bottom pill is present.
- Keyboard: `resizeToAvoidBottomInset: true`; a pinned bottom pill sits above the keyboard; sheets add `MediaQuery.viewInsetsOf(context).bottom`; the focused field scrolls to the centre.
- List strategy: plain `ListView` of about 13 rows; each switch row watches only its own field via `select`.
- Controllers: the settings screen has none; `showCashTextPrompt` owns the reporter controller in State (verified).
- Cache date and number formatters in RigFormat keyed by pattern; do not rebuild them per row.

