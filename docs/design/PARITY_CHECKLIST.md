# Parity Checklist

> RECONCILED 2026-10-13: Android only, Apple-inspired look. Read the section "Reconciliation 2026-10-13" at the end first: it lists the lines that change on purpose, the lines that are DROPPED (macOS) and the new lines (lazy tabs, theme, back, text size). Older lines keep their text and ids.

Every behavior that must be identical after the redesign, as numbered manual test lines. Use synthetic data only. "Same as before" = compare with the pre-revamp build on the same data. Section order: shells and Ledger (lead), forms and side ledger (g1), Account Ledger (g2, with PARITY-001..084 references from `docs/features/cashbook/PARITY_STATUS.md`), agents, settings, exports and stats (g3).

Global lines (apply to every task):
- G-1: `flutter analyze` reports zero errors and no more infos than before.
- G-2: Totals, balances, commission, feet totals and profit shown for the same data are numerically identical to the baseline.
- G-3: PDF and CSV exports are byte-identical to the baseline for the same data (frozen content).
- G-4: Every destructive action still asks for confirmation (delete bill, delete entry, delete agent, delete vehicle, restore, clear all data, delete forever, delete all).
- G-5: Business labels unchanged: Balance, Less, Received, Step Rate, Commission, Total, Pending.
- G-6: No emoji, no em-dash, no hard-coded color in changed files (grep).
- G-7: At text scale 130 and 200 percent no RenderFlex overflow on the changed screen.
- G-8: Backup created before the change restores correctly after it (no model or storage change).


## Shells, Ledger, Side Ledger, Portfolio, Account Ledger Daily filter (lead)


Use synthetic data only. Lines are manual test steps. "Same as before" means compare with the pre-revamp build on the same data set.

### Mobile shell (P-NAV)

- P-NAV-1: Launch on Android. Bottom navigation shows Ledger, Portfolio, Agents, Accounts, Settings in that order; Ledger is selected.
- P-NAV-2: Tap each destination; the matching screen shows; return to Ledger; the scroll offset, period and search are unchanged.
- P-NAV-3: On Ledger the FAB shows; on every other destination it does not.
- P-NAV-4: Main bore rig, Ledger tab, tap FAB: the new bill form opens. Side bore rig: the side bore form opens.
- P-NAV-5: Side Ledger tab, tap FAB: chooser lists Diesel, PVC, Bit, Hammer (main bore) or Diesel, Bit, Hammer (side bore, no PVC); each opens its own form.
- P-NAV-6: Tap Portfolio; the five ledger providers refresh (add a bill on another path, return, number is current).
- P-NAV-7: Rotate is locked to portrait (unchanged).

### Desktop shell (P-DSK)

- P-DSK-1: Launch on macOS: title bar 52 px with draggable area, RigLedger title, sync indicator, rig switcher when two or more rigs.
- P-DSK-2: Cmd+1 to Cmd+5 switch Ledger, Portfolio, Agents, Account Ledger, Settings.
- P-DSK-3: Cmd+N opens the new bill form (Ledger tab), the chooser (Side Ledger tab), a new Account Ledger entry (Account Ledger); does nothing on Portfolio, Agents, Settings (the button may be shown disabled).
- P-DSK-4: Cmd+S starts a sync; the indicator shows progress then result.
- P-DSK-5: Switch rig from the title bar: Ledger, Side Ledger, Portfolio and Agents all show the new rig's data (verify twice in a row, the second switch back must also show the right data).
- P-DSK-6: Window resized to 900 x 600: no overflow, no horizontal scrolling.
- P-DSK-7: Menu bar items (RigLedger, File, View, Window) still exist with the same actions.

### Ledger tab (P-LED)

- P-LED-1: Month period, Daily view: bills of the selected month grouped by day, newest day first, newest bill first within a day; day header shows the day total.
- P-LED-2: Month chevrons move one month; label shows the month name and year.
- P-LED-3: Period chips 3 Mo, 6 Mo, Year, Custom, All: same set of bills as before for the same data. Year shows chevrons that change the year. Custom shows the range and an Edit action; picker bounds 2000 to today.
- P-LED-4: Totals strip values (Total, Received, Balance, Commission) equal the sums of the visible bills; Commission is not added to Total.
- P-LED-5: Feet totals: 7" Depth, 8" Depth, 7" PVC, 8" PVC, MS Pipe equal the sums of the visible bills; side bore rig shows Total Depth only and no PVC.
- P-LED-6: Calendar view: month grid with day totals; today highlighted (see B-03 for non-month periods).
- P-LED-7: Search by bill number, address, agent name and notes (case insensitive); the searching indicator shows and clears.
- P-LED-8: Filter by bill number, address, agent, depth type, PVC type (PVC option hidden for side bore); Apply, Clear All, Cancel; active filter indicator visible.
- P-LED-9: Tap a bill: opens the edit form for that bill with all values loaded.
- P-LED-10: A bill with a manually edited total shows the manual-total marker.
- P-LED-11: A bill with commission above zero shows the commission line; with zero it does not.
- P-LED-12: Switch rig from the title area: list, totals and feet update; search and filter are cleared.
- P-LED-13: Empty period: empty state; the add hint is shown.
- P-LED-14: Long list (60 bills): all bills reachable by scrolling; last bill is not hidden behind the FAB.

### Side Ledger tab (P-SLD)

- P-SLD-1: Chips Month, 3 Mo, 6 Mo, Year, Custom, All; month and year navigation; Custom range with Edit; period state is independent of the Ledger tab.
- P-SLD-2: Summary: Diesel litres and amount, PVC pieces and amount (main bore), Bit and Hammer pieces and amount (side bore: Bit and Hammer only), equal the sums of the entries in the period.
- P-SLD-3: Category tiles open the Diesel, PVC (and Bit, Hammer) list screens; counts and amounts on tiles equal the list contents.

### Portfolio (P-PORT)

