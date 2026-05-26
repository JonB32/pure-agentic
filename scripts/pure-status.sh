#!/usr/bin/env bash
# pure-status.sh — Single-command PURE state snapshot.
# Usage: ./scripts/pure-status.sh
#
# Reads intents/ + sessions/ to print active intents, their current phase,
# and the next suggested agent. Replaces the 4-step orientation grep dance.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

python3 - "$ROOT" <<'PY'
import glob, os, sys, yaml
from datetime import datetime, timezone

root = sys.argv[1]

# Phase → next agent table. Single source of truth for "what comes after X".
PHASE_NEXT = {
    "PURPOSE": ("spec-agent",                "ready to UNIFY"),
    "UNIFY":   ("code-agent",                "ready for LAUNCH"),
    "LAUNCH":  ("test-agent + security-agent","ready for SHIELD"),
    "SHIELD":  ("review-agent",              "ready for review + freshness-check"),
    "EVOLVE":  ("context-agent",             "ready for archival"),
    "PARTIAL": ("(resume in same phase)",    "phase incomplete"),
}

def load_yaml(path):
    try:
        with open(path) as f:
            return yaml.safe_load(f) or {}
    except Exception:
        return {}

def latest_session_for(intent_id):
    matches = glob.glob(os.path.join(root, "sessions", f"{intent_id}-*.yaml"))
    matches = [m for m in matches if not m.endswith("-SUMMARY.yaml")]
    if not matches:
        return None, None
    # Phase ordering for tie-break when mtimes are equal
    phase_order = {"PURPOSE": 0, "UNIFY": 1, "LAUNCH": 2, "SHIELD": 3, "EVOLVE": 4, "PARTIAL": 0}
    def sort_key(p):
        data = load_yaml(p)
        phase = (data.get("knowledge_block") or {}).get("phase_completed", "")
        return (os.path.getmtime(p), phase_order.get(phase, -1))
    latest = max(matches, key=sort_key)
    data = load_yaml(latest)
    return latest, (data.get("knowledge_block") or {}).get("phase_completed")

intents = sorted(glob.glob(os.path.join(root, "intents", "INT-*.yaml")))

active   = []   # status in {approved, active} and not completed/superseded
completed_recent = []
blocked_gates = 0
open_security = 0

for path in intents:
    data = load_yaml(path)
    i = data.get("intent") or {}
    intent_id = i.get("id") or os.path.basename(path).replace(".yaml", "")
    status = i.get("status") or ("approved" if i.get("approved_by") else "draft")
    domain = i.get("domain") or "general"
    statement = i.get("statement") or ""
    superseded_by = i.get("superseded_by")

    session_path, phase = latest_session_for(intent_id)

    if status in ("completed", "superseded"):
        completed_recent.append((intent_id, domain, status, superseded_by))
        continue
    if status in ("approved", "active") or i.get("approved_by"):
        active.append((intent_id, domain, statement, phase, session_path))

# Scan sessions for blocked gates and open security findings (cheap heuristics)
for s in glob.glob(os.path.join(root, "sessions", "INT-*.yaml")):
    text = open(s).read()
    if "gate_blocked" in text:
        blocked_gates += 1
    data = load_yaml(s)
    kb = data.get("knowledge_block") or {}
    sec = (kb.get("security_findings") or {}).get("open") or []
    if sec:
        open_security += len(sec)

print()
print("PURE Status")
print("═══════════════════════════════════════════════")
print()
print("Active intents (approved, not completed):")
if not active:
    print("  (none)")
else:
    for intent_id, domain, statement, phase, session_path in active:
        phase_display = phase or "PURPOSE"
        next_agent, hint = PHASE_NEXT.get(phase_display, ("?", ""))
        truncated = (statement[:80] + "…") if len(statement) > 81 else statement
        print(f"  {intent_id:<10} {domain:<10} {phase_display:<8} ⏳ next: {next_agent}")
        print(f"             \"{truncated}\"")

print()
print("Recently completed:")
if not completed_recent:
    print("  (none)")
else:
    for intent_id, domain, status, ref in completed_recent[-5:]:
        suffix = f" ({ref})" if ref else ""
        marker = "✓ superseded" if status == "superseded" else "✓ completed"
        print(f"  {intent_id:<10} {domain:<10} {marker}{suffix}")

print()
print(f"Blocked gates: {'none' if blocked_gates == 0 else blocked_gates}")
print(f"Open security findings: {'none' if open_security == 0 else open_security}")

print()
print("Next suggested action:")
if not active:
    print("  → no active intents — run scripts/new-intent.sh to start one")
else:
    intent_id, domain, statement, phase, session_path = active[0]
    phase_display = phase or "PURPOSE"
    next_agent, hint = PHASE_NEXT.get(phase_display, ("?", ""))
    when = ""
    if session_path:
        mtime = datetime.fromtimestamp(os.path.getmtime(session_path), tz=timezone.utc)
        when = f" (last session: {phase_display} complete at {mtime.isoformat(timespec='seconds')})"
    print(f"  → {next_agent} should pick up {intent_id}{when}")
PY
