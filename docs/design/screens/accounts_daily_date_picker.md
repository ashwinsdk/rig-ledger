> SUPERSEDED IN PART (2026-10-13): the look is now the Apple-inspired Android direction. Read "Reconciliation 2026-10-13" at the end of this file first; where it conflicts with sections 4 to 7 above, it wins.
# B2: Accounts page, Daily filter date picker

Matched files: `lib/features/cashbook/widgets/cashbook_period_bar.dart` (`CashbookPeriodTabs`, `CashbookPeriodBar`), `lib/features/cashbook/cashbook_home_screen.dart` (header at lines 270-300, existing `_pickDay` at line 64). "Accounts page" = the Account Ledger tab (bottom-nav label "Accounts", desktop label "Account Ledger"). If the developer meant `cashbook_books_screen.dart` (also titled "Accounts") see the final question.

APPROVED LOGIC EXCEPTION (tiny): see section 5.

## 1. Purpose and primary user task

Jump straight to any single day in the Account Ledger instead of stepping with the previous/next arrows one day at a time (a day six months back needs about 180 taps today). The Daily tab shows one day's income, expense, previous balance and running balance.

## 2. Current structure

- `CashbookPeriodTabs`: horizontal `ChoiceChip`s All, Daily, Weekly, Monthly, Yearly. Selecting calls `cashViewConfigProvider.notifier.setPeriod(p)`, which sets `period` and `anchor = DateTime.now()` and clears any custom range.
- `CashbookPeriodBar(label, onShift)`: pill with chevron_left, centered label text, chevron_right. The label is plain `Text` (not tappable). `onShift` calls `cashViewConfigProvider.notifier.shift(delta)`, i.e. `CashbookCalculator.shiftAnchor(period, anchor, delta)` (daily = plus or minus 1 day). Arrows are hidden when the period is All, when a custom range is active, or while searching (home screen line 291).
- Label for Daily comes from `CashbookCalculator.rangeLabel(range)` which prints the same date twice ("Oct-12-2026 -> Oct-12-2026", screenshot 03) with the format `MMM-dd-yyyy`.
- Existing day jump: overflow menu item "Date" calls `_pickDay()` which opens `showDatePicker(firstDate: 2000-01-01, lastDate: 2100-12-31)` and then `setDay(d)`. `setDay` writes a one-day `customRange`, which makes the tabs show "All" as selected and hides the arrows. That path does not keep the Daily filter state, so it is not what is wanted here.
- State: `CashViewConfig {period, anchor, query, type, ascending, customRange}`; `activeRange = customRange ?? periodRange(period, anchor)`.

## 3. Problems found

1. The date in the bar looks like a label but is not interactive; no affordance (no icon, no pressed state). Evidence: cashbook_period_bar.dart:77-80.
2. Daily label repeats the date ("Oct-12-2026 -> Oct-12-2026") and uses a format used nowhere else in the app (`MMM-dd-yyyy`).
3. The only way to a distant day is the overflow menu "Date", which silently changes the active tab to All and removes the arrows (cashbook_home_screen.dart:272-286).
4. Tap targets: the arrows are `IconButton` 48 dp (ok); the label has no target.
5. Reaching an empty day gives "No transactions" in muted text; the user cannot tell if the day is empty or a filter hides rows.

## 4. Redesign

### 4.1 Daily bar (period == daily and no custom range)

Layout (compact, 411 dp): `[chevron_left 48] [date button, expands] [chevron_right 48]` inside the existing rounded pill (`primaryContainer`, `RigRadius.md`, height 48).

Date button content: `Icons.calendar_month_rounded` (20, `primary`) + 8 dp gap + label (`labelLarge`, `primary`, weight 600) + 4 dp + `Icons.arrow_drop_down_rounded` (20). Whole button is one tap target, min height 48, `InkWell` with `RigRadius.md` splash.

Label text: `Today, 12 Oct 2026` when the day is today; `Yesterday, 11 Oct 2026` for yesterday; otherwise `Mon, 05 Oct 2026` (token `dateGroup`). At 200 percent text the label may wrap to two lines; the pill grows (min height 48, no fixed height).

For Weekly, Monthly and Yearly the bar is unchanged in this task (label stays non-interactive); only Daily gets the picker (B2 scope). The same button pattern is the natural extension later and is listed in LOGIC_REQUESTS.md only if it needs new state (it does not; it would reuse `setAnchor`).

### 4.2 Picker, mobile (compact and medium)

