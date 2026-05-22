---
description: Invoke the code-reviewer sub-agent on recent changes (uncommitted by default).
---

Run a code review on the recent changes in this repo.

Default scope: **uncommitted changes** (working tree + staged). If the user passed an argument like a commit range or a specific PR/branch, use that instead.

$ARGUMENTS

Steps:

1. Determine the diff to review. Default: `git diff HEAD` (or `git status` if there's nothing to diff). If the argument names a base branch (e.g. `main`), use `git diff main...HEAD`.
2. Invoke the **code-reviewer** sub-agent (see [.claude/agents/code-reviewer.md](../agents/code-reviewer.md)) with that diff and a pointer to [CLAUDE.md](../../CLAUDE.md) for project conventions.
3. Surface the agent's findings to the user, grouped by severity:
   - **Blocking** — bugs, security issues, broken contracts.
   - **Should fix** — convention violations, missed edge cases, poor names.
   - **Nits** — style, polish.
4. Do not auto-apply fixes. The reviewer is read-only; the user decides what to act on.
