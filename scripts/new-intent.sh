#!/usr/bin/env bash
# new-intent.sh — Create a new PURE Intent Statement.
#
# Interactive mode (default when stdin is a TTY):
#   ./scripts/new-intent.sh [--id INT-0042] [--domain api]
#
# Non-interactive mode (auto-detected when stdin is not a TTY, or with
# --non-interactive):
#   ./scripts/new-intent.sh \
#     --statement "..." \
#     --outcome "..." \
#     --constraint "..." \
#     --constraint "..." \
#     --out-of-scope "..." \
#     --priority high \
#     --domain api \
#     --depends-on INT-0001 \
#     --non-interactive
#
# In non-interactive mode, --statement and --outcome are required.
# The resulting YAML is also written to stdout for the calling agent.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
INTENTS_DIR="$ROOT/intents"

INTENT_ID=""
DOMAIN=""
STATEMENT=""
OUTCOME=""
PRIORITY=""
NON_INTERACTIVE=false
CONSTRAINTS=()
OUT_OF_SCOPE=()
DEPENDS_ON=()

usage() {
  sed -n '2,22p' "$0" | sed 's/^# \{0,1\}//'
  exit "${1:-0}"
}

while [[ $# -gt 0 ]]; do
  case $1 in
    --id)               INTENT_ID="$2"; shift 2 ;;
    --domain)           DOMAIN="$2"; shift 2 ;;
    --statement)        STATEMENT="$2"; shift 2 ;;
    --outcome)          OUTCOME="$2"; shift 2 ;;
    --priority)         PRIORITY="$2"; shift 2 ;;
    --constraint)       CONSTRAINTS+=("$2"); shift 2 ;;
    --out-of-scope)     OUT_OF_SCOPE+=("$2"); shift 2 ;;
    --depends-on)       DEPENDS_ON+=("$2"); shift 2 ;;
    --non-interactive)  NON_INTERACTIVE=true; shift ;;
    -h|--help)          usage 0 ;;
    *)                  echo "Unknown argument: $1" >&2; usage 1 ;;
  esac
done

# Auto-detect non-interactive when stdin isn't a TTY (agents, pipes, CI)
if [ ! -t 0 ]; then
  NON_INTERACTIVE=true
fi

next_id() {
  local last
  last=$(ls "$INTENTS_DIR"/INT-*.yaml 2>/dev/null | grep -oP 'INT-\K[0-9]+' | sort -n | tail -1)
  if [ -z "$last" ]; then
    echo "0001"
  else
    printf "%04d" $(( 10#$last + 1 ))
  fi
}

if $NON_INTERACTIVE; then
  [ -n "$STATEMENT" ] || { echo "ERROR: --statement is required in non-interactive mode." >&2; exit 1; }
  [ -n "$OUTCOME" ]   || { echo "ERROR: --outcome is required in non-interactive mode." >&2; exit 1; }
  PRIORITY="${PRIORITY:-medium}"
  DOMAIN="${DOMAIN:-general}"
else
  echo ""
  echo "Creating ${INTENT_ID:-(auto-assigned)}"
  echo "─────────────────────────────────────────"
  read -rp "Statement (what will exist when this is done?): " STATEMENT
  read -rp "Outcome   (how will you know it worked?): " OUTCOME
  read -rp "Domain    (e.g., api, auth, notifications) [${DOMAIN:-general}]: " DOMAIN_INPUT
  DOMAIN="${DOMAIN_INPUT:-${DOMAIN:-general}}"
  echo ""
  echo "Constraints (press Enter after each; empty line to finish):"
  while IFS= read -rp "  - " line && [ -n "$line" ]; do
    CONSTRAINTS+=("$line")
  done
  echo ""
  echo "Out of scope (press Enter after each; empty line to finish):"
  while IFS= read -rp "  - " line && [ -n "$line" ]; do
    OUT_OF_SCOPE+=("$line")
  done
  read -rp "Priority [${PRIORITY:-medium}]: " P_INPUT
  PRIORITY="${P_INPUT:-${PRIORITY:-medium}}"
fi

[ -z "$INTENT_ID" ] && INTENT_ID="INT-$(next_id)"
OUTFILE="$INTENTS_DIR/${INTENT_ID}.yaml"

if [ -f "$OUTFILE" ]; then
  echo "ERROR: $OUTFILE already exists." >&2
  exit 1
fi

# YAML-escape a string for double-quoted scalars: \\ and "
yaml_escape() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  printf '%s' "$s"
}

# Render a list as YAML block items, or [] if empty
render_list() {
  local indent="$1"; shift
  if [ "$#" -eq 0 ]; then
    echo "[]"
    return
  fi
  echo ""
  for item in "$@"; do
    printf '%s- "%s"\n' "$indent" "$(yaml_escape "$item")"
  done | sed '$ s/$//'
}

# Render lists separately so the function output stays simple
render_constraints() {
  if [ "${#CONSTRAINTS[@]}" -eq 0 ]; then
    printf '    - ""\n'
  else
    for c in "${CONSTRAINTS[@]}"; do
      printf '    - "%s"\n' "$(yaml_escape "$c")"
    done
  fi
}

render_out_of_scope() {
  if [ "${#OUT_OF_SCOPE[@]}" -eq 0 ]; then
    printf '    - ""\n'
  else
    for o in "${OUT_OF_SCOPE[@]}"; do
      printf '    - "%s"\n' "$(yaml_escape "$o")"
    done
  fi
}

render_depends_on() {
  if [ "${#DEPENDS_ON[@]}" -eq 0 ]; then
    printf '[]'
  else
    printf '['
    local first=true
    for d in "${DEPENDS_ON[@]}"; do
      if $first; then first=false; else printf ', '; fi
      printf '"%s"' "$(yaml_escape "$d")"
    done
    printf ']'
  fi
}

YAML=$(cat <<EOF
intent:
  id: ${INTENT_ID}
  statement: "$(yaml_escape "$STATEMENT")"
  outcome: "$(yaml_escape "$OUTCOME")"
  constraints:
$(render_constraints)
  out_of_scope:
$(render_out_of_scope)
  priority: ${PRIORITY}
  domain: "$(yaml_escape "$DOMAIN")"
  depends_on: $(render_depends_on)
  supersedes: null
  approved_by: null
  approved_at: null
  status: draft
  superseded_by: null
  external_ref: null
EOF
)

printf '%s\n' "$YAML" > "$OUTFILE"

if $NON_INTERACTIVE; then
  # Emit YAML so the calling agent can verify field shape without re-reading
  printf '%s\n' "$YAML"
  echo "---"
  echo "Written: $OUTFILE"
else
  echo ""
  echo "Written: $OUTFILE"
  echo ""
  echo "Next steps:"
  echo "  1. Review and edit: $OUTFILE"
  echo "  2. Set status to 'approved' and approved_by/approved_at when ready"
  echo "  3. Tell your agent: '${INTENT_ID} is approved. Begin UNIFY.'"
fi
