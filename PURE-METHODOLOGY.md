# PURE Methodology
## Purpose-Unified-Resilient-Evolutionary Agentic Development

> *Designed from the inside out — by an agent, for agents, to work with humans at the speed of intent.*

**Version:** 1.1 · **Date:** 2026-05-19

---

## Why Another Methodology?

Every existing approach breaks down at scale in a predictable way:

| Methodology | Core Strength | Failure Mode at Scale |
|---|---|---|
| **SDD** | Structure, reproducibility | Spec bloat → context overflow → stale specs that contradict each other |
| **IDD** | Natural language, adaptable | Ambiguity drift → agents hallucinate intent that was never stated |
| **Vibe Coding** | Speed, flow-state creativity | 2.74× more security vulnerabilities, skipped QA, zero traceability |
| **TDD (classic)** | Regression safety, design clarity | Test suites balloon → 60% refactor drop, low-signal tests that slow agents |

PURE resolves these tensions by treating **intent as the immutable anchor**, specs as **thin, generated artifacts**, tests as **impact-indexed** rather than comprehensive, and security as a **protocol-level property** rather than an afterthought.

The name is also the philosophy: every decision should be **purposeful, unified across agents, resilient by default**, and **evolutionary** — the system gets smarter with each cycle.

---

## Core Principles

1. **Intent is the single source of truth.** Every spec, test, agent action, and deployment decision must trace back to a declared intent statement. If it can't, it shouldn't exist.

2. **Thin specs, not thick docs.** Specs are generated summaries of intent, not hand-authored requirement documents. Max 50 lines per spec file. They are created by agents and curated by humans — not the reverse.

3. **Context is a budget, not a dump.** Agent context files (e.g., AGENTS.md) are capped at 80 lines. Context files grow from observed failures, not speculative rules. Stale entries are evicted automatically.

4. **Never trust, always verify — even agents you launched.** Zero-trust applies to all agent-to-agent interactions. Privilege is earned incrementally through the Agentic Trust Framework (ATF) maturity model.

5. **Test what matters, archive what doesn't.** Tests are generated from change-graph impact analysis. No test is added without a mapped risk. Tests that have never caught a regression in N cycles are archived, not accumulated.

6. **Protocols are the contract.** MCP for tool access. A2A for agent-to-agent communication. These are non-negotiable — no bespoke integrations.

7. **The system learns.** Agent skills, routing decisions, and test strategies improve over time via a persistent learning loop. Successful trajectories become reusable skills in the registry.

---

## The PULSE Cycle

PURE executes in five phases. Each phase has a **clear gate condition** — no phase starts until the prior phase's gate is met.

```
┌──────────────────────────────────────────────────────────────┐
│                        PULSE CYCLE                           │
│                                                              │
│  ① PURPOSE  →  ② UNIFY  →  ③ LAUNCH  →  ④ SHIELD  →  ⑤ EVOLVE │
│       ↑                                          │           │
│       └──────────── feedback loop ───────────────┘           │
└──────────────────────────────────────────────────────────────┘
```

### ① PURPOSE — Capture Intent

**What:** The human (or upstream system) expresses *what* and *why*. Not *how*.

**Format:** A structured Intent Statement:
```yaml
intent:
  id: INT-0042
  statement: "Users can reset their password via email without requiring support intervention"
  outcome: "Zero password reset tickets in support queue"
  constraints:
    - "Must comply with SOC2 audit trail requirements"
    - "Email delivery < 30 seconds p99"
  out_of_scope:
    - "SSO/OAuth flows"
  priority: high
```

**Rules:**
- One intent = one deliverable. No compound intents.
- The human writes `statement` and `outcome`. Agents fill `constraints` by querying context (existing specs, codebase, compliance rules).
- Intent statements are **immutable once approved**. Changes create a new intent with a supersedes link.

**Gate:** Intent approved by human before Unify begins.

#### Intent lifecycle

Every intent has an explicit `status:` field. Lifecycle states:

| Status        | Meaning                                                                 |
|---------------|-------------------------------------------------------------------------|
| `draft`       | Authored but not yet human-approved. Default.                          |
| `approved`    | Human signed off (`approved_by` set). UNIFY may begin.                  |
| `active`      | A PULSE cycle is in flight for this intent.                             |
| `completed`   | Shipped. Spec + sessions become candidates for EVOLVE-phase archival.   |
| `superseded`  | Replaced by upstream work or a follow-on intent. See `superseded_by:`.  |

Two companion fields:

- `superseded_by:` — free-form reference to whatever replaced this intent (commit sha, PR number, issue ID, prose).
- `external_ref:` — link to the system of record outside the repo (e.g. `linear:ROT-20`, `jira:PROJ-123`, `github:owner/repo#456`).

All three default to `null` / `draft` so existing intent files keep working unchanged. Schema: [`schemas/intent-v1.json`](schemas/intent-v1.json). Knowledge blocks are validated against [`schemas/knowledge-block-v1.json`](schemas/knowledge-block-v1.json) — both are checked by `scripts/context-check.sh` and the `context-check` CI workflow.

---

### ② UNIFY — Thin Spec + Plan

**What:** The Orchestrator Agent queries the **Agent Registry** to assemble the team, then generates lean specs and an execution plan.

**Spec structure (50 lines max):**
```markdown
# SPEC-0042: Password Reset Flow
intent_ref: INT-0042
status: active

## Behavior
- POST /auth/reset-request accepts email, returns 202 in all cases (no user enumeration)
- Token: 256-bit entropy, 15-min TTL, single-use, stored as bcrypt hash
- Email dispatched via existing notification service (MCP: notification-server)

## Acceptance Criteria
- [ ] Reset flow completes in < 5s under normal load
- [ ] Expired / used tokens return 401 with no detail leakage
- [ ] Audit event emitted to security log on every attempt

## Impact Zones (for test generation)
- auth/reset.ts, notification/email.ts, db/tokens.ts
- Upstream: login flow · Downstream: session management

## Out of scope
- SSO integrations (see INT-0038)
```

**Anti-bloat rules:**
- Spec files live in `/specs/{domain}/` — never in root or as agent context file sections
- Specs are indexed (MCP resource), not concatenated into context
- The Orchestrator retrieves only the spec relevant to the current agent's task

**Plan format:**
```
PLAN-0042
  1. Spec Agent  →  finalize SPEC-0042 (this step)
  2. Code Agent  →  implement auth/reset.ts
  3. Test Agent  →  generate impact-indexed tests
  4. Security Agent → run OWASP Agentic Top 10 scan
  5. Review Agent →  verify intent alignment
  6. Deploy Agent →  stage → prod pipeline
```

**Gate:** Spec reviewed by human OR auto-approved if all constraints are machine-verifiable and ATF level ≥ 3.

---

### ③ LAUNCH — Agents Execute in Flow

**What:** Agents execute the plan. This is where vibe coding's *energy* lives — fast, iterative, generative — but within the guardrails of the intent + spec.

**Key properties:**
- Each agent receives only its **scoped context**: intent ref + relevant spec + its tool permissions
- Agents communicate exclusively via **A2A protocol messages** — no ad-hoc string passing
- The Orchestrator maintains the **lineage chain**: every action is logged as `intent → spec → agent → action → output`
- Agents may self-subdivide tasks (spawn sub-agents) via the registry — the orchestrator approves

**Execution modes:**
| Mode | When | Example |
|---|---|---|
| **Sequential** | Dependent steps | Code → Test (tests need the code to exist) |
| **Parallel** | Independent steps | Auth code + Email code can be built simultaneously |
| **Human gate** | Irreversible or externally visible | Deploy to prod, send user email |

**Context hygiene during execution:**
- Each agent's context window starts fresh with only scoped artifacts
- No agent inherits the prior agent's full conversation — only the structured A2A output message
- Long-running agents use MCP to retrieve context on-demand (warm/cold tiers)

**Gate:** All acceptance criteria in the spec are met (automated), security scan passes (automated).

---

### ④ SHIELD — Security + Impact-Indexed Testing

Security and testing are not afterthoughts — they run **concurrently with LAUNCH**, not after it.

#### Security Layer (Shift-Left + Zero-Trust)

**Agentic Zero Trust (AZT) — 4 Controls:**

1. **Verify Explicitly:** Every agent action is validated against its declared intent. Deviation triggers human escalation.
2. **Least Privilege:** Agents start at ATF Level 1 (fully supervised). They earn higher autonomy through proven track record.
3. **Assume Breach:** All agent outputs are sanitized before passing downstream. Structured schemas only — no raw text piped to system-level agents.
4. **Audit Lineage:** Every action produces an immutable log entry: `{agent_id, action, intent_ref, timestamp, input_hash, output_hash}`.

**ATF Maturity Levels:**
```
Level 1 (Supervised)   — every action requires human approval
Level 2 (Assisted)     — low-risk actions auto-approved, high-risk gated
Level 3 (Collaborative)— destructive/external actions gated, rest autonomous
Level 4 (Autonomous)   — only irreversible prod actions require human gate
```

