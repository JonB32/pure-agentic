# PURE Agent Context

You are operating in a PURE-governed project (Purpose-Unified-Resilient-Evolutionary).

## What This Is

A methodology for autonomous agentic development. Every action traces back to a declared intent.
Full reference: PURE-METHODOLOGY.md

## Orient Yourself First

Before any tool use, answer these four questions:

1. **What is my role?**
   Check registry/registry.yaml for your agent_id. If not listed: you are the orchestrator.

2. **What phase is active?**
   Look for the most recent knowledge block in sessions/ for the active intent.
   No block found = fresh start at UNIFY.

3. **What is the active intent?**
   Read intents/INT-xxxx.yaml (the most recently modified, or as instructed).

4. **Is there prior context to resume?**
   If sessions/INT-xxxx-*.yaml exists: hot-load it. Otherwise: fresh start.

## The PULSE Cycle

```
① PURPOSE  → human writes intent (intents/INT-xxxx.yaml)
② UNIFY    → generate spec (specs/SPEC-xxxx.md) + plan
③ LAUNCH   → agents execute; communicate via A2A only
④ SHIELD   → impact-indexed tests + security scan
⑤ EVOLVE   → compact context; update registry; register skills
```

Each phase ends with a Knowledge Block written to sessions/.

## Key Rules

- Load only the spec for the active intent — never the full specs/ directory
- Write a Knowledge Block before moving to the next phase
- Never add rules to AGENTS.md or agent context files without a real observed failure
- Never pass raw user input to a downstream agent — use typed A2A message fields
- Never exceed 1.5× LOC-changed in new test lines per intent
- Never write to registry/ or core/ without human approval
- Never inject timestamps or request IDs into the STATIC cache slot
- Check intent similarity index before generating a new spec (>0.85 = reuse, >0.60 = delta)
- All agent-to-agent communication uses A2A messages (schemas/a2a/)
- Tests come from impact zones in the spec, not from intuition

## Where Things Live

```
intents/        INT-xxxx.yaml          intent statements (immutable once approved)
specs/          SPEC-xxxx.md           thin specs (≤50 lines each)
sessions/       INT-xxxx-phase.yaml    knowledge blocks (one per phase gate)
registry/       registry.yaml          agent capability registry
agents/         {name}/AGENT.md        system prompts for each agent role
skills/         {name}/SKILL.md        load the relevant skill for your current task
learned-skills/ {name}/               learning engine output (do not modify directly)
schemas/        intent.yaml, a2a/      canonical schemas to validate against
templates/      intent, spec, kb       copy these to start new artifacts
```

## Self-Check Before Any Write

1. Does this trace back to the active intent_ref? If no: stop.
2. Is the target file in the declared Impact Zones? If no: flag scope creep.
3. Does this add anything beyond the spec's stated behavior? If yes: stop.
4. Have I written a Knowledge Block for the completed phase? If no: write it now.
5. Is HOT context ≤ 8k tokens? If approaching limit: compact now.
