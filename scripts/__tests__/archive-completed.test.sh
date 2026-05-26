#!/usr/bin/env bash
# Tests for scripts/archive-completed.sh — eligibility, dry-run, --apply

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./lib.sh
source "$SCRIPT_DIR/lib.sh"

ROOT_REAL="$(cd "$SCRIPT_DIR/../.." && pwd)"
SANDBOX="$(mktemp -d)"
mkdir -p "$SANDBOX/scripts" "$SANDBOX/intents" "$SANDBOX/sessions" "$SANDBOX/specs/api"
cp "$ROOT_REAL/scripts/archive-completed.sh" "$SANDBOX/scripts/archive-completed.sh"
chmod +x "$SANDBOX/scripts/archive-completed.sh"
trap 'rm -rf "$SANDBOX"' EXIT

AC="$SANDBOX/scripts/archive-completed.sh"

# Eligible intent: completed status, EVOLVE block, spec status completed, no blocked gates.
cat > "$SANDBOX/intents/INT-0001.yaml" <<'YAML'
intent:
  id: INT-0001
  statement: "ship welcome email"
  outcome: "delivered <60s"
  constraints: []
  out_of_scope: []
  priority: medium
  domain: notifications
  status: completed
YAML

cat > "$SANDBOX/specs/api/SPEC-0001.md" <<'MD'
# SPEC-0001
intent_ref: INT-0001
status: completed

## Behavior
- sends welcome email
MD

for phase in UNIFY LAUNCH SHIELD EVOLVE; do
  cat > "$SANDBOX/sessions/INT-0001-${phase}.yaml" <<YAML
knowledge_block:
  intent_ref: INT-0001
  session_id: sess-x
  phase_completed: ${phase}
  agent_id: agent
  decisions: ["x"]
  files_changed: []
  open_questions: []
  next_phase_context: "next"
YAML
done

# Ineligible intent: completed but no EVOLVE block
cat > "$SANDBOX/intents/INT-0002.yaml" <<'YAML'
intent:
  id: INT-0002
  statement: x
  outcome: y
  constraints: []
  out_of_scope: []
  priority: medium
  domain: api
  status: completed
YAML
cat > "$SANDBOX/sessions/INT-0002-SHIELD.yaml" <<'YAML'
knowledge_block:
  intent_ref: INT-0002
  session_id: x
  phase_completed: SHIELD
  agent_id: a
  decisions: []
  files_changed: []
  open_questions: []
  next_phase_context: ""
YAML

# Ineligible intent: completed + EVOLVE but blocked gate in sessions
cat > "$SANDBOX/intents/INT-0003.yaml" <<'YAML'
intent:
  id: INT-0003
  statement: x
  outcome: y
  constraints: []
  out_of_scope: []
  priority: medium
  domain: api
  status: completed
YAML
cat > "$SANDBOX/sessions/INT-0003-EVOLVE.yaml" <<'YAML'
knowledge_block:
  intent_ref: INT-0003
  session_id: x
  phase_completed: EVOLVE
  agent_id: a
  decisions: ["gate_blocked: still flaky"]
  files_changed: []
  open_questions: []
  next_phase_context: ""
YAML

# Ineligible intent: still active (not completed/superseded)
cat > "$SANDBOX/intents/INT-0004.yaml" <<'YAML'
intent:
  id: INT-0004
  statement: x
  outcome: y
  constraints: []
  out_of_scope: []
  priority: medium
  domain: api
  status: active
YAML

it "dry-run is the default and lists eligible intents"
out=$("$AC" 2>&1)
assert_contains "$out" "Dry run"
assert_contains "$out" "Would archive:"
assert_contains "$out" "SPEC-0001.md"
assert_contains "$out" "INT-0001-UNIFY.yaml"
assert_contains "$out" "INT-0001-EVOLVE.yaml"
assert_contains "$out" "1 eligible"

it "dry-run reports ineligibility reasons"
out=$("$AC" 2>&1)
assert_contains "$out" "INT-0002: no EVOLVE"
assert_contains "$out" "INT-0003"
assert_contains "$out" "open gate_blocked"
assert_contains "$out" "INT-0004"

it "--intent filter restricts to a single intent"
out=$("$AC" --intent INT-0001 2>&1)
assert_contains "$out" "INT-0001"
assert_not_contains "$out" "INT-0002"
assert_not_contains "$out" "INT-0003"

it "dry-run does not actually move files"
assert_file_exists "$SANDBOX/specs/api/SPEC-0001.md"
assert_file_exists "$SANDBOX/sessions/INT-0001-EVOLVE.yaml"

it "--apply moves files and creates SUMMARY.yaml by default"
out=$("$AC" --apply 2>&1)
assert_contains "$out" "Archived 1 intent"
assert_file_not_exists "$SANDBOX/specs/api/SPEC-0001.md"
assert_file_exists "$SANDBOX/specs/.archive/SPEC-0001.md"
assert_file_not_exists "$SANDBOX/sessions/INT-0001-UNIFY.yaml"
assert_file_exists "$SANDBOX/sessions/.archive/INT-0001-UNIFY.yaml"
assert_file_exists "$SANDBOX/sessions/INT-0001-SUMMARY.yaml"

it "--no-summary skips the merged SUMMARY.yaml"
# Set up a fresh eligible intent INT-0005
cat > "$SANDBOX/intents/INT-0005.yaml" <<'YAML'
intent:
  id: INT-0005
  statement: x
  outcome: y
  constraints: []
  out_of_scope: []
  priority: medium
  domain: api
  status: completed
YAML
cat > "$SANDBOX/sessions/INT-0005-EVOLVE.yaml" <<'YAML'
knowledge_block:
  intent_ref: INT-0005
  session_id: x
  phase_completed: EVOLVE
  agent_id: a
  decisions: []
  files_changed: []
  open_questions: []
  next_phase_context: ""
YAML
"$AC" --apply --no-summary --intent INT-0005 > /dev/null 2>&1
assert_file_exists "$SANDBOX/sessions/.archive/INT-0005-EVOLVE.yaml"
assert_file_not_exists "$SANDBOX/sessions/INT-0005-SUMMARY.yaml"

summary