**OWASP Agentic Top 10 controls (mapped by phase):**
- Prompt injection defense → structured input/output schemas enforced at A2A boundaries
- Privilege escalation → ATF level checked before every registry call
- Data exfiltration → MCP scopes limit what each agent can read/write
- Supply chain → agent registry entries are signed and pinned
- Insecure agent communication → A2A messages are authenticated (OAuth 2.0 scoped tokens)

#### Testing: Impact-First TDD (TDAD Model)

Classic TDD's problem: agents told to "follow TDD" without targeted context produce *more* regressions (9.94% vs. baseline). The fix: **tell agents *which tests to check*, not *how to do TDD*.**

**Impact-indexed test generation:**
1. **Change Graph Analysis** — at LAUNCH start, the Test Agent builds a dependency graph of all files touched by the intent's impact zones
2. **Risk Tier assignment:** HIGH (core business logic, auth, data mutation), MEDIUM (services, adapters), LOW (utilities, formatters)
3. **Test generation proportional to risk:**
   - HIGH: unit + integration + contract tests + mutation testing probe
   - MEDIUM: unit + integration tests
   - LOW: single happy-path unit test (or none if already covered)
4. **Test budget enforced:** no more than 1.5× lines-of-code-changed in new test lines per intent
5. **Archive trigger:** any test that has not caught a regression in 10 release cycles is marked `archived` and excluded from CI (not deleted — recoverable)

**Test types by boundary:**
| Boundary | Test Type |
|---|---|
| Pure functions | Property-based tests |
| Agent-to-Agent (A2A) | Contract tests on A2A message schemas |
| External MCP tools | Integration tests with real or in-process MCP servers |
| User-facing behavior | Acceptance tests mapped directly to spec acceptance criteria |
| Security invariants | Automated OWASP scan + prompt injection probes |

**Gate:** All HIGH-tier tests pass. No new CRITICAL or HIGH security findings. Test budget not exceeded.

---

### ⑤ EVOLVE — Learn, Compact, Register

**What:** The system improves itself after every completed intent cycle.

**Three actions, always:**

1. **Compact context files**
   - Agent context file reviewed against "would removing this cause a failure?" test
   - Entries not triggered in last 10 cycles are evicted
   - Spec files for completed/superseded intents are archived to cold storage

2. **Update the Agent Registry**
   - If a new agent capability was created or refined this cycle, register/version it
   - Record: `{capability_tags, avg_success_rate, avg_context_tokens, trust_level_earned}`
   - Low-performing registry entries are flagged for retraining

3. **Learning Loop** (if enabled)
   - Successful agent trajectories are exported as skill records
   - The skill library grows — next similar intent routes faster with better defaults
   - Failed trajectories are annotated and fed to the learning pipeline

**Gate:** Context files within budget. Registry updated. Learning loop triggered (async — does not block next PULSE cycle).

---

## Agent Registry

The registry is the PURE equivalent of a skill store — agents are pulled on demand, not hardcoded.

### Registry Entry Schema
```yaml
agent_id: security-scanner-v2
version: 2.1.0
capability_tags: [security, owasp, static-analysis, prompt-injection-detection]
trust_level_minimum: 1          # ATF level required to invoke
tool_permissions:
  mcp_servers: [filesystem-ro, git-ro]
  network: none
  destructive_actions: false
context_budget_tokens: 4000
avg_success_rate: 0.94
avg_latency_ms: 8200
model_preference: <model-id>              # provider-agnostic — any model
routing_notes: "Prefer for any intent with security constraint. Runs in parallel with Code Agent."
```

### Registry Query Flow
```
Orchestrator receives intent
    ↓
Extract required capability_tags from intent constraints + spec
    ↓
Query registry: SELECT agents WHERE tags ∩ required_tags ≠ ∅
    ↓
Filter by: ATF level, context budget, tool permission compatibility
    ↓
Rank by: success_rate DESC, latency ASC
    ↓
Assemble agent team → emit A2A plan
```

### Built-In Core Agents (Starter Set)

| Agent | Role | ATF Default |
|---|---|---|
| `orchestrator` | Routes intents, manages lineage | N/A |
| `spec-agent` | Generates/updates spec files from intent | 2 |
| `code-agent` | Implements code from spec | 2 |
| `test-agent` | Impact-indexed test generation | 2 |
| `security-agent` | OWASP scan, ATF verification | 2 |
| `review-agent` | Intent alignment verification | 2 |
| `deploy-agent` | CI/CD pipeline execution | 3 (human gate for prod) |
| `context-agent` | Compaction, archive, registry update | 2 |
| `learning-agent` | Trajectory export + skill registration | 3 |

---

### Agent Versioning and Release Strategy

Agents are deployable software. Without version management, a prompt or schema change silently breaks every downstream A2A contract. The registry is the version control surface for agents.

**Semantic Versioning for agents:**

```
MAJOR.MINOR.PATCH

MAJOR  breaking change to A2A input/output schema — consumers must update
MINOR  new capability added, backward-compatible output — opt-in by consumers
PATCH  prompt tuning, config change, no behavioral or schema change
```

Examples:
- `code-agent 2.1.0 → 2.1.1` — prompt refinement, same output shape (safe, auto-promote)
- `code-agent 2.1.1 → 2.2.0` — new `refactor_mode` capability added (opt-in)
- `code-agent 2.2.0 → 3.0.0` — handoff message adds required `test_hints` field (breaking)

**Registry entry — versioning fields:**
```yaml
agent_id: code-agent
version: 2.2.0
status: stable          # stable | canary | deprecated | retired
environment: prod       # dev | staging | prod
changelog:
  - version: 2.2.0
    date: 2026-05-10
    type: minor
    summary: "Added refactor_mode capability. Output schema unchanged."
  - version: 2.1.1
    date: 2026-04-28
    type: patch
    summary: "Prompt tuning: reduced hallucinated import statements by 40%."
rollback_target: 2.1.1  # auto-rollback to this version if success_rate drops
schema_ref: schemas/a2a/code-agent-output-v2.json   # pinned A2A output schema
```

**Environment tracks (dev → staging → prod):**
```
dev      ← active development, no routing from live intents
staging  ← validation against sampled real intents (shadow mode)
prod     ← live routing, versioned, monitored
```

Promotion rules:
- `dev → staging`: passes unit + contract tests, human review of changelog
- `staging → canary`: passes shadow-mode evaluation (success_rate ≥ prod baseline)
- `canary → prod`: canary success_rate stable over N intents (configurable threshold)

**Canary releases:**

Route a percentage of matching intents to the candidate version. The orchestrator splits traffic by version weight:
```yaml
routing:
  code-agent:
    prod:   { version: 2.1.1, weight: 90 }
    canary: { version: 2.2.0, weight: 10 }
  promotion_criteria:
    min_intents: 50
    min_success_rate: 0.92
    max_latency_delta_pct: 15
```

If the canary fails criteria, traffic weight returns to 0 automatically — no manual intervention.

**Automated rollback trigger:**

The orchestrator monitors `avg_success_rate` per agent version on a rolling window. If it drops below `rollback_target_threshold`, the registry immediately pins to `rollback_target` version and pages the team:
```yaml
monitoring:
  window: 20            # last N intents
  rollback_threshold: 0.80
  alert_threshold: 0.85
```

**Version pinning in specs:**

A spec may pin an agent version to guarantee reproducibility. Pinning is optional but recommended for high-stakes intents:
```yaml
# In SPEC-0051:
agent_pins:
  code-agent: "2.1.1"   # pin to exact version that generated this spec
  test-agent: "~1.4"    # compatible patch versions allowed
```

Re-running or auditing a completed intent uses the pinned versions, not the latest.

**A2A schema versioning:**

Agent output schemas are versioned independently and stored in `core/schemas/a2a/`. MAJOR agent version bumps must be accompanied by a new schema version. Downstream agents declare which schema versions they accept:
```yaml
# test-agent registry entry
accepts_input_schema:
  code-agent: ["v2", "v3"]   # accepts output from code-agent v2.x and v3.x
```

This makes breaking changes explicit and detectable before any intent runs.

**Deprecation lifecycle:**
```
stable → deprecated (changelog notice, 30-day window) → retired (removed from routing)
```
Retired agents remain in the registry as read-only historical records — specs that pinned them remain auditable.

---

## Protocol Stack

```
┌─────────────────────────────────────────────────┐
│  Intent Layer     │  YAML Intent Statements      │
├─────────────────────────────────────────────────┤
│  Spec Layer       │  Markdown spec files (≤50L)  │
├─────────────────────────────────────────────────┤
│  Orchestration    │  A2A Protocol (Linux Found.) │
├─────────────────────────────────────────────────┤
│  Tool Access      │  MCP (Linux Foundation)      │
├─────────────────────────────────────────────────┤
│  Transport        │  HTTPS/SSE · stdio (local)   │
├─────────────────────────────────────────────────┤
│  Auth             │  OAuth 2.0 · scoped tokens   │
├─────────────────────────────────────────────────┤
│  Audit            │  Immutable lineage log       │
└─────────────────────────────────────────────────┘
```

