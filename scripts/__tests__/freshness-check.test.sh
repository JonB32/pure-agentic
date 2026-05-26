#!/usr/bin/env bash
# Tests for scripts/freshness-check.sh — usage errors + clean/drift paths.

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./lib.sh
source "$SCRIPT_DIR/lib.sh"

ROOT_REAL="$(cd "$SCRIPT_DIR/../.." && pwd)"

SANDBOX="$(mktemp -d)"
trap 'rm -rf "$SANDBOX"' EXIT
mkdir -p "$SANDBOX/scripts" "$SANDBOX/sessions" "$SANDBOX/specs/api" "$SANDBOX/src"
cp "$ROOT_REAL/scripts/freshness-check.sh" "$SANDBOX/scripts/freshness-check.sh"
chmod +x "$SANDBOX/scripts/freshness-check.sh"

FC="$SANDBOX/scripts/freshness-check.sh"

# ───────────────────────────────────────────────────────
it "usage error when no arg"
out=$("$FC" 2>&1 || true)
assert_contains "$out" "Usage:"

it "rejects malformed intent_ref"
out=$("$FC" INT-foo 2>&1 || true)
assert_contains "$out" "must match"

it "errors when UNIFY block missing"
out=$("$FC" INT-1234 2>&1 || true)
assert_contains "$out" "UNIFY knowledge block must exist"

# ───────────────────────────────────────────────────────
# Build a real git repo inside the sandbox and exercise both paths.
cd "$SANDBOX"
git init -q
git config user.email "test@example.com"
git config user.name "Test"

cat > "$SANDBOX/specs/api/SPEC-0042.md" <<'MD'
# SPEC-0042
intent_ref: INT-0042
status: active
domain: api

## Behavior
- API exists

## Impact Zones
- src/api.ts (MODIFIED · HIGH)
- src/db.ts (NEW · MEDIUM)
- Upstream: nothing
- Downstream: nothing
MD

echo "v1" > src/api.ts
echo "v1" > src/db.ts
echo "v1" > src/unrelated.ts
git add -A
git commit -q -m "initial"
BASE_SHA=$(git rev-parse HEAD)

cat > "$SANDBOX/sessions/INT-0042-UNIFY.yaml" <<YAML
knowledge_block:
  intent_ref: INT-0042
  session_id: sess-x
  phase_completed: UNIFY
  agent_id: spec-agent
  decisions: []
  files_changed: []
  open_questions: []
  next_phase_context: ""
  base_sha: ${BASE_SHA}
YAML

it "clean repo: exits 0 when nothing in Impact Zones has changed"
out=$("$FC" INT-0042 2>&1)
exit_code=$?
assert_eq "0" "$exit_code" "exit code"
assert_contains "$out" "freshness-check: OK"
assert_contains "$out" "2 file(s)"

it "drift in unrelated file is ignored"
echo "v2" > src/unrelated.ts
git add -A; git commit -q -m "touch unrelated"
out=$("$FC" INT-0042 2>&1)
exit_code=$?
assert_eq "0" "$exit_code" "exit code"
assert_contains "$out" "freshness-check: OK"

it "drift in an Impact Zone file fails with exit 1 and prints the file"
echo "v2" > src/api.ts
git add -A; git commit -q -m "touch api.ts"
out=$("$FC" INT-0042 2>&1)
exit_code=$?
assert_eq "1" "$exit_code" "exit code"
assert_contains "$out" "DRIFT DETECTED"
assert_contains "$out" "src/api.ts"
assert_not_contains "$out" "src/unrelated.ts"

it "errors clearly when base_sha is missing from the UNIFY block"
cat > "$SANDBOX/sessions/INT-0099-UNIFY.yaml" <<'YAML'
knowledge_block:
  intent_ref: INT-0099
  session_id: sess-x
  phase_completed: UNIFY
  agent_id: spec-agent
  decisions: []
  files_changed: []
  open_questions: []
  next_phase_context: ""
  base_sha: null
YAML
out=$("$FC" INT-0099 2>&1 || true)
assert_contains "$out" "base_sha missing"

it "errors when base_sha is unreachable in the local repo"
cat > "$SANDBOX/sessions/INT-0077-UNIFY.yaml" <<'YAML'
knowledge_block:
  intent_ref: INT-0077
  session_id: sess-x
  phase_completed: UNIFY
  agent_id: spec-agent
  decisions: []
  files_changed: []
  open_questions: []
  next_phase_context: ""
  base_sha: 0000000000000000000000000000000000000000
YAML
# Need a spec too
cat > "$SANDBOX/specs/api/SPEC-0077.md" <<'MD'
# SPEC-0077
intent_ref: INT-0077
status: active

## Impact Zones
- src/api.ts (MODIFIED · HIGH)
MD
out=$("$FC" INT-0077 2>&1 || true)
assert_contains "$out" "not reachable"

summary
