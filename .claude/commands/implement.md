---
description: Implement an approved plan, then run ./scripts/check.sh to verify.
---

Implement the plan: **$ARGUMENTS**

If no plan is given, ask the user to either pass one or run `/plan` first.

Rules:

1. Follow the plan's steps in order. If reality diverges (a step turns out to be wrong, or a dependency surfaces), stop and tell the user before improvising.
2. Make the smallest changes that satisfy each step. Don't refactor adjacent code, don't add abstractions for hypothetical reuse, don't expand scope.
3. Match the conventions in [CLAUDE.md](../../CLAUDE.md). When the project's existing style conflicts with general best practice, the project wins.
4. After each meaningful chunk of changes, run `./scripts/check.sh`. If it fails, fix the failure before continuing — do not pile new changes on top of a broken state.

When all steps are done:

- Run `./scripts/check.sh` one more time and confirm it passes.
- Summarize what you changed in 2–4 bullets. Mention anything that deviated from the plan and why.
- Do **not** commit. Leave that to the user (or `/commit`).