- `showDatePicker` (Material 3 calendar modal, theme styled): `initialDate = cfg.anchor`, `helpText: 'Select date'`, `firstDate: DateTime(2000, 1, 1)`, `lastDate: DateTime(2100, 12, 31)`.
- Earliest and latest selectable: 1 Jan 2000 to 31 Dec 2100. Reason: these are exactly the bounds the Account Ledger entry form (`cashbook_entry_form_screen.dart:395`), `_pickDay` and `cashbook_common.dart:172` already accept for entries, so any day that can hold an entry can be opened. (Contrast: the main ledger range picker uses `lastDate: DateTime.now()`; the Account Ledger intentionally allows future dates because entries can be future dated.)
- Input mode: calendar by default with the pencil toggle to type a date (built in).
- Confirm applies the day; Cancel or back dismisses with no change.

### 4.3 Picker, macOS and wide windows (expanded, over 900 dp)

- A dialog (`RigDialogShell`, `showDialog`) 360 dp wide containing `CalendarDatePicker` (same bounds, `initialDate = cfg.anchor`), with actions `Today` (text button, left), `Cancel`, `OK`. Opened from the date button; it is positioned by `showDialog`'s default center (a popover anchored under the button is an option, decide in the prototype; the behavior is identical).
- Keyboard: arrow keys move the focused day, Enter confirms, Esc cancels, PageUp/PageDown change month, Cmd+Left/Right (existing shortcuts untouched) are not used.
- Hover on days shows `surfaceContainerHigh`.

### 4.4 Dates with no entries

- Every day in range is selectable; there is no `selectableDayPredicate`. The user lands on the day and sees the standard empty state: `EmptyState` (icon `Icons.event_busy_rounded` 48, "No transactions on this day", hint "Use Income or Expense to add one"), the Previous Balance row (unchanged behavior) and the totals strip with zeros and the carried balance. The Income/Expense buttons remain.
- Distinguishing days with entries inside the picker is NOT in v1 (the system picker cannot paint markers). The existing Calendar screen (`cashbook_calendar_screen.dart`) already shows marked days; v2 may reuse its grid in this dialog (UI only, reads `cashEntriesProvider`).

### 4.5 How the selected date is shown

- Bar label (4.1), and the day header row in the list ("Mon, Oct 12 2026" today; becomes `dateGroup` token) both show the same date, so there is no mismatch.
- The chevrons still step the anchor by one day from the picked date.
- Selecting the already selected day is a no-op (no state write, no flicker).
- After selecting, the list scrolls to the top; the totals strip animates its numbers with `AnimatedSwitcher` (`RigMotion.fast`) only if reduced motion is off.

### 4.6 State table

| State | Date button | Chevrons |
|---|---|---|
| Default (Daily, any day) | enabled | enabled |
| Search active | disabled (picker would be ignored because search ignores the period; tooltip "Clear search to pick a date") | hidden (existing) |
| Custom range active (from overflow) | not shown (bar shows the range, existing) | hidden (existing) |
| Period All | not shown | hidden (existing) |
| Loading | n/a (data is local) | n/a |
| Picker open | pressed state | disabled by the modal |

### 4.7 Motion

Dialog or sheet entrance 300 ms (`curveEnter`) from the system; list swap is a 150 ms cross-fade of the day group; reduced motion = no animation.

## 5. Logic touchpoints, and the one approved exception

Untouched: `CashbookCalculator.periodRange`, `shiftAnchor`, `rangeLabel` (export and other screens use it; the new display label is built in the widget from `cfg.anchor` with `RigFormat`, not by editing the calculator), `cashViewConfigProvider` fields, `setPeriod`, `shift`, `setDay`, the overflow "Date" item and `_pickDay`, the Previous Balance rule, `cashLedgerViewProvider`.

Needed: a way to set `anchor` to a chosen day while keeping `period == daily` and clearing `customRange`. No existing method does that: `setDay` uses a custom range; `setPeriod` resets the anchor to now; `shift` moves by one step.
- Proposed exception (one line in `CashViewConfigNotifier`): `void setAnchor(DateTime d) => state = state.copyWith(anchor: CashbookCalculator.dateOnly(d), clearCustomRange: true);`
- Zero-change alternative using only existing API: `setPeriod(daily)` then call `shift(+1)` or `shift(-1)` N times, where N is the day difference. This causes N state emissions and rebuilds and is slow for distant dates (hundreds of rebuilds); not recommended.
Decision requested in the final questions (Logic exceptions).

## 6. Acceptance criteria

