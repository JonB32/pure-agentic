# Tier 3: Persistence Architecture Wiring Guide

This document describes how to connect the three persistence tiers for a full Tier 3 PURE deployment.
No specific technology is required — use whatever satisfies each contract.

---

## Three-Store Architecture

```
┌─────────────────────────────────────────────────────┐
│  Embeddings + Vector Index                          │
│  What: intent statements, spec behavior sections,   │
│        skill descriptions, KB decisions             │
│  Contract: embed(text) → store; query(text) → Top-K │
│  Options: any vector DB, pgvector, in-process FAISS │
└─────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────┐
│  Knowledge Graph (4 graphs)                         │
│  What: codebase deps, intent deps, agent affinity,  │
│        lineage                                      │
│  Contract: labeled property graph with timestamps   │
│  Options: any graph DB, in-process networkx (Tier 2)│
└─────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────┐
│  Relational / Document Store                        │
│  What: registry, intent/spec index, audit log,      │
│        session state, A2A message log               │
│  Contract: exact lookup by id + filtered queries    │
│  Options: SQLite (Tier 1/2), PostgreSQL, DynamoDB   │
└─────────────────────────────────────────────────────┘
```

---

## Retrieval Subagent Contract

The retrieval subagent (registry entry: `retrieval-agent`) must satisfy:

**Input:**
```json
{
  "query": "string",
  "query_type": "semantic | relational | graph | multi-hop",
  "filters": { "domain": "...", "status": "...", "intent_ref": "..." },
  "top_k": 5
}
```

**Output:**
```json
{
  "results": [
    {
      "source": "specs/auth/SPEC-0031.md",
      "excerpt": "...",
      "relevance_score": 0.87,
      "artifact_type": "spec"
    }
  ]
}
```

Agents never query stores directly — they go through the retrieval subagent via MCP.

---

## Four Knowledge Graphs

### 1. Codebase Graph
**Nodes:** files, functions, classes, modules
**Edges:** imports, calls, modifies, tests
**Updated by:** code-agent and test-agent during LAUNCH/SHIELD
**Query example:** `MATCH (f:File {path: 'auth/reset.ts'})<-[:IMPORTS]-(d) RETURN d`

### 2. Intent Dependency Graph
**Nodes:** intents, specs
**Edges:** depends_on, supersedes, spawned_from, out_of_scope_of
**Updated by:** orchestrator at PURPOSE and EVOLVE
**Query example:** `MATCH (i:Intent)-[:DEPENDS_ON*]->(dep) WHERE i.id='INT-0053' RETURN dep`

### 3. Agent Capability Graph
**Nodes:** agents, capability tags
**Edges:** provides (agent→tag), works_well_with (agent→agent, weighted by trajectory outcomes)
**Updated by:** learning-agent at EVOLVE
**Query example:** `MATCH (a:Agent)-[:PROVIDES]->(t:Tag) WHERE t.name IN ['redis','security'] RETURN a ORDER BY a.avg_success_rate DESC`

### 4. Lineage Graph
**Nodes:** intents, specs, agents, actions, outputs
**Edges:** produced, consumed, approved_by, rolled_back_by
**Updated by:** orchestrator (append-only, never modified)
**Query example:** `MATCH p=(i:Intent {id:'INT-0042'})-[:PRODUCED*]->(o:Output) RETURN p`

---

## Signed Registry Entries (Tier 3)

Each registry entry has a `signature` field:
```yaml
  signature:
    algorithm: ed25519
    key_id: "registry-signing-key-2026"
    value: "<base64-encoded-signature-of-canonical-yaml>"
```

Orchestrator verifies signature before routing to any agent. Unsigned entries are not routed in Tier 3.

Signing workflow:
```bash
# Sign an entry (example using gpg or any signing tool)
canonical=$(python3 -c "import yaml,sys,json; d=yaml.safe_load(open(sys.argv[1])); print(json.dumps(d, sort_keys=True))" registry/registry.yaml)
echo "$canonical" | gpg --detach-sign --armor > registry/registry.yaml.sig
```

---

## Compliance Lineage Store

For SOC2/HIPAA: the lineage graph must be append-only and tamper-evident.

Minimum requirements:
- Every node/edge write is timestamped and attributed to an agent_id
- No delete operations — only `status: retired` or `status: superseded`
- Export capability to structured format for audit queries
- Retention: configurable, minimum 1 year

Options: any append-only log store with query (e.g., immutable DB, ledger service, write-only S3 with Athena).

---

## Agent Development Lifecycle (ADLC) Pipeline

```
dev branch → agent unit tests → staging registry entry
           → shadow evaluation (real intents, no side effects)
           → canary registry entry (10% weight)
           → promotion criteria met → stable prod entry
           → prior version → deprecated → retired (30 days)
```

Gate: every agent version promoted to canary requires:
1. Changelog entry in registry.yaml
2. A2A schema compatibility check (no breaking changes without MAJOR bump)
3. Shadow evaluation: ≥ 20 intents, success_rate ≥ prod baseline
4. Human sign-off in registry PR

Tools for shadow evaluation: run the agent against a sample of recent intent+spec pairs from sessions/.archive/ and compare outputs to known-good results.
