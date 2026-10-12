# Cashbook - SCREENS (UI crawl)

Device: 1080x2400 px at 420 dpi (density 2.625, so 1 dp = 2.625 px). Package cashbook.cashbook v238. Coordinates below are px from uiautomator bounds; divide by 2.625 for dp.
Locked or premium items are marked LOCKED. The app shows ads (banner at the bottom of most screens): not replicated.

## S01 Main (book) screen
Reach: app launch. Always opens on the last-used book ("Cash Book" by default).
- Toolbar (blue, height 168px = 64dp): hamburger (left), book name with dropdown caret (tap opens book picker, S02), Report button (document icon, desc "Reports"), Keyword Search (magnifier), overflow (three dots).
- Column header row (height 61px = 23dp): "Date" (left, bold black), "Cash In" (dark green, bold), "Cash Out" (red, bold).
- List area (RecyclerView), empty by default (no empty-state text).
- Bottom action row: two big buttons "Cash In" (green, left) and "Cash Out" (red, right), height 105px = 40dp, each about half the width with 22px gap.
- Totals strip (3 equal cells with borders, white): "Total Cash In" (green label), "Total Cash Out" (red label), "Balance" (black label); values underneath (green, red, blue), all "0" when empty.
- Banner ad area below totals (not replicated).
Colors seen (visual, approximate): toolbar blue, Cash In green, Cash Out red, balance value blue, background light grey-blue.

## S03 Navigation drawer
Reach: hamburger on S01 (also from edge swipe). Header: avatar placeholder, current book name. Items in order, each 104px (40dp) tall:
1 Remove Ads (LOCKED, in-app purchase, not opened)
2 Summary
3 Account Summary
4 Transaction-All Accounts
5 Accounts
6 Transfer
7 Report-All Accounts
8 Transaction names
9 Notebook
10 Calendar
11 Cash Calculator
12 Backup and Restore
13 Settings
14 Deleted Transactions
15 Help
16 Rate Us
17 Recommend
(Remove Ads, Rate Us and Recommend are store/marketing items; not replicated.)

## S04 Summary
Reach: drawer > Summary. Title "Summary". Toolbar: Select Date Range, Report.
Tabs (text chips): All, Daily, Weekly, Monthly, Yearly. Period label under tabs ("All"). List (empty now), bottom totals Total Cash In / Total Cash Out / Balance.

## S05 Account Summary
Reach: drawer > Account Summary. Toolbar: book name (tappable), Select Date Range, Report.
Tabs: All, Weekly, Monthly, Yearly. Period navigator with previous and next arrows and label like "Oct-01-2026 -> Oct-31-2026" (month default). Table header: Date, Cash In, Cash Out, Savings. Bottom totals strip.

## S06 Transaction-All Accounts
Reach: drawer. Toolbar: Keyword Search, Report, overflow. Tabs All, Daily, Weekly, Monthly, Yearly, period label, header Date | Accounts | Amount. Bottom totals strip.

## S07 Accounts (book manager)
Reach: drawer > Accounts. Toolbar button "ADD ACCOUNT", search field at top (EditText, hint not exposed), list of book names (one row per book, name only).

## S08 Transfer
Reach: drawer > Transfer. Fields in order: Amount (number input), From (spinner of books), To (spinner of books), date (default today, format "Oct-12-2026"), time (default now, "03:27 PM"), Notes (autocomplete text). Button "Transfer".

## S09 Report-All Accounts (dialog)
Reach: drawer. Dialog with period options: "All", "Select Date Range"; radio group PDF / EXCEL; button OK.

## S10 Transaction names (dialog)
Reach: drawer. Radio group: "Cash In Cash Out", "Income Expense", "Custom". Buttons Cancel, Save. Renames the column labels app-wide.

## S11 Notebook
Reach: drawer. Toolbar: Keyword Search, Select Date Range (sort), overflow. Tabs All, Daily, Weekly, Monthly, Yearly; period navigator; list; bottom stats "Completed", "Pending", "Total"; floating action button (add task).

## S12 Calendar
Reach: drawer. Month navigator (arrows + "Oct-01-2026 -> Oct-31-2026"), weekday header Sun..Sat, 7x5 grid; each cell shows day number, income sum (green) and expense sum (red) for that day; overflow menu; bottom totals strip.

## S13 Cash Calculator
Reach: drawer. Dialog "Select Country" with a country picker row (flag, name, arrow; default United States) and Cancel / OK. Leads to a banknote counter driven by the CurrencyNotes table.

## S14 Backup and Restore
Reach: drawer. Rows: "Export to Google Drive" (Save data in your Google Drive folder), "Import from Google Drive" (Load saved data from Google Drive), "Backup Data", "Restore Data" (Select .db database file), "Delete Account", "Last Backup" with timestamp label.

