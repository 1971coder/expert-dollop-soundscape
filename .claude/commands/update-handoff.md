---
description: Maintain docs/handoff.md as a rolling snapshot — overwrite, prune, optionally archive. Not append-only.
---

Update [../../docs/handoff.md](../../docs/handoff.md) so the next session can pick up cold.

If $ARGUMENTS contains specific notes or context to incorporate, use them. Otherwise, derive the update from recent work — git history since the last handoff update, the WP currently in `in-review`, and any open todos.

## Read first

1. [../../docs/handoff.md](../../docs/handoff.md) — current state. Note what's stale, what's still active.
2. [../../docs/delivery-plan.md](../../docs/delivery-plan.md) — what's `in-progress`, `in-review`, recently merged.
3. The active WP file(s) in [../../work-packages/](../../work-packages/) — *Integration notes*, *Acceptance criteria* (which are checked).
4. `git log -10 --oneline` and `git status` — recent activity since the last handoff.

## Procedure

`handoff.md` is a **rolling snapshot, not an append-only log.** This command's job is to keep each section current — overwriting where the state has moved, pruning where items are closed, optionally archiving where history remains useful.

For each of the eight sections, decide what to do:

1. **Current Snapshot** — **overwrite.** One paragraph (or short bullet list) describing where the project is right now. The previous content is stale by definition.
2. **Recent Completed Work** — **update.** Add newly merged WPs (top of list). If the list grows past ~5 items, push the oldest to *Historical Notes* (or delete if no longer load-bearing).
3. **Open Issues** — **prune and add.** Remove items that have been resolved. Add new ones surfaced by recent work or QA/integration reviews.
4. **Assumptions In Play** — **prune and add.** Remove assumptions that have been validated/invalidated and acted on. Add new assumptions that current WPs rely on.
5. **Blockers** — **prune and add.** Remove unblocked items. Add new ones, naming what's needed to unblock each.
6. **Technical Debt To Revisit** — **add (rarely prune).** Items here usually live longer; only remove when the debt is paid. Reference the WP that introduced each item.
7. **Next Recommended Steps** — **rewrite.** Ordered list of 3–5 items the next session should consider first. This is the *startup hint* for cold sessions.
8. **Historical Notes (optional)** — **archive when useful.** Move older entries from *Recent Completed Work* / *Open Issues* / *Assumptions* here if they remain useful as context. Date-stamp them. Prune ruthlessly: anything that hasn't been useful for two sessions can usually go.

If a section was empty (had only the `<!-- scaffold-allow-empty -->` sentinel) and you're now adding content, **remove the sentinel from that section.** A section with both the sentinel and real content fails `--strict` audit (cleanup signal).

If a section is still legitimately empty, leave the sentinel — that's correct behaviour for a fresh project.

## Do NOT

- **Append to existing sections without considering whether the older content is now stale.** This is the failure mode that turns `handoff.md` into noise.
- **Write decisions or architectural rationale here.** Those belong in [../../docs/decisions.md](../../docs/decisions.md).
- **Duplicate WP content.** WP files are the source of truth for their own *Acceptance criteria* and *Integration notes*. `handoff.md` cross-references them, doesn't restate them.
- **Mass-archive.** *Historical Notes* should grow slowly. If it grows fast, you're probably keeping things that should be deleted.
- **Forget to remove sentinels** from sections you've populated.
