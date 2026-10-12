# RigLedger - Backlog

Known gaps and tech debt live here, not in CURRENT.md or MEMORY.md.

## Tech debt

- **Step-rate configurability**: brackets are hardcoded in `LedgerEntry.calculateStepRate()`. Not user-configurable. Not scheduled for next version.
- **MiniLedgerEntry is orphaned**: fully wired into `DatabaseService` (box + CRUD) and `SyncService` (backup JSON + merge), but no screen or provider reads/writes it. Side Bore actually saves plain `LedgerEntry` records. Decide: wire Side Bore onto `MiniLedgerEntry` properly, or remove the model/box/sync path entirely.
- **`flutter_launcher_icons`** is in `dependencies` instead of `dev_dependencies` in `pubspec.yaml`. Safe housekeeping fix.
- **`riverpod_generator`** is installed but unused. Remove, or migrate providers to generator style in a dedicated refactor.
- **`test/widget_test.dart`** references `MyApp`, which does not exist. Does not compile. Must be fixed before any real tests are added.
- **`GOOGLE_DRIVE_SETUP.md`** is missing from the repo (lost with an old PC). Needs to be recreated if Drive setup is ever repeated.

## Future ideas

(none yet)
