# INDEX: which documents to read for each task

Rule (also in CLAUDE.md): for the active task read ONLY the documents listed here and in the task itself. Do not open the other design documents. Paths are relative to `docs/design/`. For a screen document read its section "Reconciliation 2026-10-13" first; it wins over the older sections of the same file.

Always-on context for every task (small): `CLAUDE.md`, `MEMORY.md`, `.claude/tasks/CURRENT.md`.

| Task | Title | Read (1 to 3) |
|---|---|---|
| T-B00 | Baseline on the reference device | PERFORMANCE.md (R1, R2, section 5 how to measure) |
| T-B01 | Repeat the baseline on a physical phone | PERFORMANCE.md (R1, R2, section 5) |
| T-D01 | Import depth, rates and extra charges from the app's own CSV | BUGS_FOUND.md (entries G3-B01, G3-B07); screens/csv_import_screen.md (Reconciliation R3, R5); LOGIC_REQUESTS.md (LR-31) |
| T-D02 | Stop duplicate bills from double taps on Save | BUGS_FOUND.md (entry B-G1-01); screens/ledger_form_screen.md (Reconciliation R3, R4); LOGIC_REQUESTS.md (LR-32) |
| T-D03 | Keep calendar day totals inside the selected month | BUGS_FOUND.md (entry B-03); screens/ledger_list.md (Reconciliation R3, R5); LOGIC_REQUESTS.md (LR-33) |
| T-F01 | Bundle Inter with tabular figures | DESIGN_SYSTEM.md (section R); mockup/TOKENS.md (sections 1, 2, 4, 6, 7); mockup/MOCKUP_NOTES.md (row Inter and tabular figures) |
| T-F02 | Light and dark color roles with contrast test | mockup/TOKENS.md (sections 1, 2, 4, 6, 7); DESIGN_SYSTEM.md (section R); COMPONENTS.md (section 0) |
| T-F03 | RigTheme component themes and system UI | DESIGN_SYSTEM.md (section R); mockup/MOCKUP_NOTES.md (rows Toggle, Circular check marks, Press feedback, Edge to edge); mockup/TOKENS.md (sections 1, 2, 4, 6, 7) |
| T-F04 | Appearance state (System, Light, Dark) | LOGIC_REQUESTS.md (LR-23, LR-35); DESIGN_SYSTEM.md (section R); screens/main.md (Reconciliation R2, R3) |
| T-F05 | Money, quantity and date formatters | mockup/TOKENS.md (sections 1, 2, 4, 6, 7); HIGHLIGHTS_AND_COLLAPSE.md (B.6 stress table); DESIGN_DIRECTION_APPLE.md (section 8.2 feet) |
| T-F06 | MoneyText, MoneyTile and RigMetricCard with fit pipeline | HIGHLIGHTS_AND_COLLAPSE.md (part B: B.3, B.4, B.6); COMPONENTS.md (section 0); mockup/MOCKUP_NOTES.md (row MoneyText) |
| T-F07 | RigCard, RigGroup, RigRow, RigFormRow | COMPONENTS.md (section 0); mockup/TOKENS.md (sections 1, 2, 4, 6, 7); mockup/MOCKUP_NOTES.md (rows Inset grouped lists, Form rows) |
| T-F08 | RigButton, RigChipRow, RigSegmented, RigSwitch, RigCheck | COMPONENTS.md (section 0); mockup/TOKENS.md (sections 1, 2, 4, 6, 7); mockup/MOCKUP_NOTES.md (rows Pill buttons, Inverse period chips) |
| T-F09 | RigAlertDialog, RigSheet, RigSnack, DatePickerSheet, EmptyState, ErrorBanner, Skeleton | COMPONENTS.md (section 0); mockup/MOCKUP_NOTES.md (rows Sheets, Alerts, Skeleton); mockup/TOKENS.md (sections 1, 2, 4, 6, 7) |
| T-F10 | LargeTitleScaffold with collapse and status strip | HIGHLIGHTS_AND_COLLAPSE.md (part A, plus the Reconciliation section); COMPONENTS.md (section 0); mockup/MOCKUP_NOTES.md (row Large title) |
| T-F11 | Floating RigTabBar with blur flag | COMPONENTS.md (section 0); mockup/MOCKUP_NOTES.md (rows Floating tab capsule, Glass blur); mockup/TOKENS.md (sections 1, 2, 4, 6, 7) |
| T-F12 | RigRing, DepthTile, CategoryTile | COMPONENTS.md (section 0); mockup/TOKENS.md (sections 1, 2, 4, 6, 7); mockup/MOCKUP_NOTES.md (rows Activity ring, Gradient category tiles) |
| T-F13 | UnsavedChangesGuard and RowActions | LOGIC_REQUESTS.md (LR-25); COMPONENTS.md (section 0); mockup/MOCKUP_NOTES.md (System back mapping, Swipe actions) |
| T-S01 | Android shell with floating tab bar and add chooser | screens/main_navigation.md (Reconciliation R2 to R5); COMPONENTS.md (section 0); HIGHLIGHTS_AND_COLLAPSE.md (A.2 pinned parts) |
| T-S02 | Ledger highlights: ring card, metric cards, depth tiles (B5) | screens/combined_home_screen.md (Reconciliation R1, R2); HIGHLIGHTS_AND_COLLAPSE.md (part B); COMPONENTS.md (section 0) |
| T-S03 | Ledger bill list: grouped days, sticky headers, bill row | screens/ledger_list.md (Reconciliation R1, R2, R4); COMPONENTS.md (section 0); PERFORMANCE.md (R4 sticky headers) |
| T-S04 | Ledger large title, status strip, period controls, search and filter (B4) | screens/combined_home_screen.md (Reconciliation R1 to R4); HIGHLIGHTS_AND_COLLAPSE.md (part A and Reconciliation); screens/ledger_list.md (Reconciliation R2) |
| T-S05 | Side Ledger home: category tiles and shared period controls | screens/combined_home_screen.md (Reconciliation R2); screens/diesel_list_screen.md (Reconciliation R2); COMPONENTS.md (section 0) |
| T-S10 | Main bore bill form as a full-height sheet | screens/ledger_form_screen.md (Reconciliation R1 to R5); COMPONENTS.md (section 0); UX_FLOWS.md (F-2 reconciliation) |
| T-S11 | Payment log editor and payment sheet | screens/payment_log_editor.md (Reconciliation R1 to R5); COMPONENTS.md (section 0); BUGS_FOUND.md (B-G1-12, B-G1-13) |
| T-S12 | Side bore bill form | screens/side_bore_form_screen.md (Reconciliation R1 to R5); COMPONENTS.md (section 0) |
| T-S20 | Portfolio overview and rig pill (B1) | screens/portfolio.md (Reconciliation R1 to R5); COMPONENTS.md (section 0); DESIGN_DIRECTION_APPLE.md (A10, Q-O1, Q-O2) |
| T-S21 | Portfolio chart tabs (Ledger and Side Ledger stats) | screens/stats_screen_charts.md (Reconciliation R1 to R5); COMPONENTS.md (section 0); BUGS_FOUND.md (G3-B19, G3-B20, G3-B21) |
| T-S30 | Accounts home: period bar, rows, totals strip | screens/cashbook_home_screen.md (Reconciliation R1 to R5); COMPONENTS.md (section 0); docs/features/cashbook/PARITY_STATUS.md |
| T-S31 | Account Ledger entry form, calculator sheet, items dialog | screens/cashbook_entry_form_screen.md (Reconciliation R1 to R5); LOGIC_REQUESTS.md (LR-25, LR-26); COMPONENTS.md (section 0) |
| T-S32 | Accounts books, pickers and dialogs | screens/cashbook_books_screen.md (Reconciliation R1 to R5); LOGIC_REQUESTS.md (LR-27); COMPONENTS.md (section 0) |
| T-S33 | Account Ledger summaries, calendar, transfer and reports | screens/cashbook_summary_screen.md (Reconciliation R1 to R5); screens/cashbook_calendar_screen.md (Reconciliation R2); COMPONENTS.md (section 0) |
| T-S34 | Account Ledger notebook, trash, settings, import, help, hub | screens/cashbook_hub_screen.md (Reconciliation R1 to R5); screens/cashbook_notebook_screen.md (Reconciliation R2); COMPONENTS.md (section 0) |
| T-S40 | Agents | screens/agents_screen.md (Reconciliation R1 to R5); COMPONENTS.md (section 0); BUGS_FOUND.md (G3-B15, G3-B13, G3-B14) |
| T-S41 | Settings with Appearance row and Drive card | screens/settings_screen.md (Reconciliation R1 to R5); LOGIC_REQUESTS.md (LR-23, LR-28); COMPONENTS.md (section 0) |
| T-S42 | About and Rigs (vehicle management) | screens/vehicle_management_screen.md (Reconciliation R1 to R5); screens/about_screen.md (Reconciliation R2); COMPONENTS.md (section 0) |
| T-S43d | Diesel ledger list and form | screens/diesel_list_screen.md (Reconciliation R1 to R5); screens/diesel_form_screen.md (Reconciliation R2, R4); COMPONENTS.md (section 0) |
| T-S43p | PVC ledger list and form | screens/pvc_list_screen.md (Reconciliation R1 to R5); screens/pvc_form_screen.md (Reconciliation R2, R4); COMPONENTS.md (section 0) |
| T-S43b | Bit ledger list and form | screens/bit_list_screen.md (Reconciliation R1 to R5); screens/bit_form_screen.md (Reconciliation R2, R4); COMPONENTS.md (section 0) |
| T-S43h | Hammer ledger list and form | screens/hammer_list_screen.md (Reconciliation R1 to R5); screens/hammer_form_screen.md (Reconciliation R2, R4); COMPONENTS.md (section 0) |
| T-S44 | Export and import screens | screens/pdf_export_screen.md (Reconciliation R1 to R5); screens/csv_import_screen.md (Reconciliation R2); COMPONENTS.md (section 0) |
| T-X01 | Crash fixes | BUGS_FOUND.md (section 3.1, the four entries) |
| T-X02 | Wrong-number display fixes | BUGS_FOUND.md (section 3.2); LOGIC_REQUESTS.md (LR-29 proposed, do not implement) |
| T-X03 | Data loss fixed with UI guards | BUGS_FOUND.md (section 3.3); LOGIC_REQUESTS.md (LR-32) |
| T-X04 | UI-only leftovers | BUGS_FOUND.md (section 3.4); INCONSISTENCIES.md (status table) |
| T-X05 | Cosmetic leftovers | BUGS_FOUND.md (section 3.5) |
| T-X10 | Shared switchRig (LR-01) | DESIGN_DIRECTION_APPLE.md (section 8.1); LOGIC_REQUESTS.md (LR-01); screens/portfolio.md (Reconciliation R3) |
| T-X11 | Daily date picker (B2) with setAnchor (LR-02) | screens/accounts_daily_date_picker.md (Reconciliation R1 to R5); LOGIC_REQUESTS.md (LR-02); COMPONENTS.md (section 0) |
| T-X20 | Data, sync and model items (one task per approved item) | BUGS_FOUND.md (section 4); LOGIC_REQUESTS.md (LR-10, LR-11) |
| T-P01 | Lazy Portfolio, Agents and Settings tabs | PERFORMANCE.md (R3); PARITY_CHECKLIST.md (section Lazy tabs and theme) |
| T-P02 | Performance pass against the baseline | PERFORMANCE.md (R1, R2, R4) |
| T-P03 | Remove old theme, gradients and unused widgets | core_theme_and_widgets.md (Reconciliation R2); INCONSISTENCIES.md (I-07, I-30) |
| T-P04 | Final QA in both themes with the largest text size | PARITY_CHECKLIST.md; BUGS_FOUND.md |
| T-P05 | Update project docs for the new design system | DESIGN_SYSTEM.md (section R); INDEX.md |
| T-Z99 | Delete dead screens (last task) | screens/home_screen.md; screens/side_ledger_screen.md |

