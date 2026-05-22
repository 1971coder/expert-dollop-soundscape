---
description: Invoke the researcher sub-agent to answer a question about the codebase. Read-only.
---

Run a read-only investigation of this codebase to answer a question.

$ARGUMENTS

If no question is given, ask the user what they want to learn before proceeding.

Steps:

1. Pass the question to the **researcher** sub-agent (see [.claude/agents/researcher.md](../agents/researcher.md)) with a pointer to [CLAUDE.md](../../CLAUDE.md) for project context.
2. Surface the agent's output to the user, preserving its structure:
   - **Answer** — direct response in plain language.
   - **Evidence** — file paths and line numbers that support it.
   - **Caveats** — uncertainty, gaps, what wasn't looked at.
3. Do not auto-apply changes. The researcher is read-only; the user decides what to do with the findings.
