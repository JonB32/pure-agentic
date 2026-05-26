# PURE — Purpose-Unified-Resilient-Evolutionary

**An agentic development methodology. Provider-agnostic. Model-agnostic. KISS-first.**

PURE gives autonomous AI agents and the humans working with them a shared operating language: intents, thin specs, phase gates, knowledge blocks, and a capability registry — all wired together with open protocols (MCP + A2A).

```
PURPOSE → UNIFY → LAUNCH → SHIELD → EVOLVE
```

Five phases. One cycle per deliverable. Everything traces back to intent.

---

## Install

```bash
# Use as a standalone repo
git clone https://github.com/your-org/pure-agentic
cd pure-agentic

# Or embed in an existing project
git clone https://github.com/your-org/pure-agentic .pure
cp .pure/AGENTS.md .          # agent entry point
cp -r .pure/{registry,templates,agents,skills,hooks,scripts} .
```

---

## Quickstart

### For humans — 5 steps to first intent

**1. Write your intent**
```bash
./scripts/new-intent.sh
# Interactive. Writes intents/INT-0001.yaml.
```

**2. Point your agent at `AGENTS.md`**

Set `AGENTS.md` as the system prompt / context file in your agent harness.
Works with any tool that accepts a system prompt.

**3. Trigger the first phase**
```
INT-0001 is approved. Begin UNIFY.
```

**4. Review the spec**

The agent writes `specs/{domain}/SPEC-0001.md`. Read it. Approve or redirect.

**5. Follow the gates**

Each phase ends with a knowledge block written to `sessions/`. The agent tells you when it needs a decision. Everything else is autonomous.

---

### For agents — orient in 4 steps

```
1. Read AGENTS.md
2. Find the active intent in intents/
3. Find the most recent knowledge block in sessions/ (or: fresh start at UNIFY)
4. Load skills/{relevant}/SKILL.md for your current task
```

Full orientation: [`AGENTS.md`](AGENTS.md) · Full methodology: [`PURE-METHODOLOGY.md`](PURE-METHODOLOGY.md) · Single-agent vs multi-agent: [`docs/topology-modes.md`](docs/topology-modes.md)

---

## Tiers

Start at Tier 1. Graduate when the next tier's complexity earns its keep.

| | **Tier 1** · Solo | **Tier 2** · Team | **Tier 3** · Enterprise |
|---|---|---|---|
| **Registry** | YAML file, 3 agents | Shared, versioned | Signed entries, ADLC pipeline |
| **Protocols** | Local JSON / stdio | HTTP/SSE message bus | Full A2A + MCP gateway |
| **Learning** | Manual skill notes | Learning engine stub | Fine-tuning pipeline |
| **Persistence** | Files + sessions/ | Vector index + graph | Three-store hybrid |
| **Security** | ATF Level 2 | ATF Level 2–3 | ATF Level 4 capable |
| **Time to first cycle** | Day 1 | Week 1–4 | Month 2+ |

Working configs at each tier: [`examples/`](examples/)

---

## What's in this repo

```
AGENTS.md                   agent entry point (≤ 80 lines)
PURE-METHODOLOGY.md         complete reference with golden paths
QUICKSTART.md               step-by-step for humans and agents

registry/registry.yaml      capability registry — 9 core agents
templates/                  intent, spec, knowledge-block blanks
schemas/a2a/handoff-v1.json A2A message schema

agents/{name}/AGENT.md      system prompt per agent role
skills/{name}/SKILL.md      on-demand how-to skills
hooks/session-start.md      agent orientation checklist
hooks/session-end.md        end-of-session guarantee checklist

scripts/new-intent.sh       create a new intent (interactive or --non-interactive)
scripts/registry-query.sh   find agents by capability tags
scripts/context-check.sh    audit context budgets and project state (--json, --quiet, --exit-on-warning)
scripts/pure-status.sh      one-line snapshot: active intents, current phase, next agent
scripts/archive-completed.sh archive completed/superseded specs + sessions (dry-run by default)

intents/                    your INT-xxxx.yaml files (tracked)
specs/                      your SPEC-xxxx.md files (tracked)
sessions/                   knowledge blocks — audit trail (tracked)
learned-skills/             learning engine output (SKILL.md tracked)
examples/                   tier 1 / 2 / 3 working examples
```

---

## Core Rules

| Rule | Limit |
|---|---|
| One intent = one deliverable | No compound intents |
| Spec length | ≤ 50 lines |
| Agent context files (AGENTS.md, AGENT.md) | ≤ 80 lines |
| New test lines per intent | ≤ 1.5× LOC changed |
| Rules added to AGENTS.md | Only after an observed failure |
| Write to `registry/` | Human approval required |

---

## Protocols

PURE uses open standards — no proprietary lock-in.

- **MCP** (Model Context Protocol, Linux Foundation) — tool access for agents
- **A2A** (Agent-to-Agent Protocol, Linux Foundation) — inter-agent communication
- **ATF** (Agentic Trust Framework, Cloud Security Alliance) — agent trust levels

---

## Contributing

Issues and PRs welcome.

Before opening a PR:
- Run `./scripts/context-check.sh` — all checks must pass
- New agent skills require a `SKILL.md` with a failing test case that motivated the skill
- Registry changes require a changelog entry and human review

---

## License

MIT
