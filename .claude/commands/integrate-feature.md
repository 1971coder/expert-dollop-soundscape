---
description: Integration / stabilisation review of a merged or about-to-merge work package.
---

Run an integration review for: **$ARGUMENTS**

Default scope: **the most recently merged WP** (or staged changes about to merge). If the user named a WP id or branch, use that.

If the project doesn't yet operate with explicit integration runs, this command is a manual checkpoint between WPs landing and the next batch starting.

## Read first

1. [../../CLAUDE.md](../../CLAUDE.md) — conventions and scope.
2. [../../docs/architecture.md](../../docs/architecture.md) — to evaluate architectural compliance.
3. [../../docs/coding-standards.md](../../docs/coding-standards.md) — convention reference.
4. [../../docs/api-contract.md](../../docs/api-contract.md), [../../docs/data-model.md](../../docs/data-model.md) — to spot shared-contract drift.
5. The WP file under review (in [../../work-packages/](../../work-packages/)) — *Integration notes*, *Files likely touched*, *Shared Files Allowed To Change*.
6. [../../docs/handoff.md](../../docs/handoff.md) — current state.
7. The diff: `git diff main...HEAD` if reviewing a branch, or `git show <merge-commit>` for a merged WP.

## Procedure

For each of the focus areas below, **report findings only; do not modify source code, tests, configuration, or any project doc beyond `handoff.md`.** This command does maintain `docs/handoff.md` as the final step (see *Output* below) — that's part of the findings flow, not source-code mutation.

Findings group as: blocking (must address before next WP starts), should-fix (clean up soon), nit (cosmetic).

1. **Merge readiness.** Does the diff cleanly satisfy the WP's *Acceptance criteria*? Are there obviously unfinished bits, dead code paths, or commented-out chunks?
2. **Duplicated logic.** Did this WP introduce a function/module that duplicates something already in `shared/`? Did it inline a value that's already a constant?
3. **Shared type / contract consistency.** If a shared type or API/DB contract changed: is it consistent with [api-contract.md](../../docs/api-contract.md) / [data-model.md](../../docs/data-model.md)? Was the change reflected in those docs?
4. **Architectural compliance.** Does the WP respect the boundaries described in [architecture.md](../../docs/architecture.md)? Cross-feature imports, layer violations (e.g. routes calling DB directly when conventions say through services), shared-state misuse.
5. **Test integrity.** Do the new tests actually exercise the *Acceptance criteria*? Are tests passing? Are mocks reasonable?
6. **Migration integrity.** If the WP includes DB migrations: are they reversible? Idempotent? Safe under concurrent writes if applicable?
7. **UI consistency.** If the WP touches UI: does it match the project's existing patterns (component library, error states, loading states, accessibility)?
8. **Integration drift cleanup.** Are there `// TODO`-style markers introduced by this WP? Were any of the WP's *Integration notes* or *Technical Debt* items closed before merge?

## Output

Produce a structured report:

```
## Integration review for <WP-id>

### Blocking
- ...

### Should fix
- ...

### Nits
- ...

### Drift to track in handoff.md
- ...
```

Then **update [../../docs/handoff.md](../../docs/handoff.md)**:
- Move closed items out of *Open Issues*.
- Add new entries to *Open Issues*, *Technical Debt to Revisit*, or *Next Recommended Steps* as the findings dictate.

## Memory-write boundary

**This command DOES update [../../docs/handoff.md](../../docs/handoff.md)** as part of its output — that is not a source-code change; it is how findings travel between sessions.

**This command does NOT update** any other doc: `docs/decisions.md` (user-curated only), `docs/architecture.md`, `docs/requirements.md`, `docs/coding-standards.md`, `docs/api-contract.md`, `docs/data-model.md`, `docs/testing-strategy.md`, the WP file under review, or any source/test/config file. If a finding suggests one of those should change, write it as a finding, not as an edit.

If you intend a fully read-only run, end at the structured report and skip the handoff step.

## Do NOT

- **Refactor.** Findings travel via the report and `handoff.md` only. The implementing agent (or a follow-up WP) addresses them in code.
- **Expand scope.** Don't propose unrelated improvements. Stay inside what the WP changed.
- **Auto-merge.** This command does not push, merge, or rebase. Those are the user's call.
- **Skip the handoff update** unless you've explicitly opted into a fully read-only run (above). Drift that doesn't make it into `handoff.md` is drift that the next agent doesn't see.
