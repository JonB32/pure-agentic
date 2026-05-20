#!/usr/bin/env bash
# new-intent.sh — Create a new PURE Intent Statement interactively.
# Usage: ./scripts/new-intent.sh [--id INT-0042] [--domain api]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMPLATE="$ROOT/templates/intent.yaml"
INTENTS_DIR="$ROOT/intents"

# Determine next intent ID
next_id() {
  local last
  last=$(ls "$INTENTS_DIR"/INT-*.yaml 2>/dev/null | grep -oP 'INT-\K[0-9]+' | sort -n | tail -1)
  if [ -z "$last" ]; then
    echo "0001"
  else
    printf "%04d" $(( 10#$last + 1 ))
  fi
}

# Parse args
INTENT_ID=""
DOMAIN=""
while [[ $# -gt 0 ]]; do
  case $1 in
    --id) INTENT_ID="$2"; shift 2 ;;
    --domain) DOMAIN="$2"; shift 2 ;;
    *) shift ;;
  esac
done

[ -z "$INTENT_ID" ] && INTENT_ID="INT-$(next_id)"
OUTFILE="$INTENTS_DIR/${INTENT_ID}.yaml"

if [ -f "$OUTFILE" ]; then
  echo "ERROR: $OUTFILE already exists." >&2
  exit 1
fi

echo ""
echo "Creating $INTENT_ID"
echo "─────────────────────────────────────────"

read -rp "Statement (what will exist when this is done?): " STATEMENT
read -rp "Outcome   (how will you know it worked?): " OUTCOME
read -rp "Domain    (e.g., api, auth, notifications) [${DOMAIN:-general}]: " DOMAIN_INPUT
DOMAIN="${DOMAIN_INPUT:-${DOMAIN:-general}}"

echo ""
echo "Constraints (press Enter after each; empty line to finish):"
CONSTRAINTS=()
while IFS= read -rp "  - " line && [ -n "$line" ]; do
  CONSTRAINTS+=("$line")
done

echo ""
echo "Out of scope (press Enter after each; empty line to finish):"
OUT_OF_SCOPE=()
while IFS= read -rp "  - " line && [ -n "$line" ]; do
  OUT_OF_SCOPE+=("$line")
done

read -rp "Priority [medium]: " PRIORITY
PRIORITY="${PRIORITY:-medium}"

# Build constraints YAML
CONSTRAINTS_YAML=""
if [ ${#CONSTRAINTS[@]} -eq 0 ]; then
  CONSTRAINTS_YAML='    - ""'
else
  for c in "${CONSTRAINTS[@]}"; do
    CONSTRAINTS_YAML+=$'\n'"    - \"$c\""
  done
  CONSTRAINTS_YAML="${CONSTRAINTS_YAML:1}"
fi

# Build out_of_scope YAML
OOS_YAML=""
if [ ${#OUT_OF_SCOPE[@]} -eq 0 ]; then
  OOS_YAML='    - ""'
else
  for o in "${OUT_OF_SCOPE[@]}"; do
    OOS_YAML+=$'\n'"    - \"$o\""
  done
  OOS_YAML="${OOS_YAML:1}"
fi

cat > "$OUTFILE" <<EOF
intent:
  id: ${INTENT_ID}
  statement: "${STATEMENT}"
  outcome: "${OUTCOME}"
  constraints:
${CONSTRAINTS_YAML}
  out_of_scope:
${OOS_YAML}
  priority: ${PRIORITY}
  domain: "${DOMAIN}"
  depends_on: []
  supersedes: null
  approved_by: null
  approved_at: null
EOF

echo ""
echo "Written: $OUTFILE"
echo ""
echo "Next steps:"
echo "  1. Review and edit: $OUTFILE"
echo "  2. Set approved_by and approved_at when ready"
echo "  3. Tell your agent: '${INTENT_ID} is approved. Begin UNIFY.'"