- P-PORT-1: Overview, Month: total billed, received, pending, commission, expenses and profit equal PortfolioCalculator results for the data (compare with a pre-revamp screenshot).
- P-PORT-2: Range chips Day, Month, 3 Mo, 6 Mo, Year, All, Custom change the period; Custom shows the date range picker.
- P-PORT-3: B1: header rig control lists all rigs, switching changes the global current rig; the Overview numbers equal the numbers the Ledger tab shows for that rig for the same period.
- P-PORT-4: This rig / All rigs toggle changes the source; agent chips filter; with an agent selected, expenses and profit are hidden (unchanged rule).
- P-PORT-5: Ledger and Side Ledger tabs show the same chart data as before.

### Account Ledger Daily filter (P-ACC)

- P-ACC-1: Daily chip: shows today, arrows move one day, Income, Expense, previous balance and running balance as before.
- P-ACC-2: B2: tapping the date opens a calendar; choosing any date from 2000 to 2100 shows that day; Daily stays selected; arrows still work from the chosen day.
- P-ACC-3: A chosen day without entries shows zero income and expense and the carried balance equal to the balance at the end of the previous day.
- P-ACC-4: Overflow "Date" and "Select Date Range" behave as before (custom range, tab shows All).
- P-ACC-5: Weekly, Monthly, Yearly and All chips and their arrows are unchanged.


## Forms, payment log and side ledger (g1)


Run each line before and after the redesign on Android (360 x 800) and macOS (window 1100 x 800). Use generic data only. "Rs" is the rupee amount. Results (values, messages, which field is focused, what is saved) must be identical unless the line says "layout".

### A. Main bore bill form (ledger_form_screen)

P-FL-01. Open the Ledger tab on a main bore rig, tap the add button. Title reads "New Entry"; fields appear in this order: Date, Bill Number, Agent, Address (City), Depth Details, PVC Details, MS Pipe Details, Extra Charges, Calculation Preview, Total, Commission, Payment, Less, Balance, Notes, Save.
P-FL-02. Date defaults to today. Tap it, pick another date: the field shows it, Save stores that date.
P-FL-03. Leave Bill Number empty, tap Save: message "Bill number is required" under the field; nothing is saved.
P-FL-04. Type a bill number that exists on another bill of the same rig (different letter case): the warning icon and note appear, Save shows "Bill number already exists", nothing is saved. Same number on a different rig is accepted.
P-FL-05. Edit an existing bill and keep its own bill number: no duplicate warning.
P-FL-06. Leave Agent empty, tap Save: "Please select an agent". Select an agent and Save passes this check.
P-FL-07. Tap the add-agent button, leave the name empty, tap Add: "Agent name is required" and the dialog stays open. Enter a name (and optionally a phone), Add: the agent is created and selected, and the agent's default commission rates fill the three commission rate fields (new bill only).
P-FL-08. Leave Address empty, Save: "Address is required". Type 2 letters of an earlier address: suggestions from earlier bills of this rig appear; choosing one fills the field.
P-FL-09. Depth Type options are exactly 7inch and 8inch; PVC Type 7inch and 8inch; MS Pipe Type only 6inch.
P-FL-10. Numeric fields accept digits and one decimal point; typing letters or a second decimal point is ignored; paste "1,000" gives "1".
P-FL-11. Depth 100 ft, Rate 50 (7inch): Step Rate and Total fill automatically; Calculation Preview rows show Depth (100.0 ft x Rs 50.0) = 5,000.00, Step Rate, PVC 0.00, MS Pipe 0.00, Extra Charges 0.00, Total = the computed total.
P-FL-12. Edit Step Rate by typing: the manual marker appears with a refresh action; Total uses the typed step rate; press the refresh action: Step Rate returns to the computed value.
P-FL-13. Change Depth Type from 7inch to 8inch with Step Rate auto: Step Rate recomputes; with Step Rate manual it is unchanged.
P-FL-14. PVC feet 20, rate 40, MS feet 10, rate 60, Extra Charges 100: Total increases by 800 + 600 + 100 relative to P-FL-11 (check against the Calculation Preview Total).
P-FL-15. Type a different Total: the manual marker and "Auto" button appear; Balance recomputes from the typed Total; press Auto: Total returns to the computed value. The Calculation Preview Total keeps showing the computed total.
P-FL-16. Commission: enter Depth rate 2, PVC rate 1, MS rate 1 with feet from P-FL-11/14: Commission field = 100 x 2 + 20 x 1 + 10 x 1 = 230.00; helper under each rate shows "<feet> ft = Rs <part>". Total is NOT changed by commission.
P-FL-17. Type a different Commission: manual marker and "Auto" appear; changing a rate afterwards does not change the typed commission; press Auto: it recomputes.
P-FL-18. Add a payment (Add payment, amount 1,000, Cash): the Payments received list shows it with date and receiver; Total Received = 1,000.00; Balance = Total - 1,000 - Less.
P-FL-19. Less = 200: Balance = Total - received - 200 (2 decimals). The Balance field cannot be edited.
P-FL-20. Notes is optional; leaving it empty stores no note.
P-FL-21. Tap Save with all required data: the form closes, snackbar "Entry added", the bill appears in the ledger with the entered values; Total, Received, Balance, Commission on the card match the form.
P-FL-22. Open the bill again: every field, the payments and the manual/auto states are restored; "Update Entry" label; Delete icon visible in the header.
P-FL-23. Edit a value and Update: snackbar "Entry updated", the card shows the new value; the stored commission rates of an old bill are not overwritten by the agent's current defaults.
P-FL-24. Delete icon: dialog "Delete Entry" with Cancel and Delete. Cancel: nothing changes. Delete: snackbar "Entry deleted", form closes, the bill is gone from the ledger.
P-FL-25. Delete a bill that has a payment linked to a receiver book: the matching Income entry in that book is removed (it appears in the Account Ledger trash).
P-FL-26. New bill from an agent with no default rates: commission rate fields stay empty (shown blank, not "0").
P-FL-27. Save twice quickly: exactly one bill is created.
P-FL-28. Press back after typing something: after the redesign a discard prompt appears; before the redesign the form closes silently (documented behavior change; confirm with the developer, B-G1-14).
P-FL-29. Save button reachable: at 360 x 800 Save and the live Total/Balance are visible without scrolling after the redesign (layout).
P-FL-30. macOS: the form is centered; width is 700 today and 640 after the redesign (layout); fields keep the same order; Cmd+S saves, Esc closes.
P-FL-31. Text scale 200 percent: every section remains usable with no overflow (layout).
P-FL-32. Payment block (see Section B) behaves identically inside this form: cash only, no mode selector, no payer field.
P-FL-33. Exported CSV and PDF of this bill (Export screen) contain the same Total, Received, Balance and Commission as before.
P-FL-34. A bill saved with Received = sum of payments: `received` equals Total Received shown; PhonePe is 0 on main bore.
P-FL-35. Change Depth feet only (rate 0): Total 0.00 and Balance negative of received; no error.
P-FL-36. Empty numeric fields are treated as 0 (clear Depth and Rate: Total 0.00).
P-FL-37. Add agent from the dropdown plus button while a payment dialog was never opened: no side effects on payments.
P-FL-38. Switching agent on a NEW bill replaces the three commission rate texts with the new agent's defaults and recomputes commission (unless commission is manual).
P-FL-39. Switching agent on an EDITED bill does not change stored commission rates.
P-FL-40. Address suggestions list is capped at about 200 dp tall and does not include the exact text already typed.

