# Topology Modes — Single-Agent vs Multi-Agent PURE

PURE assumes you can play every role in the PULSE cycle. In practice teams run PURE in two distinct topologies that need different amounts of ceremony. This page names them and tells you what to keep, what to skip, and how to graduate from one to the other.

## The two topologies

### Single-agent (one model plays every role in sequence)

One Claude/Cursor/Copilot session opens an intent, writes the spec, writes the code, writes the tests, and writes the EVOLVE knowledge block. The "next agent" is always the same context window. A2A handoff messages become journal entries rather than delivery mechanisms — there is no receiving agent.

Most solo developers, side projects, and early-stage repos start here.

### Multi-agent (distinct agents communicating over A2A)

An orchestrator routes work to specialized agents (`code-agent`, `test-agent`, `security-agent`, `review-agent`, `deploy-agent`). Each agent runs in a fresh context window, loads only the knowledge blocks it needs, and ships a typed A2A message to the next agent. Registry routing decides who picks up next.

This is what `registry/registry.yaml`, `schemas/a2a/handoff-v1.json`, and the per-agent `AGENT.md` files were built for.

## What to keep, what to skip

| Element                           | Single-agent       | Multi-agent       |
|-----------------------------------|--------------------|--------------------|
| Intent file (`intents/INT-xxxx`)  | required           | required           |
| Spec (`specs/SPEC-xxxx`, ≤50 ln)  | required           | required           |
| Knowledge block per phase         | required — as journal/checkpoint | required — as journal + handoff |
| A2A message file                  | optional           | required           |
| Registry routing                  | not applicable     | required           |
| Phase gates                       | required — as checklist | required — as A2A message |

The principle: **the artifact is always required; the protocol layer depends on whether anyone else has to consume it**.

## Upgrade path

A single-agent project that grows into multi-agent does not have to rewrite its history. The knowledge blocks already written are forward-compatible — they have the same schema (`schemas/knowledge-block-v1.json`) regardless of topology. The day a second agent joins:

1. Add the new agent to `registry/registry.yaml` (registry was previously moot).
2. Start writing A2A messages for new handoffs (`schemas/a2a/handoff-v1.json`).
3. Existing intents continue under the new topology; no migration of past sessions needed.

You do not need to "downgrade" either — running multi-agent ceremony on a single-agent intent costs a few extra file writes but never breaks anything.

## Quick decision

- **One model session per intent** → single-agent. Skip A2A. Knowledge blocks are still required.
- **Distinct sessions / models / humans per phase** → multi-agent. Use the full protocol.

When in doubt: start single-agent. The artifacts you write are valid in both modes; only the protocol layer differs.
