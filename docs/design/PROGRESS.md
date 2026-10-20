# UI Revamp Progress

## Pass 2 (2026-10-13): reconciliation with the approved Apple-inspired Android mockup

Documents only. Resume rule: this section is newer than everything below it.

| Step | Status | Notes |
|---|---|---|
| 1 Read mockup docs | DONE | DESIGN_DIRECTION_APPLE, TOKENS, MOCKUP_NOTES, MOCKUP_PROGRESS |
| 2 Record the 22 answers | DONE | DESIGN_DIRECTION_APPLE.md sections 7 to 9 (answers, verification of 13, 16, 20, conflicts, open questions); LOGIC_REQUESTS.md status section (LR-25 to LR-35) |
| 3 Reconcile system docs | DONE | DESIGN_SYSTEM (banner, status tags, section R), COMPONENTS (section 0), UX_FLOWS, PERFORMANCE (section R), PARITY_CHECKLIST (reconciliation), INCONSISTENCIES (resolution status), BUGS_FOUND (scope note, D-08) |
| 3 Reconcile per-screen docs | DONE | 46 of 46 screen docs have the banner and a Reconciliation section (R1 to R6); side files in temp/design_wip/ |
| 3 Screen map | DONE | mockup/SCREEN_MAP.md |
| 3 HIGHLIGHTS_AND_COLLAPSE | DONE | banner and Reconciliation section appended |
| 4 INDEX.md and CLAUDE.md rule | DONE | docs/design/INDEX.md, CLAUDE.md item 7 |
| 5 MIGRATION_PLAN.md rebuilt | DONE | 54 tasks: Phase 0 1, Phase 1 3, Phase 2 13, Phase 3 23, Phase 4 8, Phase 5 6 |
| 6 Finish report | DONE | open questions answered by Claude (section 9) |

Q-O1 to Q-O18 were answered by Claude on 2026-10-13 at the developer's request (DESIGN_DIRECTION_APPLE.md section 9; delegated defaults, overrulable). No open question blocks the plan. Next step: the developer says when to start; implementation (UI revamp) has NOT started. First tasks: T-B00 (provisional baseline on the emulator), then Phase 1 (T-D01 to T-D03). A physical device for T-B01 is still wanted.

---


Spec-only pass (no code changes). Skill: flutter-ui-revamp, all phases. Started 2026-10-12.
Resume rule: read this file, then continue from "Next step". Status values: DONE, PARTIAL, TODO.
Screenshots (real test data) live in docs/design/ref, ignored by git.

## Phase status

| Phase | Status | Notes |
|---|---|---|
| 0 Inventory | DONE | table below |
| 1 Visual baseline | PARTIAL | Android emulator (1080x2400) only: 7 screens in docs/design/ref. macOS not run (no GoogleService-Info.plist, see MEMORY.md). |
| 2 Per-screen docs | DONE | 46 files in docs/design/screens/ (lead, g1, g2, g3). Side files merged then kept in temp/design_wip/ as source. |
| 3 System docs | DONE | see document table |
| 4 Questions | DONE | in the final reply; waiting for the developer's answers |

## Next step

All phases are written. Wait for the developer's answers to the final questions, then apply them (brand seed, formats, labels, approvals) to DESIGN_SYSTEM.md and MIGRATION_PLAN.md. Do not start implementation until T-U00 and T-U01 are approved.

## Document status

| Document | Status |
|---|---|
| DESIGN_SYSTEM.md | DONE |
| INCONSISTENCIES.md (B3) | DONE |
| HIGHLIGHTS_AND_COLLAPSE.md (B4, B5) | DONE |
| COMPONENTS.md | DONE |
| UX_FLOWS.md | DONE |
| PERFORMANCE.md | DONE |
| PARITY_CHECKLIST.md | DONE |
| LOGIC_REQUESTS.md | DONE |
| BUGS_FOUND.md (B6) | DONE |
| MIGRATION_PLAN.md | DONE |

## User page names mapped to files

