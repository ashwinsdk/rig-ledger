# Post-edit Rules -- Enforced by Hook

`.claude/hooks/format_and_lint.sh` (wired in `.claude/settings.json` as a
`PostToolUse` hook on Edit/Write) automatically runs `dart format` then
`dart analyze` on any touched `lib/**/*.dart` file (skipping `*.g.dart`).
Output is silent when clean, otherwise shows errors/warnings (max 30 lines).
Edits under `lib/core/models/` also get a one-line reminder to follow the
model change checklist in `.claude/context/PLAYBOOKS.md`.

## Still manual (hooks don't cover these)

- After a Hive model field change: run
  `flutter pub run build_runner build --delete-conflicting-outputs` and
  verify the regenerated `.g.dart` reflects the change.
- After adding a package to `pubspec.yaml`: run `flutter pub get`.
- After a sub-task: update `.claude/tasks/CURRENT.md` (mark DONE) and
  `MEMORY.md`, then tell the developer it's ready to commit. Wait for
  confirmation before starting the next sub-task.
- After a full session: update `MEMORY.md` with a session summary and
  `.claude/tasks/CURRENT.md` with final status of all tasks touched.

## Never run without explicit instruction

`.claude/hooks/guard_bash.sh` blocks `git commit`, `git push`,
`git reset --hard`, `git checkout --`, `git stash drop`, `flutter clean`,
and `rm -rf` automatically. It does not cover every destructive command --
still avoid anything that modifies `android/app/google-services.json`,
`android/key.properties`, or anything in `temp/`.