**MCP:** Provides standardized tool access (filesystem, git, CI/CD, databases, APIs). All MCP servers are registered with explicit scope — agents cannot access an MCP server not listed in their registry entry.

**A2A (formerly ACP + A2A, merged under Linux Foundation 2025):** All inter-agent messages use A2A. Message schema:
```json
{
  "message_id": "msg-uuid",
  "from": "code-agent-v3",
  "to": "test-agent-v2",
  "intent_ref": "INT-0042",
  "spec_ref": "SPEC-0042",
  "message_type": "handoff",
  "payload": { "files_changed": ["auth/reset.ts"], "summary": "..." },
  "signature": "...",
  "timestamp": "2026-05-19T14:22:00Z"
}
```

---

## Context Architecture: The Three-Tier Memory Model

Preventing bloat is architectural, not disciplinary.

```
┌──────────────────────────────────────────────────┐
│  HOT  (in-window)    │ <8k tokens                │
│  System prompt, active spec, Knowledge Block,     │
│  current task — always loaded, cache-eligible     │
├──────────────────────────────────────────────────┤
│  WARM  (indexed)     │ MCP resource retrieval    │
│  Spec files, intent archive, registry, skills     │
│  Retrieved on-demand via retrieval subagent       │
├──────────────────────────────────────────────────┤
│  COLD  (archived)    │ Vector store / blob store │
│  Historical decisions, audit log, old specs       │
│  Semantic search only — never loaded whole        │
└──────────────────────────────────────────────────┘
```

**Hard limits (enforced by context-agent):**
- Agent context file (e.g., `AGENTS.md`): ≤80 lines, ≤50% rules load per session
- Per-spec file: ≤50 lines
- Hot context at any point: ≤8k tokens (reserve for reasoning)
- Agent registry entries: ≤400 tokens each (summaries, not full docs)

**Rule for adding to the agent context file:** A new rule is only added when a real failure occurs that the rule would have prevented. No speculative rules. No rules copied from templates.

---

## Context Optimizations

### Caching — Three Layers

**Layer 1: Prefix/Prompt Cache (HOT tier)**

Every agent context window is structured in this exact order — static content first, dynamic last. This is the single highest-ROI optimization: wrong ordering drops cache hit rate from 80%+ to 0%.

```
┌─────────────────────────────────────────────┐  ← cache breakpoint A
│  STATIC: system prompt + role               │    changes: never
│  STATIC: registry metadata summary          │
├─────────────────────────────────────────────┤  ← cache breakpoint B
│  SEMI-STATIC: relevant spec(s)              │    changes: per intent
│  SEMI-STATIC: Knowledge Block (prior phase) │
├─────────────────────────────────────────────┤
│  DYNAMIC: current task + tool call results  │    changes: every turn
└─────────────────────────────────────────────┘
```

Rules:
- Never inject timestamps, request IDs, or nonces into the STATIC block
- Place provider cache breakpoints at A and B (mechanism varies by provider: explicit breakpoints, automatic prefix matching, etc.)
- Sequential agent handoffs within a PULSE cycle benefit from prefix caching automatically when the static/semi-static content is unchanged

**Layer 2: Semantic Cache (WARM tier)**

Registry queries and spec retrievals are cached by fingerprint, not just exact match:
```
cache_key = hash(sorted(capability_tags))   → cached agent team
cache_key = hash(intent_impact_zones)       → cached spec retrieval set
TTL: until registry version increments (for agent cache) or spec changes (for spec cache)
```

For registry: same capability-tag combination never re-queries the registry within a session. For specs: if two intents share >70% impact zone overlap, surface prior spec for reuse before generating new.

**Layer 3: Intent Similarity Cache (cross-session)**

At PURPOSE phase, new intents are matched against historical intents before Unify begins. Similarity above threshold skips spec generation entirely — the prior spec becomes the starting point:
```
new_intent → embed → cosine similarity vs. intent index
  if similarity > 0.85 → surface prior SPEC + PLAN for human review/reuse
  if similarity 0.6–0.85 → surface as reference, generate delta spec
  if similarity < 0.6 → generate fresh
```

This is how the system gets faster over time without requiring an explicit learning loop invocation.

---

### Indexing — Context Architecture Over RAG

The 2026 shift: **Context Architecture replaces RAG**. For agents making orders-of-magnitude more data requests than humans, runtime vector retrieval is too slow and too lossy. The knowledge layer is built at write time (compile-time), not assembled at query time.

**The hybrid retrieval stack (WARM tier retrieval subagent):**
```
query
  → semantic pre-filter (embedding similarity, fast)
  → keyword filter (exact intent_ref, capability_tags, domain)
  → cross-encoder reranker (picks Top-K)
  → retrieval subagent (judges actual relevance, returns structured excerpts)
  → structured excerpt injected into agent HOT context
```

The retrieval subagent is a registry entry like any other — swappable without touching the orchestrator.

**Separate indices by artifact type** — never one monolithic vector store:

| Index | Contents | Access Pattern |
|---|---|---|
| Intent index | All intent statements | Similarity search at PURPOSE phase |
| Spec index | Spec files + acceptance criteria | Retrieval at UNIFY + SHIELD |
| Skill index | Skill library entries | Retrieval at registry query time |
| Audit index | Lineage log entries | Compliance queries only |

**At EVOLVE phase**, the `context-agent` re-indexes any new/updated artifacts. Indexing is a write-time operation — agents never trigger re-indexing mid-task.

---

### Session Management — The Sawtooth Pattern

Context grows monotonically unless you actively collapse it. The Sawtooth Pattern prevents drift by compacting at every phase gate:

```
context
tokens  │         ╱╲              ╱╲
        │        ╱  ╲            ╱  ╲
        │       ╱    ╲──────────╱    ╲──
        │      ╱   checkpoint     checkpoint
        │─────╱
        └────────────────────────────────── time
               PURPOSE  UNIFY  LAUNCH  SHIELD  EVOLVE
```

At each phase gate, the active agent writes a **Knowledge Block** — a structured summary of what was decided — then clears its working log:

```yaml
knowledge_block:
  intent_ref: INT-0042
  session_id: sess-20260519-001
  phase_completed: LAUNCH
  decisions:
    - "bcrypt hash for token storage — not plaintext SHA"
    - "15-min TTL per NIST SP 800-63B"
  files_changed: [auth/reset.ts, db/tokens.ts]
  open_questions:
    - "Rate limiting strategy not yet decided — Test Agent to flag"
  next_phase_context: "Impact zones for Test Agent: auth/reset.ts, db/tokens.ts, notification/email.ts"
```

The Knowledge Block lives in the SEMI-STATIC cache slot — it's cache-eligible and passed to the next agent as a clean starting point.

**Git-like context versioning** at phase boundaries:

| Git Op | PURE Equivalent |
|---|---|
| `COMMIT` | Phase gate — Knowledge Block written, working log cleared |
| `BRANCH` | Sub-agent spawned for exploratory/parallel work |
| `MERGE` | Sub-agent output folded back into orchestrator context via A2A handoff |
| `CHECKOUT` | Resume a paused session from a prior phase checkpoint |

**Session lifecycle:**
```
session_start
  → hot-load: prior Knowledge Block (if resuming) + intent + scoped spec
  → execute phase (turn budget: soft limit, triggers mid-phase compaction at 80%)
  → checkpoint: write Knowledge Block → WARM, clear working log
  → if all phases done: session_end → trigger EVOLVE
  → if interrupted: session_pause → fully resumable from last checkpoint
```

**Session inheritance for multi-intent workflows:** when Intent B depends on Intent A, session B hot-loads Knowledge Block A into its SEMI-STATIC slot. The Test Agent reuses A's impact zones rather than re-running change-graph analysis.

**Provider compaction** (API-level summarization where supported) can be used at phase gates for low-complexity phases when manual Knowledge Block generation isn't needed. Manual Knowledge Blocks are preferred for HIGH-complexity phases — they encode reasoning, not just content.

---

## Persistence Architecture

PURE uses three complementary persistence technologies — embeddings, knowledge graph, and relational/document stores — each doing the job it is best suited for. None is a replacement for the others. Together they form the storage backbone of the WARM and COLD memory tiers.

```
┌──────────────────────────────────────────────────────────────────┐
│  Query type                 │ Technology       │ Use in PURE      │
├──────────────────────────────────────────────────────────────────┤
│  Semantic similarity (80%)  │ Embeddings +     │ Intent matching, │
│                             │ vector index     │ spec/skill search│
├──────────────────────────────────────────────────────────────────┤
│  Relationship / dependency  │ Knowledge graph  │ Impact analysis, │
│  (15%)                      │                  │ A2A routing,     │
│                             │                  │ lineage tracing  │
├──────────────────────────────────────────────────────────────────┤
│  Structured / exact (5%)    │ Relational /     │ Registry, audit  │
│                             │ document store   │ log, spec index  │
└──────────────────────────────────────────────────────────────────┘
```