1. With Daily selected, the date in the bar shows a calendar icon and a drop-down arrow and is tappable (hit area at least 48 dp high and the full label width).
2. Tapping it opens the picker with the current anchor day preselected; bounds are 1 Jan 2000 and 31 Dec 2100; days outside are disabled.
3. Choosing 3 Jan 2026 shows that day's entries, totals and Previous Balance, keeps the Daily chip selected, and keeps both chevrons visible.
4. Pressing the previous chevron then shows 2 Jan 2026; next shows 3 Jan to 4 Jan.
5. Choosing a day with no entries shows the empty state, zero Income/Expense, and Previous Balance equal to the carried balance (same number as before the redesign for that day).
6. Cancel or Esc leaves the state unchanged.
7. Choosing the current day shows "Today, <date>".
8. While a search is active the date button is disabled and announces why.
9. The overflow menu items Date and Select Date Range still behave exactly as before (custom range, tab shows All).
10. macOS: the dialog is reachable by Tab, operable by keyboard only, and closes with Esc.
11. At 200 percent text scale the bar does not overflow; label wraps.
12. Screen reader: button label "Pick date, currently Monday 12 October 2026" (placeholder date).

## 7. Performance notes

The date button is a small widget watching only `cashViewConfigProvider.select((c) => (c.period, c.anchor, c.customRange))`. The picker work is one dialog. No computation in build beyond formatting one date with a cached `DateFormat`.


## Reconciliation 2026-10-13 (Apple look, Android only)

Mockup source: J "Account Ledger date picker (B2)" (`cbDatePick` -> `datePick` -> `datePickRender`), `cbPbar`, `pnav`, `cbHome`, `cbStrip`, `cbRows` in `docs/design/mockup/rigledger_apple_mockup.html`. `setAnchor` is APPROVED (LR-02, answer 14). Dropped from sections 1 to 7: macOS dialog (4.3), hover, Esc, Tab and arrow-key navigation, the system `showDatePicker` of 4.2. The Account Ledger screens themselves are specified in `cashbook_home_screen.md`; this doc owns only the Daily bar and the picker.

### R1. Mockup screens and Flutter mapping

| Mockup screen (J label) | Render function | Flutter file | Widgets | Notes |
|---|---|---|---|---|
| Account Ledger date picker (B2) | `cbDatePick`, `datePickRender` | `lib/features/cashbook/widgets/cashbook_period_bar.dart` (bar), new `lib/core/widgets/date_picker_sheet.dart` (picker) | DatePickerSheet (RigSheet), period navigator button, RigButton text ("Today") | needs `CashViewConfigNotifier.setAnchor` (LR-02) |
| Home (All) and Home (Monthly, previous balance) (context) | `cbHome`, `cbPbar`, `cbStrip` | `lib/features/cashbook/cashbook_home_screen.dart` | LargeTitleScaffold, RigChipRow, period navigator, RigGroup | other periods unchanged |
| Accounts empty (context) | `cbRows` | `cashbook_home_screen.dart` | EmptyState | empty day uses the same empty text |

### R2. What changes in the redesign (supersedes section 4)

Daily bar (period `daily`, no custom range, no search): the existing period navigator row, 48 dp high: chevron_left 48 dp, a label button that expands, chevron_right 48 dp. Label button: text 17/600 (`lb`), then `expand_more` 18 dp in `lb2`; whole width tappable (48 dp), ink press. Label text (UI only, built in the widget from `cfg.anchor` with `RigFormat`): `Today, 12 Oct 2026`, `Yesterday, 11 Oct 2026`, otherwise `Mon, 05 Oct 2026` (`dGroup`). The mockup shows the date range twice ("12 Oct 2026 to 12 Oct 2026") for a day: that is NOT built (conflicts_r1.md C6). Weekly, Monthly and Yearly bars stay non-interactive (LR-04 not scheduled). The pill background of 4.1 (`primaryContainer`) is DROPPED: the row has no fill, as in the mockup.

Picker (REPLACES 4.2 and 4.3): `DatePickerSheet` = `RigSheet` titled "Choose a date" (grabber, 28 dp top radius, scrim `scrim`), top-left close button, top-right text button "Today" (`accentText`). Body: month navigator (label `dMonth` "October 2026", chevrons 48 dp) and a 7 column grid, week starts Sunday, weekday initials S M T W T F S (12, 600, `lb2`), day cells 48 x 48 dp minimum, day number in a 30 dp circle (17): today = `accentButton` fill with `onAccent` text, selected = `fill2` fill with `lb` text, other days `lb`. Tapping a day applies it at once and closes the sheet (no OK button, no confirm); back, the close button or a swipe down dismisses with no change. "Today" applies today. Selecting the already selected day is a no-op (no state write). Bounds kept from 4.2: 1 Jan 2000 to 31 Dec 2100 (days outside are disabled and the chevrons stop at those months); initial month is the anchor's month; the sheet header text is the only title.
Apply = `cashViewConfigProvider.notifier.setAnchor(day)` (LR-02), which keeps `period == daily` and clears `customRange`. The list scrolls to the top; totals update without animation.

