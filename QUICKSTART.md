# PURE Quickstart

Three paths. Pick the one that matches where you are.

---

## Path A — You are a human starting a new project (Tier 1)

**Time: ~10 minutes**

### 1. Add PURE to your project

```bash
cp -r pure-approach/{AGENTS.md,registry,templates,agents,skills,hooks,scripts} your-project/
```

Or keep PURE as a sibling directory and symlink:
```bash
ln -s ../pure-approach/AGENTS.md your-project/AGENTS.md
```

### 2. Create your first intent

```bash
cd your-project
./scripts/new-intent.sh
# Prompts you for statement, outcome, constraints
# Writes intents/INT-0001.yaml
```

Or copy and edit manually:
```bash
cp templates/intent.yaml intents/INT-0001.yaml
# Fill in: statement, outcome, constraints, out_of_scope
```

### 3. Open your agent harness and point it at AGENTS.md

In Claude Code, Cursor, Copilot, or any agent tool:
- Set the project context/system file to `AGENTS.md`
- Or paste the contents of AGENTS.md as the system prompt

### 4. Trigger UNIFY

Tell your agent:
```
INT-0001 is approved. Begin UNIFY.
```

The agent will:
- Check intent similarity against any prior intents
- Generate specs/SPEC-0001.md
- Propose an execution plan

### 5. Review the spec, then trigger LAUNCH

Read the generated spec. If it matches your intent: approve.
```
SPEC-0001 approved. Begin LAUNCH.
```

### 6. Follow the gates

The agent will tell you when each phase completes and what it needs from you.
Your only required action: approve or reject at each gate. The rest is autonomous.

---

## Path B — You are an AI agent receiving a PURE project

**Read AGENTS.md first. Then:**

```
1. Read intents/ → find the active intent (most recent, or as instructed)
2. Read sessions/ → find the most recent knowledge block for that intent
3. Determine current phase from knowledge block (or: no block = start at UNIFY)
4. Load skills/{relevant-skill}/SKILL.md for your current task
5. Execute phase. Write knowledge block. Emit A2A handoff.
```

If you are the orchestrator:
```
1. Read intents/INT-xxxx.yaml
2. Run scripts/registry-query.sh --tags <required-tags>  (or read registry/registry.yaml directly)
3. Assemble agent team
4. Check intent similarity (embed statement, compare to intent index)
5. Generate spec from templates/spec.md
6. Emit A2A task_assignment to first agent in plan
```

---

## Path C — You are setting up Tier 2 (Team)

**Prerequisites:** Tier 1 working for at least one intent cycle.

### 1. Upgrade the registry

```bash
# Enable versioning fields in registry.yaml
# Add environment: staging/prod tracks per agent
# See examples/tier2/registry-with-versions.yaml
```

### 2. Set up a shared sessions/ store

Point sessions/ at a shared location (git-tracked, S3, or any shared filesystem):
```bash
# All team members / agents read+write the same sessions/ directory
# Knowledge blocks become the shared source of truth across sessions
```

### 3. Enable the learning engine

```bash
# Implement or connect a learning engine that satisfies the contract in PURE-METHODOLOGY.md
# Minimum: a script that reads sessions/*.yaml and writes learned-skills/
# See examples/tier2/learning-engine-stub.sh for a minimal implementation
```

### 4. Wire up hooks

```bash
# Add hooks/session-start.md content to your agent harness's system prompt
# or configure as a pre-session hook in your tool's settings
```

---

## Path D — You are setting up Tier 3 (Enterprise)

**Prerequisites:** Tier 2 stable for at least one team sprint.

See [`examples/tier3/`](examples/tier3/) for:
- Signed registry entries (GPG or OIDC)
- Canary routing configuration
- Persistence architecture wiring (embedding index + graph + document store)
- Compliance lineage store setup
- ADLC (agent development lifecycle) pipeline

---

## Common First-Intent Mistakes

| Mistake | Fix |
|---|---|
| Writing a compound intent ("add auth AND rate limiting") | Split into INT-0001 and INT-0002 |
| Spec longer than 50 lines | Cut to Behavior + Acceptance Criteria + Impact Zones only |
| Agent loads all specs into context | Agent should fetch only the active spec via MCP/file read |
| No knowledge block at phase gate | Agent must write sessions/INT-xxxx-LAUNCH.yaml before proceeding |
| Tests written without impact zones | Tests come from Impact Zones in spec — run scripts/impact-analysis first |
| Adding rules to AGENTS.md speculatively | Only add a rule after observing a real failure it would prevent |