### B. Payment log (payment_log_editor)

P-PL-01. Empty bill: card shows "No payments yet", Total Received Rs 0.00.
P-PL-02. Add payment: dialog fields in this order: Amount, (mode, side bore only), Date, Received by, (PhonePe payer name, PhonePe only), Note.
P-PL-03. Amount empty or 0, Save: "Enter an amount" under Amount, dialog stays.
P-PL-04. Amount 1,234.567 saves as 1,234.57.
P-PL-05. Received by lists "No receiver", receiver books first then other books (suffix "(book)") sorted by name, and "New receiver".
P-PL-06. New receiver: prompt for a name; the book is created as a receiver and selected; an existing name shows an error.
P-PL-07. Edit a payment (tap the row): fields prefilled; Save keeps the same payment (same id) and updates totals.
P-PL-08. Remove (trash icon): the payment disappears and Total Received drops by its amount (after the redesign an Undo snackbar offers to restore it).
P-PL-09. Older bill with unlogged received money shows an "Earlier received" row; tap edits cash (and PhonePe on side bore); the amount counts in Total Received.
P-PL-10. Receiver link: after saving the bill, the selected book has an Income entry for the amount and date; editing the amount in the book updates the payment on the bill.
P-PL-11. Payment date keeps the chosen day; editing the date keeps the original time.
P-PL-12. Side bore: switching mode to PhonePe shows the payer name field; Cash hides it and stores no payer.
P-PL-13. Payer suggestions list names used on earlier PhonePe payments or bills (this rig).
P-PL-14. Enter key (desktop) in the Note field saves the dialog (after the redesign); Esc cancels.

### C. Side bore bill form (side_bore_form_screen)

P-SB-01. Open the add form on a side bore rig. Fields in order: Date, Bill Number, Agent, Address (City), Depth Details (Depth (ft), Rate/ft (Rs)), Total, Commission (one rate field), Payment, Less, Balance, Notes, Save. No step rate, PVC, MS pipe or extra charges.
P-SB-02. Bill Number, Agent and Address validations and messages equal P-FL-03 to P-FL-08.
P-SB-03. Clear Depth and tap Save: "Required" under Depth; same for Rate.
P-SB-04. Depth 100, Rate 50: Total shows Rs 5,000.00 (Auto).
P-SB-05. Toggle to Manual, type 4,500: Total shows 4,500 and Balance follows; toggle to Auto: Total returns to 5,000.00.
P-SB-06. Commission rate 2: commission = 100 x 2 = 200.00; manual override and Auto as P-FL-17; commission not added to Total.
P-SB-07. Add a PhonePe payment of 1,000 with a payer name, and a Cash payment of 500: Total Received 1,500.00; Balance = Total - 1,500 - Less.
P-SB-08. Balance colors (layout): positive amount outstanding, zero paid in full, negative overpaid are visually distinct after the redesign; values identical.
P-SB-09. Save: bill stores `received` = cash + PhonePe, `receivedCash`, `receivedPhonePe`, and the entry's PhonePe name is the latest PhonePe payer.
P-SB-10. Edit and Delete behave as P-FL-22 to P-FL-25.
P-SB-11. Add agent dialog on this form has a name field only; an empty name now shows an inline error (before: closed silently, B-G1-04).
P-SB-12. Open an entry dated before 2020: the date picker opens without an error and Cancel keeps the date (B-G1-02).
P-SB-13. Double tap Save creates one bill.
P-SB-14 to P-SB-30. Repeat P-FL-27 to P-FL-40 for the fields that exist on the side bore form (discard prompt, Save reachability, macOS width, text scale, exports).

### D. Diesel

P-DL-01. Open Diesel Ledger from the Side Ledger tab: header "Diesel Ledger", summary Entries, Total Litres, Total, Paid, Pending, entries newest first.
P-DL-02. Summary equals the sums of the shown cards (litres, total, paid, pending).
P-DL-03. A card shows "#<bill>", date, litres, total, rate per litre, "Paid" amount, a "Due" chip only when pending is above 0, and the bunk line when non-empty.
P-DL-04. Filter by bunk text (any case): only matching entries and totals; the filter indicator is visible; Clear All restores everything.
P-DL-05. Date range filter includes entries on the end date.
P-DL-06. Empty list: "No diesel entries yet". With a filter and no matches: "No entries match your filters" with Clear Filters.
P-DL-07. Tap a card: edit form prefilled. FAB: empty form.
P-DL-08. Delete from a card: dialog "Are you sure you want to delete diesel entry #<bill>?"; Cancel keeps; Delete removes it and shows "Entry deleted".
P-DF-01. Add Diesel Entry fields in order: Date, Bill Number, Litres, Rate/L, Total Amount, Paid Amount, Pending/Balance, Paid Date, Bunk Details, Notes, Save.
P-DF-02. Bill Number accepts digits only; empty: "Please enter a bill number".
P-DF-03. Litres and Rate/L: empty "Required"; letters impossible; "." alone "Invalid".
P-DF-04. Litres 100, Rate 90: Total Rs 9,000.00; Paid 4,000: Pending Rs 5,000.00; Paid 9,500: label "Balance (Advance)" Rs 500.00.
P-DF-05. Paid Date optional: set, clear (x), "Not set" shown when empty.
P-DF-06. Same bill number as another diesel entry of this rig: message 'Bill number "<n>" already exists', nothing saved. Same number on another rig accepted.
P-DF-07. Save: snackbar "Entry added"/"Entry updated"; list shows the entry.
P-DF-08. Edit, change litres, Update: total and pending recalculated and stored.
P-DF-09. Double tap Save: one entry. Back after typing: discard prompt (after redesign).
P-DF-10. Save reachable without scrolling and totals visible (layout, after redesign).
P-DF-11. The form has no Delete action.

