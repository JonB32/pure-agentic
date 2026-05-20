---
name: impact-analysis
description: Use when you need to determine which files are affected by a change and how risky each is, to drive test generation.
---

## When to Use

- SHIELD phase begins and test-agent needs to build the change graph
- Orchestrator needs to estimate blast radius before approving a plan
- A new spec's Impact Zones need to be validated against the actual codebase

## Steps

1. Start with `files_changed` from the code-agent A2A handoff.
2. For each changed file, identify direct dependents:
   - What files import or call this file?
   - What files are imported by or called from this file?
3. Build the change graph (depth ≤ 2 for Tier 1; full graph for Tier 2/3):
   ```
   changed_file → direct_dependents → indirect_dependents
   ```
4. Assign risk tier to each node:
   - HIGH: new files, auth flows, data writes, session management, payment logic, core algorithms
   - MEDIUM: services, adapters, API handlers, scheduled jobs
   - LOW: utility functions, formatters, pure transformations, config readers
5. Verify against spec Impact Zones — flag any HIGH-risk file not listed in spec for orchestrator review.
6. Output risk-tiered file list to use as test generation input.

## Output

Structured list:
```
HIGH:   [file1, file2]
MEDIUM: [file3]
LOW:    [file4, file5]
SKIP:   [file6]   ← unmodified, already covered, not in dependency chain
```

## Anti-Patterns

- Building the full transitive closure for Tier 1 projects — depth 2 is enough to start
- Assigning MEDIUM to auth or payment files to reduce test burden — always HIGH
- Including files not in the dependency chain — only direct and indirect dependents
- Skipping the spec Impact Zones cross-check — mismatches indicate spec drift

## Notes

For Tier 2/3 with a knowledge graph: query the codebase graph directly (`files_changed → dependents`).
For Tier 1 without a graph: use grep/find for import statements manually.
