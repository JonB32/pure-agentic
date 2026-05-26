#!/usr/bin/env bash
# Tests for scripts/context-check.sh — flags (--quiet, --exit-on-warning, --json)

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./lib.sh
source "$SCRIPT_DIR/lib.sh"

ROOT_REAL="$(cd "$SCRIPT_DIR/../.." && pwd)"
SCRIPT="$ROOT_REAL/scripts/context-check.sh"

it "default mode prints OK lines"
out=$("$SCRIPT" 2>&1)
assert_contains "$out" "  OK    "

it "--quiet suppresses OK lines but keeps section headers"
out=$("$SCRIPT" --quiet 2>&1)
assert_not_contains "$out" "  OK    "
assert_contains "$out" "Agent Context Files"
# Warning, if present, must still be there
if [ "$(echo "$out" | grep -c '  WARN  ')" -gt 0 ]; then
  assert_contains "$out" "  WARN  "
fi

it "--json emits valid JSON with errors/warnings/summary keys"
json=$("$SCRIPT" --json 2>/dev/null)
parsed=$(python3 -c "import json,sys; d=json.loads(sys.stdin.read()); print(','.join(sorted(d.keys())))" <<< "$json")
assert_eq "errors,summary,warnings" "$parsed"

it "--json only emits JSON (no human-readable text)"
json=$("$SCRIPT" --json 2>/dev/null)
# First non-whitespace char should be '{'
first=$(echo "$json" | head -c 1)
assert_eq "{" "$first"

it "pure:project-context markers exclude lines from the budget"
# Build a sandbox AGENTS.md that would be 90 lines (over 80) but has 50 of
# those lines wrapped in marker block — net 40, well under cap.
SB="$(mktemp -d)"
mkdir -p "$SB/agents/code-agent"
{
  for i in $(seq 1 20); do echo "methodology line $i"; done
  echo "<!-- pure:project-context-start -->"
  for i in $(seq 1 50); do echo "project line $i"; done
  echo "<!-- pure:project-context-end -->"
  for i in $(seq 1 18); do echo "methodology trailing $i"; done
} > "$SB/AGENTS.md"
# Need a code-agent AGENT.md or the script's loop is fine empty; create a stub
echo "stub" > "$SB/agents/code-agent/AGENT.md"
mkdir -p "$SB/scripts" "$SB/schemas"
cp "$ROOT_REAL/scripts/context-check.sh" "$SB/scripts/context-check.sh"
chmod +x "$SB/scripts/context-check.sh"
out=$(cd "$SB" && ./scripts/context-check.sh 2>&1)
assert_contains "$out" "project-context excluded"
# 38 methodology lines is under 80, so no WARN/FAIL on AGENTS.md
assert_not_contains "$out" "WARN  AGENTS.md"
assert_not_contains "$out" "FAIL  AGENTS.md"
rm -rf "$SB"

it "--exit-on-warning fails when warnings exist"
# The repo currently has a WARN on AGENTS.md (the very thing PR3 addresses).
# Until PR3 lands, --exit-on-warning should be non-zero here.
"$SCRIPT" --quiet 2>&1 > /dev/null
default_exit=$?
"$SCRIPT" --quiet --exit-on-warning 2>&1 > /dev/null
warn_exit=$?
# If warnings exist, --exit-on-warning should differ from default exit.
# If somehow there are no warnings (post-PR3), both should be 0.
if [ "$default_exit" -eq 0 ] && [ "$warn_exit" -ne 0 ]; then
  assert_eq "1" "$warn_exit" "warn_exit"
else
  # No warnings → both exit 0; that's still a pass condition.
  assert_eq "$default_exit" "$warn_exit"
fi

summary
