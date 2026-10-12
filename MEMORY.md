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
- Hive typeIds currently in use: 0-11 (2 CashBook, 3 CashEntry, 11 CashNote; next free 12). See `MODELS.md`.

## Account Ledger (v2.0.0 feature 1)

- Spec in `docs/features/cashbook/` (SPEC.md has decisions D1..D14, 84 parity lines). Tasks T-CB01..T-CB19 in `CURRENT.md`.
- Books are global, receivers are just books, money is double, fifth tab, trash purged after 30 days, all devices must update (snapshot version bump).
- T-CB01 DONE (models + adapters generated, not registered). Existing analyzer error: `test/widget_test.dart` references missing `MyApp` (pre-existing).
- Reference material lives outside the repo in `~/cashbook-ref/`.

## Next recommended action

Developer commits T-CB01, then start T-CB02 (DatabaseService boxes, CRUD, trash, schemaVersion 4).
