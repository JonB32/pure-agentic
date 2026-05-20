# Session End Hook

Run this checklist before ending any PURE session.

---

## For Agents

```
1. Is a phase gate pending?
   - If yes: write the knowledge block NOW before ending.
   - Never end a session mid-phase without a checkpoint knowledge block.

2. Write checkpoint knowledge block if any of these are true:
   - You changed any file
   - You made any decision
   - You received any tool result
   Filename: sessions/INT-xxxx-PARTIAL-{timestamp}.yaml
   Mark phase_completed as PARTIAL.

3. Emit A2A status_update to orchestrator if work is ongoing:
   {message_type: "status_update", payload: {status: "paused", resume_from: "sessions/INT-xxxx-PARTIAL-*.yaml"}}

4. Verify HOT context was not modified in ways that won't survive session restart:
   - In-memory state does not persist. Everything must be in sessions/ or on disk.
```

## For Humans

```
1. Are there any gate_blocked messages in sessions/ that need your decision?
   Check: grep -r "gate_blocked" sessions/

2. Are there open security findings that need triage?
   Check: grep -r "open:" sessions/INT-*-SHIELD.yaml

3. Is the most recent knowledge block accurate?
   Skim the last sessions/INT-xxxx-*.yaml to confirm it reflects reality.

4. Tag the session in git if meaningful work was done:
   git add sessions/ specs/ intents/
   git commit -m "PURE: INT-xxxx PHASE complete"
```

## What to Leave Clean

- sessions/INT-xxxx-PARTIAL.yaml exists → next session resumes from here
- No unsaved file changes outside of git tracking
- No open CRITICAL/HIGH security findings without a human decision
