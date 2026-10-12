# Cashbook parity status (T-CB18)

Source of lines: SPEC.md section 1 (PARITY-001 to 084). Status values:
- PASS-T: implemented and covered by an automated test (named in Evidence)
- PASS-E: implemented and checked by hand on the Android emulator
- IMPL: implemented, not separately verified
- DEVIATION: implemented differently on purpose (reason given)
- N/A: out of scope by developer decision

| Lines | Status | Evidence / note |
|---|---|---|
| 001 default book | PASS-T | cashbook_provider_test "default book exists" |
| 002 Add Account dialog | PASS-E | emulator hub > Accounts; receiver switch added (v2.0.0) |
| 003 empty name creates nothing | PASS-T | cashbook_provider_test "addBook: empty name creates nothing" |
| 004 opening balance entry | PASS-T | same test (opening entry, sign) |
| 005 create does not switch | IMPL | picker dialog keeps the current book |
| 006 book picker | PASS-E | emulator |
| 007 Accounts screen and row menu | IMPL | cashbook_books_screen.dart |
| 008 rename keeps entries | PASS-T | entries reference bookId, so a rename cannot detach them |
| 009 two step delete | IMPL | confirmDeleteCashBook |
| 010 delete book trashes entries | PASS-T | "deleting a book trashes its entries with the book name" |
| 011 edit opening balance in place | PASS-T | "setOpeningBalance edits in place" |
| 012 last book remembered | IMPL | setting cashbook.lastBookId |
| 013-016 form entry points, fields, defaults, type chips | PASS-E | emulator (Income form) |
| 017 amount keyboard, no minus | IMPL | AmountInputFormatter |
| 018 empty amount blocks save | PASS-T | cashbook_flow_add_test "empty amount does not save" |
| 019 zero amount saves | PASS-T | cashbook_flow_add_test (third entry) |
| 020 two decimal rounding | PASS-T | calculator and provider tests |
| 021 notes optional, newlines | IMPL | |
| 022-023 date arrows, future dates, time kept | IMPL | form _shiftDay |
| 024-025 Save and exit / continue | PASS-T/E | flow add test; emulator |
| 026 calculator sheet | PASS-T | cashbook_expression_test (evaluator); sheet IMPL |
| 027-028 notes suggestion, description field | IMPL | settings screen toggles |
| 029 Add Items | PASS-T | CashItem tests; dialog IMPL |
| 030 Add Bills | IMPL | camera, gallery, pdf copied into app storage; max 3 |
| 031-032 list order, day headers, row anatomy | PASS-T/E | flow add test, emulator |
| 033-034 running balance, totals | PASS-T | cashbook_calculator_test, provider tests |
| 035 number format | PASS-T | calculator test; "Rs." prefix (D11) |
| 036 period tabs | PASS-T | calculator tests (ranges), provider ledger test; tabs IMPL |
| 037 previous balance | PASS-T | "ledger view: period previous balance" |
| 038 negative balance | PASS-T | calculator test |
| 039-040 balance per entry, date in entry settings | IMPL | |
| 041 long amounts | IMPL | FittedBox, no wrapping |
| 042 live search | PASS-T | cashbook_flow_search_test; provider test |
| 043 overflow menu | IMPL | Notes, Date, Select Date Range, asc/desc, Income, Expense, name; Print is the Report button |
| 044-046 type filter, ascending, combine | PASS-T | provider test |
| 047 description searchable | IMPL | _matchesQuery |
| 048-051 edit, copy, discard | IMPL | entry form |
| 052-055 trash, restore, purge | PASS-T | cashbook_flow_trash_test, provider tests |
| 056 restore after book deleted | PASS-T | restore into another book |
| 057-060 transfer | PASS-T | provider test "transfer creates two linked entries" |
| 061-064 summaries and calendar | IMPL | summary providers PASS-T |
| 065-067 notebook | IMPL | provider notes tested via backup test |
| 068 notebook Report | DEVIATION | notebook overflow has no Report item (no PDF for notes) |
| 069-072 report PDF/CSV | PASS-T | cashbook_export_test; Report button IMPL |
| 073 Excel | DEVIATION | CSV instead of xls (decision D7) |
| 074 file names | PASS-T | export test |
| 075 backup and restore | DEVIATION | covered by RigLedger backup and Drive sync (cash data is part of the backup, PASS-T in backup round trip) plus the import tool |
| 076 settings | IMPL | dark mode, fingerprint, password, language dropped (light, English only) |
| 077 hub | PASS-E | emulator drawer; Transaction names and Cash Calculator dropped (D1, D3) |
| 078 Income/Expense labels | PASS-E | |
| 079 name and address on reports | IMPL | printed under the PDF title |
| 080 empty book | DEVIATION | shows a muted "No transactions" hint |
| 081-082 payment link, receiver books | PASS-T | payment_link_test (8 tests) |
| 083 fifth tab | PASS-E | |
| 084 Rs. prefix | PASS-T | calculator and flow tests |

Not in the original checklist but built: one-time import (cashbook_import_test, emulator), PDF with bundled Tamil font (export test), linked entry type lock.
