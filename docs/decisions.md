# Decisions

Append-only log of significant architectural and engineering decisions, and the rationale behind them. **Not** a substitute for [handoff.md](handoff.md) (rolling snapshot of current state) or [architecture.md](architecture.md) (long-form structural context). Decisions are user-curated; review commands must not write to this file.

## What belongs here

- Architectural choices that constrain future work (e.g. "we're using event sourcing for the orders domain"), tooling choices with a real lock-in cost, security/compliance choices, scope boundaries.

## What does NOT belong here

- Day-to-day implementation choices that don't affect future WPs.
- Open issues, current state, or session-to-session continuity (those go in [handoff.md](handoff.md)).
- Long-form structural explanation (that goes in [architecture.md](architecture.md)).

## Entry format

Append new entries to the **bottom** of this file. Use this shape exactly so entries stay greppable and diffable:

```
## YYYY-MM-DD — <short title>

- **Decision:** <one sentence — what was chosen>
- **Alternatives considered:** <bullet list of options that were rejected>
- **Why:** <2–4 sentences. Lead with the constraint that drove the choice.>
- **Status:** active | superseded by [<later entry title>](#<anchor>)
- **WP:** <WP id where the decision was made, or "pre-WP00" / "ad-hoc">
```

When a decision is **superseded**, do not delete the old entry. Mark its status as `superseded by <link>` and append the new entry below — that's how a multi-agent project preserves the trail of why something changed.

---

## 2026-05-17 — Adopt the claude-code-template scaffold

- **Decision:** Adopt the `1971coder/claude-code-template` scaffold (CLAUDE.md, docs/, work-packages/, scripts/, .claude/) into the AuralFlow repo at `~/Dev/Soundscape`.
- **Alternatives considered:** Start from a blank Xcode project; copy only `CLAUDE.md` and skip the multi-agent layer; build a custom in-repo conventions doc set.
- **Why:** The scaffold provides a ready-made multi-agent coordination layer (work packages, delivery plan, rolling handoff, shared-file allow-list) that turns out to map cleanly onto AuralFlow's planned four-phase delivery. Reinventing this for a single-developer-plus-Claude project isn't free.
- **Status:** active
- **WP:** pre-WP00 (set during scaffold adoption)

## 2026-05-17 — `wp/NN-<slug>` work-package branch naming

- **Decision:** All work-package branches use `wp/NN-<slug>` (e.g. `wp/01-audio-prototype`). Inherited from the scaffold.
- **Alternatives considered:** `feature/...` prefix; no convention.
- **Why:** Short prefix keeps `git branch` output scannable. The numeric ID anchors a branch to its WP file unambiguously when several WPs are in flight in parallel.
- **Status:** active
- **WP:** pre-WP00 (set during scaffold adoption)

## 2026-05-17 — Repo and Xcode target keep the legacy "Soundscape" name; product is "AuralFlow"

- **Decision:** The repository directory and the Xcode project / target remain named `Soundscape` for now. The product, marketing, and all user-facing copy use **AuralFlow**. A future WP may rename Xcode-side; not now.
- **Alternatives considered:** Rename everything in this adoption pass; rename only user-facing strings; rename the repo dir but keep Xcode names.
- **Why:** Renaming an Xcode target touches `project.pbxproj`, schemes, Info.plist references, test-target names, and bundle identifier — a non-trivial change that should be its own bounded unit of work. Doing it in passing during scaffold adoption would conflate two unrelated changes.
- **Status:** active
- **WP:** pre-WP00 (set during scaffold adoption)

