---
description: Start a bounded feature-implementation agent for a single work package.
---

Implement the work package: **$ARGUMENTS**

If no work package was given, ask the user which `WPNN-<slug>.md` file in [../../work-packages/](../../work-packages/) to start, then stop and wait.

## Read first (in this order)

1. [../../CLAUDE.md](../../CLAUDE.md) — project conventions, scope, gotchas.
2. [../../docs/architecture.md](../../docs/architecture.md) — structural context.
3. [../../docs/requirements.md](../../docs/requirements.md) — user-visible behaviours and constraints.
4. The named WP file in [../../work-packages/](../../work-packages/) — the actual brief.
5. [../../docs/coding-standards.md](../../docs/coding-standards.md) — agreed conventions.
6. [../../docs/handoff.md](../../docs/handoff.md) — current rolling snapshot. Note any active blockers, assumptions, or open issues that affect this WP.

If WP00 — Foundation is still open (status not `merged`), **stop and tell the user**. No feature work begins until the foundation gate is closed. See [../../work-packages/WP00-foundation.md](../../work-packages/WP00-foundation.md).

## Procedure

1. **Confirm scope.** Read the WP's *Objective*, *Scope*, *Out of scope*, and *Acceptance criteria* sections. If anything is unclear or contradictory, stop and ask the user — do not guess.
2. **Identify dependency risks.** Check the WP's *Dependencies* section, then cross-reference [../../docs/delivery-plan.md](../../docs/delivery-plan.md) for any in-flight WP whose *Files likely touched* or *Shared Files Allowed To Change* overlap with this one. If overlap exists, stop and tell the user — running in parallel risks merge conflicts.
3. **Set the WP status to `in-progress`** in both the WP file and the corresponding row in `delivery-plan.md`.
4. **Implement, step by step.** Follow the WP's *Acceptance criteria* in order. Make the smallest changes that satisfy each criterion.
5. **Add or update tests** as the WP's *Tests required* section specifies. Match the project's [testing-strategy.md](../../docs/testing-strategy.md) — don't introduce a new framework.
6. **Run `./scripts/check.sh`** after each meaningful chunk. Fix failures before piling on more changes.
7. **Document assumptions.** Any judgement call another agent could reasonably make differently goes in the WP's *Integration notes* section, or in `handoff.md`'s *Assumptions In Play* section if cross-WP.
8. **Update [../../docs/handoff.md](../../docs/handoff.md)** at the end of the session — overwrite *Current Snapshot*, add new entries to *Recent Completed Work* / *Open Issues* / *Technical Debt to Revisit* / *Next Recommended Steps* as appropriate. Use [`/update-handoff`](update-handoff.md) if you'd rather delegate the maintenance.
9. **Run `./scripts/test.sh`** and confirm it passes. Run `./scripts/check.sh` once more.
10. **Set the WP status to `in-review`** in both the WP file and `delivery-plan.md`.

## Do NOT

- **Widen scope.** Do not refactor adjacent code, do not "tidy up while you're there", do not introduce abstractions for hypothetical future reuse.
- **Change shared contracts not on the allow-list.** The WP's *Shared Files Allowed To Change* section is the complete list. Anything shared not listed there is off-limits — if it's needed, stop and ask.
- **Modify files in another WP's *Files likely touched* or *Shared Files Allowed To Change*** while that WP is `in-progress` or `in-review`.
- **Commit.** Leave commits to the user (or `/commit`).
- **Skip the handoff update.** A WP that doesn't update `handoff.md` makes the next session start cold.
