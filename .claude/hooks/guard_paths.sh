#!/usr/bin/env bash
# PreToolUse guard for Read/Grep/Glob/Edit/Write.
# Blocks (exit 2) if the path being acted on matches a forbidden pattern.
# Extracts tool_input.file_path / tool_input.path via a real JSON parser
# (jq, else python3, else perl's core JSON::PP) -- never by scanning the raw
# JSON text, since file *content* (e.g. a doc mentioning a secret filename
# in prose) could otherwise produce false blocks.

input="$(cat)"
project_dir="${CLAUDE_PROJECT_DIR:-$(pwd)}"

extract_path() {
  if command -v jq >/dev/null 2>&1; then
    jq -r '(.tool_input.file_path // .tool_input.path // empty)' 2>/dev/null <<<"$input"
  elif command -v python3 >/dev/null 2>&1; then
    python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(0)
ti = d.get("tool_input", {}) or {}
print(ti.get("file_path") or ti.get("path") or "")
' <<<"$input" 2>/dev/null
  elif command -v perl >/dev/null 2>&1; then
    perl -MJSON::PP -e '
local $/;
my $d = eval { decode_json(<STDIN>) };
exit 0 unless $d;
my $ti = $d->{tool_input} || {};
print(($ti->{file_path} // $ti->{path} // ""));
' <<<"$input" 2>/dev/null
  fi
}

path="$(extract_path)"
[ -z "$path" ] && exit 0

deny() {
  echo "Blocked: $1" >&2
  exit 2
}

# Secrets -- never bypassable, regardless of ALLOW_GENERATED.
for pattern in \
  "android/key.properties" \
  "android/app/google-services.json" \
  ".jks" ".p12" ".keystore"; do
  case "$path" in
    *"$pattern"*) deny "'$pattern' is a secret path. Describe the steps instead of reading or editing it directly." ;;
  esac
done

# Build artifacts and caches -- always blocked, not source.
for pattern in \
  "build/" ".dart_tool/" "android/.gradle/" "macos/Flutter/ephemeral/" "temp/"; do
  case "$path" in
    *"$pattern"*) deny "'$pattern' is a build artifact or cache. Read or edit the real source file instead." ;;
  esac
done

# Generated Hive adapters -- blocked unless ALLOW_GENERATED exists.
case "$path" in
  *.g.dart)
    if [ ! -f "$project_dir/.claude/ALLOW_GENERATED" ]; then
      deny "*.g.dart is generated. Edit the model file and run build_runner instead. Create .claude/ALLOW_GENERATED to temporarily inspect a generated file."
    fi
    ;;
esac

exit 0
