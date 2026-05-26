#!/usr/bin/env bash
# Tests for scripts/new-intent.sh — non-interactive mode and TTY detection.

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./lib.sh
source "$SCRIPT_DIR/lib.sh"

# Build a throwaway "repo" with a templates/ pointing at the real templates,
# and an empty intents/ — so the script can write into it without polluting
# the real repo.
ROOT_REAL="$(cd "$SCRIPT_DIR/../.." && pwd)"
SANDBOX="$(mktemp -d)"
mkdir -p "$SANDBOX/scripts" "$SANDBOX/intents" "$SANDBOX/templates"
cp "$ROOT_REAL/scripts/new-intent.sh" "$SANDBOX/scripts/new-intent.sh"
cp "$ROOT_REAL/templates/intent.yaml" "$SANDBOX/templates/intent.yaml"
chmod +x "$SANDBOX/scripts/new-intent.sh"
trap 'rm -rf "$SANDBOX"' EXIT

NI="$SANDBOX/scripts/new-intent.sh"

# ───────────────────────────────────────────────────────
it "non-interactive requires --statement"
out=$("$NI" --non-interactive --outcome "x" 2>&1 < /dev/null || true)
assert_contains "$out" "--statement is required"

it "non-interactive requires --outcome"
out=$("$NI" --non-interactive --statement "x" 2>&1 < /dev/null || true)
assert_contains "$out" "--outcome is required"

it "non-interactive writes intent file with all fields"
out=$("$NI" --non-interactive \
  --statement "A test exists" \
  --outcome "It passes" \
  --constraint "Strict TS" \
  --constraint "Vitest" \
  --out-of-scope "Mobile" \
  --priority high \
  --domain api \
  --depends-on INT-0099 \
  2>&1 < /dev/null)
assert_contains "$out" 'id: INT-0001'
assert_contains "$out" 'statement: "A test exists"'
assert_contains "$out" 'outcome: "It passes"'
assert_contains "$out" '- "Strict TS"'
assert_contains "$out" '- "Vitest"'
assert_contains "$out" '- "Mobile"'
assert_contains "$out" 'priority: high'
assert_contains "$out" 'domain: "api"'
assert_contains "$out" 'depends_on: ["INT-0099"]'
assert_contains "$out" 'status: draft'
assert_contains "$out" 'superseded_by: null'
assert_contains "$out" 'external_ref: null'
assert_file_exists "$SANDBOX/intents/INT-0001.yaml"

it "non-interactive emits YAML to stdout"
out=$("$NI" --non-interactive --statement "another" --outcome "ok" 2>&1 < /dev/null)
assert_contains "$out" "intent:"
assert_contains "$out" "Written:"

it "auto-detects non-interactive when stdin is not a TTY"
# Note: the previous tests already ran without a TTY thanks to < /dev/null;
# this case explicitly drops --non-interactive and confirms the script still
# requires --statement (it doesn't fall through to a TTY read).
out=$("$NI" 2>&1 < /dev/null || true)
assert_contains "$out" "--statement is required"

it "auto-assigns sequential IDs"
# INT-0001 and INT-0002 already exist from prior cases; the next should be INT-0003.
out=$("$NI" --non-interactive --statement "third" --outcome "ok" 2>&1 < /dev/null)
assert_contains "$out" "id: INT-0003"
assert_file_exists "$SANDBOX/intents/INT-0003.yaml"

it "refuses to overwrite an existing intent file"
out=$("$NI" --non-interactive --id INT-0001 --statement "x" --outcome "y" 2>&1 < /dev/null || true)
assert_contains "$out" "already exists"

it "generated YAML validates against schemas/intent-v1.json"
# Validate the most recent file directly with python+jsonschema if available
if python3 -c "import jsonschema, yaml" 2>/dev/null; then
  validation=$(
    SCHEMA="$ROOT_REAL/schemas/intent-v1.json" \
    FILE="$SANDBOX/intents/INT-0001.yaml" \
    python3 - <<'PY'
import json, os, yaml
from jsonschema import Draft7Validator
errs = list(Draft7Validator(json.load(open(os.environ["SCHEMA"]))).iter_errors(yaml.safe_load(open(os.environ["FILE"]))))
print("OK" if not errs else f"FAIL: {errs}")
PY
  )
  assert_eq "OK" "$validation" "schema validation"
else
  printf '  SKIP  %s — jsonschema not installed\n' "$CURRENT_TEST"
fi

summary
