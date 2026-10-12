#!/usr/bin/env bash
# PreToolUse guard for Bash.
# Blocks (exit 2) if tool_input.command contains a destructive or
# commit/push pattern. Extracts the command via a real JSON parser (jq,
# else python3, else perl's core JSON::PP) rather than scanning raw text.

input="$(cat)"

extract_command() {
  if command -v jq >/dev/null 2>&1; then
    jq -r '(.tool_input.command // empty)' 2>/dev/null <<<"$input"
  elif command -v python3 >/dev/null 2>&1; then
    python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(0)
print((d.get("tool_input", {}) or {}).get("command") or "")
' <<<"$input" 2>/dev/null
  elif command -v perl >/dev/null 2>&1; then
    perl -MJSON::PP -e '
local $/;
my $d = eval { decode_json(<STDIN>) };
exit 0 unless $d;
print(($d->{tool_input}{command} // ""));
' <<<"$input" 2>/dev/null
  fi
}

command_str="$(extract_command)"
[ -z "$command_str" ] && exit 0

deny() {
  echo "Blocked: $1" >&2
  exit 2
}

for pattern in \
  "git commit" \
  "git push" \
  "git reset --hard" \
  "git checkout --" \
  "git stash drop" \
  "flutter clean" \
  "rm -rf"; do
  case "$command_str" in
    *"$pattern"*) deny "'$pattern' is a commit/destructive command the developer runs manually, not Claude." ;;
  esac
done

exit 0
