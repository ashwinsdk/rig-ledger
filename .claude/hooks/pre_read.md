# Pre-read Rules -- Enforced by Hook

`.claude/hooks/guard_paths.sh` (wired in `.claude/settings.json` as a `PreToolUse`
hook on Read/Grep/Glob/Edit/Write) blocks these automatically -- this file is
now just a human-readable summary, not something Claude has to self-police.

## Always blocked (secrets -- never bypassable)

- `android/key.properties`, `android/app/google-services.json`
- Any path containing `.jks`, `.p12`, `.keystore`

## Always blocked (build artifacts and caches)

- `build/`, `.dart_tool/`, `android/.gradle/`, `macos/Flutter/ephemeral/`, `temp/`

## Blocked unless `.claude/ALLOW_GENERATED` exists

- `*.g.dart` -- Hive-generated adapters. Create the marker file to temporarily
  inspect one; delete it afterward. Never edit a `.g.dart` file even when
  allowed to read it -- run build_runner instead.

## Large files -- read by section, not the whole file

For these files (> 800 lines), grep for the relevant section header first,
then read only that line range:

```bash
grep -n "section_keyword" lib/features/export/pdf_export_screen.dart
```

| File | Lines | Approach |
|---|---|---|
| `lib/features/export/pdf_export_screen.dart` | ~1,556 | Read by PDF type section |
| `lib/features/home/combined_home_screen.dart` | ~1,261 | Read widgets/ subfolder separately |
| `lib/features/ledger_form/ledger_form_screen.dart` | ~1,158 | Read by form section |
| `lib/features/settings/settings_screen.dart` | ~847 | Read the backup/sync section only if needed |
| `lib/features/navigation/desktop_shell.dart` | ~789 | Already fully read in discovery |
| `lib/core/database/database_service.dart` | ~694 | Read the relevant CRUD section only |
