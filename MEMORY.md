# RigLedger - Session Memory

Last updated: 2026-10-22 (v2.0.4 done, Apple-style design mockup)

## Current versions

- Single source of truth: `pubspec.yaml` (`version: X.Y.Z+N`). Android and macOS both read this at build time (Android via `flutter.versionName`/`flutter.versionCode` in `android/local.properties`, macOS via `$(FLUTTER_BUILD_NAME)`/`$(FLUTTER_BUILD_NUMBER)` in `Info.plist`). Neither platform hardcodes its own version.

## Active decisions

- `DesktopAuthService` (`lib/core/services/desktop_auth_service.dart`) has placeholder client ID/secret for Windows/Linux. macOS uses `google_sign_in` native plugin instead. Do not wire the desktop auth service until the developer provides real credentials.
- Task workflow: each sub-task gets its own individual commit, created automatically by Claude (`git add` the changed files, `git commit` with an imperative <=72 char message, no `Co-Authored-By` trailer, never amend). Claude never runs `git push` -- that stays the developer's call.
- Known tech debt and future ideas live in `.claude/tasks/BACKLOG.md`, not here.

## Gotchas

- `MiniLedgerEntry` is orphaned: fully wired into `DatabaseService` and `SyncService` but no screen or provider uses it. Side Bore saves plain `LedgerEntry` instead. See `BACKLOG.md`.
- `LedgerEntry.msPipe` is free-text defaulting to `'6inch'`; the form dropdown only offers `'6inch'` today, despite older docs implying multiple sizes.

## v2.0.0 (released candidate, version 2.0.0+5)

- Done: Account Ledger (tab 4, Settings is tab 5), payment log with receiver books (`PaymentLinkService`), commission, Portfolio (former Stats tab), side bore fixes (no PVC, location suggestions), About screen and proprietary LICENSE, import from the cashbook app, schemaVersion 5. Every task is committed; see `CURRENT.md` and `docs/features/cashbook/PARITY_STATUS.md`.
- Review: `docs/v2.0.0-review.md` (tested, not tested, bugs fixed, open bugs, improvements). Open items copied to `BACKLOG.md`.
- Decisions to confirm with the developer: commission formula (ft x rate per ft), profit definition, LICENSE copyright line. (Rs. vs the rupee sign: decided 2026-10-13, rupee sign everywhere, LR-24.)
- Not verifiable here: running the macOS app (needs `macos/Runner/GoogleService-Info.plist`), real Drive sync, camera/gallery bills.
- Gotchas learned: dialogs must own their TextEditingControllers (dispose in State, never right after `await showDialog`); widget tests that touch Hive must wait on real time (`runAsync`) and must not call `Hive.close()`; `flutter test` runs on the macOS host so `PlatformHelper.isDesktop` is true in tests.
- Hive typeIds in use: 0-12 (2 CashBook, 3 CashEntry, 11 CashNote, 12 OtherExpenseEntry; next free 13).

## v2.0.1 (version 2.0.1+6, all 11 bugs implemented, T-H01..T-H15 done)

