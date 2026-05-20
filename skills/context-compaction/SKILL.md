---
name: context-compaction
description: Use when HOT context is approaching its token budget, or when EVOLVE phase begins and context files need to be pruned.
---

## When to Use

- HOT context ≥ 80% of 8k token budget (mid-phase compaction)
- EVOLVE phase: compact AGENTS.md and archive completed artifacts
- An agent context file is approaching its 80-line limit

## Mid-Phase Compaction (during LAUNCH or SHIELD)

1. Write a checkpoint knowledge block (partial — mark `phase_completed: PARTIAL`).
2. Identify what in DYNAMIC context is no longer needed (resolved tool results, prior reasoning).
3. Summarize resolved items into 1–2 lines in the checkpoint block.
4. Drop resolved items from DYNAMIC. Keep only: active task + most recent tool result.
5. Reload: SEMI-STATIC stays (it's cached). DYNAMIC now has headroom.

## EVOLVE Compaction (end of intent cycle)

1. **AGENTS.md audit:**
   For each rule, ask: "has this rule prevented a failure in the last 10 cycles?"
   If no: flag for human eviction review. Never auto-remove.

2. **Spec archive:**
   If `status: completed` → move to `specs/.archive/`. Update spec index.

3. **Knowledge block merge:**
   Merge all `sessions/INT-xxxx-PHASE.yaml` into `sessions/INT-xxxx-SUMMARY.yaml`.
   Move phase files to `sessions/.archive/`.

4. **Rule for adding to AGENTS.md:**
   Only add after observing a real failure the rule would have prevented.
   Do not copy rules from templates, other projects, or "best practices" lists.

## Output

- Compacted DYNAMIC context (mid-phase)
- Updated `AGENTS.md` (EVOLVE — only if rules were evicted with human approval)
- `sessions/INT-xxxx-SUMMARY.yaml` (EVOLVE)

## Anti-Patterns

- Deleting files instead of archiving — breaks audit lineage
- Auto-evicting AGENTS.md rules without human approval
- Compacting the SEMI-STATIC slot — it's cached; leave it alone
- Adding rules to AGENTS.md "while compacting" — compaction is not a rules review
- Merging knowledge blocks before the intent cycle is complete