## S15 Settings
Reach: drawer. Rows in order (type, default seen):
1 Format Date (opens picker) | Show Time (switch)
2 Time Format (picker)
3 Currency Format (picker)
4 Show date in each entry (checkbox)
5 Language (picker)
6 Dark Mode (checkbox)
7 Fingerprint Password (checkbox)
8 Password Settings (checkbox)
9 Previous Balance (checkbox)
10 Show balance after each transaction (checkbox)
11 Add description / Category (checkbox)
12 Notes suggestion (checkbox)
13 Show time in reports (checkbox)

## S16 Deleted Transactions
Reach: drawer. Header Date | Accounts | Amount, list, total label at bottom, overflow menu. Maps to isDeleted rows.

(Remaining screens, dialogs and exact behaviours are tracked in PROGRESS.md.)

## S02 Book picker (dialog)
Reach: tap the book name in the main toolbar. Title "Accounts", "Edit" link at the right of the title (opens S07), search field, scrolling list of book names (row 100px = 38dp), "Add Account" row at the bottom (opens S17). Selecting a name switches the main screen to that book.

## S17 Add Account (dialog)
Fields: Name (text), "Opening Balance [Optional]" (number), "+" / "-" radio, date "Oct-12-2026" with calendar icon. Buttons Cancel / Save. Empty name: dialog closes, nothing created.

## S18 Entry form (add and edit)
Reach: main "Cash In" / "Cash Out" buttons (add), tap a row (edit). Title "Cash In", "Cash Out" or "Edit Transaction". Card layout on light grey background, card padding 16dp, corner radius about 8dp.
Order: [Cash In][Cash Out] chips (active chip filled green or red, inactive grey) / date row [<] date [>] calendar icon, time field with clock icon (date 60 percent width, time 40 percent) / amount field with floating label ("Cash In" or "Cash Out") and calculator icon / Notes field with mic icon / (optional Description / Category field) / [Add Bills] [Add Items] outlined buttons side by side / bottom bar: add mode "Save and exit" (light blue, left) and "Save and continue" (solid blue, right); edit mode "Delete" (red outline, left, trash icon) and "Save" (solid blue, check icon).
Toolbar: back arrow, title, overflow ("Add description / Category"); edit mode also has a "Copy" action.
Keyboard: decimal number pad for amount (digits, comma, dot, minus ignored); text keyboard for notes.
Validation: empty amount: nothing happens (form stays). 0 accepted.
Dialogs: Copy ("Copy to same account" / "Copy to different account"), Delete (Cancel/Delete then "Are You Sure ?").

## S19 Main list row anatomy
Group header: grey band (#F5F5F5), text "Mon, Oct 12 2026" bold, 61px (23dp) high.
Row: white card, 12dp horizontal padding. Left column: notes (17sp regular black, up to 2 lines), below it time "03:30 PM" (14sp grey). Right: two fixed columns (each about 25 percent width) for Cash In and Cash Out; the amount is in one column only, bold 17sp, green for in, red for out. Under the amount, right aligned grey 12sp "Balance 1,000" (running balance, setting "Show balance after each transaction").
Column header: Date (left), Cash In (green bold), Cash Out (red bold).

## Colors (sampled from screenshots, hex)
Functional: toolbar and primary #2196F3 (Material Blue 500); Cash In button #4CAF50 (rendered #45AC4A); Cash Out button #EF5350 (rendered #EE4946); screen background #ECEFF1; group header band #F5F5F5; cards white; amount text in: dark green (about #1B5E20, text sample #38723C anti-aliased); amount text out: red (about #F44336 to #FF0000); balance value in totals strip: blue (about #0D47A1).
Brand: none beyond the blue toolbar (no logo needed).

## Formats
- Date in forms and reports: MMM-dd-yyyy (Oct-12-2026). Group header: EEE, MMM dd yyyy. Time: hh:mm a (03:30 PM) or 24 hour by setting.
- Numbers: grouping commas, up to 2 decimals, trailing ".00" dropped ("1,000", "2,500.50"); negative with leading "-"; no currency symbol.
- Period label: "MMM-dd-yyyy -> MMM-dd-yyyy".

## LOCKED / not opened
- Remove Ads (in-app purchase). Export/Import Google Drive rows (need Google sign-in; the app shows a Turn On Backup promo). Password Settings, Fingerprint Password, Dark Mode flows (not exercised). Rate Us, Recommend, Help "Send email" (external intents). Language change effects. Print (main overflow) not executed.

## Gestures
- Long-press on a row behaves like tap (opens edit). No swipe actions found on rows. Pull to refresh: not observed. Edge swipe opens the drawer.
