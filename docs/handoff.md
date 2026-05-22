# Handoff

> Maintained by [`/update-handoff`](../.claude/commands/update-handoff.md). This is a **rolling snapshot, not an append-only log.** The `/update-handoff` command's job is to keep these sections current — overwriting `Current Snapshot`, pruning closed items, and (optionally) moving useful history to `Historical Notes`.

## Current Snapshot

**2026-05-17.** Scaffold adopted into the AuralFlow repo. CLAUDE.md and the core docs (`requirements`, `architecture`, `data-model`, `api-contract`, `coding-standards`, `testing-strategy`, `project-structure`, `glossary`) are now AuralFlow-specific. `decisions.md` has three initial entries. `delivery-plan.md` has rows for WP00–WP04. Five work-package files exist: `WP00-foundation.md` (scaffold-shipped), and drafts of `WP01-audio-prototype.md`, `WP02-mvp-focus-sleep.md`, `WP03-adaptive-intelligence.md`, `WP04-ai-personalisation.md`.

**Foundation gate is OPEN-pending:** WP00 is `proposed`; it has not yet been ratified. No feature WP may start until WP00 closes — currently this means a session that reviews `docs/coding-standards.md`, agrees the twelve categories, picks the actual `.swiftlint.yml` / `.swift-format` configs, and marks WP00 `merged`.

## Recent Completed Work

- **Scaffold adoption** (2026-05-17) — Pulled `1971coder/claude-code-template` into the repo, kept existing Xcode skeleton, did not overwrite `.git`. Docs populated from the AuralFlow product specification.

## Open Issues

- **SwiftLint and swift-format configs not yet committed.** Coding standards reference them; files must land during WP00.
- **`.gitignore` does not ignore `Soundscape.xcodeproj/xcuserdata/`.** Currently showing as untracked — should be added before first commit (handled in scripts/.gitignore WP).
- **Xcode project is the bare iOS template.** The directory layout in `docs/project-structure.md` is aspirational — no `Audio/`, `Adaptive/` etc. exist as folders yet. WP01 puts the layout down for real.

## Assumptions In Play

- iOS **17+** as the deployment target (provisional; WP00 ratifies). Driven by SwiftData availability and SwiftUI `@Observable`.
- **SwiftData over Core Data.** WP00 decision pending; current docs assume SwiftData.
- **AudioKit as an optional helper, not a hard dependency on every node.** Some nodes will be hand-rolled `AVAudioSourceNode`s.
- **Background audio entitlement** will be added in WP02 (when Sleep mode ships) or earlier if WP01 needs it for prototyping.
- **No first-party server.** No backend in MVP; cloud LLM calls (Phase 4) are vendor-direct.

## Blockers

- None — WP00 is unblocked and can be run as the next session.

## Technical Debt To Revisit

- **Naming drift:** repo dir and Xcode target are `Soundscape`; product is `AuralFlow`. Rename is its own WP, deferred (see `decisions.md` 2026-05-17).
- **`scripts/check.sh` / `scripts/test.sh` detection:** the scripts detect `Package.swift` but not `.xcodeproj`. They currently fall through to "no project type detected" on this repo. WP00 (or WP-script) adds Xcode-project detection.
- **`README.md` at the repo root** is still the scaffold's README, not AuralFlow's. Replace once the project has user-facing docs worth writing. Low priority.

## Next Recommended Steps

1. **Run WP00 — Foundation.** Review `docs/coding-standards.md`, ratify the twelve categories, add `.swiftlint.yml` + `.swift-format`, mark WP00 `merged`, set the foundation gate to OPEN.
2. **Adapt `scripts/check.sh`, `scripts/test.sh`, `scripts/format.sh`** for `.xcodeproj` detection (Xcode-project branch added alongside `Package.swift`).
3. **Extend `.gitignore`** to ignore `xcuserdata/` and other per-user Xcode artefacts.
4. **Run `./scripts/template-audit.sh --strict`** to catch any sentinel/TODO residue.
5. **Start WP01 — Audio Prototype** once WP00 is closed.

## Historical Notes (optional)

<!-- Older entries archived from sections above when they're no longer load-bearing for current work. Date-stamped. Prune ruthlessly. -->
