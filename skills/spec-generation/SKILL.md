---
name: spec-generation
description: Use when you need to generate a PURE spec from an approved intent, with or without prior art.
---

## When to Use

- UNIFY phase has started and no spec exists for the active intent
- An intent's similarity score (0.60–0.85) means a delta spec is appropriate
- A spec needs to be updated because the intent was amended

## Steps

1. Read `intents/INT-xxxx.yaml`.
2. Check similarity result from orchestrator:
   - Prior spec surfaced (>0.60): read it, identify reusable Behavior blocks.
   - No prior: start from `templates/spec.md`.
3. Fill **Behavior** — what the system does. Specific enough to test. No implementation details.
4. Fill **Acceptance Criteria** — one line per independently testable outcome. Use checkboxes.
5. Fill **Impact Zones** — name real files or modules. Assign HIGH/MEDIUM/LOW risk.
   - HIGH: new files, auth, data writes, core business logic
   - MEDIUM: services, adapters, integration points
   - LOW: utilities, formatters
6. Fill **Out of Scope** — reference `out_of_scope` from the intent verbatim plus anything implied.
7. Count lines. If > 50: cut Behavior down. Drop any Acceptance Criterion that doesn't add unique test coverage.
8. Write to `specs/{domain}/SPEC-xxxx.md`.

## Output

`specs/{domain}/SPEC-xxxx.md` — ≤ 50 lines, status: draft.

## Anti-Patterns

- Including implementation details in Behavior ("use a Redis sliding window") — that belongs in code or learned-skills
- Writing acceptance criteria that aren't independently testable ("system feels fast")
- Vague Impact Zones ("the auth module") — name specific files
- Exceeding 50 lines by adding explanatory text — cut, don't pad
- Setting `status: active` before human review — spec-agent sets `draft`; human or orchestrator promotes to `active`

## Quality Check

- Every Acceptance Criterion is a complete sentence starting with a verb
- Every Impact Zone names a real path or module that exists in the codebase
- No Acceptance Criterion duplicates another
- `prior_art:` field set if reusing a learned skill or prior spec
