---
description: Architectural governance review of a work package or recent changes. Read-only — does not apply changes.
---

Run an architectural review for: **$ARGUMENTS**

Default scope: **the most recently merged WP, or the current branch's diff against `main`**. If the user named a WP id, branch, or commit range, use that.

This command is for *governance*: spotting architectural drift early, before it ossifies. Findings are advisory; the user (or a follow-up WP) acts on them.

## Read first

1. [../../CLAUDE.md](../../CLAUDE.md) — conventions and scope.
2. [../../docs/architecture.md](../../docs/architecture.md) — the structural intent.
3. [../../docs/decisions.md](../../docs/decisions.md) — prior architectural decisions and their rationale. Don't relitigate decided issues unless something has changed.
4. [../../docs/coding-standards.md](../../docs/coding-standards.md) — convention reference.
5. [../../docs/project-structure.md](../../docs/project-structure.md) — folder responsibilities and feature ownership.
6. The WP file (in [../../work-packages/](../../work-packages/)) — *Scope*, *Out of scope*, *Files likely touched*, *Shared Files Allowed To Change*.
7. The diff: `git diff main...HEAD` or `git show <merge-commit>`.

Where it adds clear value, delegate read-only investigation to the **researcher** sub-agent (see [../agents/researcher.md](../agents/researcher.md)) — pass it specific questions about cross-feature usage of a new abstraction, prior precedent, etc.

## Procedure

For each focus area below, identify concerns but **do not modify source code, tests, configuration, or any project doc beyond `handoff.md`.** This command may append cross-WP architectural concerns to `docs/handoff.md` (see *Output* below) — that is part of the findings flow, not a source-code change. Decisions worth recording in `docs/decisions.md` are surfaced as recommendations only; the user writes that file.

1. **Feature boundaries.** Did the WP cross a feature boundary it shouldn't have? Did it introduce a cross-feature import that bypasses `shared/`? Does it leak feature-specific knowledge into shared code?
2. **Tight coupling.** New code that's hard to change in isolation. Hardcoded references between modules. Implicit ordering dependencies. Module A reaching into module B's internals.
3. **Duplicated business logic.** A new function/class/module that's a near-copy of something existing. A constant inlined when a shared one exists. Validation logic re-implemented because the existing helper "didn't quite fit".
4. **Abstraction quality.** Premature abstractions (single-use generics, single-implementation interfaces). Missing abstractions (the same six-line block copy-pasted in three places). Abstractions that leak the wrong details (e.g. a "user repository" that exposes SQL).
5. **Maintainability.** Code another agent in three months would struggle to change safely. Magic numbers without rationale. Unsafe assumptions baked into call sites instead of the type system.
6. **Scalability risks.** N+1 queries, unbounded loops on user input, in-memory caches without eviction, synchronous calls where async is the convention. Flag the *risk shape*; the user decides whether the risk is acceptable.
7. **Shared-state misuse.** Singleton mutation. Module-level mutable state. Process-wide caches that aren't thread-safe. Globals that pretend to be configuration.

## Output

Produce a structured report:

```
## Architecture review for <WP-id or scope>

### Concerns (high impact)
- ...

### Concerns (medium impact)
- ...

### Suggested decisions to capture in decisions.md
- ...

### Open questions for the user
- ...
```

Then:

- If the review surfaces a decision worth recording, recommend the user add an entry to [../../docs/decisions.md](../../docs/decisions.md) — but **do not write to that file from this command.** Decisions are user-curated.
- Append cross-WP architectural concerns to [../../docs/handoff.md](../../docs/handoff.md)'s *Technical Debt to Revisit* if they don't have a clear next-step yet.

## Memory-write boundary

**This command DOES update [../../docs/handoff.md](../../docs/handoff.md)** with cross-WP architectural concerns — that is not a source-code change; it is how findings travel between sessions.

**This command does NOT update** any other doc: `docs/decisions.md` (user-curated only — recommend, don't write), `docs/architecture.md`, `docs/requirements.md`, `docs/coding-standards.md`, the WP file under review, or any source/test/config file. If a finding suggests one of those should change, write it as a finding, not as an edit.

If you intend a fully read-only run, end at the structured report and skip the handoff append.

## Do NOT

- **Modify source code or other docs.** Findings travel via the report and `handoff.md` only. The user (or a follow-up WP) acts on them in code, and the user (only the user) writes to `decisions.md`.
- **Relitigate decided issues.** If [decisions.md](../../docs/decisions.md) records a choice, respect it unless the WP's context invalidates the original rationale (in which case, flag it as an *open question* — don't unilaterally reverse the decision).
- **Propose large refactors as findings.** Architecture reviews surface *concerns*; the *response* is a follow-up WP, not an in-line refactor.
- **Auto-edit `decisions.md`.** That file is the project's architectural memory and must be human-curated.
