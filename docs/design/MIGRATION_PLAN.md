# Migration Plan (rebuilt 2026-10-13 for the Apple-inspired Android direction)

Format follows `.claude/tasks/CURRENT.md`. Each task is SELF-CONTAINED: Goal, Files, Depends, the 1 to 3 Docs to read, Acceptance, Verification, Parity lines and the expected commit message. For the active task read ONLY the documents listed in the task and in `INDEX.md` (rule in CLAUDE.md). NOT STARTED: this is a plan, no implementation has begun.

Direction and answers: `DESIGN_DIRECTION_APPLE.md` section 7. Visual source of truth: `mockup/rigledger_apple_mockup.html` and `mockup/TOKENS.md`. This file replaces the Material-era plan of 2026-10-12 (T-U00 to T-U100); the old task ids are retired.

## Rules for every task

- One commit per task: imperative message of 72 characters or fewer, no Co-Authored-By trailer, never amend, never push. Stage the exact files only; the developer's uncommitted `android/app/build.gradle`, `android/app/debug.keystore`, `.claude/skills/` and `docs/ANDROID_SIGNING.md` are never staged.
- Logic freeze except the approved items (LR-01, LR-02, LR-23, LR-24, LR-25, LR-26, LR-27, LR-28, LR-31, LR-32, LR-33, LR-35). Anything else that needs a logic change stops the task and becomes an LR item.
- macOS is FROZEN (answer 15): never edit or delete `macos/`, `lib/features/navigation/desktop_shell.dart`, `lib/core/services/desktop_auth_service.dart` or any `PlatformHelper.isDesktop` branch, and keep `window_manager`. Shared code must still compile for them (`flutter analyze` covers it). Their fate is a separate later decision (DESIGN_DIRECTION_APPLE.md Q-O9).
- Android only: portrait lock stays, 360 dp is the smallest width, test widths 360 and 412 dp.
- No emojis, no em-dashes, no hex literals or `Colors.x` in screen code (only `RigColors` and theme roles); a grep in each screen task checks the files it touched. Rupee sign, en-IN, `RigFormat` only.
- Verification always includes `flutter analyze` (zero errors; infos not above the baseline of 210) and the frozen-files check. Screens add screenshots (light and dark, 360 and 412 dp, text scale 130 and 200 percent, kept in `docs/design/ref`). List screens add the profile-mode check (targets until T-B00 has numbers).
- After each task update `.claude/tasks/CURRENT.md` and `docs/design/PROGRESS.md`.
- Status legend: PENDING until started. BLOCKED names the missing answer.

## Task count per phase

| Phase | Tasks |
|---|---|
| Phase 0: baseline | 2 (T-B00 to T-B01) |
| Phase 1: data-integrity fixes (approved, answer 17) | 3 (T-D01 to T-D03) |
| Phase 2: foundation | 13 (T-F01 to T-F13) |
| Phase 3: screens by traffic | 23 (T-S01 to T-S44) |
| Phase 4: remaining bugs by severity, then logic exceptions 13 and 14 | 8 (T-X01 to T-X20) |
| Phase 5: lazy tabs, performance, cleanup, QA | 6 (T-P01 to T-Z99) |
| Total | 55 |

# Phase 0: baseline

## T-B00 Baseline on the reference device [PENDING]
Goal: Measure cold start, Ledger list scroll, Account Ledger list scroll, tab switch and header scroll in profile mode on the reference device with a synthetic seed (2,000 bills, 5,000 cash entries, 12 agents, 3 rigs; seed script kept ignored by git). Record the numbers.
Files: docs/design/PERFORMANCE.md (table R2) only
Depends: none
Docs to read (only these):
- PERFORMANCE.md (R1, R2, section 5 how to measure)
Acceptance:
1. R2 table filled with p90 and p99 build and raster, janky percent, cold start (median of 5), tab switch.
2. Method and device (model, Android version, RAM) written next to the table.
3. No file outside docs changed.
Verification:
- `flutter run --profile -d <reference device>`; DevTools Performance and `--trace-startup`.
- `flutter analyze`: zero errors and no more infos than the baseline (210 on 2026-10-12).
- `git diff --stat` shows no change under `macos/`, `desktop_shell.dart`, `desktop_auth_service.dart`; constructors used by `desktop_shell.dart` stay source compatible.
Parity lines: none
Notes: Runs on the provisional reference (attached emulator sdk_gphone64_arm64, Android 16, about 2 GB RAM, Q-O4). Every number is marked PROVISIONAL until T-B01.
Commit: Record profile-mode performance baseline

## T-B01 Repeat the baseline on a physical phone [PENDING]
Goal: Repeat T-B00 on a physical mid-range Android phone named by the developer, in profile mode, and replace the PROVISIONAL numbers.
Files: docs/design/PERFORMANCE.md (table R2) only
Depends: T-B00
Docs to read (only these):
- PERFORMANCE.md (R1, R2, section 5)
Acceptance:
1. Table R2 holds measured numbers with the device model, Android version and RAM; PROVISIONAL tag removed.
Verification:
- `flutter run --profile -d <device>`; DevTools Performance and `--trace-startup`.
- `flutter analyze`: zero errors and no more infos than the baseline (210 on 2026-10-12).
- `git diff --stat` shows no change under `macos/`, `desktop_shell.dart`, `desktop_auth_service.dart`; constructors used by `desktop_shell.dart` stay source compatible.
Parity lines: none
Notes: BLOCKED until the developer names a physical device. Does not block Phases 1 to 3 (targets, not gates).
Commit: Record baseline on a physical Android device

# Phase 1: data-integrity fixes (approved, answer 17)

## T-D01 Import depth, rates and extra charges from the app's own CSV [PENDING]
Goal: Fix the auto-mapping so that a CSV exported by the app imports depth feet, depth rate, PVC and MS pipe feet and rates, and extra charges instead of silently importing zeros (BUGS_FOUND.md G3-B01). LR-31, approved. Step rate, notes and commission (G3-B07) and double import (G3-B02, G3-B03) are NOT in this task.
Files: lib/features/export/csv_import_screen.dart (mapping table only), test/csv_import_mapping_test.dart
Depends: none
Docs to read (only these):
- BUGS_FOUND.md (entries G3-B01, G3-B07)
- screens/csv_import_screen.md (Reconciliation R3, R5)
- LOGIC_REQUESTS.md (LR-31)
Acceptance:
1. Exporting a synthetic dataset with the existing CSV export and importing the file into an empty rig yields bills whose depth feet, depth rate, PVC feet and rate, MS pipe feet and rate, extra charges, totals, received and balance equal the originals.
2. Header row of the exporter is mapped automatically for every column the exporter writes; unmapped required columns still block Validate with a message.
3. The CSV and PDF exporters are unchanged (byte-identical output).
Verification:
- Unit test: exporter header row maps to the expected fields (all depth, rate and extra charge columns).
- Round trip on the synthetic dataset: totals equal before and after.
- `flutter analyze`: zero errors and no more infos than the baseline (210 on 2026-10-12).
- `git diff --stat` shows no change under `macos/`, `desktop_shell.dart`, `desktop_auth_service.dart`; constructors used by `desktop_shell.dart` stay source compatible.
Parity lines: PARITY_CHECKLIST.md g3 section CSV import; G-2, G-3
Notes: Touches data written by import: approved explicitly for this item only.
Commit: Map depth, rates and extra charges when importing app CSV

