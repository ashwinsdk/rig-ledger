# RigLedger - Backlog

Known gaps and tech debt live here, not in CURRENT.md or MEMORY.md.

## Tech debt

- **Step-rate configurability**: brackets are hardcoded in `LedgerEntry.calculateStepRate()`. Not user-configurable. Not scheduled for next version.
- **MiniLedgerEntry is orphaned**: fully wired into `DatabaseService` (box + CRUD) and `SyncService` (backup JSON + merge), but no screen or provider reads/writes it. Side Bore actually saves plain `LedgerEntry` records. Decide: wire Side Bore onto `MiniLedgerEntry` properly, or remove the model/box/sync path entirely.
- **`flutter_launcher_icons`** is in `dependencies` instead of `dev_dependencies` in `pubspec.yaml`. Safe housekeeping fix.
- **`riverpod_generator`** is installed but unused. Remove, or migrate providers to generator style in a dedicated refactor.
- ~~`test/widget_test.dart`~~ fixed in v2.0.0 (replaced with a smoke test).
- **`GOOGLE_DRIVE_SETUP.md`** is missing from the repo (lost with an old PC). Needs to be recreated if Drive setup is ever repeated.

## Found in the v2.0.0 review (details in `docs/v2.0.0-review.md` section 3.2)

- Narrow the Google Drive scope (full Drive scope is requested today).
- Remove `MANAGE_EXTERNAL_STORAGE` from the manifest (not needed with SAF).
- Make `restoreBackup` atomic (it clears all boxes before rewriting them).
- Queue UI writes during a sync merge; prune tombstones relative to the oldest device sync.
- Auto backup should refuse to push over a remote snapshot with a higher version.
- macOS build needs `macos/Runner/GoogleService-Info.plist` (not in the repo): document it. [done]
- UI still calls `DatabaseService` directly in places (bill number duplicate check).
- `PlatformHelper.isDesktop` includes Windows and Linux; Cmd+F handler is empty.
- 210 analyzer infos (mostly `withOpacity` and `prefer_const_constructors`).
- Cashbook: commission settlement, receipts PDF, notebook report, integration_test coverage.

## Future ideas

(see the improvement list in `docs/v2.0.0-review.md` section 4)
