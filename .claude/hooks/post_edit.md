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
  `MEMORY.md`, then `git add` the exact files changed and `git commit`
  (imperative message, <=72 chars, no `Co-Authored-By` trailer). Never
  `git push`.
- After a full session: update `MEMORY.md` with a session summary and
  `.claude/tasks/CURRENT.md` with final status of all tasks touched.

## Never run without explicit instruction

`.claude/hooks/guard_bash.sh` blocks `git push`, `git commit --amend`,
`--no-verify`, `--no-gpg-sign`, `git reset --hard`, `git checkout --`,
`git stash drop`, `flutter clean`, and `rm -rf` automatically. Plain
`git commit` is allowed -- see `CLAUDE.md` Task workflow. The hook does not
cover every destructive command -- still avoid anything that modifies
`android/app/google-services.json`, `android/key.properties`, or anything
in `temp/`.