### E. PVC

P-PL2-01. PVC Ledger not offered on a side bore rig; on main bore: header "PVC Ledger", summary shows pieces per type, Total, Paid, Pending.
P-PL2-02. Card shows type text, "<n> pcs", total (sum of count x rate), breakdown lines "<type>: <count> x Rs <rate> = Rs <total>" only for 2+ types, rate per piece only for one type, Paid, Due, storage place.
P-PL2-03. Type filter (7 inch, 8 inch, 10 inch, MS) matches only the first stored type; storage place filter is case-insensitive contains; dates as diesel.
P-PL2-04. Delete message "Are you sure you want to delete PVC entry #<bill>?"; snackbar "Entry deleted".
P-PF-01. Add PVC Entry fields in order: Date, Bill Number, PVC Type chips (multi), Count & Rate per selected type, Total Amount, Paid Amount, Pending (only if above 0), Storage Place, Notes, Save.
P-PF-02. Select 7 inch (count 10, rate 100) and 8 inch (count 5, rate 200): Total Rs 2,000.00; Paid 500: Pending Rs 1,500.00.
P-PF-03. Deselect a type: its count and rate clear and the total drops.
P-PF-04. Save with no type: "Please select at least one PVC type". With a type but count or rate 0 or empty: "Please enter count and rate for <type>". Nothing saved in both cases.
P-PF-05. Duplicate bill number (same rig): 'Bill number "<n>" already exists'.
P-PF-06. Saved entry: first selected type (list order) as main type, count = sum, per-type details stored, balance = paid - total.
P-PF-07. Edit an entry saved with one type: opens with that type selected and its count and rate.
P-PF-08. Save reachable and totals visible (layout); no Delete in the form.

### F. Bit

P-BL-01. Header "Bit Ledger"; summary pieces per type, Total, Paid, Pending; empty text "No bit entries yet"; delete message "Are you sure you want to delete bit entry #<bill>?".
P-BL-02. Card: type, pcs, total, breakdown for 2+ types, Bit ID chip when non-empty, Paid, Due. Type filter options 6.5 inch, 7.25 inch, 7.5 inch, 9 inch, 9.5 inch (first stored type match).
P-BF-01. Add Bit Entry fields in order: Date, Bill Number, Bit Type chips, Bit ID, Count & Rate per type, Total Amount, Paid Amount, Pending (only above 0), Notes, Save. No storage place.
P-BF-02. Messages: 'Please select at least one Bit type', 'Please enter count and rate for <type>', duplicate bill message. Totals as P-PF-02 with the Bit types.
P-BF-03. Bit ID optional, stored trimmed, shown on the list card.

### G. Hammer

P-HL-01. Header "Hammer Ledger"; empty "No hammer entries yet"; delete message "Are you sure you want to delete hammer entry #<bill>?"; type filter options 6.5 inch, 7 inch.
P-HL-02. Card shows Hammer name chip when non-empty.
P-HF-01. Add Hammer Entry fields in order: Date, Bill Number, Hammer Type chips (6.5 inch, 7 inch), Hammer Name, Count & Rate per type, Total Amount, Paid Amount, Pending (only above 0), Notes, Save.
P-HF-02. Messages and totals as P-BF-02 with the Hammer wording.

### H. Dead code

P-DEAD-01. Search the project for `SideLedgerScreen`: only its own definition. After deletion the Side Ledger tab opens Diesel, PVC (not on side bore), Bit and Hammer lists unchanged.


## Account Ledger (g2)


Generic data only. Conventions: Book A and Book B are two books; "ledger" is the Accounts tab home. Existing parity ids from docs/features/cashbook/SPEC.md are cited as PARITY-nnn. Run the full list once on the current build (baseline) and once after the redesign; every expected value must be equal. P-xx ids are new and referenced by the screen docs.

### H. Home (cashbook_home_screen.md)
1. (PARITY-013) Tap Income: the entry form opens with the Income type selected; tap Expense: the form opens with Expense selected.
2. (PARITY-031) Add Income 1000 and Expense 400 today in Book A, Income 250 yesterday. The list is newest first, grouped under day headers; the day header text for today equals the string from before.
3. (PARITY-032) Each row shows notes, time, the amount in the Income column (Income) or the Expense column (Expense) and "Balance N" under the amount (compact layout shows the amount in one column with the same text).
4. (PARITY-033) Running balance: with entries yesterday +250, today +1000 then -400, the balances read 250, 1250, 850 in chronological order.
5. (PARITY-034) Totals: Total Income 1250, Total Expense 400, Balance 850 for tab All.
6. (PARITY-035, 076) Settings > Currency Format: Grouped, Plain, Two decimals each change every amount on the screen (rows, totals, previous balance) consistently; negative shows a leading minus.
7. (PARITY-036) Tabs All, Daily, Weekly, Monthly, Yearly each change the period; the period label shows the range; chevrons move by one period; chevrons are inactive for All, a custom range and while searching.
8. (PARITY-037) Switch to Monthly after adding an entry in the previous month: "Previous Balance" row appears first, the totals card shows "Previous Balance" and a final "Balance" = previous + period balance. Turn off Settings > Previous Balance: the row and lines disappear.
9. (PARITY-038) Make the balance negative (Expense larger than Income): values show a leading minus and the negative color.
10. (PARITY-039, 040) Toggle "Show balance after each transaction" and "Show date in each entry": row captions appear and disappear.
11. (PARITY-042) Search "rent" (notes text): list filters live, case-insensitive, across all periods; totals reflect the rows shown; closing search restores the list.
12. (PARITY-043..046) Overflow menu: Notes dialog searches; Date Ascending reverses the order; Income shows only Income and totals recompute; Expense likewise; Income and sort combine; Clear filters resets all.
13. (PARITY-043) Overflow "Select Date Range" with start and end sets a custom range; the "All" chip stays selected; chevrons inactive.
14. (PARITY-048) Tap a row: Edit Transaction opens; long press does the same.
15. (PARITY-006) Tap the book name: picker dialog; choose Book B: the ledger switches and filters clear.
16. (PARITY-080) A new empty book shows an empty list and totals 0.
17. (P-DAILY) The Daily date picker behavior is tested with screens/accounts_daily_date_picker.md, not here.
18. (P-HOME-A11Y) At 200 percent text size, 360 dp wide, no text is clipped and the Income and Expense buttons remain reachable.
19. (P-HOME-REPORT) Report button creates the PDF from what is on screen (see section R).

