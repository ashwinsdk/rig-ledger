# RigLedger - Playbooks

Step-by-step procedures for recurring session shapes. Read the relevant section before starting.

## Feature list intake

When the developer gives a list of features for a new version:

1. Split the list into small, independently committable sub-tasks.
2. Order sub-tasks by dependency (e.g. a model field change before the screen that uses it).
3. Flag any sub-task that touches a Hive model, sync (`SyncService`), or export (CSV/PDF) -- these need extra care per the checklists below.
4. Only ask the developer about real ambiguities (conflicting requirements, missing business rules) -- do not ask about things resolvable by reading the code.
5. Write the sub-task list into `.claude/tasks/CURRENT.md` using the task format (see `CLAUDE.md`), all `[PENDING]`.
6. Show the list to the developer and wait for approval before marking any task `IN_PROGRESS`.

## Resume after interruption

1. Read `.claude/tasks/CURRENT.md`. Find the task marked `IN_PROGRESS` (there should be at most one).
2. Read its "Resume notes" line -- this says exactly what was last done and what's next.
3. State the active task and next step in one line to the developer. Do not re-explore the codebase.
4. Update "Resume notes" after every meaningful step while working, not just at session end.

## Add a model field (full checklist)

1. HiveField indices are append-only -- never reuse or renumber an existing index.
2. Update `copyWith()` on the model.
3. Update serialization: `toMap`/`fromMap` (LedgerEntry, Agent) or `toJson`/`fromJson` (everything else).
4. Run `flutter pub run build_runner build --delete-conflicting-outputs` to regenerate the `.g.dart` adapter.
5. Write a real migration and bump `schemaVersion` in `DatabaseService` -- the current migration stub only increments the counter, it does not transform data. A genuine field addition needs real migration logic.
6. Update `SyncService`'s backup payload and merge logic for the new field.
7. Old backups lacking the new field must import with a safe default -- do not crash on missing keys.
8. An older app version must not crash when it reads a newer backup containing the new field. Android and macOS can be on different app versions at the same time -- never assume they match.
9. Update CSV and PDF export if the field is user-facing.
10. Update `.claude/context/MODELS.md` in the same task, without needing separate developer approval.

## Add a provider

See `.claude/context/ARCHITECTURE.md` "Adding a new provider" for the steps. In short: `StateNotifier` with `loadXxx`/`addXxx`/`updateXxx`/`deleteXxx`/`refresh`, wrap in a `StateNotifierProvider`, add a `Provider<T>` for any derived state, call `DatabaseService` only from the notifier. If the new provider needs to be refreshed alongside the existing 8 after a vehicle switch or sync, add it to the refresh list in both `ARCHITECTURE.md` and `CONVENTIONS.md` and to every call site listed there.

## Add a screen

1. Name per `.claude/context/CONVENTIONS.md` (`xxx_form_screen.dart`, `xxx_list_screen.dart`, `xxx_screen.dart`).
2. Use `AdaptiveHeader` for platform-adaptive headers; follow the mobile/desktop layout rules in `CONVENTIONS.md`.
3. Wire navigation per `.claude/context/ARCHITECTURE.md` -- check whether it belongs in the `IndexedStack` (Ledger/Stats/Agents/Settings) or is pushed via `Navigator.push(MaterialPageRoute(...))`. No named routes.
4. Never call `DatabaseService` directly from the screen -- go through a provider.

## Prepare a release

1. Bump the version in `pubspec.yaml` (`version: X.Y.Z+N`) -- this is the single source for both Android and macOS, see `MEMORY.md`.
2. Run `flutter analyze` and confirm zero errors.
3. Run the build commands from `CLAUDE.md` for the target platform(s).
4. Confirm Android and macOS are not assumed to ship the same build at the same time -- they can lag each other.
