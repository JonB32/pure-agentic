# Session Start Hook

Run this checklist at the start of every PURE session before any tool use.

---

## For Agents

```
1. Load AGENTS.md (if not already in system prompt).

2. Identify the active intent:
   - Check intents/ for the most recently modified INT-xxxx.yaml
   - Or: use the intent specified in the task you were given

3. Check for a prior session:
   - ls sessions/INT-xxxx-*.yaml
   - If found: read the most recent. Determine current phase from phase_completed.
   - If not found: fresh start at UNIFY.

4. Build your HOT context window:
   STATIC      → your AGENT.md system prompt + registry summary (≤400 tokens)
   SEMI-STATIC → active spec + most recent knowledge block
   DYNAMIC     → current task (empty at start)

5. Load the relevant skill:
   - UNIFY?  → skills/spec-generation/SKILL.md
   - LAUNCH? → load skills/{relevant-domain}/SKILL.md from learned-skills/ if prior art
   - SHIELD? → skills/impact-analysis/SKILL.md + skills/a2a-handoff/SKILL.md
   - EVOLVE? → skills/context-compaction/SKILL.md

6. Verify context budget: STATIC + SEMI-STATIC should leave ≥ 4k tokens for DYNAMIC.
```

## For Humans

```
1. Check intents/ for open (approved, not completed) intents.
2. Check sessions/ for any blocked gates (gate_blocked messages in a2a-log).
3. Review any security_findings.open items from the last SHIELD.
4. If resuming: read the most recent knowledge block to orient yourself.
```

## Quick State Check

Run from project root to see current PURE state:
```bash
./scripts/context-check.sh
```