| Name used | Matched file | Confidence |
|---|---|---|
| Main ledger screen | lib/features/home/combined_home_screen.dart (Ledger tab) with widgets/summary_row.dart, widgets/ledger_list.dart | High |
| Side ledger screen | Two things carry this name: (a) the "Side Ledger" tab inside combined_home_screen.dart (_buildSideLedgerContent, line 494) and (b) lib/features/side_ledger/side_ledger_screen.dart, which is NOT used by the shells (see BUGS_FOUND.md). Also the vehicle type "Side Bore" ledger, which uses the Ledger tab with side_bore_form_screen.dart. | Ask (final question) |
| Portfolio page | lib/features/stats/stats_screen.dart (header, tabs) with lib/features/portfolio/portfolio_view.dart (Overview tab) | High |
| Accounts page | Mobile bottom-nav label "Accounts" = Account Ledger = lib/features/cashbook/cashbook_hub_screen.dart (CashbookRootScreen) hosting lib/features/cashbook/cashbook_home_screen.dart. "Daily filter" = the Daily chip (CashPeriod.daily) in widgets/cashbook_period_bar.dart. A separate screen cashbook_books_screen.dart is also titled "Accounts". | Medium (final question) |

## Phase 0 inventory (screens and overlays)

Variant column: "shared" = one implementation for Android and macOS (macOS wraps it in _DesktopContentWrapper, max width). Only files that call PlatformHelper.isDesktop have real variants: adaptive_header, settings_screen, cashbook_home_screen, cashbook_common, cashbook_header, cashbook_hub_screen, cashbook_entry_form_screen, main.dart.

