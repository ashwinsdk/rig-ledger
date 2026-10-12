# Cashbook - BEHAVIOUR (observed on test data only)

Test book: "ZZ_TEST_BOOK" (created in the emulator app; real "Cash Book" untouched, it was empty).

## B01 Add Account (book)
- Reach: book picker (tap book name on main screen) > "Add Account", or Accounts screen > ADD ACCOUNT.
- Dialog fields: Name (text), "Opening Balance [Optional]" (number), sign radio "+" / "-", date (default today, "Oct-12-2026") with calendar icon. Buttons Cancel, Save.
- Saving with an empty name closes the dialog and creates nothing (no visible error).
- Saving name "ZZ_TEST_BOOK" with opening balance 1000 and "+": the book is created but the app stays on the current book (does not auto-switch). Switching to it shows ONE entry: note "Opening Balance", Cash In 1,000, time = creation time (03:30 PM), "Balance 1,000". So the opening balance is an ordinary cash-in entry (a "-" sign presumably makes it cash out; verify).
- Book picker dialog: title "Accounts", "Edit" link, search field, list of book names, "Add Account" row.

## B02 Entry form (Cash In / Cash Out)
- Reach: main screen big "Cash In" or "Cash Out" button. Title "Cash In" or "Cash Out". Toolbar overflow has "Add description / Category" (toggles an extra field).
- Fields in order: type chips "Cash In" (green when active) and "Cash Out" (switchable inside the form); date row with previous-day arrow, date "Oct-12-2026" (format MMM-dd-yyyy), next-day arrow, calendar icon; time "03:31 PM" (12 hour, tappable, clock icon); amount (label "Cash In"/"Cash Out", decimal keyboard, calculator icon at end); Notes (autocomplete, mic icon); buttons "Add Bills" (camera icon, attachments, up to 3: bill, bill2, bill3) and "Add Items" (list icon); bottom "Save and exit" (left, light blue) and "Save and continue" (right, solid blue).
- Defaults: date and time = now.
- Empty amount with Save: nothing happens, form stays (no visible message in the dump).
- "Save and continue": saves, clears amount and notes, stays on the form. "Save and exit": saves and returns to the list.
- Decimal amount 2500.50 accepted and displayed "2,500.50".

## B03 List display and balances
- List sorted newest first by date/time; rows grouped under a day header "Mon, Oct 12 2026" (format EEE, MMM dd yyyy).
- Row: notes (bold 17sp-ish) at left; amount shown in the Cash In column (green) or Cash Out column (red), other column blank; second line time "03:30 PM" at left and "Balance 3,500.50" right aligned grey (setting "Show balance after each transaction").
- Number format: grouping separators, no trailing ".00" ("1,000"), decimals shown only when non-zero ("2,500.50").
- Balance after each row is a running balance in chronological order (oldest first): 1000, then 3500.50, then 3100.50. Totals strip: Total Cash In 3,500.50, Total Cash Out 400, Balance 3,100.50.
- Tabs on main list: chips All, Daily, Weekly, Monthly, Yearly with a period label bar ("All").
- A promotional card "Enable Google Drive Backup and Restore" with Skip / Turn On Backup appears at the top (not replicated).

## B04 Edit, copy, delete, restore
- Tap a row: opens "Edit Transaction" (long-press behaves the same as a tap). Same form plus a book field (editable, allows moving to another book), buttons "Delete" (left) and "Save" (right); toolbar has "Copy" and overflow.
- Copy dialog: "Copy to same account" / "Copy to different account". Same-account copy opens a new-entry form prefilled (same date, time, amount, notes); saving creates a duplicate (totals Cash Out went 400 to 800).
- Delete: confirmation dialog titled "Delete" with Cancel / Delete. After delete the entry leaves the list and totals recompute (Balance 3,100.50). It moves to Deleted Transactions (soft delete, matching isDeleted/deletedDate).
- Deleted Transactions screen: header Date | Accounts | Amount; row shows notes, full date-time ("Mon, Oct 12 2026 03:32 PM"), book name, amount. Tap a row: popup menu "Restore" / "Delete" (permanent). Overflow: "Delete All". Restore returns the entry to the book and the running balances recompute (2,700.50 with both copies back).

