# RigLedger - Session Memory

Last updated: 2026-10-12 (v2.0.0 feature work)

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
- Decisions to confirm with the developer: commission formula (ft x rate per ft), profit definition, LICENSE copyright line, Rs. vs the rupee sign.
- Not verifiable here: running the macOS app (needs `macos/Runner/GoogleService-Info.plist`), real Drive sync, camera/gallery bills.
- Gotchas learned: dialogs must own their TextEditingControllers (dispose in State, never right after `await showDialog`); widget tests that touch Hive must wait on real time (`runAsync`) and must not call `Hive.close()`; `flutter test` runs on the macOS host so `PlatformHelper.isDesktop` is true in tests.
- Hive typeIds in use: 0-11 (2 CashBook, 3 CashEntry, 11 CashNote; next free 12).

## Left unfinished

- Open bugs and improvements: `BACKLOG.md` and `docs/v2.0.0-review.md` (Drive scope, MANAGE_EXTERNAL_STORAGE, non-atomic restore, auto backup vs newer snapshot).
- `android/app/build.gradle` and `debug.keystore` are the developer's local uncommitted changes.

## Next recommended action

Developer reviews `docs/v2.0.0-review.md`, answers the decisions above, then decides which open items to schedule. Nothing is left IN_PROGRESS in `CURRENT.md`.