| Screen or widget | File | Lines | Kind | Variant | Design doc | Status |
|---|---|---|---|---|---|---|
| adaptive_header | lib/core/widgets/adaptive_header.dart | 186 | widget/overlay | adaptive | screens/adaptive_header.md | DONE |
| gradient_widgets | lib/core/widgets/gradient_widgets.dart | 117 | widget/overlay | shared | screens/gradient_widgets.md | DONE |
| agents_screen | lib/features/agents/agents_screen.dart | 626 | screen | shared | screens/agents_screen.md | DONE |
| cashbook_account_summary_screen | lib/features/cashbook/cashbook_account_summary_screen.dart | 163 | screen | shared | screens/cashbook_account_summary_screen.md | DONE |
| cashbook_all_transactions_screen | lib/features/cashbook/cashbook_all_transactions_screen.dart | 204 | screen | shared | screens/cashbook_all_transactions_screen.md | DONE |
| cashbook_book_dialogs | lib/features/cashbook/cashbook_book_dialogs.dart | 258 | widget/overlay | shared | screens/cashbook_book_dialogs.md | DONE |
| cashbook_book_picker_dialog | lib/features/cashbook/cashbook_book_picker_dialog.dart | 107 | widget/overlay | shared | screens/cashbook_book_picker_dialog.md | DONE |
| cashbook_books_screen | lib/features/cashbook/cashbook_books_screen.dart | 138 | screen | shared | screens/cashbook_books_screen.md | DONE |
| cashbook_calculator_sheet | lib/features/cashbook/cashbook_calculator_sheet.dart | 200 | widget/overlay | shared | screens/cashbook_calculator_sheet.md | DONE |
| cashbook_calendar_screen | lib/features/cashbook/cashbook_calendar_screen.dart | 214 | screen | shared | screens/cashbook_calendar_screen.md | DONE |
| cashbook_entry_form_screen | lib/features/cashbook/cashbook_entry_form_screen.dart | 678 | screen | adaptive | screens/cashbook_entry_form_screen.md | DONE |
| cashbook_help_screen | lib/features/cashbook/cashbook_help_screen.dart | 83 | screen | shared | screens/cashbook_help_screen.md | DONE |
| cashbook_home_screen | lib/features/cashbook/cashbook_home_screen.dart | 439 | screen | adaptive | screens/cashbook_home_screen.md | DONE |
| cashbook_hub_screen | lib/features/cashbook/cashbook_hub_screen.dart | 178 | screen | adaptive | screens/cashbook_hub_screen.md | DONE |
| cashbook_import_screen | lib/features/cashbook/cashbook_import_screen.dart | 255 | screen | shared | screens/cashbook_import_screen.md | DONE |
| cashbook_items_dialog | lib/features/cashbook/cashbook_items_dialog.dart | 200 | widget/overlay | shared | screens/cashbook_items_dialog.md | DONE |
| cashbook_note_form_screen | lib/features/cashbook/cashbook_note_form_screen.dart | 151 | screen | shared | screens/cashbook_note_form_screen.md | DONE |
| cashbook_notebook_screen | lib/features/cashbook/cashbook_notebook_screen.dart | 212 | screen | shared | screens/cashbook_notebook_screen.md | DONE |
| cashbook_report_dialog | lib/features/cashbook/cashbook_report_dialog.dart | 151 | widget/overlay | shared | screens/cashbook_report_dialog.md | DONE |
| cashbook_settings_screen | lib/features/cashbook/cashbook_settings_screen.dart | 172 | screen | adaptive | screens/cashbook_settings_screen.md | DONE |
| cashbook_summary_screen | lib/features/cashbook/cashbook_summary_screen.dart | 89 | screen | shared | screens/cashbook_summary_screen.md | DONE |
| cashbook_transfer_screen | lib/features/cashbook/cashbook_transfer_screen.dart | 166 | screen | shared | screens/cashbook_transfer_screen.md | DONE |
| cashbook_trash_screen | lib/features/cashbook/cashbook_trash_screen.dart | 147 | screen | shared | screens/cashbook_trash_screen.md | DONE |
| cashbook_common | lib/features/cashbook/widgets/cashbook_common.dart | 329 | widget/overlay | adaptive | screens/cashbook_common.md | DONE |
| cashbook_header | lib/features/cashbook/widgets/cashbook_header.dart | 58 | widget/overlay | adaptive | screens/cashbook_header.md | DONE |
| cashbook_period_bar | lib/features/cashbook/widgets/cashbook_period_bar.dart | 102 | widget/overlay | shared | screens/cashbook_period_bar.md | DONE |
| cashbook_period_selector | lib/features/cashbook/widgets/cashbook_period_selector.dart | 83 | widget/overlay | shared | screens/cashbook_period_selector.md | DONE |
| cashbook_row | lib/features/cashbook/widgets/cashbook_row.dart | 145 | widget/overlay | shared | screens/cashbook_row.md | DONE |
| cashbook_totals_strip | lib/features/cashbook/widgets/cashbook_totals_strip.dart | 101 | widget/overlay | shared | screens/cashbook_totals_strip.md | DONE |
| csv_export_screen | lib/features/export/csv_export_screen.dart | 531 | screen | shared | screens/csv_export_screen.md | DONE |
| csv_import_screen | lib/features/export/csv_import_screen.dart | 741 | screen | shared | screens/csv_import_screen.md | DONE |
| pdf_export_screen | lib/features/export/pdf_export_screen.dart | 1595 | screen | shared | screens/pdf_export_screen.md | DONE |
| combined_home_screen | lib/features/home/combined_home_screen.dart | 1274 | screen | shared | screens/combined_home_screen.md | DONE |
| home_screen | lib/features/home/home_screen.dart | 378 | screen | shared | screens/home_screen.md | DONE |
| calendar_view | lib/features/home/widgets/calendar_view.dart | 208 | widget/overlay | shared | screens/calendar_view.md | DONE |
| filter_sheet | lib/features/home/widgets/filter_sheet.dart | 239 | widget/overlay | shared | screens/filter_sheet.md | DONE |
| ledger_list | lib/features/home/widgets/ledger_list.dart | 356 | widget/overlay | shared | screens/ledger_list.md | DONE |
| search_sheet | lib/features/home/widgets/search_sheet.dart | 133 | widget/overlay | shared | screens/search_sheet.md | DONE |
| summary_row | lib/features/home/widgets/summary_row.dart | 263 | widget/overlay | shared | screens/summary_row.md | DONE |
| ledger_form_screen | lib/features/ledger_form/ledger_form_screen.dart | 1177 | screen | shared | screens/ledger_form_screen.md | DONE |
| side_bore_form_screen | lib/features/ledger_form/side_bore_form_screen.dart | 809 | screen | shared | screens/side_bore_form_screen.md | DONE |
| address_autocomplete_field | lib/features/ledger_form/widgets/address_autocomplete_field.dart | 93 | widget/overlay | shared | screens/address_autocomplete_field.md | DONE |
| commission_section | lib/features/ledger_form/widgets/commission_section.dart | 159 | widget/overlay | shared | screens/commission_section.md | DONE |
| payment_log_editor | lib/features/ledger_form/widgets/payment_log_editor.dart | 466 | widget/overlay | shared | screens/payment_log_editor.md | DONE |
| desktop_shell | lib/features/navigation/desktop_shell.dart | 807 | shell | desktop only | screens/desktop_shell.md | DONE |
| main_navigation | lib/features/navigation/main_navigation.dart | 245 | shell | mobile only | screens/main_navigation.md | DONE |
| portfolio_view | lib/features/portfolio/portfolio_view.dart | 381 | screen | shared | screens/portfolio_view.md | DONE |
| about_screen | lib/features/settings/about_screen.dart | 210 | screen | shared | screens/about_screen.md | DONE |
| settings_screen | lib/features/settings/settings_screen.dart | 809 | screen | adaptive | screens/settings_screen.md | DONE |
| vehicle_management_screen | lib/features/settings/vehicle_management_screen.dart | 531 | screen | shared | screens/vehicle_management_screen.md | DONE |
| bit_form_screen | lib/features/side_ledger/bit/bit_form_screen.dart | 579 | screen | shared | screens/bit_form_screen.md | DONE |
| bit_list_screen | lib/features/side_ledger/bit/bit_list_screen.dart | 742 | screen | shared | screens/bit_list_screen.md | DONE |
| diesel_form_screen | lib/features/side_ledger/diesel/diesel_form_screen.dart | 462 | screen | shared | screens/diesel_form_screen.md | DONE |
| diesel_list_screen | lib/features/side_ledger/diesel/diesel_list_screen.dart | 656 | screen | shared | screens/diesel_list_screen.md | DONE |
| hammer_form_screen | lib/features/side_ledger/hammer/hammer_form_screen.dart | 567 | screen | shared | screens/hammer_form_screen.md | DONE |
| hammer_list_screen | lib/features/side_ledger/hammer/hammer_list_screen.dart | 731 | screen | shared | screens/hammer_list_screen.md | DONE |
| pvc_form_screen | lib/features/side_ledger/pvc/pvc_form_screen.dart | 570 | screen | shared | screens/pvc_form_screen.md | DONE |
| pvc_list_screen | lib/features/side_ledger/pvc/pvc_list_screen.dart | 766 | screen | shared | screens/pvc_list_screen.md | DONE |
| side_ledger_screen | lib/features/side_ledger/side_ledger_screen.dart | 200 | screen | shared | screens/side_ledger_screen.md | DONE |
| stats_screen | lib/features/stats/stats_screen.dart | 1421 | screen | shared | screens/stats_screen.md | DONE |
| main | lib/main.dart | 165 | app root | adaptive | screens/main.md | DONE |