### HUB. Hub (cashbook_hub_screen.md)
20. (PARITY-077) Open each of the 12 destinations from the drawer (mobile) or left pane (macOS wide): Summary, Account Summary, Transaction-All Accounts, Accounts, Report-All Accounts (dialog), Transfer, Notebook, Calendar, Import from cashbook app, Settings, Help, Deleted Transactions.
21. (PARITY-083) The Account Ledger is the fifth tab on both shells.
22. (P-HUB-CMDN) macOS: Cmd+N opens the Income form for the current book.
23. On macOS with width >= 900 the ledger and hub show side by side; below 900 only the ledger with a menu button.

### X. Common (cashbook_common.md)
24. (P-RANGE) Date range dialog: Start 5th and End 2nd of the same month returns the range 2nd to 5th (swapped); Start = End = one day returns that single day; the range is inclusive of the end day (the entry at 23:30 on the end day is included).
25. Amount fields ignore letters and the minus sign and accept one decimal point; "1,234.5" typed in the calculator-less field parses as 1234.5.
26. Confirm dialogs: Cancel returns without changes.

### B. Books (cashbook_books_screen.md)
27. (PARITY-002, 004) Add Account "Book C" with Opening Balance 500 positive: Book C exists and has one Income of 500 noted "Opening Balance" at the chosen date; with "-" the entry is an Expense.
28. (PARITY-003) Add Account with an empty name: the dialog closes, no book is created.
29. (PARITY-005) After creating a book the current book does not change.
30. (PARITY-007) Accounts screen lists every book with its balance; search filters by name.
31. (PARITY-008) Rename Book C to "Book D": entries remain attached.
32. (PARITY-009, 010) Delete Book D: two confirmations ("Delete", "Are You Sure ?"); its entries appear in Deleted Transactions; the book is gone from the lists; deleting the only book shows "Cannot delete the last book".
33. (PARITY-011) Opening Balance dialog: change the amount to 800 and sign to "-": the existing "Opening Balance" entry changes in place (no second entry).
34. (PARITY-082) A book created with "Receiver book" on shows as a receiver in the Accounts list and in the picker.
35. (PARITY-012) Pick Book B, close and reopen the app: Book B is still current.

### E. Entry form (cashbook_entry_form_screen.md)
36. (PARITY-014) Field order: type, date with arrows, time, amount, notes, (description), (account in edit), Add Bills, Add Items.
37. (PARITY-015) New entry date is today, time is now; time format follows Settings (12 or 24 hour).
38. (PARITY-016) Type can be switched inside the form with the two options.
39. (PARITY-017) Amount: typing "12a-3.456" results in "123.456"; the keyboard is decimal.
40. (PARITY-018) Empty amount: Save and exit and Save and continue do nothing (form stays, amount focused).
41. (PARITY-019, 020) Amount 0 can be saved. Amount 1.239 saves as 1.24 and shows 1.24 in the list.
42. (PARITY-021) Notes empty is allowed; a note with a newline saves with the newline.
43. (PARITY-022, 023) Date arrows move one day and cross a month end; time of day is unchanged; a future date can be saved.
44. (PARITY-024) Save and exit returns to the list with the new row.
45. (PARITY-025) Save and continue: amount, notes, items and bills clear; "Saved" snackbar; the form stays; the date and type stay.
46. (PARITY-026) Calculator: type 12+3.5*2 -> result 19; Use fills the amount with 19; 5/0 gives no result and Use is disabled; "00" and "000" keys append zeros; C clears; DEL removes one character.
47. (PARITY-027) With "Notes suggestion" on, typing a prefix of an earlier note shows up to 5 suggestions; off hides them.
48. (PARITY-028) With "Add description / Category" on, the field shows under Notes; the form menu can toggle it per form.
49. (PARITY-029) Add Items: add "Pipe" qty 2 rate 150 and "Joint" qty 3 rate 40: total 420; OK sets the amount to 420; Cancel leaves the amount; removing an item updates the total; the count reads "Item (2)".
50. (PARITY-030) Add Bills offers Camera (mobile only), Gallery, PDF; a fourth bill shows "Up to 3 bills per entry".
51. (PARITY-049, 050) Edit form: the Account dropdown moves the entry to another book on Save; Back discards changes without a prompt.
52. (PARITY-051) Copy to same account opens a prefilled add form (same date, time, amount, notes); to a different account asks for the account first and prefills it.
53. (PARITY-052) Delete asks confirmation, moves the entry to Deleted Transactions; totals and balances update.
54. (PARITY-081) For an entry created from a bill payment (link icon), the type control is locked; the other fields edit and the bill follows.

