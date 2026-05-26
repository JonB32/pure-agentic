#!/usr/bin/env bash
# archive-completed.sh — EVOLVE-phase archival for completed/superseded intents.
#
# Eligibility: intent has an EVOLVE knowledge block AND no open gates
# (i.e. no `gate_blocked` strings in its sessions) AND its status is
# `completed` or `superseded`.
#
# Usage:
#   ./scripts/archive-completed.sh                # dry-run (default)
#   ./scripts/archive-completed.sh --apply        # actually move files
#   ./scripts/archive-completed.sh --intent INT-0001
#   ./scripts/archive-completed.sh --apply --no-summary

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

APPLY=false
NO_SUMMARY=false
INTENT_FILTER=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --dry-run)    APPLY=false; shift ;;
    --apply)      APPLY=true; shift ;;
    --no-summary) NO_SUMMARY=true; shift ;;
    --intent)     INTENT_FILTER="$2"; shift 2 ;;
    -h|--help)
      sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'
      exit 0 ;;
    *) echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
done

APPLY="$APPLY" NO_SUMMARY="$NO_SUMMARY" INTENT_FILTER="$INTENT_FILTER" \
  ROOT="$ROOT" python3 - <<'PY'
import glob, os, shutil, sys, yaml
from datetime import datetime, timezone

root           = os.environ["ROOT"]
apply          = os.environ["APPLY"] == "true"
no_summary     = os.environ["NO_SUMMARY"] == "true"
intent_filter  = os.environ["INTENT_FILTER"]

specs_archive    = os.path.join(root, "specs",    ".archive")
sessions_archive = os.path.join(root, "sessions", ".archive")

def load_yaml(path):
    with open(path) as f:
        return yaml.safe_load(f) or {}

def find_spec_for(intent_id):
    # Spec files reference intent_ref in the body; scan specs/ recursively.
    for spec_path in sorted(glob.glob(os.path.join(root, "specs", "**", "*.md"), recursive=True)):
        if ".archive" in spec_path: continue
        try:
            with open(spec_path) as f:
                head = f.read(2000)
            if f"intent_ref: {intent_id}" in head or f"intent_ref:{intent_id}" in head:
                return spec_path
        except Exception:
            continue
    return None

def sessions_for(intent_id):
    paths = glob.glob(os.path.join(root, "sessions", f"{intent_id}-*.yaml"))
    return sorted(p for p in paths if not p.endswith("-SUMMARY.yaml"))

def has_blocked_gate(intent_id):
    for p in sessions_for(intent_id):
        try:
            if "gate_blocked" in open(p).read():
                return True
        except Exception:
            pass
    return False

def has_phase(intent_id, phase):
    for p in sessions_for(intent_id):
        data = load_yaml(p)
        kb = data.get("knowledge_block") or {}
        if kb.get("phase_completed") == phase:
            return True
    return False

def spec_status(spec_path):
    if not spec_path: return None
    try:
        with open(spec_path) as f:
            text = f.read()
    except Exception:
        return None
    for line in text.splitlines():
        s = line.strip()
        if s.startswith("status:"):
            return s.split(":", 1)[1].strip()
    return None

# Enumerate intents
intents = sorted(glob.glob(os.path.join(root, "intents", "INT-*.yaml")))
if intent_filter:
    intents = [p for p in intents if os.path.basename(p).startswith(intent_filter)]

eligible = []
ineligible = []

for ip in intents:
    intent = (load_yaml(ip).get("intent") or {})
    intent_id = intent.get("id") or os.path.basename(ip).replace(".yaml", "")
    status = (intent.get("status") or "").lower()
    spec_path = find_spec_for(intent_id)
    sp_status = spec_status(spec_path)

    reasons = []
    if status not in ("completed", "superseded"):
        reasons.append(f"intent.status={status or 'unset'} (need completed|superseded)")
    if not has_phase(intent_id, "EVOLVE"):
        reasons.append("no EVOLVE knowledge block")
    if has_blocked_gate(intent_id):
        reasons.append("open gate_blocked in sessions")
    if spec_path and sp_status and sp_status not in ("completed", "superseded"):
        reasons.append(f"spec.status={sp_status} (need completed|superseded)")

    record = {
        "intent_id": intent_id,
        "spec_path": spec_path,
        "sessions":  sessions_for(intent_id),
    }
    if reasons:
        ineligible.append((record, reasons))
    else:
        eligible.append(record)

prefix = "Would" if not apply else "Will"
header = "Dry run — pass --apply to execute" if not apply else "Applying archival"
print(header)
print()

if not eligible:
    print("(no eligible intents found)")
else:
    print(f"{prefix} archive:")
    for r in eligible:
        if r["spec_path"]:
            print(f"  {r['spec_path']}  → specs/.archive/{os.path.basename(r['spec_path'])}")
        for s in r["sessions"]:
            print(f"  {s}  → sessions/.archive/{os.path.basename(s)}")
        if not no_summary:
            print(f"  + create sessions/{r['intent_id']}-SUMMARY.yaml (merged)")
    print()

if ineligible:
    print("Ineligible:")
    for r, reasons in ineligible:
        print(f"  {r['intent_id']}: " + "; ".join(reasons))
    print()

print(f"{len(eligible)} eligible; {len(ineligible)} ineligible.")

if not apply:
    sys.exit(0)

# Execute
os.makedirs(specs_archive,    exist_ok=True)
os.makedirs(sessions_archive, exist_ok=True)

for r in eligible:
    # Move spec
    if r["spec_path"]:
        dest = os.path.join(specs_archive, os.path.basename(r["spec_path"]))
        shutil.move(r["spec_path"], dest)

    # Optionally write merged SUMMARY before archiving phase files
    if not no_summary and r["sessions"]:
        summary = {
            "summary": {
                "intent_ref": r["intent_id"],
                "archived_at": datetime.now(timezone.utc).isoformat(timespec="seconds"),
                "phases": [],
            }
        }
        for s in r["sessions"]:
            data = load_yaml(s)
            kb = data.get("knowledge_block") or {}
            summary["summary"]["phases"].append({
                "phase":          kb.get("phase_completed"),
                "agent_id":       kb.get("agent_id"),
                "session_id":     kb.get("session_id"),
                "decisions":      kb.get("decisions") or [],
                "files_changed":  kb.get("files_changed") or [],
                "next_phase_context": kb.get("next_phase_context") or "",
            })
        summary_path = os.path.join(root, "sessions", f"{r['intent_id']}-SUMMARY.yaml")
        with open(summary_path, "w") as f:
            yaml.safe_dump(summary, f, sort_keys=False)

    # Archive phase files
    for s in r["sessions"]:
        dest = os.path.join(sessions_archive, os.path.basename(s))
        shutil.move(s, dest)

print()
print(f"Archived {len(eligible)} intent(s).")
PY