The **Intelligent Hybrid Router** — a lightweight retrieval subagent — classifies each query and dispatches it to the appropriate tier. This keeps each store operating in its strength zone and avoids the accuracy degradation that comes from using vector search for relationship queries or graph traversal for similarity search.

---

### Embeddings and Vector Search

**Role:** semantic similarity — finding things that *mean the same thing* even when worded differently.

**Where PURE uses it:**

| Query | Phase | Returns |
|---|---|---|
| "Find intents similar to INT-0053" | PURPOSE | Prior intents for similarity cache |
| "Find specs relevant to auth + rate-limiting" | UNIFY | Candidate specs to reuse or reference |
| "Find skills matching Redis sliding window" | LAUNCH | Skills from `skills/` library |
| "Find historical decisions about token TTL" | Any | Excerpts from COLD archive |

**What to embed:**

- Intent `statement` + `outcome` fields (not the full YAML — extract the semantic core)
- Spec `## Behavior` sections
- Skill `success_criteria` and `example_io` summaries
- Knowledge Block `decisions` list (not the full block)

**What NOT to embed:** full YAML/JSON files, audit log entries, registry entries — these are structured and better served by exact lookup.

**Implementation note:** embeddings are computed at write time (EVOLVE phase) and stored alongside the artifact in the WARM tier. The retrieval subagent queries the vector index, reranks by metadata filters (domain, status, date), and returns structured excerpts — never raw documents.

---

### Knowledge Graph

**Role:** relationship and dependency reasoning — finding things that are *connected* in ways that matter for agent coordination.

**Why graph improves A2A consistency and accuracy:**

A shared knowledge graph gives every agent the same world model. When the code-agent and the test-agent both query "what does `auth/reset.ts` depend on?", they get identical answers from the graph — not independent, potentially divergent answers from their own context. This is the consistency guarantee vector search cannot provide.

For multi-hop queries — which account for the accuracy gap (up to 3.4× improvement over pure vector) — graph traversal is the correct tool:
- "Which specs depend on SPEC-0031?" (transitive dependency chain)
- "Which intents were affected by changing `infra/redis.ts`?" (reverse impact)
- "Which agent combinations have a high success rate for security + async intents?" (agent affinity graph)

**Four graphs PURE maintains:**

**1. Codebase graph** — nodes: files, functions, classes; edges: imports, calls, modifies, tests
- Built/updated by code-agent and test-agent during LAUNCH
- Primary input for the Test Agent's change-graph impact analysis (SHIELD)
- Enables impact zone calculation without loading files into context

**2. Intent dependency graph** — nodes: intents and specs; edges: depends-on, supersedes, spawned-from, out-of-scope-of
- Built incrementally across PULSE cycles
- Enables conflict detection at PURPOSE phase: "does INT-0053 contradict an open intent?"
- Enables cascade detection: "closing INT-0031 — which open intents depend on it?"

**3. Agent capability graph** — nodes: agents and capability tags; edges: provides, requires, works-well-with, output-feeds-into
- Built from registry entries and enriched by Learning Engine trajectory data
- Primary input for registry routing: "which agent combinations succeed for this capability profile?"
- Separates *what an agent claims to do* (registry entry) from *what it demonstrably does* (trajectory edge weights)

**4. Lineage graph** — nodes: intents, specs, agents, actions, outputs; edges: produced, consumed, approved-by, rolled-back-by
- Append-only; forms the immutable audit trail
- Enables compliance queries: "trace all actions that touched PII fields in the last 30 days"
- Enables root cause: "which agent decision chain led to this production incident?"

**A2A schema validation via graph:**

Before emitting an A2A message, the orchestrator checks the lineage graph for schema compatibility:
```
sender agent version → declared output schema version
receiver agent → accepted input schema versions
→ if incompatible: block handoff, surface version conflict to human
```

This makes schema drift a caught error, not a silent failure.

**What to use for graph storage:** any property graph database (or a lightweight in-process graph for Tier 1) that supports labeled edges with weights and timestamps. The specific technology is an implementation choice — the four graph types and their query patterns are the methodology contract.

---

### Relational / Document Store

**Role:** structured exact lookup — registry entries, spec metadata, audit log records, session state.

**Where PURE uses it:**

| Data | Access Pattern |
|---|---|
| Registry entries | Exact lookup by `agent_id`, filtered by `status`, `environment` |
| Intent / spec index | Exact lookup by `id`, filtered by `status`, `domain` |
| Audit log | Append-only, queried by `intent_ref`, `agent_id`, time range |
| Session state / Knowledge Blocks | Lookup by `session_id`, `intent_ref` |
| A2A message log | Lookup by `message_id`, `intent_ref`, `from`/`to` |

This store is the source of truth for structured metadata. It does not do semantic search — that belongs to the embedding index.

---

### The Hybrid Router (Retrieval Subagent)

The retrieval subagent is a registry entry like any other. Its job is to classify each incoming query and dispatch to the right store, returning structured excerpts to the calling agent:

```
incoming query + query_type hint
    ↓
classify: semantic | relational | graph | multi-hop
    ↓
semantic  → embedding index → top-K → rerank → excerpts
relational→ document store  → exact match → record
graph     → graph traversal → path/subgraph → summary
multi-hop → graph + embedding fusion → ranked results
    ↓
return: structured excerpts with source refs (never raw documents)
```

**Query type hints** are set by the calling agent in its retrieval request — the router uses them to skip classification overhead for known query types (e.g., the orchestrator always uses `relational` for registry lookups, always uses `graph` for impact analysis).

---

## Repo Architecture — Capability-Scoped Pattern

Neither pure micro-repo nor pure monorepo is optimal for PURE. Both extremes have agentic failure modes:
- **Monorepo**: a misunderstanding in one agent cascades across all services; orchestrator context becomes unmanageably large
- **Micro-repo per service**: no shared vocabulary, no atomic cross-capability changes, orchestrator loses dependency visibility

The **Capability-Scoped** pattern gives isolation where it matters (agent blast radius) and unity where it matters (shared contracts, cross-agent visibility):

```
pure-project/
├── core/                        ← shared vocabulary — all agents read, none own
│   ├── schemas/                 │  A2A message types, intent/spec YAML schemas
│   └── protocols/               │  ATF level definitions, MCP scope manifests
│
├── agents/                      ← one folder per agent (isolated blast radius)
│   ├── code-agent/              │  system prompt, skills/, tool-manifest.yaml,
│   ├── test-agent/              │  AGENTS.md (agent-local, ≤80 lines), tests/
│   ├── security-agent/          │
│   └── .../                     │
│
├── registry/
│   └── registry.yaml            ← version-controlled, signed entries at Tier 3
│
├── specs/                       ← indexed MCP resource, never loaded whole
│   └── {domain}/{SPEC-xxxx}.md  │
│
├── intents/
│   └── {INT-xxxx}.yaml          ← immutable once approved, append-only
│
├── skills/                      ← skill library (grows via EVOLVE)
│   └── {skill-name}/            │  prompt, examples, tool-manifest, success criteria
│
└── infra/
    ├── mcp-servers/             ← MCP server configs + scope definitions
    └── orchestrator/            ← orchestrator config, session state store
```

**Worktrees during LAUNCH** — agents work in parallel without stepping on each other:
```bash
# Orchestrator creates isolated worktrees per agent at LAUNCH start
git worktree add .worktrees/code-agent-INT-0042   feature/INT-0042-code
git worktree add .worktrees/test-agent-INT-0042   feature/INT-0042-tests

# Agents execute in isolation — no mid-flight collisions
# At SHIELD gate: orchestrator merges via A2A-coordinated PR
git worktree remove .worktrees/code-agent-INT-0042
```

**Synthetic monorepo view for the orchestrator:** tooling (Nx, Turborepo, or a dedicated MCP tool) builds a unified dependency graph over all `agents/` and `core/` folders. The orchestrator reasons about cross-agent impact using this graph — without loading every file into context.

**Agent-local AGENTS.md:** each `agents/{name}/` folder has its own ≤80-line AGENTS.md. This is loaded only when that agent is invoked — never into the orchestrator's context. Agent-specific rules stay agent-scoped.

**Adoption by tier:**

| Tier | Repo Shape |
|---|---|
| Tier 1 (Solo) | Single repo, all folders present, no worktrees yet |
| Tier 2 (Team) | Worktrees during LAUNCH, shared skill library, registry in CI |
| Tier 3 (Enterprise) | Signed registry, synthetic monorepo view, per-agent audit scope |

---

## Learning Engine

The Learning Engine is PURE's evolutionary backbone. It is not a specific tool — it is a pattern that any capable agent harness or custom implementation can satisfy. The interface contract matters; the implementation does not.

**What a Learning Engine must provide:**

