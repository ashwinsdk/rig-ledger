# RigLedger - Claude Session Context

@MEMORY.md
@.claude/tasks/CURRENT.md

## Read this first, every session

Project: RigLedger -- Flutter (Android + macOS) borewell drilling ledger.
100% offline-first. No Firebase Firestore. Google Drive is used only for JSON backup and sync.
No iOS. No web. No flavors. No named routes. No l10n. English only. No emojis. No em-dashes.

## Mandatory session start checklist

1. Read `.claude/tasks/CURRENT.md` -- this tells you exactly what was in progress and what is next.
2. Read `MEMORY.md` -- this records where the last session ended and any decisions made.
3. If starting work on a model file, read `.claude/context/MODELS.md` first.
4. If starting work on a provider or service, read `.claude/context/ARCHITECTURE.md` first.
5. If starting work on any UI, read `.claude/context/CONVENTIONS.md` first.
6. If starting a feature list, resuming after interruption, adding a model field/provider/screen, or preparing a release, read `.claude/context/PLAYBOOKS.md` first.

## Mandatory session end checklist

1. Update `MEMORY.md` with what was done, what was left incomplete, and any decisions made.
2. Update `.claude/tasks/CURRENT.md` -- mark completed items, add new items if the session created them.
3. Run `flutter analyze` and confirm zero errors before ending.
4. Do NOT run `git commit` or `git push` -- the developer does that.

## Task workflow (per sub-task)

When working through a feature list from the developer:
1. Break the list into individual sub-tasks in `CURRENT.md`.
2. Mark one sub-task IN_PROGRESS at a time.
3. Implement and verify it with `flutter analyze`.
4. Mark it DONE in `CURRENT.md`.
5. The developer commits it individually before you move to the next sub-task.
6. Repeat.

Do not start the next sub-task until the developer confirms the current one is committed.

## What NOT to do

- Never read: `build/`, `.dart_tool/`, `android/.gradle/`, `lib/core/models/*.g.dart` (unless explicitly told to).
- Never read or print: `temp/`, `android/key.properties`, `android/app/google-services.json`.
- Never run: `git commit`, `git push`, `rm`, `flutter clean` without explicit instruction.
- Never edit generated files: `*.g.dart` -- run `flutter pub run build_runner build --delete-conflicting-outputs` instead.
- See `.claude/hooks/pre_read.md` for full list of files to avoid.

## Quick reference

- Entry point: `lib/main.dart`
- DB layer: `lib/core/database/database_service.dart` (static singleton, Hive)
- State: Riverpod `StateNotifierProvider` -- see `.claude/context/ARCHITECTURE.md`
- Models: `.claude/context/MODELS.md`
- Domain glossary: `.claude/context/DOMAIN.md`
- Coding conventions: `.claude/context/CONVENTIONS.md`
- Pre-read rules: `.claude/hooks/pre_read.md`
- Post-edit rules: `.claude/hooks/post_edit.md`
- Active tasks: `.claude/tasks/CURRENT.md`
- Backlog / tech debt: `.claude/tasks/BACKLOG.md`
- Playbooks (feature intake, resume, model/provider/screen, release): `.claude/context/PLAYBOOKS.md`

## Build commands

```bash
# Android
export JAVA_HOME=/Library/Java/JavaVirtualMachines/zulu-17.jdk/Contents/Home
flutter build apk --release
flutter build appbundle --release

# macOS
flutter build macos --release

# Run checks (always run after edits)
flutter analyze
flutter pub run build_runner build --delete-conflicting-outputs
```
