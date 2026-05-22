---
description: Run a QA / regression review on a work package or recent changes. Read-only — does not auto-fix.
---

Run a QA review for: **$ARGUMENTS**

Default scope: **uncommitted changes + the WP currently in `in-review`**. If the user named a WP id, branch, or commit range, use that instead.

## Read first

1. [../../CLAUDE.md](../../CLAUDE.md) — conventions and scope.
2. [../../docs/testing-strategy.md](../../docs/testing-strategy.md) — coverage expectations.
3. [../../docs/requirements.md](../../docs/requirements.md) — user-visible behaviours and constraints.
4. The WP file (in [../../work-packages/](../../work-packages/)) — *Acceptance criteria* and *Tests required*.
5. The diff: `git diff main...HEAD` for a branch, or `git diff` for uncommitted.

## Procedure

For each focus area below, identify problems but **do not fix them.** Findings group as: blocking, should-fix, nit.

Where it adds clear value, delegate diff-reading to the **code-reviewer** sub-agent (see [../agents/code-reviewer.md](../agents/code-reviewer.md)) — pass it the diff plus a pointer to [../../CLAUDE.md](../../CLAUDE.md) and the WP's *Acceptance criteria*.

1. **Broken flows.** Walk through the user-visible flows touched by this WP. Does each path end successfully? Are error paths reachable and sensible?
2. **Edge cases.** Empty inputs, max-length inputs, unicode, concurrent requests, missing optional fields, expired/invalid auth, network failures, partial state. Pick the ones that apply to this WP and check them.
3. **Validation gaps.** Are all inputs validated at the boundary the project's [coding-standards.md](../../docs/coding-standards.md) says they should be? Are validation errors propagated consistently?
4. **Unsafe assumptions.** Anything assumed about input shape, environment, ordering, atomicity, or external services that isn't enforced by the type system or tests? List them.
5. **Missing tests.** Each *Acceptance criterion* should map to a test. Each obvious edge case should have one. Flag gaps.
6. **Data integrity issues.** Schema changes that could leave existing rows in a bad state. Foreign key relationships not enforced. Migrations that don't backfill. Race conditions on writes.
7. **Inconsistent behaviour.** Same-shape inputs producing different-shape outputs. Error messages that contradict success-path messages. Different code paths converging on different log levels.

## Output

Produce a structured report:

```
## QA review for <WP-id or scope>

### Blocking
- ...

### Should fix
- ...

### Nits
- ...

### Untested but worth testing
- ...
```

Then surface the report to the user — they decide what to act on. Optionally, **and only as a memory update (not a source-code change)**, append cross-WP entries to [../../docs/handoff.md](../../docs/handoff.md)'s *Open Issues*. No other doc gets written from this command.

## Memory-write boundary

**This command MAY update [../../docs/handoff.md](../../docs/handoff.md)** for cross-WP issues, and only `handoff.md` — never source code, tests, configuration, the WP file, or any other doc (including `decisions.md`, which is user-curated).

## Do NOT

- **Auto-apply fixes.** This command is read-only for source code; QA is evaluative.
- **Modify tests or implementation.** If a fix is obvious, the user (or a follow-up WP) makes it.
- **Re-run the full implementation.** Stay inside the diff. QA is *evaluative*, not creative.
- **Skip findings because they're "out of scope of this WP".** A QA pass should report what it sees; the user decides whether to act on cross-WP issues.
