---
name: registry-routing
description: Use when the orchestrator needs to assemble an agent team for an intent by querying the registry.
---

## When to Use

- UNIFY phase begins and no agent team has been assembled
- A new capability is needed mid-cycle that wasn't in the original plan
- Registry is being updated after a new agent is added

## Steps

1. Extract required capability tags from the intent:
   - Read `constraints` — map each to a capability tag
   - Read `domain` — add as a tag
   - Examples: "Redis" → `redis`, "security compliance" → `security`, "API endpoint" → `api`

2. Read `registry/registry.yaml`.

3. Filter by: `status: stable` (or `canary` if canary is enabled), `environment: prod`.

4. Match: `capability_tags ∩ required_tags ≠ ∅`.

5. Filter by:
   - `atf_level_minimum ≤ current_atf_budget`
   - `context_budget_tokens` fits within orchestrator's remaining budget

6. Rank by: `avg_success_rate DESC`, then `avg_latency_ms ASC`.

7. Assemble team — always include:
   - code-agent (or domain specialist if available)
   - test-agent
   - security-agent
   - review-agent
   - deploy-agent (if deployment is in scope)

8. Check for canary agents: if a `canary` version exists for any selected agent, apply traffic weight from registry canary config.

9. Record team in plan: `sessions/INT-xxxx-PLAN.yaml`.

## Output

Agent team list with versions, ATF levels, and execution order (sequential/parallel per dependency).

## Anti-Patterns

- Hardcoding agent names instead of querying the registry — defeats the routing system
- Selecting deprecated or retired agents — always check `status`
- Skipping test-agent or security-agent to save time — they are non-optional
- Assembling a team without checking `atf_level_minimum` — ATF violation

## Execution Modes

```
Sequential  → code-agent before test-agent (tests need code to exist)
Parallel    → test-agent + security-agent (independent work in SHIELD)
Human gate  → deploy-agent to prod (always)
```
