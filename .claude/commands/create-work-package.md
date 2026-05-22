---
description: Author a new work package from TEMPLATE.md and add a row to delivery-plan.md.
---

Create a new work package for: **$ARGUMENTS**

If no description was given, ask the user what the WP should accomplish (objective, scope, acceptance criteria) and stop until they answer.

## Read first

1. [../../CLAUDE.md](../../CLAUDE.md) — project conventions and scope.
2. [../../docs/delivery-plan.md](../../docs/delivery-plan.md) — to choose the next available WP id and check for shared-file overlap with in-flight WPs.
3. [../../work-packages/TEMPLATE.md](../../work-packages/TEMPLATE.md) — the schema to follow.
4. [../../docs/architecture.md](../../docs/architecture.md), [../../docs/api-contract.md](../../docs/api-contract.md), [../../docs/data-model.md](../../docs/data-model.md) — surface areas to flag in *API impacts* / *DB impacts*.

## Procedure

1. **Pick the WP id.** Next sequential `NN` not already used in `work-packages/` (zero-padded). Slug is short kebab-case derived from the objective.
2. **Copy `TEMPLATE.md` to `work-packages/WPNN-<slug>.md`.**
3. **Fill in every section.** Concrete and specific. Empty sections are not acceptable — if a section truly doesn't apply, write `none` and a one-line reason. The sections to fill:
   - Objective, Scope, Out of scope
   - Dependencies (other WPs, external services)
   - Files likely touched
   - Files explicitly excluded
   - **Shared Files Allowed To Change** — be deliberate; this gates parallel-WP safety
   - API impacts, DB impacts, UI impacts
   - Acceptance criteria (each maps to at least one test)
   - Tests required
   - Integration notes (initially: known assumptions)
   - Handoff requirements
4. **Add a row to [../../docs/delivery-plan.md](../../docs/delivery-plan.md)** in the *Active* table with status `proposed`. Include: id, title, objective (one line), agent (if known), branch (`wp/NN-<slug>`), deps, parallel-safe assessment, files-likely-touched (brief), shared-file risk, integration risk.
5. **Check shared-file overlap.** For each WP currently in `in-progress` or `in-review`, compare its *Shared Files Allowed To Change* with this WP's. If overlap exists, mark the new WP `parallel-safe: no` and add a note in its *Integration notes* explaining the sequencing.
6. **Stop.** Do not start implementation. Tell the user the WP is created and at status `proposed`. They (or another session) will run [`/start-agent`](start-agent.md) when the WP is ready.

## Do NOT

- **Start implementing.** This command authors the WP; nothing else.
- **Skip sections.** Empty `Acceptance criteria` or empty `Shared Files Allowed To Change` (without `none`) is a failure mode — the WP can't be safely dispatched in that state.
- **Bypass the delivery-plan row.** Coordination depends on `delivery-plan.md` reflecting reality.
- **Pick a WP id that's already taken.** Check the directory first.