## B05 Amount edge cases (entry form)
- Zero: accepted. Saves a row with amount 0 and empty notes (shown as "0" in the Cash In column). Empty notes are allowed.
- Negative: the minus key is ignored, so "-50" becomes "50". Amounts are always positive; sign comes from Cash In / Cash Out.
- Very large: 99999999999 accepted, displayed "99,999,999,999"; 123456789.5 shown "123,456,789.50". Long numbers wrap onto two lines in their column (ugly), and totals strip cells wrap too.
- More than 2 decimals: 1.239 is displayed "1.24" (display rounds to 2 decimals). Whether the stored value keeps 1.239 is unverified (live DB not readable; see Unknowns).
- Decimal separator: "." on the keyboard; grouping "," (international grouping in this locale setting).

## B06 Dates and period tabs
- Future dates are allowed (date arrow forward twice gave Oct-14-2026; the entry was listed above today's under header "Wed, Oct 14 2026").
- Date arrows move one day; month boundary works (12 steps back from Oct-12 gave Sep-30-2026).
- List ordering: by date and time, newest first; same-day entries by time descending.
- Monthly tab: period bar with arrows "Oct-01-2026 -> Oct-31-2026"; shows "Previous Balance <sum of everything before the period>" as the first row (20, from the Sep-30 entry), then day groups; totals strip shows period Total Cash In / Total Cash Out / Balance, plus extra rows "Previous Balance" and final "Balance" (period balance + previous balance). Other tabs (Daily, Weekly, Yearly) assumed to behave the same; verify.
- Editing an existing entry via Save works (notes edited from "Test diesel" to "Test dieselzero").

## B07 Search, filters, sort (main screen)
- Keyword search (magnifier): expands a search view in the toolbar (hint "Search", with Report and overflow still shown). Live filter as you type, case-insensitive substring match on notes. Results ignore the period tab (searched "diesel": 2 rows from All time). Totals strip updates to the filtered rows only (Balance became -800: negative balances show "-800").
- Overflow menu on main screen, in order:
  - "Notes": dialog "Notes" with a text field, buttons Cancel / Search (search by notes).
  - "Date": single-day DatePicker (Material calendar dialog); filters to that day.
  - "Select Date Range": dialog with "Start Date" and "End Date" (both default today, "Oct-12-2026") and OK.
  - "Date Ascending" / "Date Descending": checkbox items; ascending reverses the order (oldest first, same-day by time ascending). Descending is the default.
  - "Cash In": shows only cash-in entries; totals recalc (Total Cash Out 0). "Cash Out": only cash-out entries.
  - "Print", "Your Name and Address", "How to use the app?".
- A type filter persisted while changing sort (Cash Out filter stayed after choosing Date Ascending): filters and sort combine; how to clear them is TODO (pick the other filter or reopen the book).

## B08 Export (toolbar Report button)
- Report dialog "Report": two rows "PDF" and "Excel". Tapping one generates the file and opens the Android share sheet ("Sharing 1 file"); the file is also saved to shared storage at `Documents/Cash Book/<BookName> <MMM-dd-yyyy>.<pdf|xls>` (folder is the app name, not the book; example "ZZ_TEST_BOOK Oct-12-2026.pdf"). Same name overwrites.
- Exports honour the active view: with the Cash Out filter on, the PDF contained only cash-out rows and the title range "Oct-12-2026 To Oct-12-2026". With no filter the Excel contained all rows of the book.
- PDF (A4 portrait, iText): centered book name title, line "Oct-12-2026 To Oct-12-2026" (range), table with columns: serial no (unlabeled), Date (MMM-dd-yyyy), Notes, Cash In (pale teal cells), Cash Out (pale pink cells), Balance (negative shown red with minus); then a small centered 2-column summary table: "Total Cash In", "Total Cash Out", "Balance" (green, red, black labels). Rows ordered oldest first; running balance column is cumulative from the first exported row.
- Excel (.xls legacy BIFF written by the Java Excel API / jxl): one sheet named "Transactions"; book name title; header Date, Notes, Cash In, Cash Out, Balance; all values written as formatted text strings (for example "2,500.50"), a first row carrying the previous balance ("1,020" when earlier entries exist), then entries oldest first, then totals row(s). Not real numeric cells.
- No CSV export exists in the app.
- Toolbar "Print" in the main overflow and the "Report-All Accounts" dialog (PERIOD: All / Select Date Range; format PDF or EXCEL) provide the same outputs across books.

## B09 Settings (observed defaults and pickers)
Defaults: Show Time = ON; Show date in each entry = off; Dark Mode = off; Fingerprint Password = off; Password Settings = off; Previous Balance = ON; Show balance after each transaction = ON; Add description / Category = off; Notes suggestion = ON; Show time in reports = off.
- Format Date picker (6 options): dd/MMM/yyyy, dd/MM/yyyy, dd/MM/yy, MM/dd/yyyy, MMM/dd/yyyy, yyyy/MMM/dd. (The observed on-screen format "Oct-12-2026" uses "-" separators, so the picker values are patterns, separator rendered as "-" in the UI; verify when changing it.)
- Time Format: "12 hour" (default) / "24 hour".
- Currency Format: "1234" or "1,234.00" (number style; no currency symbol is shown anywhere in lists).
- Language: "Select Language" with 10+ options (Device Language, English, Hinglish, Spanish, French, German, Indonesian, Italian, Uzbek, Russian, ...). Not replicated (RigLedger is English only).
- Add description / Category ON: entry form shows an extra "Description / Category" autocomplete field under Notes (maps to the `description` column). Setting restored to off after the test.
- Password, fingerprint, dark mode not exercised (not in scope for RigLedger: light only).

## B10 Entry form extras
- "Add Items" dialog: fields Item, Quantity, Unit, Rate, button "Add"; list header "Item (N)" with running "Total X"; Cancel / OK. Line items attach to the entry (the DB has no items table in this backup, so how they are stored is UNKNOWN; likely serialised into notes or description).
- "Add Bills" popup menu: Camera, Gallery, PDF (attachments, up to 3 slots matching bill, bill2, bill3).
- Amount calculator (icon at end of amount field): bottom sheet with result display, expression line, keys 7 8 9 /, 4 5 6 *, 1 2 3 -, comma 0 dot +, 00 000 delete (plus equals/clear presumably below).
- Notes field is an autocomplete (setting "Notes suggestion"), mic icon for voice input.
- "Your Name and Address" (main overflow): dialog with one text field, Cancel/Save; stored text is used as the report header (not verified).
- "How to use the app?": Help screen with FAQ and "Send email" button.

## B11 Transfer between books
- Reach: drawer > Transfer. Fields: Amount (numeric), From (spinner of all books, default first book), To (spinner), date (today), time (now), Notes, button "Transfer". Amount field drops non-digit characters when typing.
- Test: 100 from ZZ_TEST_BOOK to ZZ_TEST_BOOK2 with notes "transfer test". Result: after Transfer the form stays on screen and is cleared (no navigation, no visible toast in the dump). Two ordinary entries are created, linked only by text: source gets a Cash Out of 100 with notes "To ZZ_TEST_BOOK2 transfer test"; destination gets a Cash In of 100 with notes "From ZZ_TEST_BOOK transfer test". There is no transfer id; editing or deleting one side does not touch the other (assumed, verify).
- The empty-amount tap on Transfer does nothing visible.

## B12 Discarding edits
- Pressing Back on the Edit Transaction screen discards changes silently (no confirm dialog). Verified: typing digits into the amount then Back left the stored amount and totals unchanged.
- The first Back press may only close the keyboard.

## B13 Books (accounts): rename, delete, opening balance
- Accounts screen (drawer > Accounts): search field, list of book names, ADD ACCOUNT. Tap a row: popup menu "Edit", "Delete", "Opening Balance".
- Edit: dialog with the name prefilled, Cancel / Save. Renaming ZZ_TEST_BOOK2 to ZZ_TEST_BOOK2B kept its entries visible under the new name (the app rewrites the book name stored on each entry, since the link is by text).
- Delete: first dialog "Delete" with text "If you delete this account then all transactions in this account will also get deleted" (Cancel/Delete), then a second dialog "Are You Sure ?" (Cancel/Delete). After both, the book disappears from the list.
- Deleting a book soft-deletes its entries: they appear in Deleted Transactions with the old book name (here "ZZ_TEST_BOOK2B") and can be restored or purged there. (Restoring an entry whose book no longer exists is UNTESTED.)
- Deleted Transactions row tap menu: "Restore" / "Delete". "Delete" opens a confirm dialog titled "Delete Transaction" (Cancel/Delete) and removes the row permanently.
- Book picker (tap book name on main screen): "Accounts" dialog with "Edit" link (opens the Accounts screen), search field, list, and "Add Account".
- The opening balance of a book is a normal Cash In entry with notes "Opening Balance" (a "-" sign presumably makes it a Cash Out).
- The app remembers the last opened book across launches (relaunch reopened ZZ_TEST_BOOK).

## B14 Summary, Account Summary, Transaction-All, Calendar (with data)
- Summary (drawer): one card per book that has entries (book name; Total Cash In (green), Total Cash Out (red), Balance), plus a bottom grand-total strip across books. Tabs All / Daily / Weekly / Monthly / Yearly and a Select Date Range button. Books with no entries ("Cash Book", empty) are not listed.
- Account Summary (drawer): title is a book picker (tap name to switch book). Tabs All / Weekly / Monthly / Yearly (no Daily). Monthly default with navigator "Oct-01-2026 -> Oct-31-2026". Table columns Date | Cash In | Cash Out | Savings; one row per day that has entries (format "Oct-12-2026"); Savings = in minus out for that day. Bottom strip Total Cash In / Total Cash Out / Balance for the period only (previous balance is not added here: 100,123,459,450.24).
- Transaction-All Accounts (drawer): all books in one list, grouped by day headers; each row: notes + time at left, book name in the middle, amount colored green (in) or red (out) at right (single Amount column, not two). Keyword search, Report, overflow. Bottom totals strip across all books.
- Calendar (drawer): month grid Sun..Sat; each day cell shows income sum (green) and expense sum (red) for that day, blank when none; arrows change month; totals strip for the month. The book is chosen via overflow > "Accounts" (dialog listing books with Cancel) and defaults to the first book, not the last-used one.

## B15 Notebook (to-do notes)
- Reach: drawer > Notebook. Tabs All / Daily / Weekly / Monthly / Yearly with period navigator (default Monthly "Oct-01-2026 -> Oct-31-2026"), toolbar search, date range, overflow (Completed, Pending, Date Ascending, Date Descending, Report). Floating "+" button adds a note.
- Add form (title "Notes"): date (default today, calendar icon), time (default now, clock icon), multiline "Notes" field, full-width "Save".
- Row: note text (top), then "Mon, Oct 12 2026 03:51 PM" and a checkbox at right. Checking the checkbox marks it completed immediately (stats Completed 1, Pending 0, Total 1). Stats strip at bottom: Completed (green), Pending (red), Total.
- Tap a row: "Edit" screen with same fields plus "Delete" (left) and "Save" (right). Delete removed the note (confirmation dialog first).
- DB table `notebook` (date epoch ms, note text, completed text flag) matches this.

## B16 Local backup (Backup and Restore > Backup Data) and what it proves about storage
- Flow: "Backup Data" opens a dialog titled "Backup Data" (Cancel / Save); Save opens the Android system file picker (Storage Access Framework) for a destination folder (default Downloads) with a SAVE button. File produced: `Download/cashbook <MMM-dd-yyyy>.db` (example "cashbook Oct-12-2026.db").
- The file is a raw SQLite database (SQLite 3.x, PRAGMA user_version 6) with exactly the tables of DATA_MODEL.md. A freshly created database has the same columns as the older backup but in a cleaner order (bill2, bill3 right after bill; `isDeleted` and `deletedDate` NOT NULL without DEFAULT in the DDL). So an import must read by column name, never by position.
- Storage facts proven from rows created on the emulator:
  - `date` is epoch milliseconds of the real instant; an entry saved at 03:30 PM local (IST, UTC+5:30) was stored as 10:00:51 UTC (1791799251000). Seconds are kept, milliseconds are zero. The entry time of day is kept when the date arrow is used (Sep-30 entry kept its 03:35 PM time).
  - Amounts are rounded to 2 decimals on save: typed 1.239 stored as 1.24. Large values are stored as doubles exactly (99999999999.0).
  - Zero-amount entries are stored (cash_in 0.0, cash_out 0.0, transactionType by the chip: 1 here). So "both zero never occurs" in the real data is only a user habit, not a rule.
  - `balance` column is written as 0.0 for every new row (never maintained).
  - `notes` for a transfer contain a real newline: "To ZZ_TEST_BOOK2" newline "transfer test".
  - Opening balance created with a book is an ordinary row: notes "Opening Balance", cash_in 1000.0, transactionType 1.
  - Deleted-and-purged rows are physically removed; ids are not reused (AUTOINCREMENT).
  - Books table: `accounts(_id, name)`; the book deletion removed the book row.
- The backup includes the CurrencyNotes reference table (2135 rows now) and the empty `notebook` table.

## B17 Report-All Accounts, Restore, Cash Calculator
- Report-All Accounts dialog (drawer): choose period "All" or "Select Date Range", choose PDF or EXCEL, OK. Output `Documents/Cash Book/cashbook <MMM-dd-yyyy>.pdf`. PDF (A4): generated date at top right ("Oct-12-2026"), centered title "Cash Book" (fixed text, not a book name), range line (period text), table columns: serial number, Date, Notes, Cash In (pale teal cells), Cash Out (pale pink), Accounts (book name); rows oldest first, no balance column; then summary table Total Cash In / Total Cash Out / Balance (in minus out over all rows, 100,123,459,470.24). Long amounts and book names wrap inside cells.
- Restore Data: dialog "Are You Sure ?" with text "Your Existing Data Will Be Replaced" (Cancel / Import), then the system file picker to choose a .db file; on success the app returns to the main screen. Round trip with the file produced by Backup Data kept all rows and totals identical (books Cash Book + ZZ_TEST_BOOK, totals 100,123,460,370.24 / 900 / 100,123,459,470.24). Restore replaces everything (no merge).
- Cash Calculator (drawer): country picker dialog (default United States, Cancel/OK), then a denomination counter: for each note a row "100 X [-] [count] [+] = amount", total at the bottom, optional notes box at the top; overflow: "Show Online", "Add/Remove Currency Denomination", "Select Currency". It is a side tool unrelated to the ledger.
- Interstitial full-screen ads appear after some navigation (back closes them). Not replicated.

## B18 Per-book Opening Balance
- Accounts row menu > "Opening Balance": dialog with the amount prefilled (1,000), "+" / "-" radio and a date; Cancel / Save. Choosing "-" and saving converted the existing "Opening Balance" entry from Cash In 1,000 to Cash Out 1,000 (Total Cash In fell by 1,000, Total Cash Out rose by 1,000). So the opening balance entry is edited in place and its type follows the sign.