Dates with no entries (4.4 KEPT): every day selectable. The list shows EmptyState with "No transactions" and "Nothing matches this period or filter." (the mockup text, replaces "No transactions on this day"); the totals strip still shows Income, Expense, Balance and, when the previous balance is not zero, the Previous balance group (carried balance, unchanged rule). Income and Expense buttons stay.

States:

| State | Date button | Chevrons |
|---|---|---|
| Default (Daily) | enabled | enabled |
| Search active | bar hidden (as in the mockup and today) | hidden |
| Custom range active | bar shows the range text, not tappable | hidden |
| Period All | bar shows "All time", not tappable | hidden |
| Picker open | pressed state | blocked by the sheet |
| Loading, Error | n/a (local data) | n/a |

Motion: sheet rise 300 ms ease-out; day press feedback by ink; no list animation; instant under reduced motion.

Old section 4 mapping: 4.1 bar CHANGED (no pill, `expand_more` instead of calendar icon, no `arrow_drop_down`), label text KEPT; 4.2 mobile picker CHANGED (custom sheet instead of `showDatePicker`); 4.3 macOS dialog DROPPED; 4.4 empty days CHANGED (copy); 4.5 selected date display KEPT (day header becomes `dGroup`); 4.6 state table CHANGED (search hides the bar instead of disabling the button); 4.7 motion CHANGED.

### R3. Logic touchpoints and LR items

Untouched: `CashbookCalculator.periodRange`, `shiftAnchor`, `rangeLabel` (the label is built in the widget), `cashViewConfigProvider` fields, `setPeriod`, `shift`, `setDay`, the overflow "Date" item and `_pickDay`, the Previous Balance rule, `cashLedgerViewProvider`.

| Item | Status |
|---|---|
| LR-02 `CashViewConfigNotifier.setAnchor(DateTime)` (one line, `dateOnly`, `clearCustomRange: true`) | approved |
| LR-04 weekly, monthly, yearly pickers | not scheduled |
| LR-24 date format default `d MMM yyyy` | approved for the rupee sign; date default still to confirm. The label here uses `dGroup` and `dFull` and does not read the Account Ledger "Format Date" setting |
| Proposed, new | none |

### R4. Acceptance criteria delta

REPLACES 6 items 1, 2, 7, 8, 10, 11, 12; the others stay. 360 and 412 dp, light and dark, text scale 100, 130, 200 percent.
1. With Daily selected the label shows "Today, <date>", "Yesterday, <date>" or "<EEE>, <d MMM yyyy>" with a down arrow; the hit area is the full label width and at least 48 dp high.
2. Tapping the label opens "Choose a date" with the anchor's month shown and the anchor day selected; today is marked; days before 1 Jan 2000 and after 31 Dec 2100 are not selectable.
3. Tapping 3 Jan 2026 closes the sheet at once, shows that day's entries, keeps Daily selected, keeps both chevrons, and the next chevron then shows 4 Jan 2026.
4. "Today" selects today. Selecting the current anchor day writes no state.
5. Back, the close button or a swipe down closes the sheet and leaves the state unchanged.
6. A day without entries shows the empty text, zero Income and Expense, and the carried balance in the totals strip equal to the balance at the end of the previous day (P-ACC-3).
7. While a search is active the Daily bar is hidden; clearing the search restores it with the same anchor.
8. The overflow items "Date" and "Select Date Range" still produce a custom range and the chips show "Range" selected, as before.
9. At 200 percent text the label wraps to two lines, the bar grows, cells stay 48 dp, nothing clips.
10. Screen reader: label button "Pick date, currently Monday 12 October 2026"; each day cell reads its `dGroup` text; selected day announces "selected".

### R5. Parity delta

Changed on purpose: P-ACC-2 (picker is the custom sheet with instant apply instead of an OK step), the Daily label text (no repeated date), the empty-day copy, search hides the Daily bar (it already hid the arrows).
Identical: P-ACC-1, P-ACC-3, P-ACC-4, P-ACC-5 (arrows move one day, running and previous balance, overflow Date and range, other periods).

### R6. Performance and Android notes

- The label button watches `cashViewConfigProvider.select((c) => (c.period, c.anchor, c.customRange))`; the picker is one sheet with a local `ValueNotifier<int>` for the visible month, a plain `GridView.count(crossAxisCount: 7)` (42 cells, no builder needed).
- No computation in `build` beyond formatting one date with cached `DateFormat`s from `RigFormat`.
- Sheet: `isScrollControlled: false` (fixed content), bottom padding `viewPaddingOf.bottom`; no keyboard on this sheet.
- Android back closes the sheet first (route pop, no extra code); predictive back works with the route.
- No `BackdropFilter` on the scrim (plain `scrim` colour).
