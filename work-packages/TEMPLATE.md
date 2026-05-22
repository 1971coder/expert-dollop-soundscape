# WPNN — <Title>

> **Status:** proposed | ready | in-progress | in-review | merged
> **Branch:** `wp/NN-<slug>`
> **Assigned:** <agent name or human>
> **Depends on:** <WP IDs or "none">

## Behaviour rules for the implementing agent

Before reading any further, the implementing agent must abide by these rules. They are the reason the WP exists in this shape.

- **Avoid unrelated refactors.** Make the smallest change that satisfies the acceptance criteria. Don't tidy adjacent code, don't rename things "while you're there", don't restructure folders unless that *is* the WP.
- **Avoid changing shared contracts unnecessarily.** Shared types, API contracts, DB schemas, error formats, and other files used by other features are off-limits unless explicitly listed in **Shared Files Allowed To Change**.
- **Document assumptions.** If you make a judgement call that another agent could reasonably make differently, write it down — either in this file's *Integration notes* or in [../docs/handoff.md](../docs/handoff.md).
- **Update [../docs/handoff.md](../docs/handoff.md)** when you finish (or stop). Use `/update-handoff` if available.

---

## Objective

<!-- One or two sentences. What problem does this WP solve? What changes for the user / operator / next agent? -->

## Scope

<!-- Bullet list. What's in. Be concrete. -->
-

## Out of scope

<!-- Bullet list. What's explicitly NOT being done in this WP, even if it would be tempting. -->
-

## Dependencies

<!-- Other WPs that must be merged first, external services, design decisions, etc. "none" is a valid answer. -->
-

## Files likely touched

<!-- Best-guess list of files this WP will create or modify. Used for parallel-WP collision checks. Doesn't have to be exact — flag anything you reasonably expect to touch. -->
-

## Files explicitly excluded

<!-- Files this WP must NOT touch. Often shared contracts or files owned by another in-flight WP. -->
-

## Shared Files Allowed To Change

<!-- Allow-list of shared / global files this WP IS permitted to modify (a subset of "Files likely touched" that overlaps with shared code). Anything shared not on this list is off-limits.

Examples:
- shared/types/auth.ts
- docs/api-contract.md

This is the load-bearing primitive for parallel-agent merge safety. Two WPs that both touch the same entry here should not run in parallel without explicit approval. -->
-

## API impacts

<!-- New or changed API endpoints, request/response shapes, breaking changes, versioning notes. "none" if no API surface changes. -->
-

## DB impacts

<!-- Schema migrations, new tables/columns, data backfills, indexes. "none" if no DB changes. -->
-

## UI impacts

<!-- New screens, modified flows, copy changes, accessibility considerations. "none" if no UI surface changes. -->
-

## Acceptance criteria

<!-- Bulleted, testable. "User can do X." "Endpoint returns Y for Z input." Each criterion should map to at least one test. -->
-

## Tests required

<!-- Unit / integration / e2e tests this WP must add or update. Reference [../docs/testing-strategy.md](../docs/testing-strategy.md) for the project's expectations. -->
-

## Integration notes

<!-- Anything the integration agent (`/integrate-feature`) or the next implementing agent needs to know: assumptions, config flags introduced, follow-up cleanup, known temporary shortcuts. -->
-

## Handoff requirements

<!-- What this WP must update before being marked merged:
- [ ] Row in [../docs/delivery-plan.md](../docs/delivery-plan.md) status updated.
- [ ] [../docs/handoff.md](../docs/handoff.md) reflects new state (run `/update-handoff`).
- [ ] [../docs/decisions.md](../docs/decisions.md) updated if this WP introduced a new architectural decision.
- [ ] Tests pass: `./scripts/test.sh`.
- [ ] Audit passes: `./scripts/template-audit.sh --strict`. -->
-