- Review and what changed: `docs/v2.0.1-review.md`. Schema 6. New Hive typeId 12 (OtherExpenseEntry, next free 13). Agent HiveField 10 (`commissionRatesJson`). Ledger types stored as JSON in the settings box (`ledgerTypes`).
- Gotchas: widget tests that use Hive need one database per test file (two files' worth in one file hung); `LedgerTypes.shortLabel` gives `7"`; the mobile Agents tab is gone but `agents_screen.dart` and `desktop_shell.dart` (frozen) still use it; `desktop_shell.dart` rig switch does not refresh `otherExpenseEntriesProvider`.
- Not verified: any of the new UI on a device, real file save on Android 11+, Drive sync with new keys.

## v2.0.2 (version 2.0.2+7, T-J01..T-J06 done)

- Review: `docs/v2.0.2-review.md`. Schema 7. `LedgerEntry.linesJson` (HiveField 38) with `LedgerLine` (depth/pvc/ms lines per bill); single-type fields stay as aggregates (`withLines`). Step rate per depth line, commission per line.
- Gotchas: agent dialogs opened from a sheet must use the caller's context and ref, never the sheet's; widget test files with Hive and several tests can hang, keep one DB and few tests per file and pump twice after opening a sheet; the side bore form has no types (lines have feet, rate, commission rate only).
- Not verified: any of it on a device. Both mockups were updated to 2.0.2 (Apple one: new QA baseline `qa/logic-baseline-v2.0.2.txt` and `qa/flows.mjs`).

## v2.0.3 (version 2.0.3+8, T-K01..T-K04 done)

- Review: `docs/v2.0.3-review.md`. Agent price edits recalculate the commission of the agent's bills (`CommissionRecalc`: skips `isCommissionManuallyEdited`, keeps hand-typed line rates by comparing with the old agent price). Portfolio `AgentView` (lib/features/portfolio/agent_view.dart). macOS shell has no Agents tab (Cmd+1..4); `agents_screen.dart` deleted.
- Gotchas: agents are per rig (`getAllAgents` filters by the current rig), so tests must give agents `vehicleId: 'default_vehicle'`; tapping an agent row in Portfolio filters to that agent, the info icon opens the sheet.
- Not verified: any of it on a device or on macOS. Both mockups were updated to 2.0.3 (Apple one: `qa/logic-baseline-v2.0.3.txt`).

## v2.0.4 (version 2.0.4+9, T-L01..T-L05 done)

- Review: `docs/v2.0.4-review.md`. Schema 8. `StepRates` per rig (settings key `stepRates`, lib/core/models/step_rates.dart, Settings > Step Rates); saved bills keep `stepRate`. `AgentView` shows feet by type. `CashEntry.vehicleId` (HiveField 19): optional rig, automatic for linked bill payments.
- Gotchas: `calculateStepRate(custom:)` delegates to `StepTable.calculate`; `CashbookRow` is now a ConsumerWidget (reads the rig name); CSV of the Account Ledger has a trailing Rig column.
- Not verified: any of it on a device. The mockups do not show these three changes yet.

## Apple-style design mockup (design only, no lib/ changes)

- `docs/design/mockup/rigledger_apple_mockup.html` is the visual source of truth for the later Flutter restyle (light, dark, Android phone 412 x 892 and 360 x 800 dp). Baseline: `docs/design/ref/mockup-v1/rigledger_android_mockup.html` (ignored by git, untouched). References and QA output: `docs/design/ref/` (never commit).
- Docs: `docs/design/mockup/TOKENS.md`, `MOCKUP_NOTES.md`, `MOCKUP_PROGRESS.md` (resume file, open questions), `docs/design/DESIGN_DIRECTION_APPLE.md`. New logic requests LR-21 to LR-24 are in `docs/design/LOGIC_REQUESTS.md`.
- Checks: `docs/design/mockup/qa/` (`logic-diff.mjs`, `token-audit.mjs`, `smoke.mjs`, `shoot.mjs`); run `npm install` there first (node_modules is ignored). All pass in light, dark, STRESS data, 200 percent text, 360 dp, 3-button nav and blur on. The app is Android only: macOS was dropped from the plan (CSS in `docs/design/mockup/archive/`). Glass blur ships OFF; profile on the reference device first.
- Decided 2026-10-13: keep AA text colour variants, rupee sign everywhere (LR-24), Appearance setting System by default (LR-23), Portfolio metric cards first and insight cards after LR-21 and LR-22. Open: card gap 11 vs 12, flag for sticky headers and blur.
- Gotchas: Pillow is not installed for python3.14 (use `/opt/homebrew/bin/python3.12` with a `--target` dir); the path guard blocks paths containing `build/`.

## Left unfinished

- Open bugs and improvements: `BACKLOG.md` and `docs/v2.0.0-review.md` (Drive scope, MANAGE_EXTERNAL_STORAGE, non-atomic restore, auto backup vs newer snapshot).
- `android/app/build.gradle` and `debug.keystore` are the developer's local uncommitted changes.

## Next recommended action

Developer reviews `docs/v2.0.0-review.md`, answers the decisions above, then decides which open items to schedule. Nothing is left IN_PROGRESS in `CURRENT.md`.