### T. Transfer (cashbook_transfer_screen.md)
55. (PARITY-057, 058) Transfer 500 from Book A to Book B, notes "Rent": A gets an Expense of 500 noted "To Book B" plus newline plus "Rent"; B gets an Income of 500 noted "From Book A" plus newline plus "Rent"; balances change by 500.
56. (PARITY-059) After success the form clears and stays open; date resets to now.
57. (PARITY-060) Empty amount: nothing happens.
58. Same book in From and To: the provider refuses with an error (or the UI prevents selection).
59. (P-TRANSFER-ONCE) Activating Transfer twice quickly creates exactly one pair.

### S. Summary screens (cashbook_summary_screen.md, cashbook_account_summary_screen.md, cashbook_all_transactions_screen.md, cashbook_calendar_screen.md)
60. (PARITY-061) Summary: one card per book with entries (Total Income, Total Expense, Balance) and a grand total strip equal to the sum; all five tabs and custom range work; tapping a card makes that book current and returns to the ledger.
61. (PARITY-062) Account Summary: for a month with entries on 3 days, three rows (newest first) each with Income, Expense, Savings = Income - Expense; totals strip equals the sums and excludes the previous balance; no Daily tab; the book selector changes the book without changing the ledger's current book.
62. (PARITY-063) Transaction-All Accounts: entries of both books grouped by day, newest first, each row with the book name; search by notes, description and book name; totals follow the visible rows; tapping a row opens its edit form.
63. (PARITY-064) Calendar: month grid shows per-day Income (green) and Expense (red) sums that equal the sums of that day in the ledger; Sunday first; the 1st sits under the right weekday; month chevrons change the month; tapping a day with entries lists them; a day without entries does nothing; month totals equal the ledger's Monthly totals for that book without previous balance.

### N. Notebook (cashbook_notebook_screen.md, cashbook_note_form_screen.md)
64. (PARITY-065) Notebook lists notes for the period with tabs All, Daily, Weekly, Monthly, Yearly, a checkbox per row and the stats Completed, Pending, Total.
65. (PARITY-066) Add note: date, time, multi-line text, Save; edit adds Delete with a confirmation ("Delete this note?"); empty text on edit shows "Enter a note".
66. (PARITY-067) Checking a note marks it completed immediately and updates the stats; unchecking reverses.
67. (PARITY-068) Overflow: Completed and Pending filter (selecting again returns to all); Date Ascending and Date Descending sort; stats always count the whole period.
68. (P-NOTE-ONCE) Activating Save twice quickly in add mode creates one note.

### D. Deleted transactions (cashbook_trash_screen.md)
69. (PARITY-053) Deleted entries list with date, time, book, days left and amount; tapping a row offers Restore or Delete; overflow offers Delete All.
70. (PARITY-054) Restore returns the entry to its book; balances recompute.
71. (PARITY-055) Delete asks "Delete Transaction" confirmation and removes the entry permanently.
72. (PARITY-056) Entry deleted with its book: Restore asks to pick a book first; Cancel aborts.
73. (P-TRASH-PLURAL) An entry with exactly one day left reads "1 day left" after the fix; all others read "N days left".

### G. Settings (cashbook_settings_screen.md)
74. (PARITY-076) Settings screen holds: Format Date (6 patterns), Show Time, Time Format, Currency Format, the six display switches, Your Name and Address; all persist across restarts.
75. (P-DATEFMT) On a day where day equals month (for example set the device date to 10 Oct) the Format Date dialog lists all six patterns.
76. (PARITY-079) "Your Name and Address" appears on reports; clearing it removes it.
77. Labels are Income and Expense everywhere (PARITY-078).
78. (PARITY-084) Amounts show with the same currency prefix as before the redesign unless the Rs. versus rupee decision is made.

### I. Import (cashbook_import_screen.md)
79. Choose a backup file: the dry run shows counts, period, totals and book list; nothing is written; the "Import" confirm opens with the counts.
80. Import: result counts; running it again reports every entry as skipped (no duplicates); the file is unchanged.
81. A wrong file shows an error and writes nothing.

### R. Reports (cashbook_report_dialog.md)
82. (PARITY-069, 070, 071) Ledger home Report > PDF: A4, centered book name, range line, table oldest first with running balance, summary lines; with a search or Income filter active only those rows are exported; CSV has the same rows (UTF-8 with BOM).
83. (PARITY-072) Report-All Accounts > All > PDF: all books, no balance column, summary box; with a custom range only that range.
84. (PARITY-074) File names: '<Book> <MMM-dd-yyyy>.<ext>' and 'cashbook <MMM-dd-yyyy>.<ext>'.
85. (P-RPT) Compare a PDF and a CSV from the baseline build and the redesigned build for identical data: text content identical (dates, amounts, ranges "<start> To <end>").
86. Report with no rows shows 'Nothing to export' and creates no file.

### Z. Help (cashbook_help_screen.md)
87. All 8 topics are present with the same titles and text.

### Cross-cutting
88. At 130 percent and 200 percent text scale every Account Ledger screen shows no overflow stripes and no clipped amounts.
89. macOS: Tab order follows reading order; Esc closes dialogs; focus ring visible.
90. Light theme only; no dark mode toggle appears.


## Agents, settings, exports, stats (g3)


Use generic data (Agent A, Agent B, Rig 1, Rig 2). Run each line before the redesign (baseline) and after; results must be identical in content (layout may differ). "Same" means the same numbers, rows, messages and files.

### Agents
1. Open Agents with no agents: an empty state with an Add Agent button shows.
2. Add Agent A with name only: success message "Agent added"; card shows 0 bills; commission total 0.
3. Add Agent B with phone "9000000000", notes "Test", rates Depth 50, PVC 20, MS pipe 30: card shows phone and default rates.
4. Add with blank name: error "Name is required"; no agent created.
5. Add a second "agent a" (different case): error "An agent with this name already exists".
6. Edit Agent B: change phone, rates to 60, 25, 35, Save: "Agent updated"; reopen shows saved values; rate field shows empty (not 0) when the rate is 0.
7. Rename Agent B to "Agent A" (duplicate): current behavior is that it saves (record for baseline; see bugs_g3 G3-B12).
8. Create a bill for Agent B: commission rates prefill 60, 25, 35 (default rates copied).
9. Agent with 2 bills and commission: card shows "2 bills" and the commission total equal to the sum shown in Portfolio for that agent.
10. Delete an agent with 0 bills: confirmation, then removed; message "Agent and entries deleted" only when bills existed else the same delete message path (record text).
11. Delete Agent A with 3 bills choosing Reassign to Agent B: Agent B bill count increases by 3; message "Agent deleted and entries reassigned".
12. Delete Agent A with 3 bills choosing Delete all: the 3 bills are gone from the Ledger tab and Portfolio totals drop accordingly.

