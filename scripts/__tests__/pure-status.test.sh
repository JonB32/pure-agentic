#!/usr/bin/env bash
# Tests for scripts/pure-status.sh — orientation snapshot

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./lib.sh
source "$SCRIPT_DIR/lib.sh"

ROOT_REAL="$(cd "$SCRIPT_DIR/../.." && pwd)"
SANDBOX="$(mktemp -d)"
mkdir -p "$SANDBOX/scripts" "$SANDBOX/intents" "$SANDBOX/sessions"
cp "$ROOT_REAL/scripts/pure-status.sh" "$SANDBOX/scripts/pure-status.sh"
chmod +x "$SANDBOX/scripts/pure-status.sh"
trap 'rm -rf "$SANDBOX"' EXIT

PS="$SANDBOX/scripts/pure-status.sh"

it "empty repo prints no active intents"
out=$("$PS" 2>&1)
assert_contains "$out" "PURE Status"
assert_contains "$out" "Active intents"
assert_contains "$out" "(none)"
assert_contains "$out" "no active intents"

# Set up a fake active intent at SHIELD phase
cat > "$SANDBOX/intents/INT-0042.yaml" <<'YAML'
intent:
  id: INT-0042
  statement: "A user-facing daily progress bar exists"
  outcome: "Bar updates within 200ms after a review"
  constraints: []
  out_of_scope: []
  priority: medium
  domain: mobile
  depends_on: []
  supersedes: null
  approved_by: "jon"
  approved_at: "2026-05-20T10:00:00Z"
  status: active
  superseded_by: null
  external_ref: "linear:ROT-21"
YAML

cat > "$SANDBOX/sessions/INT-0042-UNIFY.yaml" <<'YAML'
knowledge_block:
  intent_ref: INT-0042
  session_id: sess-20260520-001
  phase_completed: UNIFY
  agent_id: spec-agent
  decisions: ["x"]
  files_changed: ["specs/mobile/SPEC-0042.md"]
  open_questions: []
  next_phase_context: "code-agent should start"
YAML

# Touch SHIELD session newer
sleep 0.01
cat > "$SANDBOX/sessions/INT-0042-SHIELD.yaml" <<'YAML'
knowledge_block:
  intent_ref: INT-0042
  session_id: sess-20260520-004
  phase_completed: SHIELD
  agent_id: security-agent
  decisions: ["all clear"]
  files_changed: []
  open_questions: []
  next_phase_context: "review-agent next"
YAML

it "active intent appears with current phase + next agent"
out=$("$PS" 2>&1)
assert_contains "$out" "INT-0042"
assert_contains "$out" "SHIELD"
assert_contains "$out" "review-agent"
assert_contains "$out" "mobile"

# Add a completed intent
cat > "$SANDBOX/intents/INT-0001.yaml" <<'YAML'
intent:
  id: INT-0001
  statement: "x"
  outcome: "y"
  constraints: []
  out_of_scope: []
  priority: medium
  domain: api
  depends_on: []
  status: superseded
  superseded_by: "ROT-20 commits 7af1128"
YAML

it "superseded intent appears in Recently completed"
out=$("$PS" 2>&1)
assert_contains "$out" "Recently completed"
assert_contains "$out" "INT-0001"
assert_contains "$out" "superseded"
assert_contains "$out" "ROT-20"

# Drop in a session with a blocked gate
cat > "$SANDBOX/sessions/INT-0042-LAUNCH.yaml" <<'YAML'
knowledge_block:
  intent_ref: INT-0042
  session_id: sess-20260520-002
  phase_completed: LAUNCH
  agent_id: code-agent
  decisions: ["gate_blocked here"]
  files_changed: []
  open_questions: []
  next_phase_context: "fix and retry"
YAML

it "blocked gates are counted"
out=$("$PS" 2>&1)
assert_contains "$out" "Blocked gates: 1"

summary