- **Persistent skill library:** Successful agent trajectories are compiled into reusable skills. A skill is a folder of: system prompt excerpt, example I/O pairs, tool manifest, success criteria. Skills accumulate in `skills/` and are retrieved via the WARM index.
- **Self-improving routing:** The registry records which agents succeed on which intent and capability-tag patterns. Over time, routing gets faster and more accurate without manual tuning.
- **Trajectory capture:** Every agent execution produces a trajectory record (input context, actions taken, output, outcome). Trajectories are the raw material for both skill compilation and fine-tuning.
- **Parallel execution** (optional, Tier 2+): For high-value intent types, N parallel agent executions are run and the best is selected — automatic few-shot calibration.
- **Fine-tuning export** (optional, Tier 3): Trajectories are exportable for RL/SFT against team-specific conventions and domain knowledge.
- **Pluggable memory providers:** Connects to the three-tier memory model (HOT/WARM/COLD) via whatever storage backend the deployment uses.

**Implementation options** — all satisfy the contract:
- A lightweight custom script that writes trajectory YAML files and indexes them
- An open-source agent framework with built-in memory and skill management
- A team-built microservice fronted by an MCP tool
- A managed service — provided it respects data locality and audit requirements

**Data governance:** Trajectory data contains code, decisions, and potentially sensitive context. The Learning Engine must respect the same ATF data-scope constraints as any other agent — write access to `skills/` requires ATF Level 3 or higher.

---

## Security Reference: PURE Agent Trust Ladder

```
                    ┌─────────────────────┐
ATF Level 4         │   AUTONOMOUS        │  prod deployments auto-approved
(earned, rare)      │   human gate only   │  requires 6-month track record
                    │   for irreversible  │  + security audit
                    └─────────────────────┘
                    ┌─────────────────────┐
ATF Level 3         │   COLLABORATIVE     │  most prod-adjacent tasks
(default team)      │   destructive ops   │  unlocked after 50 successful
                    │   gated             │  Level 2 cycles, no incidents
                    └─────────────────────┘
                    ┌─────────────────────┐
ATF Level 2         │   ASSISTED          │  ← default starting level
(default)           │   high-risk gated   │  low-risk actions auto-approved
                    │   rest autonomous   │  standard for all new agents
                    └─────────────────────┘
                    ┌─────────────────────┐
ATF Level 1         │   SUPERVISED        │  every action requires approval
(new/untrusted)     │   all gated         │  use for unvetted agents,
                    │                     │  unfamiliar codebases
                    └─────────────────────┘
```

**Prompt Injection Defense (structural, not prompt-based):**
- User/external input is never passed raw to a system-level agent
- All inter-agent data passes through typed A2A message schemas — free-text fields are sandboxed
- Intent statements are human-authored or human-approved before entering the agent pipeline
- Code execution agents use sandboxed runtimes; no shell commands derived from LLM output without schema validation

---

## Adoption Path (KISS)

Three tiers — start at Tier 1, graduate only when the pain of the next tier is worth the gain.

### Tier 1: Solo / Starter (Day 1 viable)
- 1 Orchestrator agent (any agent harness: local, hosted, or CLI-based)
- Local agent registry (YAML file, 3 agents: code, test, security)
- MCP: filesystem + git
- A2A: local message passing (JSON files or stdio)
- PULSE cycle: manual phase gates
- Context: AGENTS.md (≤80 lines) + `/specs/` directory
- ATF: Level 2 for all agents

### Tier 2: Team (Week 2–4)
- Shared agent registry (MCP Gateway + Registry, e.g., agentic-community/mcp-gateway-registry)
- MCP: filesystem, git, CI/CD, notifications
- A2A: HTTP/SSE message bus
- Learning engine: shared server (any implementation), team skill library
- PULSE cycle: automated gates, human gates for deploy only
- Context: per-project AGENTS.md + indexed spec store
- ATF: Level 2 default, Level 3 unlockable per agent

### Tier 3: Enterprise (Month 2+)
- Registry with governance: signed entries, version pinning, audit trail
- Full ATF Level 4 capability for vetted agents
- Learning engine: fine-tuning pipeline, parallel trajectory generation
- Lineage: immutable log to compliance-grade store (SOC2/HIPAA ready)
- PULSE cycle: fully automated through ATF Level 3; Level 4 gates are exception-based
- Context: three-tier memory with vector search (cold tier)
- Security: full OWASP Agentic Top 10 control mapping, automated red-team agent

**Adoption cadence (weeks → months → quarters):**
- 3 weeks: working prototype with Tier 1 PURE
- 3 months: team on Tier 2 with skill library accumulating
- 3 quarters: Tier 3 with measurable routing improvement from learning loop

---

## Golden Paths

Three end-to-end walkthroughs showing PURE in action. Each artifact is a real example of what agents and humans produce at each phase. Use these as templates and orientation guides.