### Settings
13. Settings shows sections Vehicle, Export & Import, Backup & Restore, Google Drive Backup, Data, About in this order; Vehicle row shows "Current: <rig name>".
14. Create Backup: file named rigledger_backup_<yyyyMMdd_HHmmss>.json is saved or shared; message "Backup created successfully"; cancelling the save shows no success message.
15. Restore Backup with a file produced in line 14 on a device with changed data: after restore all screens (Ledger, Portfolio, Agents, Accounts, Side Ledger) show the backup data; "Backup restored successfully".
16. Restore with a non-backup JSON: record the outcome (baseline: failure or empty data; compare after).
17. Cancel the restore confirmation: no file picker (baseline) or no change (after); data unchanged.
18. Clear All Data: confirm, everything is gone, one default rig and the default cash book remain; message "All data cleared".
19. Drive card signed out: shows "Google Drive not connected" and Connect; sign in shows email, Last backup, Auto Backup toggle (default off), Backup Now, Restore from Drive.
20. Auto Backup toggle persists after leaving and returning to Settings.
21. Backup Now: spinner, then "Backup successful" and Last backup updates to "Just now".
22. Restore from Drive: confirmation, data replaced, "Data restored successfully"; with no backup: "No backup found on Google Drive".
23. Disconnect: confirmation, card returns to signed-out state.
24. About row text shows "Version <x> (build <n>), license, notices" and opens About.
25. Manage Vehicles opens vehicle management; Export to CSV, Import from CSV, Export to PDF open their screens.

### About
26. About shows app name, version and build equal to pubspec, package id, the three info sections with the same sentences, License (opens text), Open source licenses (opens Flutter license page with fonts listed), Developer link opens the browser, copyright footer.

### Vehicles
27. List shows all rigs with type text, the active rig has "Active"; the active rig cannot be tapped to switch.
28. Tap Rig 2: switches, search and filters reset, message "Switched to Rig 2", returns to Settings; Ledger now shows Rig 2 data.
29. Add Vehicle with blank name: "Please enter a vehicle name". Add "Rig 3" as Side Bore: appears in list; PVC is hidden for it in Ledger and Portfolio.
30. Edit Rig 3 name and type: "Vehicle updated".
31. Delete the last remaining rig: "Cannot delete the last vehicle".
32. Delete the active rig (two rigs exist): another rig becomes active, data of the deleted rig is gone, "Vehicle deleted".

### PDF export
33. Defaults: type Ledger, From = today minus 30 days, To = today, all columns selected (PVC columns hidden for side bore).
34. Summary card: entries count, Total, Received, Balance, Commission (not in total), 7" and 8" depth, 7" and 8" PVC (not for side bore), MS Pipe; values equal the PDF summary page values.
35. Selecting Diesel/PVC/Bit/Hammer changes the summary to that category (Total Litres or Total Count, Total Amount, Paid, Pending).
36. Column selection: All, None, individual chips; exported PDF has exactly the selected columns in the original order.
37. Export: file name rigledger_<type>_<yyyyMMdd>_to_<yyyyMMdd>.pdf; success message "PDF exported successfully".
38. Preview: shows the same document as exported; page count equal; 22 rows per page.
39. Zero entries: Export disabled with "No <Type> entries found in the selected date range."
40. PDF content (frozen): compare page 1 text of a baseline export and a post-redesign export for the same data and range: identical.

### CSV export
41. Defaults: Ledger, Export all entries on; entries count equals rows in the file; header chips list equals the CSV header row (21 columns for Ledger).
42. Turning Export all off shows From/To (default last 30 days); file name rigledger_<type>_export_<start>_to_<end>.csv; with all on rigledger_<type>_export_all_<yyyyMMdd>.csv.
43. Diesel/PVC/Bit/Hammer export uses the active rig only; PVC hidden for side bore.
44. Zero entries disables Export.
45. CSV content identical to baseline for the same data (diff the files).

