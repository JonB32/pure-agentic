#!/usr/bin/env bash
# registry-query.sh — Find agents in the registry matching capability tags.
# Usage: ./scripts/registry-query.sh --tags security,redis,api [--env prod] [--status stable]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
REGISTRY="$ROOT/registry/registry.yaml"

if [ ! -f "$REGISTRY" ]; then
  echo "ERROR: registry/registry.yaml not found." >&2
  exit 1
fi

# Defaults
TAGS=""
ENV="prod"
STATUS="stable"
SHOW_ALL=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --tags)   TAGS="$2"; shift 2 ;;
    --env)    ENV="$2"; shift 2 ;;
    --status) STATUS="$2"; shift 2 ;;
    --all)    SHOW_ALL=true; shift ;;
    --help)
      echo "Usage: registry-query.sh --tags tag1,tag2 [--env prod] [--status stable] [--all]"
      exit 0 ;;
    *) shift ;;
  esac
done

# Requires python3 or yq; fall back to grep-based approach
if command -v python3 &>/dev/null; then
  python3 - "$REGISTRY" "$TAGS" "$ENV" "$STATUS" "$SHOW_ALL" <<'PYEOF'
import sys, re

registry_file = sys.argv[1]
tags_input    = sys.argv[2]
env_filter    = sys.argv[3]
status_filter = sys.argv[4]
show_all      = sys.argv[5].lower() == "true"

required_tags = set(t.strip() for t in tags_input.split(",") if t.strip())

with open(registry_file) as f:
  content = f.read()

# Simple YAML block parser (no external deps)
agents_raw = re.split(r'\n  - agent_id:', content)
results = []

for block in agents_raw[1:]:
  block = "  - agent_id:" + block.split('\n  - agent_id:')[0]

  def field(name):
    m = re.search(rf'{name}:\s*(.+)', block)
    return m.group(1).strip().strip('"') if m else ""

  def list_field(name):
    m = re.search(rf'{name}:\s*\[([^\]]*)\]', block)
    if m:
      return [t.strip().strip('"') for t in m.group(1).split(",") if t.strip()]
    return []

  agent_id    = field("agent_id")
  version     = field("version")
  status      = field("status")
  environment = field("environment")
  atf_level   = field("atf_level_minimum")
  success     = field("avg_success_rate")
  cap_tags    = list_field("capability_tags")
  routing     = field("routing_notes")

  if not show_all:
    if status_filter and status != status_filter:
      continue
    if env_filter and environment != env_filter:
      continue

  matched_tags = required_tags & set(cap_tags) if required_tags else set(cap_tags)
  if required_tags and not matched_tags:
    continue

  results.append({
    "agent_id": agent_id,
    "version": version,
    "status": status,
    "environment": environment,
    "atf_level": atf_level,
    "success_rate": success,
    "matched_tags": sorted(matched_tags),
    "all_tags": cap_tags,
    "routing": routing,
  })

if not results:
  print("No agents matched.")
  sys.exit(0)

print(f"\n{'AGENT':<22} {'VER':<8} {'STATUS':<10} {'ATF':<5} {'RATE':<6}  MATCHED TAGS")
print("─" * 80)
for r in results:
  tags_str = ", ".join(r["matched_tags"]) if r["matched_tags"] else ", ".join(r["all_tags"])
  rate = r["success_rate"] if r["success_rate"] not in ("", "null") else "n/a"
  print(f"{r['agent_id']:<22} {r['version']:<8} {r['status']:<10} {r['atf_level']:<5} {rate:<6}  {tags_str}")
  if r["routing"]:
    print(f"  → {r['routing'][:78]}")
print()
PYEOF
else
  # Fallback: plain grep
  echo "Note: python3 not found. Using basic grep output."
  echo ""
  IFS=',' read -ra TAG_LIST <<< "$TAGS"
  grep -A 20 "agent_id:" "$REGISTRY" | grep -E "(agent_id|version|status|capability_tags|routing_notes)"
fi
