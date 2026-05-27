# WP00 — Foundation

> **Status:** merged
> **Branch:** `wp/00-foundation`
> **Assigned:** <human + agent>
> **Depends on:** none

> ## ⚠️ NO FEATURE WORK BEGINS UNTIL THIS WP IS CLOSED.
>
> Until the conventions below are agreed and recorded in [../docs/coding-standards.md](../docs/coding-standards.md), every feature WP risks re-litigating the same decisions, producing inconsistent code, and creating merge conflicts. Close this WP first.

## Objective

Establish the project's foundational conventions so that every subsequent WP can be implemented consistently by humans and AI agents alike. This WP produces *agreed conventions* — not feature code.

## Scope

Agree, document, and reference (from [../CLAUDE.md](../CLAUDE.md) where appropriate) the following twelve categories of conventions. Each one should land in a section of [../docs/coding-standards.md](../docs/coding-standards.md) — except for project structure, which belongs in [../docs/project-structure.md](../docs/project-structure.md).

1. **Project structure** — top-level folder layout, where features / services / shared code live, where tests live. Recipes in [../docs/project-structure.md](../docs/project-structure.md) by project type.
2. **Routing conventions** — URL/path/route naming (if applicable), how new routes are added, how route handlers are organised.
3. **Shared type conventions** — where shared types live, how they're versioned, how to introduce a new shared type without breaking other WPs.
4. **Validation conventions** — input validation library or pattern, where validation lives (boundary vs. domain), how validation errors propagate.
5. **Error handling conventions** — error types, propagation rules, user-facing error messages, logging on error.
6. **Testing conventions** — test framework, naming, fixture/mock policy, what coverage level is expected. Cross-reference [../docs/testing-strategy.md](../docs/testing-strategy.md).
7. **Linting conventions** — linter, rule set, how violations are handled (block CI vs. warn).
8. **Formatting conventions** — formatter, on-save vs. pre-commit, how to enforce in CI.
9. **Environment variable conventions** — naming (e.g. `SCREAMING_SNAKE_CASE`), where they're declared, how secrets are kept out of the repo, `.env.example` policy.
10. **Naming conventions** — files, folders, variables, types, branches (default is `wp/NN-<slug>`), git tags.
11. **Logging conventions** — logger, structured vs. unstructured, log levels, what gets logged at each level, PII handling.
12. **Documentation expectations** — what must be documented, where (`docs/` vs. inline), how to keep docs in sync with code.

## Out of scope

- Feature implementation. This WP intentionally produces no feature code.
- Tooling installation steps that are project-specific (covered in onboarding docs).
- Editor / IDE configuration (per-developer).

## Dependencies

None. This is the first WP.

## Files likely touched

- [../CLAUDE.md](../CLAUDE.md) (Conventions section, References section)
- [../docs/coding-standards.md](../docs/coding-standards.md) (most categories land here)
- [../docs/project-structure.md](../docs/project-structure.md) (project-structure category)
- [../docs/testing-strategy.md](../docs/testing-strategy.md) (testing conventions cross-link)
- [../.claude/settings.json](../.claude/settings.json) (permissions tuned to the chosen ecosystem)

## Files explicitly excluded

- Any feature source code. This WP is conventions-only.

## Shared Files Allowed To Change

- [../CLAUDE.md](../CLAUDE.md)
- [../docs/coding-standards.md](../docs/coding-standards.md)
- [../docs/project-structure.md](../docs/project-structure.md)
- [../docs/testing-strategy.md](../docs/testing-strategy.md)
- [../.claude/settings.json](../.claude/settings.json)
- [../.gitignore](../.gitignore)

## API impacts

None.

## DB impacts

None.

## UI impacts

None.

## Acceptance criteria

- [../docs/coding-standards.md](../docs/coding-standards.md) has a section for each of the twelve categories above. Each section is non-empty (no `<!-- scaffold-allow-empty -->` sentinel remaining) and answers the question "what is the convention here?" in a way another agent can follow.
- [../docs/project-structure.md](../docs/project-structure.md) is updated to reflect the project's actual chosen layout (one of the recipes, or a project-specific variant).
- [../CLAUDE.md](../CLAUDE.md)'s **Conventions** section either contains the high-level rules directly or links to the relevant `coding-standards.md` sections.
- `./scripts/template-audit.sh --strict` passes (no leftover `<!-- scaffold-allow-empty -->` sentinels in the docs touched by this WP).

## Tests required

None — this WP doesn't ship code. It does, however, gate the *testing convention* that all subsequent WPs follow.

## Integration notes

**Ratified by WP00 (2026-05-22):**

- **iOS 17 minimum deployment target.** Won over iOS 16 (would have forced a parallel Core Data path) and iOS 18 (no near-term feature gain). See `docs/decisions.md` 2026-05-22.
- **SwiftData as the persistence layer.** Won over Core Data and raw SQLite/GRDB. Migration risk explicitly accepted; if SwiftData's tooling bites, fallback is a dedicated GRDB migration WP. See `docs/decisions.md`.
- **AudioKit as an optional helper, not a hard dependency.** Source nodes that need realtime guarantees skip AudioKit and use `AVAudioSourceNode`.
- **SwiftLint + swift-format split.** SwiftLint owns correctness/safety; swift-format owns layout. SwiftLint's posture is intentionally small at WP00 — widened as the codebase grows.

**Deliberately deferred:**

- **Tightening the SwiftLint audio-thread guard.** Current custom rules cover only `print()` under `Audio/`. WP01 extends to `os_log`, dispatch-async, allocations once `Soundscape/Audio/` actually exists.
- **Xcode project / scheme fixes.** `Soundscape.xcodeproj` has a pre-existing scheme/SUPPORTED_PLATFORMS issue that prevents `xcodebuild` from finding any iOS Simulator destination. `project.pbxproj` is **not** in this WP's allow-list, so it stays unfixed here. WP01's first task is to resolve it — without that, no Swift code can build. Captured in `docs/handoff.md` Open Issues.
- **NLP env-loader implementation.** `.env.example` defines `AURALFLOW_OPENAI_KEY` and `AURALFLOW_ANTHROPIC_KEY`; the build-time script that reads them is WP04's responsibility.
- **README.md replacement.** Still the scaffold's README. Low priority; deferred until there's user-facing copy worth writing.

No conventions were contested — the AuralFlow spec was unambiguous on the high-level choices, and the alternatives considered (logged in `decisions.md`) were genuinely weaker for this project's constraints.

## Handoff requirements

- [x] All twelve categories addressed in [../docs/coding-standards.md](../docs/coding-standards.md).
- [x] Row in [../docs/delivery-plan.md](../docs/delivery-plan.md) marked `merged` (2026-05-22).
- [x] [../docs/handoff.md](../docs/handoff.md) updated to reflect that the foundation gate is OPEN.
- [x] [../docs/decisions.md](../docs/decisions.md) updated with the architectural decisions made during this WP (five new entries on 2026-05-22).
- [x] `./scripts/template-audit.sh --strict` passes.
