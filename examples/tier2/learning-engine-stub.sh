#!/usr/bin/env bash
# learning-engine-stub.sh — Minimal Tier 2 learning engine.
# Reads a completed session summary and creates a skill entry in learned-skills/.
# Replace with a proper implementation as your team grows.
#
# Usage: ./examples/tier2/learning-engine-stub.sh sessions/INT-0001-SUMMARY.yaml

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

SUMMARY_FILE="${1:-}"
if [ -z "$SUMMARY_FILE" ] || [ ! -f "$SUMMARY_FILE" ]; then
  echo "Usage: $0 sessions/INT-xxxx-SUMMARY.yaml" >&2
  exit 1
fi

# Extract intent_ref
INTENT_REF=$(grep 'intent_ref:' "$SUMMARY_FILE" | head -1 | sed 's/.*: //' | tr -d '"')
if [ -z "$INTENT_REF" ]; then
  echo "ERROR: Could not extract intent_ref from $SUMMARY_FILE" >&2
  exit 1
fi

# Find matching spec
SPEC_FILE=$(ls "$ROOT/specs"/**/"SPEC-${INTENT_REF#INT-}.md" 2>/dev/null | head -1 || \
            ls "$ROOT/specs/.archive/SPEC-${INTENT_REF#INT-}.md" 2>/dev/null | head -1 || true)

echo ""
echo "Learning Engine: processing $INTENT_REF"
echo "─────────────────────────────────────────"

# Check for prior_art in spec — if already reused a skill, note it
if [ -n "$SPEC_FILE" ] && grep -q 'prior_art:' "$SPEC_FILE" 2>/dev/null; then
  PRIOR_ART=$(grep 'prior_art:' "$SPEC_FILE" | sed 's/.*: //' | tr -d '"')
  echo "  Prior art reused: $PRIOR_ART"
fi

# Prompt for skill creation (non-interactive mode: skip if PURE_NONINTERACTIVE=1)
if [ "${PURE_NONINTERACTIVE:-0}" = "1" ]; then
  echo "  Non-interactive mode: skipping skill creation prompt."
  exit 0
fi

read -rp "Create a learned skill from this cycle? (y/N): " CREATE_SKILL
if [[ ! "$CREATE_SKILL" =~ ^[Yy]$ ]]; then
  echo "  Skipped."
  exit 0
fi

read -rp "Skill name (e.g., redis-sliding-window): " SKILL_NAME
SKILL_DIR="$ROOT/learned-skills/$SKILL_NAME"

if [ -d "$SKILL_DIR" ]; then
  echo "  Skill '$SKILL_NAME' already exists. Update it manually in $SKILL_DIR"
  exit 0
fi

mkdir -p "$SKILL_DIR"

read -rp "When should an agent use this skill? (trigger condition): " TRIGGER
read -rp "One-line description of the pattern: " DESCRIPTION

cat > "$SKILL_DIR/SKILL.md" <<EOF
---
name: ${SKILL_NAME}
description: Use when ${TRIGGER}
source_intent: ${INTENT_REF}
created: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
---

## Pattern

${DESCRIPTION}

## When to Use

${TRIGGER}

## Key Decisions

$(grep -A 20 'decisions:' "$SUMMARY_FILE" 2>/dev/null | grep '    - ' | sed 's/    - /- /' || echo "- (see source intent)")

## Success Criteria

- Acceptance criteria from SPEC-${INTENT_REF#INT-} all passed
- All HIGH-tier tests passed
- No CRITICAL or HIGH security findings

## Notes

Generated from ${INTENT_REF} session summary.
Review and edit before relying on this skill in production.
EOF

echo ""
echo "  Created: $SKILL_DIR/SKILL.md"
echo "  Review and fill in example-spec.md and example-output.md manually."
echo "  Update WARM tier skill index to include: $SKILL_NAME"