## Reference documents (read only when a task points to them)

| Document | What it holds |
|---|---|
| DESIGN_DIRECTION_APPLE.md | decisions A1 to A21, the 22 answers (section 7), verification results (section 8), open questions (section 9) |
| mockup/TOKENS.md | every colour, size, formatter and contrast value; Flutter mapping |
| mockup/MOCKUP_NOTES.md | Flutter cost of each effect and the cheap alternative; system back mapping |
| mockup/SCREEN_MAP.md | every mockup screen mapped to its Flutter file and widgets |
| DESIGN_SYSTEM.md | token architecture, section R reconciliation |
| COMPONENTS.md | section 0 is the component catalogue |
| HIGHLIGHTS_AND_COLLAPSE.md | B4 header collapse, B5 highlight fit rules and the 19 row stress table |
| PERFORMANCE.md | targets, baseline table, measuring method |
| PARITY_CHECKLIST.md | manual test lines by screen, global lines G-1 to G-8, reconciliation section |
| BUGS_FOUND.md | 104 entries by severity, section 4 needs per-item approval |
| INCONSISTENCIES.md | inventory, with the resolving token or component and status |
| LOGIC_REQUESTS.md | LR items and their status |
| UX_FLOWS.md | flows before and after |
| screens/*.md | one per screen file, each with a Reconciliation section |