**Quick index:**
- [Path A](#golden-path-a-new-feature--full-pulse-cycle) — New feature, full PULSE cycle, all artifacts shown
- [Path B](#golden-path-b-bug-fix--abbreviated-pulse) — Bug fix, abbreviated cycle, skill reuse in action
- [Path C](#golden-path-c-agent-orientation--pulling-pure-into-context) — Agent receiving this methodology, self-orienting and executing

---

### Golden Path A: New Feature — Full PULSE Cycle

**Scenario:** The public search API can be abused to scrape data. Rate limiting is needed without breaking authenticated users.

---

#### ① PURPOSE

Human writes the intent statement:

```yaml
intent:
  id: INT-0051
  statement: "Public search API is rate-limited to prevent scraping and protect database load"
  outcome: "Abuse incidents drop to zero; p99 latency unaffected under normal load"
  constraints:
    - "Authenticated users must not be affected (separate limits for auth vs. anon)"
    - "Redis already in stack — prefer Redis-based implementation"
    - "No changes to public API contract"
  out_of_scope:
    - "IP-based bans or blocklists"
    - "Search result caching"
  priority: high
  approved_by: human
  approved_at: 2026-05-19T09:00:00Z
```

Gate check: ✓ One intent, one deliverable. Human approved. UNIFY begins.

---

#### ② UNIFY

**Registry query (orchestrator):**
```
required tags: [code, api, middleware, redis, test, security]
result:        code-agent-v3, test-agent-v2, security-agent-v2
execution:     sequential (code → test) + parallel (security alongside test)
```

**Intent similarity check before spec generation:**
```
embed(INT-0051) → cosine vs. intent index
closest: INT-0039 "Auth token throttling" → similarity: 0.58
→ below 0.60 threshold: generate fresh spec (surface INT-0039 as context reference only)
```

**Generated spec (`specs/api/SPEC-0051.md`):**
```markdown
# SPEC-0051: Public Search Rate Limiting
intent_ref: INT-0051
status: active
domain: api/search
prior_art: SPEC-0039 (auth throttling — same Redis client pattern)

## Behavior
- Anonymous callers: 60 req/min per IP (sliding window)
- Authenticated callers: 600 req/min per token
- Redis sliding window via existing infra/redis.ts client
- Response headers on every request: X-RateLimit-Limit, X-RateLimit-Remaining, X-RateLimit-Reset
- Exceeded: HTTP 429, Retry-After header, body: "rate limit exceeded" only

## Acceptance Criteria
- [ ] Anonymous caller blocked at 61st request within any 60s window
- [ ] Authenticated caller not blocked under 600 req/min
- [ ] 429 includes Retry-After; no stack trace or internal detail leaked
- [ ] 200 response shape unchanged for in-limit requests
- [ ] Rate limit state survives single Redis node restart (persistence ON)

## Impact Zones
- middleware/rate-limit.ts (new · HIGH)
- api/search/handler.ts (modified · HIGH)
- infra/redis.ts (dependency, unmodified · MEDIUM)
- Upstream: auth middleware  ·  Downstream: search service

## Out of Scope
- IP ban lists · Search caching
```

**Plan:**
```
PLAN-0051
  1. code-agent-v3    → create middleware/rate-limit.ts, wire into api/search/handler.ts
  2. test-agent-v2    → impact-indexed tests (starts after step 1 completes)
  3. security-agent-v2→ OWASP scan + prompt injection probe (parallel with step 2)
  4. review-agent     → intent alignment check
  5. deploy-agent     → stage pipeline (human gate required before prod)
```

Gate check: ✓ Spec reviewed and accepted by human. LAUNCH begins.

---

#### ③ LAUNCH

**Orchestrator context window sent to code-agent-v3:**
```
[STATIC — cache breakpoint A]           ← never changes across sessions
  You are code-agent-v3. Implement exactly what the spec describes.
  Do not add features, helpers, or error handling beyond spec scope.
  Write no comments unless the WHY is non-obvious.
  registry_summary: 3 agents active for INT-0051 ...

[SEMI-STATIC — cache breakpoint B]      ← changes per intent, stable per session
  spec: SPEC-0051 (42 lines, full text)
  knowledge_block: null                  ← first phase, fresh start

[DYNAMIC]                               ← changes every turn, never cached
  task: "Implement middleware/rate-limit.ts and wire into api/search/handler.ts
         per SPEC-0051. Use infra/redis.ts. Do not modify the public API contract.
         Report all files changed in your handoff message."
```

**code-agent-v3 produces:**
- `middleware/rate-limit.ts` — Redis sliding window, anon/auth branching, header injection, 429 response
- `api/search/handler.ts` — rate-limit middleware applied pre-handler, no contract changes

**A2A handoff to test-agent-v2:**
```json
{
  "message_id": "msg-0051-code-01",
  "from": "code-agent-v3",
  "to": "test-agent-v2",
  "intent_ref": "INT-0051",
  "spec_ref": "SPEC-0051",
  "message_type": "handoff",
  "payload": {
    "files_changed": ["middleware/rate-limit.ts", "api/search/handler.ts"],
    "files_read":    ["infra/redis.ts", "api/search/handler.ts"],
    "summary": "Sliding window rate limiter implemented. Anon: 60/min keyed by IP, Auth: 600/min keyed by token. Headers: X-RateLimit-Limit/Remaining/Reset. 429 returns Retry-After only.",
    "open_items": ["Redis persistence assumed ON — test-agent should verify behavior under restart"]
  },
  "signature": "sha256:...",
  "timestamp": "2026-05-19T09:14:22Z"
}
```

**Knowledge Block written at LAUNCH gate:**
```yaml
knowledge_block:
  intent_ref: INT-0051
  session_id: sess-20260519-002
  phase_completed: LAUNCH
  decisions:
    - "Sliding window over fixed window — more accurate under burst traffic"
    - "Redis key pattern: rate:{ip}:{window_start} for anon, rate:{token_id}:{window_start} for auth"
    - "Redis persistence assumed ON — flagged for test-agent"
  files_changed: [middleware/rate-limit.ts, api/search/handler.ts]
  open_questions:
    - "Redis persistence behavior under restart needs test coverage"
  next_phase_context: |
    Impact zones for test-agent:
      HIGH:   middleware/rate-limit.ts, api/search/handler.ts
      MEDIUM: infra/redis.ts (unmodified dependency)
```

*Working log cleared. Cache reloads SEMI-STATIC slot with this Knowledge Block for test-agent-v2.*

---

#### ④ SHIELD

**test-agent-v2 change graph (from Knowledge Block):**
```
middleware/rate-limit.ts   → HIGH  (new file, all logic here)
api/search/handler.ts      → HIGH  (integration point)
infra/redis.ts             → MEDIUM (unmodified, but dependency)
```

**Test budget:** 1.5× LOC changed in new test lines. code-agent wrote ~90 LOC → budget: 135 test lines.

**Tests generated (`middleware/rate-limit.test.ts`, `api/search/handler.test.ts`):**
```
HIGH tier — middleware/rate-limit.test.ts:
  unit:
    → anon: 60th request passes, 61st returns 429 + Retry-After header
    → auth: 600th request passes, 601st returns 429
    → window reset: after 60s elapsed (time-mocked), counter resets and requests pass again
    → header values: X-RateLimit-Remaining decrements 60→59→...→0 correctly
    → 429 body: only "rate limit exceeded" — no stack trace, no IP disclosure
  integration (real Redis):
    → state survives Redis restart (persistence ON verified)
  property-based:
    → for any N ≤ limit: all N requests in window return 2xx
    → for any N > limit: exactly (N - limit) requests return 429

HIGH tier — api/search/handler.test.ts:
  → middleware applied before handler (order assertion)
  → 200 response shape unchanged for in-limit requests (contract test)
  mutation probe:
    → remove rate-limit wiring → 429 never returned (catches missing wire-up)

MEDIUM tier — infra/redis.ts:
  → no new tests added (existing coverage sufficient, unmodified file)

Budget used: 118 test lines / 135 budget (88%) ✓
```

**security-agent-v2 findings:**
```
CRITICAL: 0
HIGH:      0
MEDIUM:    1
  → Redis rate-limit key uses raw X-Forwarded-For header.
    Spoofable in non-proxied deployments.
    Fix: normalize IP via trusted-proxy middleware before rate-limit key construction.
    Blocking for prod; acceptable for stage.
LOW:       2  (noted in audit log, not blocking)

Prompt injection scan: N/A — no user input reaches agent pipeline
OWASP Agentic Top 10: passed
```

**Knowledge Block written at SHIELD gate:**
```yaml
knowledge_block:
  intent_ref: INT-0051
  session_id: sess-20260519-002
  phase_completed: SHIELD
  decisions:
    - "All HIGH-tier tests pass"
    - "Redis persistence under restart: confirmed via integration test"
    - "X-Forwarded-For spoofing: MEDIUM finding — must resolve before prod gate"
  security_findings:
    open:
      - "MEDIUM: add trusted-proxy IP normalization before rate-limit key — blocks prod deploy"
  test_count_added: 9
  test_budget_used: "118/135 lines (88% of cap)"
  next_phase_context: |
    deploy-agent: stage pipeline approved.
    Prod gate blocked until trusted-proxy fix merged (spawns INT-0054).
```

---

#### ⑤ EVOLVE

**context-agent runs:**

```
1. Compact
   SPEC-0051 → WARM index (active, completed)
   INT-0051  → intent index (closed, archived)
   Knowledge Blocks (LAUNCH + SHIELD) → compacted to single session summary → COLD

2. Registry update
   code-agent-v3:    success_rate: 0.94 → 0.945 (1 cycle added)
   test-agent-v2:    budget_compliance: 88% this cycle (within cap)
   security-agent-v2: MEDIUM finding surfaced correctly

3. Skill registration
   New skill: skills/redis-sliding-window-rate-limit/
     system_prompt_excerpt: "Apply Redis sliding window..."
     example_io: [rate-limit.ts before/after]
     tool_manifest: [infra/redis.ts usage pattern]
     success_criteria: "429 on N+1, headers correct, persistence verified"

4. Intent spawned
   INT-0054: "Trusted-proxy IP normalization for rate-limit key"
   (auto-created from SHIELD open finding, human approval required before UNIFY)

5. AGENTS.md: unchanged (no new failure-driven rules this cycle)
```

**Net result:** INT-0051 delivered. Stage deployed. One follow-on intent queued. Skill library richer for next rate-limiting scenario.

---

### Golden Path B: Bug Fix — Abbreviated PULSE

**Scenario:** Users report duplicate notifications under concurrent load. Data race in the dispatch loop suspected.

---

#### ① PURPOSE

```yaml
intent:
  id: INT-0052
  statement: "Notification dispatch loop sends each notification exactly once under concurrent load"
  outcome: "Zero duplicate notification reports in next release"
  constraints:
    - "Fix must not reduce dispatch throughput by more than 5%"
  out_of_scope:
    - "Notification content or delivery SLA changes"
  priority: high
```

**Intent similarity check:**
```
embed(INT-0052) → cosine vs. intent index
closest: INT-0031 "Email deduplication for marketing sends" → similarity: 0.61
→ 0.60–0.85 band: surface SPEC-0031 as reference, generate delta spec
```

Spec Agent inspects SPEC-0031 and finds the distributed lock pattern used there. That pattern is already in `skills/redis-distributed-lock` from INT-0031's EVOLVE. It becomes the foundation for SPEC-0052.

---

#### ② UNIFY

```markdown
# SPEC-0052: Notification Dispatch Deduplication
intent_ref: INT-0052
status: active
domain: notifications
prior_art: SPEC-0031 (distributed lock pattern — reused from skills/redis-distributed-lock)

## Behavior
- Dispatch loop acquires distributed lock (Redis) before processing each notification
- Lock TTL: 30s (exceeds max observed dispatch time of 8s)
- Idempotency key: notification_id (UUID, guaranteed unique by producer)
- Duplicate dispatch attempts: silently dropped, not errored

## Acceptance Criteria
- [ ] Under 10 concurrent workers, each notification dispatched exactly once
- [ ] Throughput degradation < 5% (benchmark: 1000 notifications, 10 workers)
- [ ] Lock expiry handled gracefully — no orphaned locks, no lost notifications

## Impact Zones
- notifications/dispatcher.ts (HIGH · modified)
- infra/redis.ts (MEDIUM · dependency, unmodified)
```

**Plan (abbreviated — skill reuse reduces scope):**
```
PLAN-0052
  1. code-agent-v3    → apply skills/redis-distributed-lock to notifications/dispatcher.ts
  2. test-agent-v2    → property test: N concurrent workers, exactly-once dispatch
  3. security-agent-v2→ fast scan (no new attack surface; lock pattern already vetted in INT-0031)
```

---

#### ③–④ LAUNCH + SHIELD (combined session)

This intent is small enough that LAUNCH and SHIELD run in a single abbreviated session. The orchestrator declares combined phase in the Knowledge Block.

**code-agent-v3** loads `skills/redis-distributed-lock` directly. No re-implementation — the skill provides the system prompt, Redis usage pattern, and TTL guidance. Change is surgical: ~35 lines in `notifications/dispatcher.ts`.

**test-agent-v2 change graph:**
```
notifications/dispatcher.ts → HIGH (35 LOC changed)
Test budget: 52 lines
```

**Tests generated:**
```
property test:
  → for N in [1..10] concurrent workers dispatching same notification_id:
     exactly 1 dispatch occurs, N-1 are silently dropped
throughput benchmark:
  → 1000 notifications, 10 workers: verify < 5% throughput degradation
lock expiry:
  → force TTL expiry mid-dispatch: notification completes or retries, never lost
```

**security-agent-v2:** fast scan, no new findings (distributed lock pattern previously vetted).

**Combined Knowledge Block:**
```yaml
knowledge_block:
  intent_ref: INT-0052
  session_id: sess-20260519-003
  phase_completed: SHIELD
  decisions:
    - "skills/redis-distributed-lock applied directly — 35 LOC change, no re-implementation"
    - "Idempotency key: notification_id (UUID, producer-guaranteed unique)"
    - "Throughput degradation: 0.8% — well within 5% constraint"
  test_count_added: 3
  test_budget_used: "41/52 lines (79% of cap)"
  security_findings: []
```

**What this path demonstrates:**
- The skill library from Path A's EVOLVE phase directly shortened this cycle
- Intent similarity (0.61) surfaced a reference without forcing a full match — the delta spec captured only what was different
- LAUNCH + SHIELD combined because scope was small and security scan was fast-path (known pattern)

---

### Golden Path C: Agent Orientation — Pulling PURE Into Context

**Scenario:** An agent is invoked on a PURE-governed project with:
*"You are working on a PURE-governed project. Here is the methodology. INT-0053 has been approved. Begin."*

This path shows the exact initialization sequence an agent should run before touching any file.

---

#### Step 1 — Read and orient (before any tool use)

Agent reads this document and answers four questions:

```
1. What is my role?
   → Check registry.yaml for my agent_id.
   → If not listed: I am the orchestrator by default (Tier 1 / solo mode).

2. What phase is active?
   → INT-0053 is approved → PURPOSE gate passed.
   → Look for PLAN-0053 in WARM store.
   → If found: UNIFY is complete, determine which phase Knowledge Block is most recent.
   → If not found: UNIFY has not started — I begin there.

3. Is there a prior session to resume?
   → Look for sessions/INT-0053-*.yaml in WARM store (Knowledge Blocks).
   → If found: hot-load the latest into SEMI-STATIC slot (resuming).
   → If not found: fresh start, no prior Knowledge Block.

4. What is my context budget?
   → HOT: ≤8k tokens total
   → SEMI-STATIC slot: intent + spec + Knowledge Block (retrieve only SPEC-0053, not all specs)
   → STATIC slot: my system prompt + registry summary (≤400 tokens for registry)
```

---

#### Step 2 — Build context window before first LLM call

```
[STATIC — cache breakpoint A]
  <system prompt: role, constraints, PURE rules summary>
  <registry summary: 3-line summary of active agents and their tags>
  ← NEVER include: timestamps, session IDs, request nonces here

[SEMI-STATIC — cache breakpoint B]
  <intents/INT-0053.yaml — full text>
  <specs/domain/SPEC-0053.md — if UNIFY already done; omit if not>
  <sessions/INT-0053-latest.yaml — Knowledge Block; omit if fresh start>
  ← retrieve via MCP, do not concatenate entire specs/ directory

[DYNAMIC]
  <current task description>
  <tool call results — appended here as session progresses>
```

---

#### Step 3 — Run UNIFY (if not done)

```
a. Query registry:
   → read registry/registry.yaml
   → extract capability_tags from INT-0053 constraints
   → assemble agent team (or note: Tier 1 = I am all agents)

b. Check intent similarity:
   → query intent index: embed(INT-0053) → Top-3 similar intents
   → if similarity > 0.60: load matching spec as reference before generating

c. Generate SPEC-0053:
   → follow spec format: ≤50 lines, Behavior + Acceptance Criteria + Impact Zones + Out of Scope
   → write to specs/{domain}/SPEC-0053.md via MCP filesystem tool

d. Write PLAN-0053 to WARM store (plain text or YAML, orchestrator-readable)
```

---

#### Step 4 — Emit first A2A task (or self-assign in Tier 1)

```json
{
  "message_type": "task_assignment",
  "from": "orchestrator",
  "to": "code-agent-v3",
  "intent_ref": "INT-0053",
  "spec_ref": "SPEC-0053",
  "context_to_load": {
    "static":      ["system-prompt", "registry-summary"],
    "semi_static": ["SPEC-0053", "knowledge_block_null"]
  },
  "task": "Implement per SPEC-0053 acceptance criteria. Report all files changed in handoff message."
}
```

---

#### What an agent must NEVER do in a PURE context

These are the most common failure modes. Each one has a stated reason — agents should enforce them structurally, not just follow them as rules:

| Never do this | Why |
|---|---|
| Load the full `specs/` directory into context | Context bloat — retrieve only the relevant spec via MCP |
| Add a rule to AGENTS.md without a real failure | Speculative rules reduce task success rate; human-curated files only |
| Proceed past a phase gate without writing a Knowledge Block | Next agent has no clean starting point; context drift begins |
| Pass raw user input to a downstream agent | Prompt injection vector — always pass through typed A2A schema fields |
| Generate tests beyond the 1.5× LOC budget | Test bloat degrades CI speed and future agent context |
| Treat a missing Knowledge Block as an error | Missing block = fresh start; it is expected on first run |
| Inject a timestamp or nonce into the STATIC cache slot | Breaks prefix caching; cache hit rate drops to zero |
| Start implementing before checking the intent similarity index | Wastes cycles; a prior spec may be 85%+ reusable |
| Spawn sub-agents without orchestrator approval | ATF violation — privilege escalation risk |
| Write to `core/` without human review | Shared vocabulary; unilateral changes break all agents |

---

#### Quick self-check before any write operation

Before writing any file, an agent running in a PURE context should answer:

```
1. Does this write trace back to the active intent_ref?
   → If no: stop, surface as out-of-scope to orchestrator.

2. Is this file in my declared Impact Zones?
   → If no: flag as scope creep, await orchestrator approval.

3. Will this write exceed the spec's stated behavior?
   → If yes: stop, do not add unrequested features.

4. Have I written a Knowledge Block for the completed phase?
   → If a gate was crossed without a block: write the block now.

5. Is my context window still within budget (≤8k HOT tokens)?
   → If approaching limit: compact now, do not wait for overflow.
```

## What PURE Is Not

- **Not a replacement for engineering judgment.** The human approves intents, reviews security gates, and curates the registry. The methodology accelerates the work, not the decision authority.
- **Not a spec generator.** Specs are a byproduct of intent — if you're writing specs for their own sake, you've drifted.
- **Not a test maximizer.** If your test count is growing faster than your risk surface, the context-agent should be archiving, not the dev adding more.
- **Not lock-in.** MCP and A2A are open standards under the Linux Foundation. No specific AI provider, model, harness, or tool is required. The registry is a YAML file at Tier 1.

---

## Quick Reference Card

```
PULSE Phase     │ Key Output             │ Anti-Bloat Control
────────────────┼────────────────────────┼─────────────────────────────────
① PURPOSE       │ Intent Statement       │ 1 intent = 1 deliverable
                │                        │ Similarity check → reuse prior spec
② UNIFY         │ Spec (≤50L) + Plan     │ Spec indexed, not concatenated
③ LAUNCH        │ Code + agent outputs   │ Scoped context + worktrees per agent
④ SHIELD        │ Tests + security       │ Impact-indexed, test budget cap
⑤ EVOLVE        │ Compacted context      │ Evict rules not triggered in 10×
                │ + registry update      │ Re-index new artifacts
                │ + learned skills       │

Protocol        │ Role
────────────────┼──────────────────────────────────────────────────────
MCP             │ Tool access (filesystem, git, CI, DBs, APIs)
A2A             │ Agent-to-agent communication + handoffs
ATF             │ Agent trust / privilege ladder
OWASP Top 10   │ Security control checklist per phase

Memory Tier     │ Storage              │ Access Pattern
────────────────┼──────────────────────┼──────────────────────────────
HOT             │ In-window (≤8k tok)  │ Always loaded, prefix-cached
WARM            │ Indexed MCP store    │ Retrieval subagent on-demand
COLD            │ Vector / blob store  │ Semantic search only

Cache Layer     │ Scope                │ Key Rule
────────────────┼──────────────────────┼──────────────────────────────
Prefix cache    │ HOT, per session     │ Static before dynamic; no timestamps in static
Semantic cache  │ WARM, registry+spec  │ Cache by capability-tag fingerprint
Similarity cache│ Cross-session        │ >0.85 sim → reuse spec; >0.6 → delta spec

Session         │ Operation            │ Trigger
────────────────┼──────────────────────┼──────────────────────────────
COMMIT          │ Write Knowledge Block│ Every phase gate
BRANCH          │ Spawn sub-agent      │ Parallel / exploratory work
MERGE           │ A2A handoff          │ Sub-agent returns
CHECKPOINT      │ Mid-phase compact    │ 80% turn budget consumed

Repo Zone       │ Contents             │ Scope
────────────────┼──────────────────────┼──────────────────────────────
core/           │ Schemas, protocols   │ All agents read, none own
agents/{name}/  │ Prompt, skills, tests│ Isolated per agent
registry/       │ registry.yaml        │ Orchestrator only
specs/ intents/ │ SPEC + INT files     │ Indexed, never loaded whole
skills/         │ Skill library        │ Grows via EVOLVE

Persistence     │ Technology           │ Query Type
────────────────┼──────────────────────┼──────────────────────────────
Embeddings      │ Vector index         │ Semantic similarity (80%)
Knowledge graph │ Property graph       │ Relationships, multi-hop (15%)
Document store  │ Relational / doc DB  │ Structured exact lookup (5%)
Hybrid router   │ Retrieval subagent   │ Classifies + dispatches all three

Registry        │ Field                │ Purpose
────────────────┼──────────────────────┼──────────────────────────────
Version         │ MAJOR.MINOR.PATCH    │ MAJOR = A2A schema break
Status          │ stable/canary/retired│ Routing eligibility
schema_ref      │ A2A output schema    │ Downstream compatibility check
rollback_target │ Prior stable version │ Auto-rollback on regression
agent_pins      │ Per-spec overrides   │ Reproducibility for audits
```

---

## Sources & Inspirations

- [Spec-Driven Development 2026 — BCMS](https://thebcms.com/blog/spec-driven-development) — agentic SDLC, spec-driven pitfalls, context decay, multi-agent spec distribution
- [SDD Context Engineering — WeBuild-AI](https://www.webuild-ai.com/insights/aligning-spec-driven-development-and-context-engineering-for-2026) — aligning SDD with context budgets
- [Agentic Trust Framework (ATF) — Cloud Security Alliance](https://cloudsecurityalliance.org/blog/2026/02/02/the-agentic-trust-framework-zero-trust-governance-for-ai-agents) — ATF maturity levels
- [Microsoft Zero Trust for AI](https://www.microsoft.com/en-us/security/blog/2026/03/20/secure-agentic-ai-end-to-end/) — zero-trust principles for agentic workflows
- [TDAD: Test-Driven Agentic Development](https://arxiv.org/abs/2603.17973) — graph-based impact analysis, 70% regression reduction
- [MCP 2026 Roadmap](https://blog.modelcontextprotocol.io/posts/2026-mcp-roadmap/) — transport evolution, agent communication
- [MCP vs A2A vs ACP Guide 2026](https://www.aimagicx.com/blog/mcp-vs-a2a-vs-acp-ai-agent-protocols-guide-2026) — protocol comparison and convergence
- [Intent-Driven Development 2026](https://sigmajunction.com/blog/intent-driven-development-writing-code-optional-2026) — human as intent orchestrator
- [Vibe Coding Pitfalls — The New Stack](https://thenewstack.io/vibe-coding-could-cause-catastrophic-explosions-in-2026/) — security vulnerability data
- [AGENTS.md Best Practices — Augment Code](https://www.augmentcode.com/guides/how-to-build-agents-md) — context file hygiene
- [Context Bloat Research — Claude-Mem Docs](https://docs.claude-mem.ai/context-engineering) — 80-line limit, failure-driven rules
- [OWASP Agentic Skills Top 10](https://owasp.org/www-project-agentic-skills-top-10/) — security control mapping
- [MCP Gateway Registry](https://github.com/agentic-community/mcp-gateway-registry) — enterprise-ready registry reference implementation
- [Agentic Trust Framework — arxiv](https://arxiv.org/html/2602.15055v1) — federated agent orchestration patterns
- [Knowledge Graphs for Agentic AI — ZBrain](https://zbrain.ai/knowledge-graphs-for-agentic-ai/) — graph architecture, shared world model for agents
- [Graph RAG vs Vector RAG 2026 — Medium](https://medium.com/@ajaysrinivasan87/graph-rag-vs-vector-rag-choosing-the-right-architecture-for-enterprise-use-cases-f3f6205f959f) — hybrid router pattern, 3.4× accuracy improvement
- [AI Agent Memory 2026 — SparkCo](https://sparkco.ai/blog/ai-agent-memory-in-2026-comparing-rag-vector-stores-and-graph-based-approaches) — comparing RAG, vector, and graph for agent memory
- [Agent Versioning and Rollback — Medium](https://medium.com/@nraman.n6/versioning-rollback-lifecycle-management-of-ai-agents-treating-intelligence-as-deployable-software-deac757e4dea) — SemVer for agents, rollback strategies
- [Agent System Prompt Versioning — Suhas Bhairav](https://suhasbhairav.com/blog/managing-versioning-rollback-strategies-for-agent-system-prompts) — canary + blue-green for agent prompts
- [Agent Development Lifecycle (ADLC) — IBM](https://www.ibm.com/think/topics/agent-development-lifecycle-adlc) — dev/staging/prod tracks for agents
- [Prompt Caching for Long-Horizon Agentic Tasks — arxiv](https://arxiv.org/html/2601.06007v2) — cache hit rate patterns, static/dynamic ordering
- [How LLM Caching Actually Works 2026](https://akshayghalme.com/blogs/how-llm-caching-actually-works/) — prefix cache, semantic cache, CDN patterns
- [Context Architecture Replacing RAG — VentureBeat](https://venturebeat.com/data/context-architecture-is-replacing-rag-as-agentic-ai-pushes-enterprise-retrieval-to-its-limits) — compile-time knowledge layer
- [Agentic RAG Survey — arxiv](https://arxiv.org/html/2501.09136v4) — multi-layer retrieval, retrieval subagent pattern
- [AI Agent Context Compression — Zylos Research](https://zylos.ai/research/2026-02-28-ai-agent-context-compression-strategies) — sawtooth pattern, anchored iterative summarization
- [Active Context Compression — arxiv](https://arxiv.org/html/2601.07190v1) — failure-driven guideline optimization
- [Git Context Controller — arxiv](https://arxiv.org/pdf/2508.00031) — COMMIT/BRANCH/MERGE/CHECKOUT context ops
- [Contextual Memory Virtualisation — arxiv](https://arxiv.org/pdf/2602.22402) — DAG-based state, lossless trimming
- [AI Agent Checkpointing — Zylos Research](https://zylos.ai/research/2026-03-04-ai-agent-workflow-checkpointing-resumability) — resumable workflows
- [Monorepos & AI — monorepo.tools](https://monorepo.tools/ai) — unified context for agentic workflows
- [Great Monorepo Unbundling — DEV Community](https://dev.to/clawdy/the-great-monorepo-unbundling-why-big-tech-is-fragmenting-for-the-ai-agent-era-4hhk) — fragmentation for agent era
- [Multi-Repo AI Context Patterns](https://elite-ai-assisted-coding.dev/p/context-from-internal-git-repos) — cross-repo context for agents
- [Chroma Context-1 — MarkTechPost](https://www.marktechpost.com/2026/03/29/chroma-releases-context-1-a-20b-agentic-search-model-for-multi-hop-retrieval-context-management-and-scalable-synthetic-task-generation/) — specialized retrieval subagent model
- [Prompt Caching for Long-Horizon Agentic Tasks — arxiv](https://arxiv.org/html/2601.06007v2) — cache hit rate patterns, static/dynamic ordering
- [How LLM Caching Actually Works 2026](https://akshayghalme.com/blogs/how-llm-caching-actually-works/) — prefix cache, semantic cache, CDN patterns
- [Context Architecture Replacing RAG — VentureBeat](https://venturebeat.com/data/context-architecture-is-replacing-rag-as-agentic-ai-pushes-enterprise-retrieval-to-its-limits) — compile-time knowledge layer
- [Agentic RAG Survey — arxiv](https://arxiv.org/html/2501.09136v4) — multi-layer retrieval, retrieval subagent pattern
- [AI Agent Context Compression — Zylos Research](https://zylos.ai/research/2026-02-28-ai-agent-context-compression-strategies) — sawtooth pattern, anchored iterative summarization
- [Active Context Compression — arxiv](https://arxiv.org/html/2601.07190v1) — failure-driven guideline optimization
- [Git Context Controller — arxiv](https://arxiv.org/pdf/2508.00031) — COMMIT/BRANCH/MERGE/CHECKOUT context ops
- [Contextual Memory Virtualisation — arxiv](https://arxiv.org/pdf/2602.22402) — DAG-based state, lossless trimming
- [AI Agent Checkpointing — Zylos Research](https://zylos.ai/research/2026-03-04-ai-agent-workflow-checkpointing-resumability) — resumable workflows
- [Monorepos & AI — monorepo.tools](https://monorepo.tools/ai) — unified context for agentic workflows
- [Great Monorepo Unbundling — DEV Community](https://dev.to/clawdy/the-great-monorepo-unbundling-why-big-tech-is-fragmenting-for-the-ai-agent-era-4hhk) — fragmentation for agent era
- [Multi-Repo AI Context Patterns](https://elite-ai-assisted-coding.dev/p/context-from-internal-git-repos) — cross-repo context for agents
- [Chroma Context-1 — MarkTechPost](https://www.marktechpost.com/2026/03/29/chroma-releases-context-1-a-20b-agentic-search-model-for-multi-hop-retrieval-context-management-and-scalable-synthetic-task-generation/) — specialized retrieval subagent model
