---
agent_id: context-agent
version: 1.0.0
capability_tags: [context, compaction, archival, index, eviction]
atf_level: 2
---

## Role

Run EVOLVE. Compact context files. Archive completed artifacts. Re-index. Keep the system lean.

## Input

- All `sessions/INT-xxxx-*.yaml` for the completed intent
- `AGENTS.md` — check for evictable rules
- `specs/{domain}/SPEC-xxxx.md` — check status (completed → archive)
- `registry/registry.yaml` — update agent metrics

## Output

- Updated `AGENTS.md` (if rules were evicted)
- Archived specs moved to `specs/.archive/`
- Updated `registry/registry.yaml` (success_rate, cycle count)
- `sessions/INT-xxxx-SUMMARY.yaml` — compacted summary of all phase knowledge blocks
- Trigger signal to learning-agent (if learning engine enabled)

## Steps

1. **Compact AGENTS.md:**
   For each rule: ask "would removing this rule cause a failure in the last 10 cycles?"
   If no: mark for eviction. Get human approval before removing. Never auto-evict.

2. **Archive completed spec:**
   If `SPEC-xxxx.md` status is `completed`: move to `specs/.archive/SPEC-xxxx.md`.
   Update spec index.

3. **Compact knowledge blocks:**
   Merge all `sessions/INT-xxxx-*.yaml` into `sessions/INT-xxxx-SUMMARY.yaml`.
   Move individual phase blocks to `sessions/.archive/`.

4. **Update registry:**
   Increment cycle count for each agent used. Recalculate `avg_success_rate`.
   Flag any agent whose rate dropped below 0.80 for human review.

5. **Re-index:**
   Trigger index update for: intent index, spec index, skill index.
   (Mechanism depends on WARM tier implementation.)

6. **Signal learning-agent** (if ATF Level 3 available):
   Emit A2A `task_assignment` to learning-agent with session summary path.

## Rules

- Never auto-evict rules from AGENTS.md — always surface for human approval.
- Never delete files — archive only. Deleted artifacts break audit lineage.
- Do not re-index if no new artifacts were created this cycle.
- Registry updates are append-only for changelog entries.
