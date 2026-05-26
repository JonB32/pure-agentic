#!/usr/bin/env bash
# freshness-check.sh — Detect upstream drift between spec write-time
# and current HEAD on every file the spec calls out as an Impact Zone.
#
# Usage:
#   ./scripts/freshness-check.sh INT-0042
#
# Reads sessions/INT-xxxx-UNIFY.yaml for base_sha (the HEAD of the base
# branch when the spec was written; see schemas/knowledge-block-v1.json),
# then `git diff --name-only $base_sha HEAD -- <impact_zone_files>`.
#
# Exits 0 if no Impact Zone file changed since base_sha. Exits 1 (with
# the drifted file list printed to stdout) if any did. Exits 2 on
# usage/data errors.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

INTENT_REF="${1:-}"
if [ -z "$INTENT_REF" ]; then
  echo "Usage: $0 INT-xxxx" >&2
  exit 2
fi

if ! [[ "$INTENT_REF" =~ ^INT-[0-9]{4,}$ ]]; then
  echo "ERROR: intent_ref must match ^INT-[0-9]{4,}$ (got: $INTENT_REF)" >&2
  exit 2
fi

UNIFY_BLOCK="$ROOT/sessions/${INTENT_REF}-UNIFY.yaml"
if [ ! -f "$UNIFY_BLOCK" ]; then
  echo "ERROR: $UNIFY_BLOCK not found — UNIFY knowledge block must exist before freshness-check." >&2
  exit 2
fi

# Extract base_sha and the spec_ref / files_changed list from the UNIFY block.
read -r BASE_SHA SPEC_PATH <<<"$(
  UB="$UNIFY_BLOCK" ROOT="$ROOT" INTENT_REF="$INTENT_REF" python3 - <<'PY'
import os, glob, yaml, sys
with open(os.environ["UB"]) as f:
    kb = (yaml.safe_load(f) or {}).get("knowledge_block") or {}
base = kb.get("base_sha")
# YAML parses an all-digit sha as an int; coerce to str. None/empty stays empty.
base = "" if base is None else str(base)
# Find the spec by intent_ref grep over specs/
intent_ref = os.environ["INTENT_REF"]
spec_path = ""
for p in sorted(glob.glob(os.path.join(os.environ["ROOT"], "specs", "**", "*.md"), recursive=True)):
    if ".archive" in p: continue
    try:
        head = open(p).read(4096)
    except Exception:
        continue
    if f"intent_ref: {intent_ref}" in head or f"intent_ref:{intent_ref}" in head:
        spec_path = p
        break
print(f"{base} {spec_path}")
PY
)"

if [ -z "$BASE_SHA" ]; then
  echo "ERROR: base_sha missing from $UNIFY_BLOCK (required field — see schemas/knowledge-block-v1.json)." >&2
  exit 2
fi
if [ -z "$SPEC_PATH" ] || [ ! -f "$SPEC_PATH" ]; then
  echo "ERROR: no spec found for $INTENT_REF (looking for intent_ref: $INTENT_REF in specs/)." >&2
  exit 2
fi

# Parse Impact Zones out of the spec. Lines under "## Impact Zones" of the
# form "- path/to/file.ext (...)". Stops at the next "##" heading.
mapfile -t IMPACT_FILES < <(
  awk '
    /^##[[:space:]]+Impact Zones/ { collecting = 1; next }
    /^##[[:space:]]/              { collecting = 0 }
    collecting && /^[[:space:]]*-[[:space:]]+/ {
      sub(/^[[:space:]]*-[[:space:]]+/, "")
      # Skip Upstream:/Downstream: prose lines
      if ($0 ~ /^Upstream:|^Downstream:/) next
      # Strip everything from the first ( onward, then trim
      sub(/[[:space:]]*\(.*$/, "")
      gsub(/^[[:space:]]+|[[:space:]]+$/, "")
      if (length($0) > 0) print
    }
  ' "$SPEC_PATH"
)

if [ "${#IMPACT_FILES[@]}" -eq 0 ]; then
  echo "WARN: no Impact Zone files parsed from $SPEC_PATH — nothing to check." >&2
  exit 0
fi

cd "$ROOT" || exit 2

# Verify the base_sha is reachable in the local repo
if ! git rev-parse --verify --quiet "${BASE_SHA}^{commit}" > /dev/null; then
  echo "ERROR: base_sha $BASE_SHA is not reachable in this repo — fetch the base branch first." >&2
  exit 2
fi

# Diff base_sha..HEAD restricted to the impact-zone paths.
mapfile -t DRIFT < <(git diff --name-only "$BASE_SHA" HEAD -- "${IMPACT_FILES[@]}" 2>/dev/null)
DRIFT=("${DRIFT[@]/#}")  # noop, keeps array shape

if [ "${#DRIFT[@]}" -eq 0 ] || { [ "${#DRIFT[@]}" -eq 1 ] && [ -z "${DRIFT[0]}" ]; }; then
  echo "freshness-check: OK — no Impact Zone files changed since $BASE_SHA"
  echo "  spec:    $SPEC_PATH"
  echo "  checked: ${#IMPACT_FILES[@]} file(s)"
  exit 0
fi

echo "freshness-check: DRIFT DETECTED — $INTENT_REF is in flight but main has moved"
echo "  spec:        $SPEC_PATH"
echo "  base_sha:    $BASE_SHA"
echo "  now (HEAD):  $(git rev-parse HEAD)"
echo "  drifted files:"
for f in "${DRIFT[@]}"; do
  [ -z "$f" ] && continue
  echo "    - $f"
done
exit 1
