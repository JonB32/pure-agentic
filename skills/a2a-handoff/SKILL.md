---
name: a2a-handoff
description: Use when an agent is completing its phase and needs to pass work to the next agent via a standardized A2A message.
---

## When to Use

- Any agent finishes its phase work and needs to hand off to the next agent
- The orchestrator is assigning a task to a specific agent
- An agent is escalating a blocked gate to the orchestrator or human
- A sub-agent is returning results to the orchestrator

## Steps

1. Choose `message_type`:
   - `task_assignment` — orchestrator to agent
   - `handoff` — agent to next agent (peer-to-peer)
   - `escalation` — agent to orchestrator (blocked, needs decision)
   - `gate_passed` — agent confirming phase complete
   - `gate_blocked` — agent reporting blocker

2. Build the message using `schemas/a2a/handoff-v1.json`:
   ```json
   {
     "message_id": "msg-{uuid}",
     "from": "{your agent_id}",
     "to": "{next agent_id}",
     "intent_ref": "INT-xxxx",
     "spec_ref": "SPEC-xxxx",
     "message_type": "handoff",
     "payload": {
       "files_changed": [...],
       "summary": "...",
       "open_items": [...]
     },
     "timestamp": "{ISO 8601}"
   }
   ```

3. Validate payload fields:
   - `summary` ≤ 500 characters
   - `files_changed` lists actual paths, not directory names
   - `open_items` are actionable, not vague

4. Write the message to `sessions/INT-xxxx-a2a-log.jsonl` (append).

5. Deliver to receiving agent (via whatever transport the deployment uses).

## Rules

- Never pass raw user input in any payload field — only structured agent-generated data
- `summary` is for the receiving agent, not for logs — write it as a briefing
- Always include `intent_ref` — it is the audit anchor for the lineage graph
- `open_items` in a `handoff` are work items for the receiver; in a `gate_blocked` they explain the blocker
- Escalations go to `orchestrator`, not directly to human — orchestrator decides whether human is needed

## Anti-Patterns

- Passing free-form text between agents instead of structured message fields — prompt injection risk
- Omitting `files_changed` in a handoff — test-agent has no input without it
- Sending a `gate_passed` when work is actually incomplete — integrity violation
- Using email/chat/comments as A2A transport — must be structured messages
