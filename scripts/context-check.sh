#!/usr/bin/env bash
# context-check.sh — Verify PURE context file budgets and project state.
# Usage: ./scripts/context-check.sh [--fix-suggestions]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

ERRORS=0
WARNINGS=0

check() {
  local label="$1" file="$2" limit="$3"
  if [ ! -f "$file" ]; then return; fi
  local lines
  lines=$(wc -l < "$file")
  if [ "$lines" -gt "$limit" ]; then
    echo "  FAIL  $label: $lines lines (limit: $limit) — $file"
    ERRORS=$((ERRORS + 1))
  elif [ "$lines" -gt $(( limit * 80 / 100 )) ]; then
    echo "  WARN  $label: $lines lines (limit: $limit, at $(( lines * 100 / limit ))%) — $file"
    WARNINGS=$((WARNINGS + 1))
  else
    echo "  OK    $label: $lines lines — $file"
  fi
}

echo ""
echo "PURE Context Budget Check"
echo "═══════════════════════════════════════════════"

echo ""
echo "Agent Context Files (limit: 80 lines)"
echo "───────────────────────────────────────"
check "AGENTS.md" "$ROOT/AGENTS.md" 80
for f in "$ROOT"/agents/*/AGENT.md; do
  name=$(basename "$(dirname "$f")")
  check "$name/AGENT.md" "$f" 80
done

echo ""
echo "Spec Files (limit: 50 lines)"
echo "───────────────────────────────────────"
SPEC_COUNT=0
SPEC_OVER=0
for f in "$ROOT"/specs/**/*.md "$ROOT"/specs/*.md; do
  [ -f "$f" ] || continue
  [ "$(basename "$f")" = ".gitkeep" ] && continue
  lines=$(wc -l < "$f")
  SPEC_COUNT=$((SPEC_COUNT + 1))
  if [ "$lines" -gt 50 ]; then
    echo "  FAIL  $(basename "$f"): $lines lines (limit: 50)"
    SPEC_OVER=$((SPEC_OVER + 1))
    ERRORS=$((ERRORS + 1))
  fi
done
if [ "$SPEC_COUNT" -eq 0 ]; then
  echo "  (no spec files found)"
else
  echo "  $SPEC_COUNT spec files checked, $SPEC_OVER over limit"
fi

echo ""
echo "Project State"
echo "───────────────────────────────────────"

# Open intents
OPEN_INTENTS=$(grep -rl 'approved_by:' "$ROOT/intents/" 2>/dev/null | xargs grep -l '^.*approved_by: [^n]' 2>/dev/null | wc -l || echo 0)
TOTAL_INTENTS=$(ls "$ROOT/intents/"INT-*.yaml 2>/dev/null | wc -l || echo 0)
echo "  Intents: $TOTAL_INTENTS total, $OPEN_INTENTS approved+open"

# Blocked gates
BLOCKED=$(grep -rl 'gate_blocked' "$ROOT/sessions/" 2>/dev/null | wc -l || echo 0)
if [ "$BLOCKED" -gt 0 ]; then
  echo "  WARN  $BLOCKED blocked gate(s) — check sessions/ for gate_blocked messages"
  WARNINGS=$((WARNINGS + 1))
else
  echo "  OK    No blocked gates"
fi

# Open security findings
SEC_OPEN=$(grep -rl 'open:' "$ROOT/sessions/" 2>/dev/null | xargs grep -A2 'security_findings:' 2>/dev/null | grep -c 'open:' || echo 0)
if [ "$SEC_OPEN" -gt 0 ]; then
  echo "  WARN  Open security findings in sessions/ — review before prod deploy"
  WARNINGS=$((WARNINGS + 1))
else
  echo "  OK    No open security findings"
fi

# Sessions store size
SESSION_COUNT=$(ls "$ROOT/sessions/"INT-*.yaml 2>/dev/null | wc -l || echo 0)
echo "  Sessions: $SESSION_COUNT knowledge blocks in sessions/"

echo ""
echo "═══════════════════════════════════════════════"
if [ "$ERRORS" -gt 0 ]; then
  echo "  RESULT: $ERRORS error(s), $WARNINGS warning(s) — fix errors before proceeding"
  exit 1
elif [ "$WARNINGS" -gt 0 ]; then
  echo "  RESULT: $WARNINGS warning(s) — review recommended"
  exit 0
else
  echo "  RESULT: All checks passed"
  exit 0
fi
