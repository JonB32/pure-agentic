#!/usr/bin/env bash
# context-check.sh — Verify PURE context file budgets and project state.
# Usage: ./scripts/context-check.sh [--fix-suggestions]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SCHEMAS_DIR="$ROOT/schemas"

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

# Intents — find returns 0 cleanly even with no matches (avoids pipefail issues)
TOTAL_INTENTS=$(find "$ROOT/intents" -maxdepth 1 -name 'INT-*.yaml' 2>/dev/null | wc -l)
OPEN_INTENTS=0
while IFS= read -r f; do
  [ -n "$f" ] || continue
  if grep -q 'approved_by: [^n]' "$f" 2>/dev/null; then
    OPEN_INTENTS=$((OPEN_INTENTS + 1))
  fi
done < <(find "$ROOT/intents" -maxdepth 1 -name 'INT-*.yaml' 2>/dev/null)
echo "  Intents: $TOTAL_INTENTS total, $OPEN_INTENTS approved+open"

# Blocked gates
BLOCKED=$(grep -rl 'gate_blocked' "$ROOT/sessions/" 2>/dev/null | wc -l || true)
BLOCKED=${BLOCKED:-0}
if [ "$BLOCKED" -gt 0 ]; then
  echo "  WARN  $BLOCKED blocked gate(s) — check sessions/ for gate_blocked messages"
  WARNINGS=$((WARNINGS + 1))
else
  echo "  OK    No blocked gates"
fi

# Open security findings
SEC_OPEN=$(grep -rh -A2 'security_findings:' "$ROOT/sessions/" 2>/dev/null | grep -c 'open:' || true)
SEC_OPEN=${SEC_OPEN:-0}
if [ "$SEC_OPEN" -gt 0 ]; then
  echo "  WARN  Open security findings in sessions/ — review before prod deploy"
  WARNINGS=$((WARNINGS + 1))
else
  echo "  OK    No open security findings"
fi

# Sessions store size
SESSION_COUNT=$(find "$ROOT/sessions" -maxdepth 1 -name 'INT-*.yaml' 2>/dev/null | wc -l)
echo "  Sessions: $SESSION_COUNT knowledge blocks in sessions/"

echo ""
echo "Schema Validation (intents + knowledge blocks)"
echo "───────────────────────────────────────"

# Validate intents/INT-*.yaml and sessions/INT-*.yaml against schemas/*.json.
# Requires python3 with PyYAML + jsonschema. If jsonschema is missing, skip
# (CI installs it; local users get a one-line notice).
if ! python3 -c "import jsonschema, yaml" 2>/dev/null; then
  echo "  SKIP  jsonschema not installed — pip install jsonschema to enable"
else
  SCHEMA_OUTPUT=$(
    INTENT_SCHEMA="$SCHEMAS_DIR/intent-v1.json" \
    KB_SCHEMA="$SCHEMAS_DIR/knowledge-block-v1.json" \
    INTENTS_GLOB="$ROOT/intents" \
    SESSIONS_GLOB="$ROOT/sessions" \
    python3 - <<'PY'
import glob, json, os, sys
import yaml
from jsonschema import Draft7Validator

def load_schema(path):
    if not os.path.exists(path):
        return None
    with open(path) as f:
        return json.load(f)

def validate_file(path, schema, label):
    try:
        with open(path) as f:
            data = yaml.safe_load(f)
    except Exception as e:
        print(f"  FAIL  {label}: YAML parse error in {path}: {e}")
        return 1
    errors = sorted(Draft7Validator(schema).iter_errors(data), key=lambda e: e.path)
    if not errors:
        return 0
    for err in errors:
        loc = "/".join(str(p) for p in err.absolute_path) or "<root>"
        print(f"  FAIL  {label}: {os.path.relpath(path)} — {loc}: {err.message}")
    return len(errors)

intent_schema = load_schema(os.environ["INTENT_SCHEMA"])
kb_schema     = load_schema(os.environ["KB_SCHEMA"])

err_count = 0
ok_count  = 0

if intent_schema:
    for f in sorted(glob.glob(os.path.join(os.environ["INTENTS_GLOB"], "INT-*.yaml"))):
        e = validate_file(f, intent_schema, "intent")
        if e: err_count += e
        else: ok_count += 1

if kb_schema:
    for f in sorted(glob.glob(os.path.join(os.environ["SESSIONS_GLOB"], "INT-*.yaml"))):
        e = validate_file(f, kb_schema, "knowledge-block")
        if e: err_count += e
        else: ok_count += 1

print(f"__SUMMARY__ ok={ok_count} errors={err_count}")
PY
  )
  echo "$SCHEMA_OUTPUT" | grep -v '^__SUMMARY__' || true
  SUMMARY_LINE=$(echo "$SCHEMA_OUTPUT" | grep '^__SUMMARY__' | tail -1)
  OK_COUNT=$(echo "$SUMMARY_LINE" | sed -n 's/.*ok=\([0-9]*\).*/\1/p')
  ERR_COUNT=$(echo "$SUMMARY_LINE" | sed -n 's/.*errors=\([0-9]*\).*/\1/p')
  OK_COUNT=${OK_COUNT:-0}
  ERR_COUNT=${ERR_COUNT:-0}
  if [ "$ERR_COUNT" -gt 0 ]; then
    ERRORS=$((ERRORS + ERR_COUNT))
    echo "  $OK_COUNT file(s) validated, $ERR_COUNT error(s)"
  elif [ "$OK_COUNT" -eq 0 ]; then
    echo "  (no intents or knowledge blocks to validate)"
  else
    echo "  OK    $OK_COUNT file(s) validated against schemas/"
  fi
fi

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
