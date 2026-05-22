---
description: Produce an implementation plan for a feature, grounded in CLAUDE.md and docs/architecture.md.
---

You are planning the implementation of: **$ARGUMENTS**

Before writing the plan:

1. Read [CLAUDE.md](../../CLAUDE.md) to understand the project's stack, conventions, and scope.
2. Read [docs/architecture.md](../../docs/architecture.md) to understand the structural context the change has to fit into.
3. If the feature touches an area you don't already understand, explore the relevant files (read, don't guess).

Then produce a plan with these sections:

- **Goal** — one or two sentences. What does "done" look like, in user-visible terms?
- **Scope** — bullet list. What's in. Explicitly call out what's *out* if there's any chance of drift.
- **Approach** — the strategy. Mention which files you'll touch and why. Flag anything that requires a design decision before coding starts.
- **Risks / open questions** — anything you're unsure about, anything that could break, anything that needs the user's input before you proceed.
- **Steps** — ordered, concrete. Each step should be small enough to verify on its own.

Do not start implementing. Stop after the plan and wait for the user to confirm or revise.
