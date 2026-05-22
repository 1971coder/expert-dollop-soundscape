---
description: Invoke the test-engineer sub-agent to add or improve coverage, then run ./scripts/test.sh.
---

Improve or verify test coverage for: **$ARGUMENTS**

If the user only asked to run the current test suite, run `./scripts/test.sh` directly and report the result.

Otherwise:

1. Read [CLAUDE.md](../../CLAUDE.md) and the relevant implementation/tests before changing anything.
2. Invoke the **test-engineer** sub-agent (see [.claude/agents/test-engineer.md](../agents/test-engineer.md)) with the target behavior, relevant files, and any recent diff context.
3. Keep coverage focused on behavior and edge cases. Do not introduce a new test framework unless the user explicitly asks.
4. Run `./scripts/test.sh` after the test work is done.
5. Report what behavior is covered, which files changed, and whether the test suite passed.
