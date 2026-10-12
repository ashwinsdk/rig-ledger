# RigLedger - Session Memory

Last updated: 2026-10-12

## Current versions

- Single source of truth: `pubspec.yaml` (`version: X.Y.Z+N`). Android and macOS both read this at build time (Android via `flutter.versionName`/`flutter.versionCode` in `android/local.properties`, macOS via `$(FLUTTER_BUILD_NAME)`/`$(FLUTTER_BUILD_NUMBER)` in `Info.plist`). Neither platform hardcodes its own version.

## Active decisions

- `DesktopAuthService` (`lib/core/services/desktop_auth_service.dart`) has placeholder client ID/secret for Windows/Linux. macOS uses `google_sign_in` native plugin instead. Do not wire the desktop auth service until the developer provides real credentials.
- Task workflow: each sub-task gets its own individual commit. Claude marks IN_PROGRESS, implements, verifies with `flutter analyze`, marks DONE. Developer commits. Then next sub-task begins.
- Known tech debt and future ideas live in `.claude/tasks/BACKLOG.md`, not here.

## Gotchas

- `MiniLedgerEntry` is orphaned: fully wired into `DatabaseService` and `SyncService` but no screen or provider uses it. Side Bore saves plain `LedgerEntry` instead. See `BACKLOG.md`.
- `LedgerEntry.msPipe` is free-text defaulting to `'6inch'`; the form dropdown only offers `'6inch'` today, despite older docs implying multiple sizes.
- Hive typeIds currently in use: 0, 1, 4-10. typeIds 2 and 3 are unassigned -- re-verify before reusing (see `MODELS.md`).

## Next recommended action

Ready for the next feature list from the developer. Break it into sub-tasks in `.claude/tasks/CURRENT.md` per `.claude/context/PLAYBOOKS.md` and begin working through them one by one.
