---
name: intent-capture
description: Use when a human has expressed a goal and you need to turn it into a valid PURE Intent Statement.
---

## When to Use

- Human says "I want to..." or "we need to..." or describes a feature/fix/change
- An upstream system triggers a new work item
- An existing intent needs to be split because it's compound

## Steps

1. Extract the core deliverable: what single thing will exist that doesn't exist now?
2. Extract the success signal: how will the human know it worked?
3. Identify constraints from context (existing tech stack, compliance, performance SLAs).
4. Identify explicit exclusions — what is the human NOT asking for?
5. Check: is this compound? ("add X and Y" → split into two intents.)
6. Write to `intents/INT-xxxx.yaml` using `templates/intent.yaml`.
7. Present to human for approval. Do not proceed to UNIFY until `approved_by` is set.

## Output

`intents/INT-xxxx.yaml` with all fields populated except `approved_by` / `approved_at`.

## Anti-Patterns

- Writing a compound intent ("add auth AND rate limiting") — always split
- Filling in `constraints` speculatively — only include constraints the human stated or that are verifiably present in the codebase
- Setting `approved_by` yourself — that field is human-only
- Treating a vague request as a complete intent — ask clarifying questions first

## Quality Check

Before presenting for approval, verify:
- `statement` answers "what will exist?"
- `outcome` answers "how will we know it worked?"
- At least one constraint is present
- `out_of_scope` has at least one entry