## T-D02 Stop duplicate bills from double taps on Save [PENDING]
Goal: Add an in-flight guard to Save on the six bill and side ledger forms so a double tap or double press writes one record (BUGS_FOUND.md B-G1-01). LR-32, scope of this task: the six forms; transfer, note, vehicle, agent and import buttons follow in Phase 4.
Files: lib/features/ledger_form/ledger_form_screen.dart, side_bore_form_screen.dart, lib/features/side_ledger/diesel|pvc|bit|hammer/*_form_screen.dart, widget tests
Depends: none
Docs to read (only these):
- BUGS_FOUND.md (entry B-G1-01)
- screens/ledger_form_screen.md (Reconciliation R3, R4)
- LOGIC_REQUESTS.md (LR-32)
Acceptance:
1. Two Save taps within 100 ms create exactly one record (before: two with different ids).
2. Save is disabled while the first save runs and re-enabled on failure (finally block).
3. No change to what is saved, validators or navigation.
Verification:
- Widget test per form: pump, tap Save twice, expect one add call.
- Manual: double tap Save on each of the six forms, count entries.
- `flutter analyze`: zero errors and no more infos than the baseline (210 on 2026-10-12).
- `git diff --stat` shows no change under `macos/`, `desktop_shell.dart`, `desktop_auth_service.dart`; constructors used by `desktop_shell.dart` stay source compatible.
Parity lines: PARITY_CHECKLIST.md g1 sections A, C, D, E, F, G; G-2, G-4
Commit: Block duplicate bills from double taps on Save

## T-D03 Keep calendar day totals inside the selected month [PENDING]
Goal: calendarDayTotalsProvider keys totals by day of month over all filtered entries, so with 3 Mo, 6 Mo, Year, Custom or All the cell for day 12 adds every month's day 12 (BUGS_FOUND.md B-03). Restrict the totals to entries of the selected month. LR-33, approved.
Files: lib/core/providers/ledger_provider.dart (calendarDayTotalsProvider), test/ledger_calendar_totals_test.dart
Depends: none
Docs to read (only these):
- BUGS_FOUND.md (entry B-03)
- screens/ledger_list.md (Reconciliation R3, R5)
- LOGIC_REQUESTS.md (LR-33)
Acceptance:
1. Bills on 12 Sep and 12 Oct with period 3 Mo and selected month October: the 12 cell shows only the October bill total.
2. Period Month behaves exactly as before.
3. Search and filters still apply to the totals.
Verification:
- Provider unit test with the two-month case and the Month case.
- `flutter analyze`: zero errors and no more infos than the baseline (210 on 2026-10-12).
- `git diff --stat` shows no change under `macos/`, `desktop_shell.dart`, `desktop_auth_service.dart`; constructors used by `desktop_shell.dart` stay source compatible.
Parity lines: PARITY_CHECKLIST.md lead section Ledger tab (P-LED-6); G-2
Commit: Keep calendar day totals within the selected month

# Phase 2: foundation

## T-F01 Bundle Inter with tabular figures [PENDING]
Goal: Add Inter 400, 500, 600, 700 (OFL notice) and make it the theme font; Noto Sans stays for PDFs only; Noto Sans Tamil stays the fallback.
Files: pubspec.yaml (fonts), assets/fonts/Inter-*.ttf or InterVariable.ttf, assets/fonts/OFL-Inter.txt, lib/core/theme/rig_text.dart
Depends: none
Docs to read (only these):
- DESIGN_SYSTEM.md (section R)
- mockup/TOKENS.md (sections 1, 2, 4, 6, 7)
- mockup/MOCKUP_NOTES.md (row Inter and tabular figures)
Acceptance:
1. Text renders in Inter on both themes; amounts use FontFeature.tabularFigures (a widget test asserts equal digit widths for 1111 and 8888).
2. Tamil note text still renders (fallback).
3. PDF output unchanged.
Verification:
- Test: tabular figures; manual: Tamil sample string; export a PDF and compare with baseline.
- `flutter analyze`: zero errors and no more infos than the baseline (210 on 2026-10-12).
- `git diff --stat` shows no change under `macos/`, `desktop_shell.dart`, `desktop_auth_service.dart`; constructors used by `desktop_shell.dart` stay source compatible.
Parity lines: G-3, G-6
Commit: Bundle Inter font with tabular figures

## T-F02 Light and dark color roles with contrast test [PENDING]
Goal: Add RigColors (ThemeExtension) and two hand-built ColorSchemes from TOKENS.md section 2 and the Flutter mapping in section 6, one accent source (system blue default, #315D9A documented alternate), glass tokens. AppColors stays as thin aliases until the end.
Files: lib/core/theme/rig_colors.dart, lib/core/theme/rig_theme.dart (schemes only), lib/core/theme/app_colors.dart (aliases), test/rig_colors_contrast_test.dart
Depends: T-F01
Docs to read (only these):
- mockup/TOKENS.md (sections 1, 2, 4, 6, 7)
- DESIGN_SYSTEM.md (section R)
- COMPONENTS.md (section 0)
Acceptance:
1. Every role in TOKENS.md section 2 exists in light and dark with the listed value.
2. Changing the single accent source Color changes accent, accentText, accentButton, onAccent and accentTint only.
3. Contrast test reproduces the TOKENS.md section 5 matrix (all text rows at least 4.5, filled controls at least 4.5) in both themes.
Verification:
- flutter test test/rig_colors_contrast_test.dart.
- `flutter analyze`: zero errors and no more infos than the baseline (210 on 2026-10-12).
- `git diff --stat` shows no change under `macos/`, `desktop_shell.dart`, `desktop_auth_service.dart`; constructors used by `desktop_shell.dart` stay source compatible.
Parity lines: G-1, G-6
Commit: Add light and dark color roles with contrast test

## T-F03 RigTheme component themes and system UI [PENDING]
Goal: Component themes: Switch (51 x 31 look, padded 48 dp), Checkbox (circle), chip, snackbar (floating capsule), dialog (alert 14 radius), bottom sheet (28 radius, grabber), page transitions (predictive back builder), ink (InkSparkle, press overlay colors), text selection. Edge to edge system UI and transparent system bars.
Files: lib/core/theme/rig_theme.dart, lib/main.dart (theme wiring only, keep every platform branch)
Depends: T-F02
Docs to read (only these):
- DESIGN_SYSTEM.md (section R)
- mockup/MOCKUP_NOTES.md (rows Toggle, Circular check marks, Press feedback, Edge to edge)
- mockup/TOKENS.md (sections 1, 2, 4, 6, 7)
Acceptance:
1. App renders with RigTheme.light and RigTheme.dark; no screen is migrated yet, existing screens still work.
2. Status and navigation bars are transparent with correct icon brightness per theme.
3. android:enableOnBackInvokedCallback is set in the manifest (predictive back).
Verification:
- `flutter analyze`: zero errors and no more infos than the baseline (210 on 2026-10-12).
- Run on the reference device: light and dark launch, no exceptions, back gesture animates on Android 13 and up.
- `git diff --stat` shows no change under `macos/`, `desktop_shell.dart`, `desktop_auth_service.dart`; constructors used by `desktop_shell.dart` stay source compatible.
Parity lines: G-1, G-6
Notes: The manifest line is the only Android file touched.
Commit: Add RigTheme component themes and edge to edge system UI

## T-F04 Appearance state (System, Light, Dark) [PENDING]
Goal: themeModeProvider reading and writing one key in the existing Hive settings box (no schema bump, not synced), wired to MaterialApp.themeMode, default System. LR-23, LR-35, approved. The Settings row comes in the Settings task.
Files: lib/core/providers/appearance_provider.dart, lib/main.dart (themeMode only), test/appearance_provider_test.dart
Depends: T-F03
Docs to read (only these):
- LOGIC_REQUESTS.md (LR-23, LR-35)
- DESIGN_SYSTEM.md (section R)
- screens/main.md (Reconciliation R2, R3)
Acceptance:
1. Default follows the system theme; setting the provider to Light or Dark changes the app theme immediately and survives restart.
2. schemaVersion remains 5; backup JSON unchanged; sync merge unaffected.
Verification:
- Provider test with a temp Hive dir (real-time wait, no Hive.close, per MEMORY.md).
- Manual: change the system theme and the stored mode.
- `flutter analyze`: zero errors and no more infos than the baseline (210 on 2026-10-12).
- `git diff --stat` shows no change under `macos/`, `desktop_shell.dart`, `desktop_auth_service.dart`; constructors used by `desktop_shell.dart` stay source compatible.
Parity lines: PARITY_CHECKLIST.md section Lazy tabs and theme; G-8
Notes: Logic touchpoint: one settings key.
Commit: Add appearance mode provider and apply it to the app

## T-F05 Money, quantity and date formatters [PENDING]
Goal: RigFormat per TOKENS.md section 7: money (rupee sign, en-IN, paise only when present, minus before the sign, no negative zero, double dash for non-finite), moneyCompact (L, Cr, L Cr), qty, ftq with the feet rule (up to one decimal, trailing .0 hidden, rounded before hiding), dRow, dGroup, dFull, dMonth. Cached static instances. Export code is not touched.
Files: lib/core/format/rig_format.dart, test/rig_format_test.dart
Depends: T-F01
Docs to read (only these):
- mockup/TOKENS.md (sections 1, 2, 4, 6, 7)
- HIGHLIGHTS_AND_COLLAPSE.md (B.6 stress table)
- DESIGN_DIRECTION_APPLE.md (section 8.2 feet)
Acceptance:
1. All 19 stress inputs of HIGHLIGHTS_AND_COLLAPSE.md B.6 format as specified (including 1e15, negative zero, NaN).
2. 350 shows 350, 350.5 shows 350.5, 350.25 shows 350.3, 0.1 + 0.2 shows 0.3 (feet rule, Q-O5 default).
3. money has two decimals only when the value has paise: 59000 shows the rupee sign and 59,000; 125000.5 shows 1,25,000.50.
Verification:
- flutter test test/rig_format_test.dart (at least the 19 stress inputs and the feet rule).
- `flutter analyze`: zero errors and no more infos than the baseline (210 on 2026-10-12).
- `git diff --stat` shows no change under `macos/`, `desktop_shell.dart`, `desktop_auth_service.dart`; constructors used by `desktop_shell.dart` stay source compatible.
Parity lines: G-2, G-3
Commit: Add cached money, quantity, feet and date formatters

## T-F06 MoneyText, MoneyTile and RigMetricCard with fit pipeline [PENDING]
Goal: MoneyText: full value, scale to 75 percent, then (only in MoneyTile and RigMetricCard) compact, last guard shrinks to 11 sp; measured once per (string, style, width, textScale) and cached; tap or long press opens a popover or sheet with the full value and Copy. RigMetricCard and MoneyTile built on it.
Files: lib/core/widgets/rig/money_text.dart, money_tile.dart, rig_metric_card.dart, test/money_stress_test.dart
Depends: T-F02, T-F05
Docs to read (only these):
- HIGHLIGHTS_AND_COLLAPSE.md (part B: B.3, B.4, B.6)
- COMPONENTS.md (section 0)
- mockup/MOCKUP_NOTES.md (row MoneyText)
Acceptance:
1. The 19 stress rows render without overflow at widths 360 and 412 and text scales 100, 130, 200 (114 cases) in light and dark.
2. Rows and list cells use MoneyText with allowCompact false (never compact).
3. Semantics label is the full plain value.
Verification:
- flutter test test/money_stress_test.dart; goldens at 360 dp 200 percent (light and dark).
- `flutter analyze`: zero errors and no more infos than the baseline (210 on 2026-10-12).
- `git diff --stat` shows no change under `macos/`, `desktop_shell.dart`, `desktop_auth_service.dart`; constructors used by `desktop_shell.dart` stay source compatible.
Parity lines: G-2, G-7
Commit: Add MoneyText, MoneyTile and metric card with stress tests

## T-F07 RigCard, RigGroup, RigRow, RigFormRow [PENDING]
Goal: Inset grouped list and card components: RigCard (radius 20, light shadow only), RigGroup (clip, hairline separators inset 16), RigRow (48 dp, press ink, chevron, value, swipe slot), RigFormRow (label left, value right, focus ring, error, helper slot; validators and controllers passed in).
Files: lib/core/widgets/rig/rig_card.dart, rig_group.dart, rig_row.dart, rig_form_row.dart, widget tests
Depends: T-F02
Docs to read (only these):
- COMPONENTS.md (section 0)
- mockup/TOKENS.md (sections 1, 2, 4, 6, 7)
- mockup/MOCKUP_NOTES.md (rows Inset grouped lists, Form rows)
Acceptance:
1. Rows are at least 48 dp tall, pressed state uses pressOverlay, dark mode has no shadow and no border.
2. RigFormRow passes validators and onChanged through unchanged; error text does not shift layout.
3. At 200 percent text a row stacks label above value.
Verification:
- Widget tests: semantics, 200 percent, validator pass-through.
- `flutter analyze`: zero errors and no more infos than the baseline (210 on 2026-10-12).
- `git diff --stat` shows no change under `macos/`, `desktop_shell.dart`, `desktop_auth_service.dart`; constructors used by `desktop_shell.dart` stay source compatible.
Parity lines: G-6, G-7
Commit: Add card, grouped list, row and form row components

## T-F08 RigButton, RigChipRow, RigSegmented, RigSwitch, RigCheck [PENDING]
Goal: 50 dp pill buttons (filled, tonal, text, destructive using moneyOutButton), inverse selected chips with a 48 dp box around the visible pill, segmented control, themed switch and circle checkbox.
Files: lib/core/widgets/rig/rig_button.dart, rig_chip_row.dart, rig_segmented.dart, widget tests
Depends: T-F02
Docs to read (only these):
- COMPONENTS.md (section 0)
- mockup/TOKENS.md (sections 1, 2, 4, 6, 7)
- mockup/MOCKUP_NOTES.md (rows Pill buttons, Inverse period chips)
Acceptance:
1. Every control has a 48 dp hit box; chip rows scroll with the selected chip scrolled into view; a clipped chip shows a fade edge.
2. Destructive button contrast is at least 4.5:1 in both themes.
Verification:
- Widget tests: hit box size, keyboard or switch-access focus, semantics.
- `flutter analyze`: zero errors and no more infos than the baseline (210 on 2026-10-12).
- `git diff --stat` shows no change under `macos/`, `desktop_shell.dart`, `desktop_auth_service.dart`; constructors used by `desktop_shell.dart` stay source compatible.
Parity lines: G-6, G-7
Commit: Add buttons, chip row, segmented control and toggles

## T-F09 RigAlertDialog, RigSheet, RigSnack, DatePickerSheet, EmptyState, ErrorBanner, Skeleton [PENDING]
Goal: Overlay and feedback components: alert (270 dp, stacked 48 dp actions, destructive in moneyOutText, cancel focused), sheet (grabber, radius 28, keyboard insets, full-height option), floating snackbar capsule above the tab bar and inset, date picker sheet (bounds passed by callers, existing bounds kept; initialDate clamped), empty, error banner, skeleton.
Files: lib/core/widgets/rig/*.dart, widget tests
Depends: T-F07, T-F08
Docs to read (only these):
- COMPONENTS.md (section 0)
- mockup/MOCKUP_NOTES.md (rows Sheets, Alerts, Skeleton)
- mockup/TOKENS.md (sections 1, 2, 4, 6, 7)
Acceptance:
1. Alert actions never default to the destructive option.
2. Sheets keep the primary action above the keyboard.
3. DatePickerSheet clamps initialDate into [first, last] (fixes B-G1-02 for every caller).
Verification:
- Widget tests: keyboard inset, clamp, back dismisses.
- `flutter analyze`: zero errors and no more infos than the baseline (210 on 2026-10-12).
- `git diff --stat` shows no change under `macos/`, `desktop_shell.dart`, `desktop_auth_service.dart`; constructors used by `desktop_shell.dart` stay source compatible.
Parity lines: G-4, G-6
Commit: Add alert, sheet, snackbar, date sheet and state components

## T-F10 LargeTitleScaffold with collapse and status strip [PENDING]
Goal: Large title 34 collapsing to a centered 17 inline title, solid 94 percent bar with hairline (blur only behind the flag, default off), optional status strip, content slivers, bottom padding for the tab bar, back control. No setState per scroll tick (ValueNotifier flip).
Files: lib/core/widgets/rig/large_title_scaffold.dart, widget and scroll tests
Depends: T-F02, T-F09
Docs to read (only these):
- HIGHLIGHTS_AND_COLLAPSE.md (part A, plus the Reconciliation section)
- COMPONENTS.md (section 0)
- mockup/MOCKUP_NOTES.md (row Large title)
Acceptance:
1. Scrolling 200 dp collapses the large title; scrolling up reveals; a short list does not collapse.
2. Strip appears only when collapsed and is a 48 dp button that expands the header.
3. Scroll offset survives a data rebuild (key and PageStorage tests).
Verification:
- Scroll widget tests; profile mode: no rebuilds of the page body while scrolling (DevTools rebuild counts).
- `flutter analyze`: zero errors and no more infos than the baseline (210 on 2026-10-12).
- `git diff --stat` shows no change under `macos/`, `desktop_shell.dart`, `desktop_auth_service.dart`; constructors used by `desktop_shell.dart` stay source compatible.
Parity lines: G-6, G-7
Commit: Add large title scaffold with collapse and status strip

## T-F11 Floating RigTabBar with blur flag [PENDING]
Goal: Floating capsule (62 dp, 16 dp side margin, floats inset + 8 above the bottom, selected capsule darker), five tabs, hides while the keyboard is open, solid 94 percent by default, blur behind a build flag (default off, profile before enabling). Not wired into main_navigation yet.
Files: lib/core/widgets/rig/rig_tab_bar.dart, widget tests
Depends: T-F02
Docs to read (only these):
- COMPONENTS.md (section 0)
- mockup/MOCKUP_NOTES.md (rows Floating tab capsule, Glass blur)
- mockup/TOKENS.md (sections 1, 2, 4, 6, 7)
Acceptance:
1. Each tab has a 48 dp hit box and a semantics label 'Ledger, tab 1 of 5, selected'.
2. With the flag off there is no BackdropFilter in the tree (test).
Verification:
- Widget tests; manual on 3-button and gesture navigation (insets).
- `flutter analyze`: zero errors and no more infos than the baseline (210 on 2026-10-12).
- `git diff --stat` shows no change under `macos/`, `desktop_shell.dart`, `desktop_auth_service.dart`; constructors used by `desktop_shell.dart` stay source compatible.
Parity lines: G-6, G-7
Commit: Add floating tab bar with optional blur flag

## T-F12 RigRing, DepthTile, CategoryTile [PENDING]
Goal: Ring (CustomPainter arc, round caps, reveal off under reduced motion), depth tile, gradient category tile (category colour to 62 percent white, black label).
Files: lib/core/widgets/rig/rig_ring.dart, depth_tile.dart, category_tile.dart, widget tests
Depends: T-F06
Docs to read (only these):
- COMPONENTS.md (section 0)
- mockup/TOKENS.md (sections 1, 2, 4, 6, 7)
- mockup/MOCKUP_NOTES.md (rows Activity ring, Gradient category tiles)
Acceptance:
1. Ring with received 0, half, equal to billed, above billed renders correctly and exposes a semantics label.
2. Category tile labels pass contrast against every gradient stop.
Verification:
- Widget and golden tests.
- `flutter analyze`: zero errors and no more infos than the baseline (210 on 2026-10-12).
- `git diff --stat` shows no change under `macos/`, `desktop_shell.dart`, `desktop_auth_service.dart`; constructors used by `desktop_shell.dart` stay source compatible.
Parity lines: G-6, G-7
Commit: Add ring, depth tile and category tile

## T-F13 UnsavedChangesGuard and RowActions [PENDING]
Goal: PopScope wrapper with a dirty flag and the discard alert (LR-25), and RowActions: long-press menu (Edit, Delete) plus an explicit trailing more button, reusing the existing edit and delete flows through callbacks. NO swipe actions and no new dependency (Q-O7).
Files: lib/core/widgets/rig/unsaved_changes_guard.dart, row_actions.dart, widget tests
Depends: T-F09
Docs to read (only these):
- LOGIC_REQUESTS.md (LR-25)
- COMPONENTS.md (section 0)
- mockup/MOCKUP_NOTES.md (System back mapping, Swipe actions)
Acceptance:
1. With dirty false, back pops immediately; with dirty true, back and the close control show 'Discard changes?'; discard pops, keep stays.
2. Delete from RowActions still opens the existing confirm alert.
Verification:
- Widget tests with a simulated back.
- `flutter analyze`: zero errors and no more infos than the baseline (210 on 2026-10-12).
- `git diff --stat` shows no change under `macos/`, `desktop_shell.dart`, `desktop_auth_service.dart`; constructors used by `desktop_shell.dart` stay source compatible.
Parity lines: G-4
Notes: Q-O7 answered: no swipe, no flutter_slidable; the mockup swipe is a deliberate deviation.
Commit: Add unsaved changes guard and row actions

# Phase 3: screens by traffic

## T-S01 Android shell with floating tab bar and add chooser [PENDING]
Goal: main_navigation.dart uses RigTabBar (Ledger, Portfolio, Agents, Accounts, Settings, order unchanged), FAB or add control behaviour unchanged (Ledger tab opens the bill form or side bore form, Side Ledger tab opens the chooser as a RigSheet), list padding for the bar. IndexedStack stays for now (lazy tabs in Phase 5). Rig wording.
Files: lib/features/navigation/main_navigation.dart
Depends: T-F11, T-F09
Docs to read (only these):
- screens/main_navigation.md (Reconciliation R2 to R5)
- COMPONENTS.md (section 0)
- HIGHLIGHTS_AND_COLLAPSE.md (A.2 pinned parts)
Acceptance:
1. Five tabs, same order and screens; tab switch under 100 ms; the keyboard hides the bar.
2. Back on a root tab does nothing (brief; Q-O6).
3. Add chooser lists Diesel, PVC (main bore only), Bit, Hammer with the category icons and colours.
Verification:
- `flutter analyze`: zero errors and no more infos than the baseline (210 on 2026-10-12).
- Screenshots of the screen in light and dark at 360 and 412 dp, text scale 130 and 200 percent, saved to docs/design/ref (ignored by git): no overflow, no clipped digits, nothing under 11 sp, targets 48 dp.
- Profile: tab switch time recorded.
- `git diff --stat` shows no change under `macos/`, `desktop_shell.dart`, `desktop_auth_service.dart`; constructors used by `desktop_shell.dart` stay source compatible.
Parity lines: PARITY_CHECKLIST.md lead section Mobile shell (P-NAV-1..7)
Notes: desktop_shell.dart is frozen; MainNavigation is mobile only.
Commit: Use floating tab bar in the Android shell

## T-S02 Ledger highlights: ring card, metric cards, depth tiles (B5) [PENDING]
Goal: Replace SummaryRow with the Fitness Summary style card: RigRing (received of billed), 2 x 2 RigMetricCard (Total, Received, Balance, Commission), depth tiles 3 columns (7" Depth, 8" Depth, 7" PVC, 8" PVC, MS Pipe wrap 3 + 2; side bore: Total Depth only, no PVC). Labels unchanged.
Files: lib/features/home/widgets/summary_row.dart (replaced), combined_home_screen.dart
Depends: T-F06, T-F12, T-S01
Docs to read (only these):
- screens/combined_home_screen.md (Reconciliation R1, R2)
- HIGHLIGHTS_AND_COLLAPSE.md (part B)
- COMPONENTS.md (section 0)
Acceptance:
1. Stress table rows 1 to 19 pass on the live screen at 360 and 412 dp, scales 100, 130, 200, light and dark.
2. Values equal the pre-change numbers for the same data (monthlyStatsProvider, feetTotalsProvider unchanged).
3. Feet use the one-decimal rule in tiles and the summary.
Verification:
- `flutter analyze`: zero errors and no more infos than the baseline (210 on 2026-10-12).
- Screenshots of the screen in light and dark at 360 and 412 dp, text scale 130 and 200 percent, saved to docs/design/ref (ignored by git): no overflow, no clipped digits, nothing under 11 sp, targets 48 dp.
- Compare totals with a pre-change screenshot of the same synthetic data.
- `git diff --stat` shows no change under `macos/`, `desktop_shell.dart`, `desktop_auth_service.dart`; constructors used by `desktop_shell.dart` stay source compatible.
Parity lines: PARITY_CHECKLIST.md lead Ledger tab P-LED-4, P-LED-5; G-2, G-7
Commit: Rebuild Ledger highlights as ring, metric cards and depth tiles

## T-S03 Ledger bill list: grouped days, sticky headers, bill row [PENDING]
Goal: Day groups as inset RigGroups with sticky headers (dGroup, day total), bill row (bill number, agent, depth text with the feet rule, Total/Received/Balance fitted, commission line when above zero, manual-total marker with tooltip), RowActions (long press: Edit, Delete via the existing flows), two empty states (no data, no match with Clear). Keys by entry id.
Files: lib/features/home/widgets/ledger_list.dart
Depends: T-F07, T-F10, T-F13, T-S02
Docs to read (only these):
- screens/ledger_list.md (Reconciliation R1, R2, R4)
- COMPONENTS.md (section 0)
- PERFORMANCE.md (R4 sticky headers)
Acceptance:
1. Opening a row opens the edit form of that bill (side bore opens the side bore form).
2. Balance tone: outstandingText above zero, moneyInText at zero or credit; label unchanged.
3. Profile: 2,000 bills, p99 under 16 ms with sticky headers; if not, record and apply the fallback.
Verification:
- `flutter analyze`: zero errors and no more infos than the baseline (210 on 2026-10-12).
- Screenshots of the screen in light and dark at 360 and 412 dp, text scale 130 and 200 percent, saved to docs/design/ref (ignored by git): no overflow, no clipped digits, nothing under 11 sp, targets 48 dp.
- Profile mode on the reference device, 10 s fling of the longest list: p90 build and raster under 8 ms, p99 under 16 ms, janky under 2 percent (targets until the baseline exists; then compare with PERFORMANCE.md R2 and record the numbers in the commit body).
- `git diff --stat` shows no change under `macos/`, `desktop_shell.dart`, `desktop_auth_service.dart`; constructors used by `desktop_shell.dart` stay source compatible.
Parity lines: PARITY_CHECKLIST.md lead P-LED-1, P-LED-9..11, P-LED-13, P-LED-14; G-2, G-4
Commit: Rebuild the bill list with grouped days and row actions

## T-S04 Ledger large title, status strip, period controls, search and filter (B4) [PENDING]
Goal: Ledger tab and Side Ledger tab on LargeTitleScaffold: pinned rig pill and search and filter buttons, tabs Ledger | Side Ledger as RigSegmented, collapsible period chips (Month, 3 Mo, 6 Mo, Year, Custom, All), month or year navigator, Daily | Calendar segmented, highlights; status strip with period and Balance, Filters on chip and search chip; filter and search as RigSheets (option values unchanged); calendar view restyled (fitted totals, tooltip, still non-interactive).
Files: lib/features/home/combined_home_screen.dart (split into widgets), widgets/filter_sheet.dart, search_sheet.dart, calendar_view.dart
Depends: T-S03, T-F10
Docs to read (only these):
- screens/combined_home_screen.md (Reconciliation R1 to R4)
- HIGHLIGHTS_AND_COLLAPSE.md (part A and Reconciliation)
- screens/ledger_list.md (Reconciliation R2)
Acceptance:
1. Collapsing leaves at least 650 dp for the list on 412 x 892 dp; scroll up reveals; tap on the strip expands.
2. Search, filter, period, month, year, custom range, Daily and Calendar give the same lists and totals as before.
3. TabBarView horizontal swipe is disabled (NeverScrollableScrollPhysics) so it does not fight row swipe actions (r1 C1); tabs change by tapping the segmented control only. Switching Ledger and Side Ledger keeps each scroll offset; vehicle (rig) switching still uses today's handler body (LR-01 comes in Phase 4).
Verification:
- `flutter analyze`: zero errors and no more infos than the baseline (210 on 2026-10-12).
- Screenshots of the screen in light and dark at 360 and 412 dp, text scale 130 and 200 percent, saved to docs/design/ref (ignored by git): no overflow, no clipped digits, nothing under 11 sp, targets 48 dp.
- Profile mode on the reference device, 10 s fling of the longest list: p90 build and raster under 8 ms, p99 under 16 ms, janky under 2 percent (targets until the baseline exists; then compare with PERFORMANCE.md R2 and record the numbers in the commit body).
- `git diff --stat` shows no change under `macos/`, `desktop_shell.dart`, `desktop_auth_service.dart`; constructors used by `desktop_shell.dart` stay source compatible.
Parity lines: PARITY_CHECKLIST.md lead P-LED-1..14, P-SLD-1..3; G-2, G-7
Notes: The rig pill opens RigRigSheet whose callback is today's handler body unchanged (a pure extraction).
Commit: Collapse the Ledger header with large title and status strip

## T-S05 Side Ledger home: category tiles and shared period controls [PENDING]
Goal: Side Ledger tab content: shared period chips and navigator (side ledger providers unchanged), summary tiles with quantity and amount fitted, gradient CategoryTiles (Diesel orange, PVC teal main bore only, Bit purple, Hammer pink) that open the four list screens.
Files: lib/features/home/combined_home_screen.dart (side tab widgets in a new file)
Depends: T-F12, T-S04
Docs to read (only these):
- screens/combined_home_screen.md (Reconciliation R2)
- screens/diesel_list_screen.md (Reconciliation R2)
- COMPONENTS.md (section 0)
Acceptance:
1. Side ledger period state stays independent of the Ledger tab.
2. Tile counts and amounts equal the list contents; side bore rigs show Bit and Hammer only.
3. The four side filters are not changed here.
Verification:
- `flutter analyze`: zero errors and no more infos than the baseline (210 on 2026-10-12).
- Screenshots of the screen in light and dark at 360 and 412 dp, text scale 130 and 200 percent, saved to docs/design/ref (ignored by git): no overflow, no clipped digits, nothing under 11 sp, targets 48 dp.
- `git diff --stat` shows no change under `macos/`, `desktop_shell.dart`, `desktop_auth_service.dart`; constructors used by `desktop_shell.dart` stay source compatible.
Parity lines: PARITY_CHECKLIST.md lead P-SLD-1..3
Commit: Rebuild Side Ledger home with category tiles

## T-S10 Main bore bill form as a full-height sheet [PENDING]
Goal: Sheet layout with inset grouped rows in the existing field order, live total card, calculation preview, commission section, payment log host, pinned 50 dp Save pill above the keyboard, UnsavedChangesGuard, double-tap guard retained. Validators, calculations and widget keys untouched.
Files: lib/features/ledger_form/ledger_form_screen.dart, widgets/commission_section.dart, widgets/address_autocomplete_field.dart
Depends: T-F07, T-F09, T-F13, T-D02
Docs to read (only these):
- screens/ledger_form_screen.md (Reconciliation R1 to R5)
- COMPONENTS.md (section 0)
- UX_FLOWS.md (F-2 reconciliation)
Acceptance:
1. Every field, order, keyboard type and validator is identical; total, step rate, commission and payment totals compute the same.
2. Back with unsaved edits asks to discard; clean back does not.
3. Save and the focused field stay above the keyboard on 360 dp. When the live total card scrolls off, a compact Total and Balance strip stays visible (default for Q-O12, UI only).
Verification:
- `flutter analyze`: zero errors and no more infos than the baseline (210 on 2026-10-12).
- Screenshots of the screen in light and dark at 360 and 412 dp, text scale 130 and 200 percent, saved to docs/design/ref (ignored by git): no overflow, no clipped digits, nothing under 11 sp, targets 48 dp.
- Create, edit and delete a bill; compare saved values.
- `git diff --stat` shows no change under `macos/`, `desktop_shell.dart`, `desktop_auth_service.dart`; constructors used by `desktop_shell.dart` stay source compatible.
Parity lines: PARITY_CHECKLIST.md g1 section A; G-2, G-4
Commit: Rebuild the bill form as a sheet with a pinned Save

## T-S11 Payment log editor and payment sheet [PENDING]
Goal: Payment log as an inset group (amount, mode, date, receiver book, payer, note), add and edit as a RigSheet, 'Earlier received' row, payment removal confirms (BUGS_FOUND.md B-G1-12 stays in Phase 4), receiver book creation unchanged.
Files: lib/features/ledger_form/widgets/payment_log_editor.dart
Depends: T-S10
Docs to read (only these):
- screens/payment_log_editor.md (Reconciliation R1 to R5)
- COMPONENTS.md (section 0)
- BUGS_FOUND.md (B-G1-12, B-G1-13)
Acceptance:
1. Totals equal base plus logs; receiver link behaviour identical (PaymentLinkService untouched).
2. Dialog controllers are owned and disposed in State.
Verification:
- `flutter analyze`: zero errors and no more infos than the baseline (210 on 2026-10-12).
- Screenshots of the screen in light and dark at 360 and 412 dp, text scale 130 and 200 percent, saved to docs/design/ref (ignored by git): no overflow, no clipped digits, nothing under 11 sp, targets 48 dp.
- `git diff --stat` shows no change under `macos/`, `desktop_shell.dart`, `desktop_auth_service.dart`; constructors used by `desktop_shell.dart` stay source compatible.
Parity lines: PARITY_CHECKLIST.md g1 section B; G-2, G-4
Commit: Rebuild the payment log editor and payment sheet

## T-S12 Side bore bill form [PENDING]
Goal: Same sheet pattern as T-S10 for the side bore form (no PVC, location suggestions, depth only).
Files: lib/features/ledger_form/side_bore_form_screen.dart
Depends: T-S10
Docs to read (only these):
- screens/side_bore_form_screen.md (Reconciliation R1 to R5)
- COMPONENTS.md (section 0)
Acceptance:
1. Fields, validators and calculations identical; no PVC anywhere; date picker range clamped (B-G1-02 via DatePickerSheet).
Verification:
- `flutter analyze`: zero errors and no more infos than the baseline (210 on 2026-10-12).
- Screenshots of the screen in light and dark at 360 and 412 dp, text scale 130 and 200 percent, saved to docs/design/ref (ignored by git): no overflow, no clipped digits, nothing under 11 sp, targets 48 dp.
- `git diff --stat` shows no change under `macos/`, `desktop_shell.dart`, `desktop_auth_service.dart`; constructors used by `desktop_shell.dart` stay source compatible.
Parity lines: PARITY_CHECKLIST.md g1 section C; G-2, G-4
Commit: Rebuild the side bore form on shared sheet components

## T-S20 Portfolio overview and rig pill (B1) [PENDING]
Goal: Portfolio on LargeTitleScaffold: rig pill that opens RigRigSheet (callback is today's handler body, LR-01 later), range chips in the Ledger tab order (Month, 3 Mo, 6 Mo, Year, Custom, All) with a leading Day chip kept on Portfolio only (Q-O1), This rig | All rigs segmented with helper text, metric cards first (profit card, Total billed, Received, Pending, Commission), expenses and by-agent groups, definitions collapsed. Insight cards are NOT built (LR-21, LR-22 proposed).
Files: lib/features/stats/stats_screen.dart (header and tabs), lib/features/portfolio/portfolio_view.dart
Depends: T-S04, T-F06
Docs to read (only these):
- screens/portfolio.md (Reconciliation R1 to R5)
- COMPONENTS.md (section 0)
- DESIGN_DIRECTION_APPLE.md (A10, Q-O1, Q-O2)
Acceptance:
1. Numbers equal PortfolioCalculator results for the same data; This rig and All rigs and agent filters unchanged.
2. With one rig the pill is plain text.
3. Range chips: all reachable by scroll, selected one visible.
Verification:
- `flutter analyze`: zero errors and no more infos than the baseline (210 on 2026-10-12).
- Screenshots of the screen in light and dark at 360 and 412 dp, text scale 130 and 200 percent, saved to docs/design/ref (ignored by git): no overflow, no clipped digits, nothing under 11 sp, targets 48 dp.
- Profile mode on the reference device, 10 s fling of the longest list: p90 build and raster under 8 ms, p99 under 16 ms, janky under 2 percent (targets until the baseline exists; then compare with PERFORMANCE.md R2 and record the numbers in the commit body).
- `git diff --stat` shows no change under `macos/`, `desktop_shell.dart`, `desktop_auth_service.dart`; constructors used by `desktop_shell.dart` stay source compatible.
Parity lines: PARITY_CHECKLIST.md lead P-PORT-1..5; G-2
Notes: Q-O1: Day stays on Portfolio only. Q-O2: the Pending card label stays.
Commit: Restyle Portfolio overview with metric cards and rig pill

## T-S21 Portfolio chart tabs (Ledger and Side Ledger stats) [PENDING]
Goal: Donut and bars with accessible text legends; chart touch state local to the chart widget (no whole-screen setState); NaN percent guard; Ledger tab renames Pending to Balance (Ledger tab only).
Files: lib/features/stats/stats_screen.dart (Ledger and Side Ledger tabs)
Depends: T-S20
Docs to read (only these):
- screens/stats_screen_charts.md (Reconciliation R1 to R5)
- COMPONENTS.md (section 0)
- BUGS_FOUND.md (G3-B19, G3-B20, G3-B21)
Acceptance:
1. Chart data equals the pre-change data; legends show label, value and percent as text; no overflow at 200 percent.
2. 'Balance' replaces 'Pending' on the Ledger tab only.
Verification:
- `flutter analyze`: zero errors and no more infos than the baseline (210 on 2026-10-12).
- Screenshots of the screen in light and dark at 360 and 412 dp, text scale 130 and 200 percent, saved to docs/design/ref (ignored by git): no overflow, no clipped digits, nothing under 11 sp, targets 48 dp.
- `git diff --stat` shows no change under `macos/`, `desktop_shell.dart`, `desktop_auth_service.dart`; constructors used by `desktop_shell.dart` stay source compatible.
Parity lines: PARITY_CHECKLIST.md g3 section Stats
Commit: Restyle Portfolio chart tabs and rename Pending to Balance

## T-S30 Accounts home: period bar, rows, totals strip [PENDING]
Goal: Account Ledger home in the new look: book selector, period chips (All, Daily, Weekly, Monthly, Yearly), period bar (date not yet tappable; B2 in Phase 4), grouped day list with Previous Balance row, Income and Expense buttons (moneyInButton and moneyOutButton), totals strip with the rupee sign (LR-24), Format Date and number style settings still honoured.
Files: lib/features/cashbook/cashbook_home_screen.dart, widgets/cashbook_*.dart
Depends: T-F07, T-F10, T-F11, T-S01
Docs to read (only these):
- screens/cashbook_home_screen.md (Reconciliation R1 to R5)
- COMPONENTS.md (section 0)
- docs/features/cashbook/PARITY_STATUS.md
Acceptance:
1. Running balance, previous balance rule, totals and filters identical (PARITY-031..047 except the Rs. text).
2. Money shows the rupee sign; dates default to d MMM yyyy unless the user's stored format says otherwise (Q-O8).
Verification:
- `flutter analyze`: zero errors and no more infos than the baseline (210 on 2026-10-12).
- Screenshots of the screen in light and dark at 360 and 412 dp, text scale 130 and 200 percent, saved to docs/design/ref (ignored by git): no overflow, no clipped digits, nothing under 11 sp, targets 48 dp.
- Existing provider tests (11) and export tests (6) still pass: flutter test test/cashbook_provider_test.dart.
- Profile mode on the reference device, 10 s fling of the longest list: p90 build and raster under 8 ms, p99 under 16 ms, janky under 2 percent (targets until the baseline exists; then compare with PERFORMANCE.md R2 and record the numbers in the commit body).
- `git diff --stat` shows no change under `macos/`, `desktop_shell.dart`, `desktop_auth_service.dart`; constructors used by `desktop_shell.dart` stay source compatible.
Parity lines: PARITY_CHECKLIST.md g2 section H (changed lines marked in R5)
Commit: Restyle Account Ledger home with grouped rows and totals

## T-S31 Account Ledger entry form, calculator sheet, items dialog [PENDING]
Goal: Entry form as a sheet (type, amount, date and time, notes, bills, items), calculator as round keys, items dialog with the half-typed row warning (LR-26), discard guard (LR-25), Copy and Delete flows unchanged.
Files: lib/features/cashbook/cashbook_entry_form_screen.dart, cashbook_calculator_sheet.dart, cashbook_items_dialog.dart
Depends: T-S30, T-F13
Docs to read (only these):
- screens/cashbook_entry_form_screen.md (Reconciliation R1 to R5)
- LOGIC_REQUESTS.md (LR-25, LR-26)
- COMPONENTS.md (section 0)
Acceptance:
1. Half-typed items row on OK shows 'Add this row or discard it' (Add adds, Discard drops).
2. Calculator evaluator tests pass unchanged; amount set from items total as before.
Verification:
- `flutter analyze`: zero errors and no more infos than the baseline (210 on 2026-10-12).
- Screenshots of the screen in light and dark at 360 and 412 dp, text scale 130 and 200 percent, saved to docs/design/ref (ignored by git): no overflow, no clipped digits, nothing under 11 sp, targets 48 dp.
- flutter test (calculator tests)
- `git diff --stat` shows no change under `macos/`, `desktop_shell.dart`, `desktop_auth_service.dart`; constructors used by `desktop_shell.dart` stay source compatible.
Parity lines: PARITY_CHECKLIST.md g2 section E; G-4
Commit: Rebuild Account Ledger entry form, calculator and items dialog

## T-S32 Accounts books, pickers and dialogs [PENDING]
Goal: Accounts screen, book picker, add/rename/opening balance/delete dialogs, account actions sheet; Add Account Save disabled while the name is empty (LR-27).
Files: lib/features/cashbook/cashbook_books_screen.dart, cashbook_book_picker_dialog.dart, cashbook_book_dialogs.dart
Depends: T-S30
Docs to read (only these):
- screens/cashbook_books_screen.md (Reconciliation R1 to R5)
- LOGIC_REQUESTS.md (LR-27)
- COMPONENTS.md (section 0)
Acceptance:
1. Empty name: Save disabled (PARITY-003 silent close superseded); two-step delete unchanged; opening balance rules unchanged.
Verification:
- `flutter analyze`: zero errors and no more infos than the baseline (210 on 2026-10-12).
- Screenshots of the screen in light and dark at 360 and 412 dp, text scale 130 and 200 percent, saved to docs/design/ref (ignored by git): no overflow, no clipped digits, nothing under 11 sp, targets 48 dp.
- `git diff --stat` shows no change under `macos/`, `desktop_shell.dart`, `desktop_auth_service.dart`; constructors used by `desktop_shell.dart` stay source compatible.
Parity lines: PARITY_CHECKLIST.md g2 section B (PARITY-003 changes on purpose)
Commit: Rebuild Accounts books screen and dialogs

## T-S33 Account Ledger summaries, calendar, transfer and reports [PENDING]
Goal: Summary, Account Summary, Transaction-All, Calendar, Transfer, Report dialog in the new look; same data and exports.
Files: lib/features/cashbook/cashbook_summary_screen.dart, cashbook_account_summary_screen.dart, cashbook_all_transactions_screen.dart, cashbook_calendar_screen.dart, cashbook_transfer_screen.dart, cashbook_report_dialog.dart
Depends: T-S30
Docs to read (only these):
- screens/cashbook_summary_screen.md (Reconciliation R1 to R5)
- screens/cashbook_calendar_screen.md (Reconciliation R2)
- COMPONENTS.md (section 0)
Acceptance:
1. Totals identical; calendar cells fit large amounts; report PDF and CSV byte-identical.
Verification:
- `flutter analyze`: zero errors and no more infos than the baseline (210 on 2026-10-12).
- Screenshots of the screen in light and dark at 360 and 412 dp, text scale 130 and 200 percent, saved to docs/design/ref (ignored by git): no overflow, no clipped digits, nothing under 11 sp, targets 48 dp.
- flutter test (6 export tests)
- `git diff --stat` shows no change under `macos/`, `desktop_shell.dart`, `desktop_auth_service.dart`; constructors used by `desktop_shell.dart` stay source compatible.
Parity lines: PARITY_CHECKLIST.md g2 sections S, T, R
Commit: Restyle Account Ledger summaries, calendar, transfer and report

## T-S34 Account Ledger notebook, trash, settings, import, help, hub [PENDING]
Goal: Notebook and note form, Deleted Transactions, Account Ledger settings (Appearance is NOT here), import, help and the hub drawer in the new look.
Files: lib/features/cashbook/cashbook_notebook_screen.dart, cashbook_note_form_screen.dart, cashbook_trash_screen.dart, cashbook_settings_screen.dart, cashbook_import_screen.dart, cashbook_help_screen.dart, cashbook_hub_screen.dart
Depends: T-S30
Docs to read (only these):
- screens/cashbook_hub_screen.md (Reconciliation R1 to R5)
- screens/cashbook_notebook_screen.md (Reconciliation R2)
- COMPONENTS.md (section 0)
Acceptance:
1. Behaviour identical; hub is the Android drawer (two-pane macOS layout stays in code, frozen); trash pluralization and feedback fixes land in Phase 4.
Verification:
- `flutter analyze`: zero errors and no more infos than the baseline (210 on 2026-10-12).
- Screenshots of the screen in light and dark at 360 and 412 dp, text scale 130 and 200 percent, saved to docs/design/ref (ignored by git): no overflow, no clipped digits, nothing under 11 sp, targets 48 dp.
- `git diff --stat` shows no change under `macos/`, `desktop_shell.dart`, `desktop_auth_service.dart`; constructors used by `desktop_shell.dart` stay source compatible.
Parity lines: PARITY_CHECKLIST.md g2 sections HUB, N, D, G, I, Z
Commit: Restyle Account Ledger notebook, trash, settings, import and hub

## T-S40 Agents [PENDING]
Goal: Agents list as an inset group with commission totals, add and edit sheets (default commission rates), delete alert that does not preselect Delete all entries (G3-B15); rename still calls updateAgentInLedgerEntries before saving.
Files: lib/features/agents/agents_screen.dart
Depends: T-F07, T-F09, T-F10
Docs to read (only these):
- screens/agents_screen.md (Reconciliation R1 to R5)
- COMPONENTS.md (section 0)
- BUGS_FOUND.md (G3-B15, G3-B13, G3-B14)
Acceptance:
1. Add, edit, rename and delete behave as before; dialog controllers owned by State.
2. Screen can be built lazily later (Phase 5) without losing state.
Verification:
- `flutter analyze`: zero errors and no more infos than the baseline (210 on 2026-10-12).
- Screenshots of the screen in light and dark at 360 and 412 dp, text scale 130 and 200 percent, saved to docs/design/ref (ignored by git): no overflow, no clipped digits, nothing under 11 sp, targets 48 dp.
- `git diff --stat` shows no change under `macos/`, `desktop_shell.dart`, `desktop_auth_service.dart`; constructors used by `desktop_shell.dart` stay source compatible.
Parity lines: PARITY_CHECKLIST.md g3 section Agents; G-4
Commit: Restyle Agents list and dialogs

## T-S41 Settings with Appearance row and Drive card [PENDING]
Goal: Settings as inset groups: Drive hero card (connected, not connected, error with Retry), backup and restore, auto backup, Appearance row (System, Light, Dark sheet, LR-23), rigs and exports entries, About. Clear All Data alert lists that Account Ledger books and notes are erased too; Restore picks the file first, then confirms (LR-28).
Files: lib/features/settings/settings_screen.dart
Depends: T-F04, T-F09, T-F10
Docs to read (only these):
- screens/settings_screen.md (Reconciliation R1 to R5)
- LOGIC_REQUESTS.md (LR-23, LR-28)
- COMPONENTS.md (section 0)
Acceptance:
1. Appearance changes the theme immediately and persists.
2. Restore: file picker first, confirmation second; Clear All Data text names the Account Ledger; the operations themselves are unchanged.
3. Backup, Drive sign-in and out, auto backup toggle work as before.
Verification:
- `flutter analyze`: zero errors and no more infos than the baseline (210 on 2026-10-12).
- Screenshots of the screen in light and dark at 360 and 412 dp, text scale 130 and 200 percent, saved to docs/design/ref (ignored by git): no overflow, no clipped digits, nothing under 11 sp, targets 48 dp.
- `git diff --stat` shows no change under `macos/`, `desktop_shell.dart`, `desktop_auth_service.dart`; constructors used by `desktop_shell.dart` stay source compatible.
Parity lines: PARITY_CHECKLIST.md g3 section Settings; G-4, G-8
Commit: Rebuild Settings with Appearance row and safer restore flow

## T-S42 About and Rigs (vehicle management) [PENDING]
Goal: About and Rigs screens in the new look; About text says Android only (Q-O15); all UI copy says Rig (title Rigs, Add Rig, Switch Rig); class and file names unchanged; add and delete flows and confirms unchanged.
Files: lib/features/settings/about_screen.dart, vehicle_management_screen.dart
Depends: T-F07, T-F09
Docs to read (only these):
- screens/vehicle_management_screen.md (Reconciliation R1 to R5)
- screens/about_screen.md (Reconciliation R2)
- COMPONENTS.md (section 0)
Acceptance:
1. No UI string says Vehicle; delete vehicle still removes its data with the existing confirms.
Verification:
- `flutter analyze`: zero errors and no more infos than the baseline (210 on 2026-10-12).
- Screenshots of the screen in light and dark at 360 and 412 dp, text scale 130 and 200 percent, saved to docs/design/ref (ignored by git): no overflow, no clipped digits, nothing under 11 sp, targets 48 dp.
- grep of UI strings for 'Vehicle' (excluding identifiers).
- `git diff --stat` shows no change under `macos/`, `desktop_shell.dart`, `desktop_auth_service.dart`; constructors used by `desktop_shell.dart` stay source compatible.
Parity lines: PARITY_CHECKLIST.md g3 sections About, Vehicles
Commit: Restyle About and Rigs screens and use Rig wording

## T-S43d Diesel ledger list and form [PENDING]
Goal: Diesel list (summary strip, RigGroup rows with RowActions, filter as RigSheet, empty state) and form (sheet layout, per-type count and rate where the entry has types, litres and rate for Diesel, Pending = total minus paid unchanged) using orange as the category colour.
Files: lib/features/side_ledger/diesel/diesel_list_screen.dart, diesel_form_screen.dart
Depends: T-F07, T-F09, T-F13, T-F12
Docs to read (only these):
- screens/diesel_list_screen.md (Reconciliation R1 to R5)
- screens/diesel_form_screen.md (Reconciliation R2, R4)
- COMPONENTS.md (section 0)
Acceptance:
1. Totals, counts and pending equal the pre-change values (summary netting unchanged until LR-29 is approved).
2. Date picker clamps out of range dates; delete confirms unchanged; discard guard on the form.
Verification:
- `flutter analyze`: zero errors and no more infos than the baseline (210 on 2026-10-12).
- Screenshots of the screen in light and dark at 360 and 412 dp, text scale 130 and 200 percent, saved to docs/design/ref (ignored by git): no overflow, no clipped digits, nothing under 11 sp, targets 48 dp.
- `git diff --stat` shows no change under `macos/`, `desktop_shell.dart`, `desktop_auth_service.dart`; constructors used by `desktop_shell.dart` stay source compatible.
Parity lines: PARITY_CHECKLIST.md g1 section D; G-2, G-4
Notes: One commit per category; Diesel is the reference implementation.
Commit: Restyle Diesel ledger list and form

## T-S43p PVC ledger list and form [PENDING]
Goal: PVC list (summary strip, RigGroup rows with RowActions, filter as RigSheet, empty state) and form (sheet layout, per-type count and rate where the entry has types, litres and rate for Diesel, Pending = total minus paid unchanged) using teal as the category colour.
Files: lib/features/side_ledger/pvc/pvc_list_screen.dart, pvc_form_screen.dart
Depends: T-F07, T-F09, T-F13, T-F12
Docs to read (only these):
- screens/pvc_list_screen.md (Reconciliation R1 to R5)
- screens/pvc_form_screen.md (Reconciliation R2, R4)
- COMPONENTS.md (section 0)
Acceptance:
1. Totals, counts and pending equal the pre-change values (summary netting unchanged until LR-29 is approved).
2. Date picker clamps out of range dates; delete confirms unchanged; discard guard on the form.
Verification:
- `flutter analyze`: zero errors and no more infos than the baseline (210 on 2026-10-12).
- Screenshots of the screen in light and dark at 360 and 412 dp, text scale 130 and 200 percent, saved to docs/design/ref (ignored by git): no overflow, no clipped digits, nothing under 11 sp, targets 48 dp.
- `git diff --stat` shows no change under `macos/`, `desktop_shell.dart`, `desktop_auth_service.dart`; constructors used by `desktop_shell.dart` stay source compatible.
Parity lines: PARITY_CHECKLIST.md g1 section E; G-2, G-4
Notes: One commit per category; follows the Diesel implementation.
Commit: Restyle PVC ledger list and form

## T-S43b Bit ledger list and form [PENDING]
Goal: Bit list (summary strip, RigGroup rows with RowActions, filter as RigSheet, empty state) and form (sheet layout, per-type count and rate where the entry has types, litres and rate for Diesel, Pending = total minus paid unchanged) using purple as the category colour.
Files: lib/features/side_ledger/bit/bit_list_screen.dart, bit_form_screen.dart
Depends: T-F07, T-F09, T-F13, T-F12
Docs to read (only these):
- screens/bit_list_screen.md (Reconciliation R1 to R5)
- screens/bit_form_screen.md (Reconciliation R2, R4)
- COMPONENTS.md (section 0)
Acceptance:
1. Totals, counts and pending equal the pre-change values (summary netting unchanged until LR-29 is approved).
2. Date picker clamps out of range dates; delete confirms unchanged; discard guard on the form.
Verification:
- `flutter analyze`: zero errors and no more infos than the baseline (210 on 2026-10-12).
- Screenshots of the screen in light and dark at 360 and 412 dp, text scale 130 and 200 percent, saved to docs/design/ref (ignored by git): no overflow, no clipped digits, nothing under 11 sp, targets 48 dp.
- `git diff --stat` shows no change under `macos/`, `desktop_shell.dart`, `desktop_auth_service.dart`; constructors used by `desktop_shell.dart` stay source compatible.
Parity lines: PARITY_CHECKLIST.md g1 section F; G-2, G-4
Notes: One commit per category; follows the Diesel implementation.
Commit: Restyle Bit ledger list and form

## T-S43h Hammer ledger list and form [PENDING]
Goal: Hammer list (summary strip, RigGroup rows with RowActions, filter as RigSheet, empty state) and form (sheet layout, per-type count and rate where the entry has types, litres and rate for Diesel, Pending = total minus paid unchanged) using pink as the category colour.
Files: lib/features/side_ledger/hammer/hammer_list_screen.dart, hammer_form_screen.dart
Depends: T-F07, T-F09, T-F13, T-F12
Docs to read (only these):
- screens/hammer_list_screen.md (Reconciliation R1 to R5)
- screens/hammer_form_screen.md (Reconciliation R2, R4)
- COMPONENTS.md (section 0)
Acceptance:
1. Totals, counts and pending equal the pre-change values (summary netting unchanged until LR-29 is approved).
2. Date picker clamps out of range dates; delete confirms unchanged; discard guard on the form.
Verification:
- `flutter analyze`: zero errors and no more infos than the baseline (210 on 2026-10-12).
- Screenshots of the screen in light and dark at 360 and 412 dp, text scale 130 and 200 percent, saved to docs/design/ref (ignored by git): no overflow, no clipped digits, nothing under 11 sp, targets 48 dp.
- `git diff --stat` shows no change under `macos/`, `desktop_shell.dart`, `desktop_auth_service.dart`; constructors used by `desktop_shell.dart` stay source compatible.
Parity lines: PARITY_CHECKLIST.md g1 section G; G-2, G-4
Notes: One commit per category; follows the Diesel implementation.
Commit: Restyle Hammer ledger list and form

## T-S44 Export and import screens [PENDING]
Goal: PDF export, CSV export and CSV import screens in the new look (screens only; the generated PDF and CSV are frozen), sticky Generate pill, progress and success states, date range validation message for From after To.
Files: lib/features/export/pdf_export_screen.dart, csv_export_screen.dart, csv_import_screen.dart
Depends: T-F07, T-F09, T-F10
Docs to read (only these):
- screens/pdf_export_screen.md (Reconciliation R1 to R5)
- screens/csv_import_screen.md (Reconciliation R2)
- COMPONENTS.md (section 0)
Acceptance:
1. PDF and CSV output byte-identical to the baseline for the same data.
2. CSV import mapping fixed earlier (T-D01) is unaffected.
Verification:
- `flutter analyze`: zero errors and no more infos than the baseline (210 on 2026-10-12).
- Screenshots of the screen in light and dark at 360 and 412 dp, text scale 130 and 200 percent, saved to docs/design/ref (ignored by git): no overflow, no clipped digits, nothing under 11 sp, targets 48 dp.
- Export PDF and CSV from the synthetic dataset and compare bytes.
- `git diff --stat` shows no change under `macos/`, `desktop_shell.dart`, `desktop_auth_service.dart`; constructors used by `desktop_shell.dart` stay source compatible.
Parity lines: PARITY_CHECKLIST.md g3 sections PDF export, CSV export, CSV import; G-3
Commit: Restyle export and import screens

# Phase 4: remaining bugs by severity, then logic exceptions 13 and 14

## T-X01 Crash fixes [PENDING]
Goal: Fix every Crash entry of BUGS_FOUND.md section 3.1 not already fixed by a screen task: date picker range (B-G1-02 if still open), Account Summary and Calendar empty books guard (G2-B13), setState after await (G3-B11), zero PDF columns (G3-B24).
Files: files named in the four entries
Depends: Phase 3 tasks touching the files
Docs to read (only these):
- BUGS_FOUND.md (section 3.1, the four entries)
Acceptance:
1. Each crash reproduces on the pre-fix build and no longer reproduces after.
2. Mark each id fixed with the fixing commit in BUGS_FOUND.md.
Verification:
- `flutter analyze`: zero errors and no more infos than the baseline (210 on 2026-10-12).
- Reproduction steps per entry.
- `git diff --stat` shows no change under `macos/`, `desktop_shell.dart`, `desktop_auth_service.dart`; constructors used by `desktop_shell.dart` stay source compatible.
Parity lines: G-1
Commit: Fix date picker range and async state crashes

## T-X02 Wrong-number display fixes [PENDING]
Goal: Fix every Wrong number entry of BUGS_FOUND.md section 3.2 not fixed earlier: Calculation Preview Total with a manual total (B-G1-03), donut NaN percent (G3-B19), transfer and note duplicates (G2-B05, G2-B06 via guards), calendar and others listed there. Stats Ledger tab Balance label done in T-S21.
Files: files named in the entries
Depends: T-X01
Docs to read (only these):
- BUGS_FOUND.md (section 3.2)
- LOGIC_REQUESTS.md (LR-29 proposed, do not implement)
Acceptance:
1. Each entry reproduced before and fixed after; LR-29 (side ledger Pending netting) is NOT changed in this task.
Verification:
- `flutter analyze`: zero errors and no more infos than the baseline (210 on 2026-10-12).
- Reproduction steps per entry.
- `git diff --stat` shows no change under `macos/`, `desktop_shell.dart`, `desktop_auth_service.dart`; constructors used by `desktop_shell.dart` stay source compatible.
Parity lines: G-2
Commit: Fix misleading numbers and duplicate saves

## T-X03 Data loss fixed with UI guards [PENDING]
Goal: Entries of section 3.3 that need only a UI guard or copy: transfer, note, vehicle, agent and import double-tap guards (LR-32 remainder), agent delete default option (G3-B15), vehicle add, import run twice guard where UI only, payment removal confirmation (B-G1-12). Items that change what is written stay in section 4 of BUGS_FOUND.md.
Files: files named in the entries
Depends: T-X02
Docs to read (only these):
- BUGS_FOUND.md (section 3.3)
- LOGIC_REQUESTS.md (LR-32)
Acceptance:
1. Double activation of each button creates one record.
2. Destructive defaults are never preselected.
Verification:
- `flutter analyze`: zero errors and no more infos than the baseline (210 on 2026-10-12).
- Per entry reproduction.
- `git diff --stat` shows no change under `macos/`, `desktop_shell.dart`, `desktop_auth_service.dart`; constructors used by `desktop_shell.dart` stay source compatible.
Parity lines: G-4
Commit: Guard remaining save buttons and destructive defaults

## T-X04 UI-only leftovers [PENDING]
Goal: Close every remaining entry of BUGS_FOUND.md section 3.4 (tap targets, overflow at 200 percent, contrast, feedback after actions, trash pluralization, duplicate-name rename warning copy) not already resolved by a screen task. macOS-only entries (B-05 to B-08, B-16) are out of scope: frozen.
Files: files named in the entries
Depends: T-X03
Docs to read (only these):
- BUGS_FOUND.md (section 3.4)
- INCONSISTENCIES.md (status table)
Acceptance:
1. Checklist in the commit body: each id marked fixed (with commit) or out of scope (macOS) or deferred.
Verification:
- `flutter analyze`: zero errors and no more infos than the baseline (210 on 2026-10-12).
- Screenshots of the screen in light and dark at 360 and 412 dp, text scale 130 and 200 percent, saved to docs/design/ref (ignored by git): no overflow, no clipped digits, nothing under 11 sp, targets 48 dp.
- `git diff --stat` shows no change under `macos/`, `desktop_shell.dart`, `desktop_auth_service.dart`; constructors used by `desktop_shell.dart` stay source compatible.
Parity lines: G-6, G-7
Commit: Fix remaining UI-only issues from the review

## T-X05 Cosmetic leftovers [PENDING]
Goal: Entries of section 3.5 (copy, grammar, pluralization). Deprecated withOpacity and prefer_const sweep (B-21).
Files: files named in the entries
Depends: T-X04
Docs to read (only these):
- BUGS_FOUND.md (section 3.5)
Acceptance:
1. analyze infos of kinds deprecated_member_use and prefer_const_constructors are zero.
Verification:
- `flutter analyze`: zero errors and no more infos than the baseline (210 on 2026-10-12).
- `git diff --stat` shows no change under `macos/`, `desktop_shell.dart`, `desktop_auth_service.dart`; constructors used by `desktop_shell.dart` stay source compatible.
Parity lines: G-1
Commit: Clear cosmetic issues and lint infos

## T-X10 Shared switchRig (LR-01) [PENDING]
Goal: One function switchRig(ref, vehicle): await currentVehicleProvider.setCurrentVehicle, clear searchQueryProvider, ledgerFilterProvider, dieselFilterProvider, pvcFilterProvider, bitFilterProvider, hammerFilterProvider, then refresh ledger, agents, diesel, pvc, bit, hammer (and vehicles). Used by RigRigSheet in the Ledger and Portfolio headers. The frozen desktop shell keeps its own handler and is NOT edited (its B-01 race stays a macOS item).
Files: lib/core/providers/vehicle_provider.dart or lib/core/services/rig_switch.dart, rig sheet usage in combined_home_screen.dart and stats_screen.dart, and the fourth copy `_switchVehicle` in lib/features/settings/vehicle_management_screen.dart (L2-r4-1), test/switch_rig_test.dart
Depends: T-S20
Docs to read (only these):
- DESIGN_DIRECTION_APPLE.md (section 8.1)
- LOGIC_REQUESTS.md (LR-01)
- screens/portfolio.md (Reconciliation R3)
Acceptance:
1. Switching rig twice and back shows each rig's data in Ledger, Side Ledger, Portfolio and Agents with no stale list.
2. Search and all side filters are cleared; period state is not reset.
3. The provider list equals the verified list in section 8.1.
Verification:
- Provider test with two rigs (temp Hive).
- `flutter analyze`: zero errors and no more infos than the baseline (210 on 2026-10-12).
- Manual: switch from the Ledger header and from the Portfolio header.
- `git diff --stat` shows no change under `macos/`, `desktop_shell.dart`, `desktop_auth_service.dart`; constructors used by `desktop_shell.dart` stay source compatible.
Parity lines: PARITY_CHECKLIST.md lead P-LED-12, P-PORT-3; G-2
Notes: Logic exception 13, approved.
Commit: Share one awaited rig switch used by Ledger and Portfolio

## T-X11 Daily date picker (B2) with setAnchor (LR-02) [PENDING]
Goal: Add CashViewConfigNotifier.setAnchor(DateTime) (one line: anchor to date only, clear custom range) and make the Daily date in the period bar a button that opens DatePickerSheet (bounds 1 Jan 2000 to 31 Dec 2100, clamp, Today label). Arrows and the Daily chip stay.
Files: lib/core/providers/cashbook_provider.dart (one method), lib/features/cashbook/widgets/cashbook_period_bar.dart, cashbook_home_screen.dart, test/cashbook_provider_test.dart
Depends: T-S30
Docs to read (only these):
- screens/accounts_daily_date_picker.md (Reconciliation R1 to R5)
- LOGIC_REQUESTS.md (LR-02)
- COMPONENTS.md (section 0)
Acceptance:
1. Picking 3 Jan 2026 shows that day with Daily still selected and both arrows working; a day without entries shows the empty state and the carried balance.
2. The overflow Date and Select Date Range items behave as before; the 11 provider tests pass plus a setAnchor test.
Verification:
- flutter test test/cashbook_provider_test.dart
- `flutter analyze`: zero errors and no more infos than the baseline (210 on 2026-10-12).
- Screenshots of the screen in light and dark at 360 and 412 dp, text scale 130 and 200 percent, saved to docs/design/ref (ignored by git): no overflow, no clipped digits, nothing under 11 sp, targets 48 dp.
- `git diff --stat` shows no change under `macos/`, `desktop_shell.dart`, `desktop_auth_service.dart`; constructors used by `desktop_shell.dart` stay source compatible.
Parity lines: PARITY_CHECKLIST.md lead P-ACC-1..5
Notes: Logic exception 14, approved.
Commit: Let the Daily filter jump to any date from a date sheet

## T-X20 Data, sync and model items (one task per approved item) [PENDING]
Goal: BUGS_FOUND.md section 4 (18 entries: D-01 Drive scope, D-02 atomic restore, D-03 write queue and tombstone pruning, D-04 auto backup guard, D-05 permission, D-06 orphan model, B-19 and B-20 provider reads, G2-B09 entry mutation, G3-B02 and G3-B03 double import, G3-B06 to G3-B08 CSV import, G3-B10 restore validation, G3-B12 duplicate agent name, D-07 isDesktop). NONE is scheduled. For each item: enter plan mode, present the item, wait for an explicit yes, then one task and one commit. Never batched. D-07 and macOS-specific parts are frozen.
Files: per item
Depends: T-X05
Docs to read (only these):
- BUGS_FOUND.md (section 4)
- LOGIC_REQUESTS.md (LR-10, LR-11)
Acceptance:
1. Per item: unit tests, restore from a backup taken before the change, and for sync a two-device rehearsal.
Verification:
- Per item, written in the plan-mode proposal.
- `flutter analyze`: zero errors and no more infos than the baseline (210 on 2026-10-12).
- `git diff --stat` shows no change under `macos/`, `desktop_shell.dart`, `desktop_auth_service.dart`; constructors used by `desktop_shell.dart` stay source compatible.
Parity lines: G-8
Notes: Placeholder task: do not start without a per-item yes.
Commit: (one message per approved item)

# Phase 5: lazy tabs, performance, cleanup, QA

## T-P01 Lazy Portfolio, Agents and Settings tabs [PENDING]
Goal: Build Portfolio, Agents and Settings on first visit and keep them alive (lazy stack wrapper). Ledger and Accounts stay built at launch (Q-O3).
Files: lib/features/navigation/main_navigation.dart
Depends: T-S20, T-S40, T-S41
Docs to read (only these):
- PERFORMANCE.md (R3)
- PARITY_CHECKLIST.md (section Lazy tabs and theme)
Acceptance:
1. Cold start improves versus the baseline; first visit to each lazy tab shows its content; second visit keeps scroll position, selected chips, open tab and agent filter.
2. Edits made on the Ledger while a lazy tab is not yet built appear when the tab is first opened.
Verification:
- `flutter analyze`: zero errors and no more infos than the baseline (210 on 2026-10-12).
- Profile: cold start and tab switch recorded against the baseline.
- `git diff --stat` shows no change under `macos/`, `desktop_shell.dart`, `desktop_auth_service.dart`; constructors used by `desktop_shell.dart` stay source compatible.
Parity lines: PARITY_CHECKLIST.md Lazy tabs lines; G-2
Commit: Build Portfolio, Agents and Settings lazily on first visit

## T-P02 Performance pass against the baseline [PENDING]
Goal: Profile Ledger list, Account Ledger list, tab switch, header collapse; fix regressions (sticky headers fallback, row actions, shadows, formatter caches, rebuild scopes); decide the blur flag (stays off unless p99 holds).
Files: files identified by profiling
Depends: T-P01
Docs to read (only these):
- PERFORMANCE.md (R1, R2, R4)
Acceptance:
1. Numbers recorded in PERFORMANCE.md; each target met or the deviation explained (targets, not gates).
2. Blur flag decision recorded.
Verification:
- Profile mode on the reference device, DevTools timeline.
- `flutter analyze`: zero errors and no more infos than the baseline (210 on 2026-10-12).
- `git diff --stat` shows no change under `macos/`, `desktop_shell.dart`, `desktop_auth_service.dart`; constructors used by `desktop_shell.dart` stay source compatible.
Parity lines: G-2
Commit: Tune list and header performance against the baseline

## T-P03 Remove old theme, gradients and unused widgets [PENDING]
Goal: Remove AppColors aliases and gradient entries, AppTheme, AdaptiveHeader, GradientAppBar and unused tokens once grep shows no references in non-frozen code. `desktop_shell.dart` (frozen) references AppColors 21 times, so `AppColors` is NOT deleted: keep `app_colors.dart` reduced to exactly the symbols the frozen files import (a compatibility shim with a comment naming the frozen files), delete everything else (L2-r4-4). Never edit the frozen files to make the deletion easier.
Files: lib/core/theme/app_colors.dart, app_theme.dart, lib/core/widgets/adaptive_header.dart, gradient_widgets.dart
Depends: T-P02
Docs to read (only these):
- core_theme_and_widgets.md (Reconciliation R2)
- INCONSISTENCIES.md (I-07, I-30)
Acceptance:
1. `grep -rn "AppColors\." lib` shows only frozen files and the shim; `flutter analyze` proves the frozen files still compile.
2. Both themes unchanged visually.
Verification:
- `flutter analyze`: zero errors and no more infos than the baseline (210 on 2026-10-12).
- `git diff --stat` shows no change under `macos/`, `desktop_shell.dart`, `desktop_auth_service.dart`; constructors used by `desktop_shell.dart` stay source compatible.
- App builds for Android release.
Parity lines: G-1, G-6
Notes: If a frozen file imports a symbol, keep that symbol: do not edit frozen files.
Commit: Remove old color aliases, gradients and unused header widgets

## T-P04 Final QA in both themes with the largest text size [PENDING]
Goal: Walk PARITY_CHECKLIST.md on the reference device in light and dark at text scale 100, 130 and 200 (system largest), 360 and 412 dp widths, gesture and 3-button navigation; record accepted differences.
Files: docs/design/PARITY_CHECKLIST.md (results column), docs/design/BUGS_FOUND.md (statuses)
Depends: T-P03
Docs to read (only these):
- PARITY_CHECKLIST.md
- BUGS_FOUND.md
Acceptance:
1. Every parity line passed or has a recorded intentional difference (rupee sign, Rig wording, disabled Save, discard prompt).
2. No overflow, no clipped digits, no text under 11 sp, all targets 48 dp.
Verification:
- Screenshots to docs/design/ref; QA table in the commit body.
- `flutter analyze`: zero errors and no more infos than the baseline (210 on 2026-10-12).
- `git diff --stat` shows no change under `macos/`, `desktop_shell.dart`, `desktop_auth_service.dart`; constructors used by `desktop_shell.dart` stay source compatible.
Parity lines: all
Commit: Record final QA results for both themes and large text

## T-P05 Update project docs for the new design system [PENDING]
Goal: Ask the developer the macOS fate question (keep building, archive on a branch, or delete; recommendation: archive; Q-O9), then update ARCHITECTURE.md (shell, theme, appearance), CONVENTIONS.md (replace light-only and gradient rules with tokens and components), MEMORY.md and CURRENT.md. MODELS.md untouched.
Files: .claude/context/ARCHITECTURE.md, CONVENTIONS.md, MEMORY.md, .claude/tasks/CURRENT.md
Depends: T-P04
Docs to read (only these):
- DESIGN_SYSTEM.md (section R)
- INDEX.md
Acceptance:
1. No document still says light only, gradient header, Noto Sans UI, Vehicle in UI wording or macOS targets (macOS: frozen note).
Verification:
- grep for the stale phrases.
- `flutter analyze`: zero errors and no more infos than the baseline (210 on 2026-10-12).
- `git diff --stat` shows no change under `macos/`, `desktop_shell.dart`, `desktop_auth_service.dart`; constructors used by `desktop_shell.dart` stay source compatible.
Parity lines: none
Commit: Update project docs for the new design system

## T-Z99 Delete dead screens (last task) [PENDING]
Goal: Delete lib/features/home/home_screen.dart and lib/features/side_ledger/side_ledger_screen.dart ONLY after a search proves zero references. Evidence goes into the commit body.
Files: lib/features/home/home_screen.dart, lib/features/side_ledger/side_ledger_screen.dart
Depends: T-P05
Docs to read (only these):
- screens/home_screen.md
- screens/side_ledger_screen.md
Acceptance:
1. `grep -rn "HomeScreen\b\|SideLedgerScreen\b" lib test` shows only the two declarations before deletion and nothing after.
2. `flutter analyze` is clean after deletion and the app builds.
Verification:
- The grep output and analyze output pasted in the commit body.
- `flutter analyze`: zero errors and no more infos than the baseline (210 on 2026-10-12).
- `git diff --stat` shows no change under `macos/`, `desktop_shell.dart`, `desktop_auth_service.dart`; constructors used by `desktop_shell.dart` stay source compatible.
Parity lines: none
Notes: Needs git rm: CLAUDE.md forbids rm without explicit instruction. This task IS the explicit instruction for these two files only.
Commit: Remove unused HomeScreen and SideLedgerScreen