### CSV import
46. Select File: pick a CSV; "N rows found (excluding header)"; empty file shows "CSV file is empty".
47. Map Columns: shows 16 expected fields with Date, Bill number, Agent name required (starred); auto mapping result equals baseline (record it; includes the known mismatch with the app's own export).
48. Validate: counts of valid and error rows equal baseline; messages "Bill number is required", "Agent name is required", "Invalid date format", `Agent "X" not found` (when auto-create is off).
49. Auto-create missing agents on: new agent names are created; off: rows with unknown agents error.
50. Import: bills appear in Ledger of the active rig; message "Successfully imported N entries"; totals equal CSV TOTAL values; imported entries have depth and PVC defaults '7inch' when empty.
51. Double click Import quickly: baseline may duplicate (record); after redesign exactly one import.

### Stats (Ledger and Side Ledger tabs, chips)
52. Chips Day, Month, 3 Mo, 6 Mo, Year, All, Custom: each shows the same Total, Entries, Received, Pending as baseline for the same data; Custom defaults to first of this month to today.
53. By Agent: slice shares and legend amounts and percents equal baseline; sorted by total descending; sums of percents about 100.
54. Side Ledger tab: for each category the Paid and Due percents and amounts equal baseline; Detailed Statistics values (Total Litres, Total Amount, Avg Rate, Total Count, per-type pcs, Total Value, Paid, Pending) equal baseline.
55. Side bore rig: no PVC chart or card.
56. No data in the period: By Agent empty message, mini cards "No data", detail cards "No entries in selected period".
57. Overview tab (lead) receives the same range as the chips: change the chip and verify Overview figures change.

### App startup (main)
58. Cold start offline: app reaches the ledger; data intact.
59. With Drive signed in: sync triggers on launch, every 5 minutes (observe the sync status), and when returning from background.
60. macOS: window opens 1280 x 820 centered, minimum 900 x 600, hidden title bar, title RigLedger.
61. Android: portrait only, immersive mode.

### Theme and widgets
62. Primary color of buttons, selected chips, FAB equals the seed; snackbars keep readable text.
63. Any unstyled AppBar (License page from About) has a legible title and back arrow.


## Reconciliation 2026-10-13 (Apple look, Android only)

### Global lines added or changed

- G-9: Money on every screen shows the rupee sign, en-IN grouping, two decimals only when the value has paise (59,000 not 59,000.00). Account Ledger no longer shows "Rs.". EXPORTS (PDF and CSV) keep their own formats and must stay byte-identical (G-3).
- G-10: No UI string says "Vehicle" (switcher, Rigs screen, dialogs, snackbars); it says "Rig". Code identifiers are unchanged. Tab labels: Ledger, Portfolio, Agents, Accounts, Settings.
- G-11: Every screen is checked in Light and Dark (and System follows the device), with the same data.
- G-12: Android back: closes the keyboard first, then the top sheet or dialog, then the screen; on a root tab nothing happens (Q-O6 decides). A form with unsaved edits asks "Discard changes?"; a clean form does not.
- G-13: Text scale 130 and 200 percent (system largest): no overflow, no clipped digits, nothing under 11 sp, targets 48 dp.
- G-14: Smallest width 360 dp and test width 412 dp; portrait lock unchanged; gesture and 3-button navigation both leave content visible above the inset.
- G-15: Feet show up to one decimal with a trailing .0 hidden (350, 350.5) in the bill card, summary tiles and form pre-fill; stored values are unchanged.
- G-16: Category colours: Diesel orange, PVC teal, Bit purple, Hammer pink on tiles, lists, forms and charts.

### Lines that change on purpose

| Old line or area | New expected result | Reason |
|---|---|---|
| PARITY-003 (Add Account empty name closes silently) | Save is disabled while the name is empty | LR-27, answer 19 |
| Every Account Ledger line that expects "Rs." | the rupee sign | LR-24, answer 3 |
| Account Ledger date text `MMM-dd-yyyy` default | `d MMM yyyy` default; a stored user choice is kept (Q-O8) | LR-24 |
| g3 Settings: Clear All Data text and Restore order | text names that Account Ledger books and notes are erased; Restore asks for the file first, then confirms | LR-28 |
| g2 section E: Add Items OK with a half-typed row | warning 'Add this row or discard it' | LR-26 |
| Bill, side ledger and Account Ledger forms: back with unsaved edits | 'Discard changes?' alert | LR-25 |
| g1 A, C, D, E, F, G: two quick Save taps | one record | LR-32 |
| P-LED-6 calendar day totals in non-Month periods | only entries of the selected month are summed | LR-33 |
| g3 Stats Ledger tab label "Pending" | "Balance" (Ledger tab only; Side Ledger and side lists keep "Pending") | answer 10 |
| P-PORT range chips order | Month, 3 Mo, 6 Mo, Year, Custom, All (Day per Q-O1) | answer 5 |
| g3 CSV import after export (round trip) | depth feet, depth rate, PVC and MS pipe, extra charges are imported (before: zeros) | LR-31 |
| P-LED-12 and P-PORT-3 rig switch | search and all side filters are cleared; every per-rig list shows the new rig | LR-01 |
| P-ACC-2 Daily date | the date is a button that opens a date sheet; Daily and arrows stay | LR-02 |
| Feet text in bill card, summary and form (any line that expects `500.0ft`, `450 ft` or whole feet) | 500 and 450.5 style (G-15) | answer 16 |
| Bit and Hammer colours in lists, FAB and Save buttons | purple and pink | answer 8 |
| Bottom navigation | floating capsule with the same five tabs and the same destinations | A2 |

### Lines DROPPED (macOS out of scope, frozen)

P-DSK-1 to P-DSK-7, the macOS menu bar, Cmd+1..5, Cmd+N, Cmd+S, Cmd+F, desktop title bar, sidebar, window sizes (900 x 600, 1280 x 820), hover and context menu lines, the g2 hub two-pane line (desktop), the g3 App startup lines about window manager and desktop auth, and every parity line that begins "macOS". The code stays untouched; these lines return only if macOS is revived (Q-O9).

### Lazy tabs and theme (new lines)

- L-1: Cold start: only Ledger and Accounts trees exist after launch (no Portfolio, Agents or Settings build; verify with the DevTools widget inspector or a debug log in the lazy wrapper during the task).
- L-2: First tap on Portfolio builds it once; it shows current data (including a bill added before the first visit).
- L-3: Leave Portfolio and return: selected range chip, This rig / All rigs, agent filter and scroll position are kept.
- L-4: Same for Agents (scroll, open sheets are closed) and Settings (scroll, Appearance value).
- L-5: Add a bill on the Ledger, open a lazy tab built earlier: its numbers update (providers, not snapshots).
- L-6: Switch rig, then open a lazy tab not yet visited and one already visited: both show the new rig.
- L-7: Settings, Appearance: choose Dark: the whole app switches immediately, including open lazy tabs; restart keeps Dark.
- L-8: Appearance System: change the device theme: the app follows without restart; Light and Dark ignore the device.
- L-9: Backup then Restore does not change the Appearance value (device setting, not part of the backup JSON).
- L-10: Sync merge does not touch the Appearance key.
- L-11: Every screen in Light and Dark: no text under 4.5:1 (spot check with the contrast test and a color-picker on 5 screens), no raw white boxes in Dark, charts readable.
- L-12: Keyboard open on a long form: the focused field and the Save pill are visible; the tab bar is hidden.
- L-13: Predictive back (Android 13 and up): back gesture on a form with unsaved edits shows the discard alert; on a clean form it pops with the system animation.
- L-14: Blur flag off by default: no BackdropFilter in the widget tree (test); if turned on in a debug build, bars blur and lists still scroll under 16 ms p99.
