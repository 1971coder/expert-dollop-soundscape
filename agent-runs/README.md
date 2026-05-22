# Agent Runs

Per-run scratch space for AI agents: notes, intermediate findings, transcripts of long investigations.

## Convention

- One file or subdirectory per run, named `YYYY-MM-DD-<short-slug>.md` (e.g. `2026-05-10-investigate-auth-flow.md`).
- These files are **not** durable project memory. Anything that should survive the next session belongs in:
  - [../docs/decisions.md](../docs/decisions.md) — permanent architectural choices.
  - [../docs/handoff.md](../docs/handoff.md) — current rolling-snapshot state.
  - [../docs/architecture.md](../docs/architecture.md) — long-form structural context.
  - The relevant work package file in [../work-packages/](../work-packages/).

## Gitignore

By default, `agent-runs/*` is gitignored (this README is the only file kept). If a project wants to commit run logs, edit the project's [`.gitignore`](../.gitignore) to remove the exclusion.

## When to use this directory

- A long, exploratory `/research` session that produces too much detail to fit in conversation context.
- An integration run (`/integrate-feature`) that surfaces issues worth recording before the next session.
- A QA run (`/qa-review`) whose findings are too detailed for a single PR comment.

If the content is short and clearly belongs in `handoff.md` or a WP file, write it there instead.