## Overlay inventory (grep counts, lib/)

showDialog 36 calls in 20 files, AlertDialog 29 in 17, showModalBottomSheet 14 in 11, showDatePicker/showDateRangePicker 20 in 18, PopupMenuButton 7 in 6, SnackBar 115 in 18, DropdownButton(FormField) 14 in 8, TabBar 2 in 2, Navigator.push 22 in 8, IndexedStack 2 in 2 (both shells).

## Log

- 2026-10-12: Phase 0 done. Emulator baseline captured (7 screens). Contrast ratios computed for DESIGN_SYSTEM.md.

- 2026-10-12: DESIGN_SYSTEM, COMPONENTS, HIGHLIGHTS_AND_COLLAPSE (B4, B5), INCONSISTENCIES (lead part), PERFORMANCE, UX_FLOWS, LOGIC_REQUESTS written. Lead screen docs written. Agents g1, g2, g3 launched for the remaining screens.
- 2026-10-12: g1, g2, g3 agents finished. Merged: BUGS_FOUND.md (104 entries: safe vs approval needed), INCONSISTENCIES.md sections A1-A3, PARITY_CHECKLIST.md, LOGIC_REQUESTS.md L1-L3, COMPONENTS.md section 9. MIGRATION_PLAN.md written (T-U00 to T-U100). Hygiene: no em-dash or emoji. Only docs/design/ changed.
