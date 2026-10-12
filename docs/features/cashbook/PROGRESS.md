# Cashbook replication - PROGRESS

STATUS (2026-10-12): the replica is IMPLEMENTED in the app (tasks T-CB01..T-CB19 and T-V201..T-V208 in .claude/tasks/CURRENT.md). See PARITY_STATUS.md for the per line result. The notes below describe the research phase.

Resume from this file alone. Docs only: do not touch lib/, pubspec.yaml, CURRENT.md.
Reference material (DB copy, dumps, screenshots, tools) lives in ~/cashbook-ref/ (outside repo).

## Setup (Phase 0) - DONE
- Emulator: emulator-5554 online. Package: `cashbook.cashbook`, versionName/versionCode 238, minSdk 24, targetSdk 36. Not debuggable (run-as fails), so the live DB cannot be pulled; only the user's backup is used.
- Backup DB: user supplied temp/cashbook.db, copied to ~/cashbook-ref/backup.db (read-only copy, opened with `sqlite3 -readonly`). User approved reading only that file.
- Tools: adb, sqlite3, python3 present.
- Read ARCHITECTURE.md, MODELS.md, CONVENTIONS.md. Free Hive typeIds: 2, 3 (re-verify by grep before use), then 11+.

## Phases
| Phase | Status | Notes |
|---|---|---|
| 1 DB analysis | DONE | DATA_MODEL.md written |
| 2 UI crawl | DONE (LOCKED items listed in SCREENS.md) | SCREENS.md |
| 3 Behaviour tests | DONE (Drive backup, Print, password/fingerprint untested) | BEHAVIOUR.md |
| 4 SPEC.md | DONE | 80 parity lines, 18 tasks |
| 5 Questions | DONE | below; waiting for developer answers |

## Screen list
S01 Main: PARTIAL (list, forms, edit, copy, delete done; overflow semantics, search TODO)
S16 Deleted Transactions: DONE (restore, delete, delete all menu seen)
S03 Drawer: DONE (17 items)
S04 Summary: DONE
S05 Account Summary: DONE
S06 Transaction-All: DONE
S07 Accounts: DONE (edit/delete/opening balance menu; Opening Balance dialog contents TODO)
S08 Transfer: DONE
S09 Report-All dialog: DONE
S10 Transaction names: PARTIAL
S11 Notebook: DONE
S12 Calendar: DONE
S13 Cash Calculator: DONE (side tool, out of scope)
S14 Backup and Restore: DONE except Drive rows (LOCKED: need Google sign-in)
S15 Settings: DONE except password/fingerprint/dark mode flows (not in scope)
S16 Deleted Transactions: PARTIAL
S02 Book picker, S17 Add Account, S18 Entry form, S19 Row anatomy, Colors, Formats: DONE
Help: DONE (FAQ + Send email); Rate Us, Recommend: external intents, not opened; Remove Ads: LOCKED

## Next
Tools: ~/cashbook-ref/tools/home.sh (relaunch + dump drawer), tapt.sh "<text|id>" <dumpname> (tap node + dump), snap.sh, shot.sh. Use /usr/bin/python3 -I (Homebrew python has broken expat; no PIL installed, color sampling needs `pip install pillow` in a venv).
The emulator app only has the default book "Cash Book" and no entries. Test book to create: "ZZ_TEST_BOOK".
Done: test book ZZ_TEST_BOOK created with opening balance 1000 (see BEHAVIOUR.md B01). Main screen overflow items seen: Notes, Date, Select Date Range, Date Ascending/Descending (checkboxes), Cash In, Cash Out, Print, Your Name and Address, How to use the app? (semantics TODO).
Done: entry form, list/balance display, edit, copy, delete, restore (BEHAVIOUR B02-B04). Done too: amount and date edge cases, Monthly tab (B05, B06). Done too: search, overflow filters/sort (B07). Done too: PDF and Excel export from main Report (B08). Done too: Settings pickers/defaults, entry form extras, Help (B09, B10). Done too: Transfer (B11), discard edits (B12). Books B13 done: ZZ_TEST_BOOK2 was created, renamed, and deleted (gone). Only ZZ_TEST_BOOK remains besides the real empty Cash Book. Done too: Summary, Account Summary, Transaction-All, Calendar with data (B14). Done too: Notebook (B15). Done too: Backup Data file format (B16, fills several DATA_MODEL facts). Done too: Report-All, Restore round trip, Cash Calculator (B17). Open: Drive backup (LOCKED needs Google sign-in), Print, Report-All export,  Summary/Account Summary/Transaction-All with data, Add Bills, Add Items, calculator icon, description/category field, midnight time, sort/filter items, tabs with data, Transfer, Accounts screen edit/delete, Settings pickers, exports, backup/restore, Notebook, Calendar with data, Cash Calculator.

## Developer answers received (applied in SPEC.md section 0)
All 15 answered; Q2 clarified by v2.0.0.md (books = receivers). SPEC.md now has 84 parity lines and 19 tasks. Q-N1 to Q-N5 resolved (just books, 30 days, no migration, editable, Rs.). No open questions remain; next step is T-CB01 after a typeId re-grep.

## Original questions (answered)
Product: Q-P1 scope (skip Cash Calculator, ads, rate, recommend?); Q-P2 book scoping A, B or C; Q-P3 keep Transaction names relabel feature?; Q-P4 trash retention (forever as reference, or auto purge)?
Data and sync: Q-D1 import real data now or only after the feature is stable?; Q-D2 old app versions overwriting the Drive snapshot: require all devices to update, or add unknown-key passthrough?; Q-D3 export: CSV plus PDF only, or also xlsx?; Q-D4 allow a new sqlite reader dependency for the import tool?; Q-D5 store money as double (project rule) or int paise for this feature?
UI: Q-U1 visual option 1 (copy) or 2 (RigLedger theme); Q-U2 show an Rs. prefix or no symbol; Q-U3 entry point: Settings tile only, or fifth tab; Q-U4 desktop two-pane layout acceptable?
Unknowns: Q-X1 may I run a second pass in the emulator for Add Items/attachments/Drive/lock (needs a sign-in or a user action)?; Q-X2 do you have other backups with items or bills attached?
