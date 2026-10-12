#!/usr/bin/env bash
# PostToolUse hook for Edit/Write. Formats and lints just the touched file
# when it's a non-generated Dart file under lib/. Silent when clean.
# Extracts tool_input.file_path via a real JSON parser (jq, else python3,
# else perl's core JSON::PP) rather than scanning raw text.

input="$(cat)"
project_dir="${CLAUDE_PROJECT_DIR:-$(pwd)}"

extract_path() {
  if command -v jq >/dev/null 2>&1; then
    jq -r '(.tool_input.file_path // empty)' 2>/dev/null <<<"$input"
  elif command -v python3 >/dev/null 2>&1; then
    python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(0)
print((d.get("tool_input", {}) or {}).get("file_path") or "")
' <<<"$input" 2>/dev/null
  elif command -v perl >/dev/null 2>&1; then
    perl -MJSON::PP -e '
local $/;
my $d = eval { decode_json(<STDIN>) };
exit 0 unless $d;
print(($d->{tool_input}{file_path} // ""));
' <<<"$input" 2>/dev/null
  fi
}

file_path="$(extract_path)"
[ -z "$file_path" ] && exit 0

case "$file_path" in
  *.g.dart) exit 0 ;;
  *lib/*.dart) ;;
  *) exit 0 ;;
esac

cd "$project_dir" || exit 0
rel_path="${file_path#"$project_dir"/}"

dart format "$rel_path" >/dev/null 2>&1
output="$(dart analyze "$rel_path" 2>&1)"

if grep -qE "error •|warning •" <<<"$output"; then
  grep -E "error •|warning •" <<<"$output" | head -30 >&2
  exit 2
fi

case "$rel_path" in
  lib/core/models/*)
    echo "Model file changed: follow the checklist in .claude/context/PLAYBOOKS.md (append-only HiveField indices, copyWith/serialization, build_runner, migration, sync payload, exports, MODELS.md)." >&2
    ;;
esac

exit 0
