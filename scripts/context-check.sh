#!/usr/bin/env bash
# context-check.sh — Verify PURE context file budgets and project state.
#
# Usage:
#   ./scripts/context-check.sh [--quiet] [--exit-on-warning] [--json]
#
# Flags:
#   --quiet             Suppress OK lines (keep WARN/FAIL + section headers).
#   --exit-on-warning   Treat warnings as exit 1 (default: exit 1 only on errors).
#   --json              Emit machine-readable JSON; all other output suppressed.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SCHEMAS_DIR="$ROOT/schemas"

QUIET=false
EXIT_ON_WARNING=false
JSON_MODE=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --quiet)            QUIET=true; shift ;;
    --exit-on-warning)  EXIT_ON_WARNING=true; shift ;;
    --json)             JSON_MODE=true; QUIET=true; shift ;;
    --fix-suggestions)  shift ;;  # accepted for back-compat
    -h|--help)
      sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'
      exit 0 ;;
    *)
      echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
done

ERRORS=0
WARNINGS=0
# Per-line records for JSON, accumulated in a tempfile so multi-line/null-safe.
RECORDS_FILE="$(mktemp)"
trap 'rm -f "$RECORDS_FILE"' EXIT

emit() {
  # emit <level> <label> <message> [file]
  local level="$1" label="$2" message="$3" file="${4:-}"
  printf '%s\t%s\t%s\t%s\n' "$level" "$label" "$message" "$file" >> "$RECORDS_FILE"
  if $JSON_MODE; then return; fi
  case "$level" in
    OK)   $QUIET && return; printf '  OK    %s: %s%s\n' "$label" "$message" "${file:+ — $file}" ;;
    WARN) printf '  WARN  %s: %s%s\n' "$label" "$message" "${file:+ — $file}" ;;
    FAIL) printf '  FAIL  %s: %s%s\n' "$label" "$message" "${file:+ — $file}" ;;
    INFO) $QUIET && return; printf '  %s\n' "$message" ;;
    SKIP) $QUIET && return; printf '  SKIP  %s\n' "$message" ;;
  esac
}

section() {
  $JSON_MODE && return
  $QUIET || echo ""
  echo ""
  echo "$1"
  echo "───────────────────────────────────────"
}

header() {
  $JSON_MODE && return
  echo ""
  echo "PURE Context Budget Check"
  echo "═══════════════════════════════════════════════"
}

# Count lines outside any pure:project-context-start..end marker block.
# The marker convention lets AGENTS.md / AGENT.md carry an unbudgeted
# Project Context section (per docs/topology-modes.md). Marker lines
# themselves are excluded too.
budget_line_count() {
  local file="$1"
  awk '
    /<!--[[:space:]]*pure:project-context-start[[:space:]]*-->/ { skipping = 1; next }
    /<!--[[:space:]]*pure:project-context-end[[:space:]]*-->/   { skipping = 0; next }
    !skipping
  ' "$file" | wc -l
}

check_budget() {
  local label="$1" file="$2" limit="$3"
  if [ ! -f "$file" ]; then return; fi
  local lines total
  total=$(wc -l < "$file")
  lines=$(budget_line_count "$file")
  local suffix=""
  if [ "$lines" -ne "$total" ]; then
    suffix=" (counted $lines of $total; project-context excluded)"
  fi
  if [ "$lines" -gt "$limit" ]; then
    emit FAIL "$label" "$lines lines (limit: $limit)$suffix" "$file"
    ERRORS=$((ERRORS + 1))
  elif [ "$lines" -gt $(( limit * 80 / 100 )) ]; then
    emit WARN "$label" "$lines lines (limit: $limit, at $(( lines * 100 / limit ))%)$suffix" "$file"
    WARNINGS=$((WARNINGS + 1))
  else
    emit OK "$label" "$lines lines$suffix" "$file"
  fi
}

header

