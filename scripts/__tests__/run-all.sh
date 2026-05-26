#!/usr/bin/env bash
# Run every *.test.sh in this directory. Used by CI and by humans locally.

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

EXIT=0
for t in "$SCRIPT_DIR"/*.test.sh; do
  [ -f "$t" ] || continue
  echo ""
  echo "═══ $(basename "$t") ═══"
  if ! bash "$t"; then
    EXIT=1
  fi
done

echo ""
if [ "$EXIT" -eq 0 ]; then
  echo "All test files passed."
else
  echo "FAIL: at least one test file failed."
fi
exit "$EXIT"
