---
name: knowledge-block
description: Use when a PULSE phase gate has been reached and you must write a Knowledge Block before the next phase begins.
---

## When to Use

- Any PULSE phase just completed (PURPOSE, UNIFY, LAUNCH, SHIELD, EVOLVE)
- A sub-agent is about to hand off work to another agent
- HOT context is approaching 80% of budget (mid-phase checkpoint)
- A session was interrupted and needs to be resumable

## Steps

1. Copy `templates/knowledge-block.yaml` to `sessions/INT-xxxx-PHASE.yaml`.
2. Fill `decisions` — every non-obvious decision made this phase. Include the WHY.
   Bad: "Used Redis"
   Good: "Used Redis sliding window over fixed window — more accurate under burst traffic"
3. Fill `files_changed` — complete list, no omissions.
4. Fill `open_questions` — anything unresolved that the next agent must know.
5. Fill `security_findings` — even if empty, include the key.
6. Fill `next_phase_context` — one paragraph. What does the next agent need to start cleanly?
7. Write the file.
8. Clear working log from HOT context (keep only this knowledge block + intent + spec in SEMI-STATIC).

## Output

`sessions/INT-xxxx-PHASE.yaml` — complete, structured, under 40 lines.

## Anti-Patterns

- Writing "no decisions made" — every phase has at least one decision worth recording
- Omitting `open_questions` — this is how context survives agent handoffs
- Writing a narrative instead of structured YAML — keep it machine-readable
- Skipping the knowledge block because the phase was "simple" — the next agent has no prior context without it
- Writing the knowledge block after emitting the A2A handoff — write it first

## Quality Check

- `decisions` has at least one entry with a reason, not just a fact
- `next_phase_context` is specific enough that a cold-start agent could continue without reading the full conversation
- `files_changed` matches what was actually written to disk