section "Agent Context Files (limit: 80 lines)"
check_budget "AGENTS.md" "$ROOT/AGENTS.md" 80
for f in "$ROOT"/agents/*/AGENT.md; do
  name=$(basename "$(dirname "$f")")
  check_budget "$name/AGENT.md" "$f" 80
done

section "Spec Files (limit: 50 lines)"
SPEC_COUNT=0
SPEC_OVER=0
for f in "$ROOT"/specs/**/*.md "$ROOT"/specs/*.md; do
  [ -f "$f" ] || continue
  [ "$(basename "$f")" = ".gitkeep" ] && continue
  lines=$(wc -l < "$f")
  SPEC_COUNT=$((SPEC_COUNT + 1))
  if [ "$lines" -gt 50 ]; then
    emit FAIL "$(basename "$f")" "$lines lines (limit: 50)" ""
    SPEC_OVER=$((SPEC_OVER + 1))
    ERRORS=$((ERRORS + 1))
  fi
done
if [ "$SPEC_COUNT" -eq 0 ]; then
  emit INFO "specs" "(no spec files found)" ""
else
  emit INFO "specs" "$SPEC_COUNT spec files checked, $SPEC_OVER over limit" ""
fi

section "Project State"

TOTAL_INTENTS=$(find "$ROOT/intents" -maxdepth 1 -name 'INT-*.yaml' 2>/dev/null | wc -l)
OPEN_INTENTS=0
while IFS= read -r f; do
  [ -n "$f" ] || continue
  if grep -q 'approved_by: [^n]' "$f" 2>/dev/null; then
    OPEN_INTENTS=$((OPEN_INTENTS + 1))
  fi
done < <(find "$ROOT/intents" -maxdepth 1 -name 'INT-*.yaml' 2>/dev/null)
emit INFO "intents" "Intents: $TOTAL_INTENTS total, $OPEN_INTENTS approved+open" ""

BLOCKED=$(grep -rl 'gate_blocked' "$ROOT/sessions/" 2>/dev/null | wc -l || true)
BLOCKED=${BLOCKED:-0}
if [ "$BLOCKED" -gt 0 ]; then
  emit WARN "gates" "$BLOCKED blocked gate(s) — check sessions/ for gate_blocked messages" ""
  WARNINGS=$((WARNINGS + 1))
else
  emit OK "gates" "No blocked gates" ""
fi

SEC_OPEN=$(grep -rh -A2 'security_findings:' "$ROOT/sessions/" 2>/dev/null | grep -c 'open:' || true)
SEC_OPEN=${SEC_OPEN:-0}
if [ "$SEC_OPEN" -gt 0 ]; then
  emit WARN "security" "Open security findings in sessions/ — review before prod deploy" ""
  WARNINGS=$((WARNINGS + 1))
else
  emit OK "security" "No open security findings" ""
fi

SESSION_COUNT=$(find "$ROOT/sessions" -maxdepth 1 -name 'INT-*.yaml' 2>/dev/null | wc -l)
emit INFO "sessions" "Sessions: $SESSION_COUNT knowledge blocks in sessions/" ""

section "Schema Validation (intents + knowledge blocks)"

if ! python3 -c "import jsonschema, yaml" 2>/dev/null; then
  emit SKIP "schema" "jsonschema not installed — pip install jsonschema to enable" ""
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
        print(f"__FAIL__\t{label}\tYAML parse error: {e}\t{os.path.relpath(path)}")
        return 1
    errors = sorted(Draft7Validator(schema).iter_errors(data), key=lambda e: e.path)
    if not errors:
        return 0
    for err in errors:
        loc = "/".join(str(p) for p in err.absolute_path) or "<root>"
        print(f"__FAIL__\t{label}\t{loc}: {err.message}\t{os.path.relpath(path)}")
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

print(f"__SUMMARY__\t{ok_count}\t{err_count}")
PY
  )
  # Forward FAIL records into the emit pipeline
  while IFS=$'\t' read -r tag label message file; do
    [ "$tag" = "__FAIL__" ] || continue
    emit FAIL "$label" "$message" "$file"
    ERRORS=$((ERRORS + 1))
  done <<< "$SCHEMA_OUTPUT"

  SUMMARY_LINE=$(echo "$SCHEMA_OUTPUT" | grep '^__SUMMARY__' | tail -1)
  OK_COUNT=$(echo "$SUMMARY_LINE" | cut -f2)
  ERR_COUNT=$(echo "$SUMMARY_LINE" | cut -f3)
  OK_COUNT=${OK_COUNT:-0}
  ERR_COUNT=${ERR_COUNT:-0}
  if [ "$ERR_COUNT" -eq 0 ] && [ "$OK_COUNT" -eq 0 ]; then
    emit INFO "schema" "(no intents or knowledge blocks to validate)" ""
  elif [ "$ERR_COUNT" -eq 0 ]; then
    emit OK "schema" "$OK_COUNT file(s) validated against schemas/" ""
  else
    emit INFO "schema" "$OK_COUNT file(s) validated, $ERR_COUNT error(s)" ""
  fi
fi

# Decide exit code
EXIT_CODE=0
if [ "$ERRORS" -gt 0 ]; then
  EXIT_CODE=1
elif [ "$WARNINGS" -gt 0 ] && $EXIT_ON_WARNING; then
  EXIT_CODE=1
fi

if $JSON_MODE; then
  python3 - "$RECORDS_FILE" "$ERRORS" "$WARNINGS" "$EXIT_CODE" <<'PY'
import json, sys
records_file   = sys.argv[1]
errors_total   = int(sys.argv[2])
warnings_total = int(sys.argv[3])
exit_code      = int(sys.argv[4])
errors = []
warnings = []
with open(records_file) as f:
    for line in f:
        line = line.rstrip("\n")
        if not line:
            continue
        parts = line.split("\t", 3)
        if len(parts) < 4:
            continue
        level, label, message, file_ = parts
        entry = {"label": label, "message": message}
        if file_:
            entry["file"] = file_
        if level == "FAIL":
            errors.append(entry)
        elif level == "WARN":
            warnings.append(entry)
print(json.dumps({
    "errors": errors,
    "warnings": warnings,
    "summary": {
        "errors": errors_total,
        "warnings": warnings_total,
        "exit_code": exit_code,
    },
}, indent=2))
PY
  exit "$EXIT_CODE"
fi

echo ""
echo "═══════════════════════════════════════════════"
if [ "$ERRORS" -gt 0 ]; then
  echo "  RESULT: $ERRORS error(s), $WARNINGS warning(s) — fix errors before proceeding"
elif [ "$WARNINGS" -gt 0 ]; then
  if $EXIT_ON_WARNING; then
    echo "  RESULT: $WARNINGS warning(s) — failing (--exit-on-warning)"
  else
    echo "  RESULT: $WARNINGS warning(s) — review recommended"
  fi
else
  echo "  RESULT: All checks passed"
fi
exit "$EXIT_CODE"
