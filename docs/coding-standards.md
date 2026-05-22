# Coding Standards

The agreed conventions for AuralFlow, by category. This file is the canonical home for the twelve categories enumerated in [WP00 — Foundation](../work-packages/WP00-foundation.md). **Ratified by WP00 on 2026-05-22.** Subsequent refinements are by amendment — leave a dated note in the relevant section when a rule changes.

When CLAUDE.md's *Conventions* section conflicts with this file, **this file wins** — and CLAUDE.md should be updated to match.

---

## 1. Project structure

See [project-structure.md](project-structure.md). Top-level summary: app source under `Soundscape/` split by concern (`App/`, `Audio/`, `Adaptive/`, `Modes/`, `Persistence/`, `Views/`, `Resources/`), tests under `SoundscapeTests/` and `SoundscapeUITests/`.

## 2. Routing conventions

Not applicable — AuralFlow has no URL/HTTP routing. SwiftUI navigation conventions:

- Use `NavigationStack` (iOS 16+) over `NavigationView`.
- One root-level stack per top-tab; deep links resolve to a `Route` enum decoded at the root.
- Screens are pushed by `Route` values, never by direct view construction inside navigation modifiers.

## 3. Shared type conventions

- "Shared types" = types used across the module boundaries described in [api-contract.md](api-contract.md). These live in `Soundscape/` at the **lowest common module** (often `Audio/` for audio types, `Persistence/Models/` for entities).
- Cross-module shared types are `public` (or `package` once we move to a package layout).
- A WP introducing a new shared type adds it to the relevant section of [api-contract.md](api-contract.md) and lists the file in its *Shared Files Allowed To Change*.
- Avoid `Any`, `[String: Any]`, untyped dictionaries on the audio path — use enums and structs.

## 4. Validation conventions

- **Boundary validation** for any user input (intensity slider clamps, preset name length, free-text feedback length) — done in `SessionStateManager` or repository layer before persisting.
- **No validation on the audio render thread.** Inputs to the engine are already bounded by `ParameterDelta`'s contract (`value: Float` normalised 0…1).
- Validation failures surface as Swift `throw`s, not silent clamps in user-facing flows. (Engine-internal clamps are fine — defence in depth.)

## 5. Error handling conventions

- Use Swift's typed `Result` / throwing functions; **no `NSError`** in app code.
- Errors crossing the UI boundary become user-facing messages via a `UserFacingError` envelope (one source of truth for copy).
- **Audio thread:** non-recoverable errors set a flag and bail to silence; recovery is `SessionStateManager`'s job.
- Log on error at `error` level (see §11). Never log PII or raw HealthKit values.
- Never use `try!` outside of `XCTest` and trivially safe contexts.

## 6. Testing conventions

See [testing-strategy.md](testing-strategy.md). Summary:

- **XCTest** is the unit framework.
- **XCUITest** for end-to-end UI flows; only the critical mode-pick-and-start flow gets an XCUITest in MVP.
- Test files mirror source files: `Foo.swift` → `FooTests.swift`.
- Use real implementations where possible; mock at protocol boundaries (`AudioEngineControl`, repositories).
- Realtime DSP nodes are tested via **offline rendering** with `AVAudioEngine.manualRenderingMode` — fast, deterministic.

## 7. Linting conventions

- **SwiftLint** with the project ruleset committed at [`.swiftlint.yml`](../.swiftlint.yml) (introduced by WP00).
- `./scripts/check.sh` runs `swiftlint --strict` when the binary is installed and the config is present — every warning is a build failure.
- New rules go in `.swiftlint.yml` (not disabled inline) so the policy is grep-able.
- SwiftLint owns **correctness and safety** (force-unwrap, force-try, audio-thread `print`, naming). Whitespace and layout are swift-format's job — do not double-enforce them in SwiftLint.
- A custom rule in `.swiftlint.yml` already flags `print()` anywhere under `Audio/`. Tighten the audio-thread guard further in WP01 once `Soundscape/Audio/` actually exists.

## 8. Formatting conventions

- **swift-format** (Apple's, JSON config) is the formatter. Config committed at [`.swift-format`](../.swift-format) (WP00).
- Line length is **120**; SwiftLint's hard error threshold is 200 — the formatter is the first line of defence, the linter catches what survives.
- Run on save in Xcode (per-developer setting; documented in onboarding).
- Run by `./scripts/format.sh` and enforced in CI via a non-zero exit if the diff is non-empty.

## 9. Environment variable conventions

- iOS apps rarely need env vars; secrets (e.g. OpenAI / Anthropic API keys for Phase 4) live outside source control. Local dev values live in `.env` (gitignored); production values are injected by a build-time script delivered in WP04.
- [`.env.example`](../.env.example) is the canonical list of recognised variables. Any new variable must be added there in the same WP that introduces it.
- Naming: `SCREAMING_SNAKE_CASE`, prefixed `AURALFLOW_` (e.g. `AURALFLOW_OPENAI_KEY`, `AURALFLOW_ANTHROPIC_KEY`).
- No secrets in CI logs; no `print`/`os_log` of variable contents.

## 10. Naming conventions

| Subject | Convention | Example |
|---|---|---|
| Types (`class`, `struct`, `enum`, `actor`, `protocol`) | UpperCamelCase | `SessionStateManager` |
| Methods, properties, variables | lowerCamelCase | `startSession()` |
| Enum cases | lowerCamelCase | `ModeKind.focus` |
| Files | UpperCamelCase, matching the primary type | `SessionStateManager.swift` |
| Folders | lowerCamelCase if grouping, UpperCamelCase if module-like | `Audio/Nodes/DroneSynth.swift` |
| Test files | `<Subject>Tests.swift` | `DroneSynthTests.swift` |
| Branches | `wp/NN-<slug>` (kebab-case slug) | `wp/01-audio-prototype` |
| Tags | `v<MAJOR>.<MINOR>.<PATCH>` | `v0.1.0` |
| Booleans | start with `is`, `has`, `should` | `isPlaying`, `hasMicrophonePermission` |
| Acronyms | UpperCamelCase treats acronyms as words: `URL` in types, `url` in identifiers, except established Apple style (`URL` is a type) | `urlString`, `URLProvider` |

## 11. Logging conventions

- **`os.Logger`** is the standard logger. One `Logger` per file, with subsystem `app.auralflow` and a category matching the module (e.g. `audio.engine`, `adaptive.controller`).
- Levels:
  - `.debug` — verbose; off in release.
  - `.info` — lifecycle events (session start/end, engine init).
  - `.notice` — meaningful state changes (mode switch, route change).
  - `.error` — recoverable failures.
  - `.fault` — programming errors / unrecoverable.
- **PII / biometrics never logged.** Heart-rate values, raw motion data, user free-text feedback — none of these appear in logs.
- **No logging on the audio render thread.** Period.

## 12. Documentation expectations

- **CLAUDE.md** is the entry point; it points to `docs/`.
- **Inline docs** (`///`) only when the *why* is non-obvious. The "what" comes from the name.
- **Public protocols and types in `Audio/` and `Adaptive/` get a one-paragraph doc** explaining the realtime contract and threading model.
- **Decisions** go in `decisions.md` with the date + WP that made them. Append-only, superseded never deleted.
- **Architecture changes** update [architecture.md](architecture.md) in the same WP.

---

## WP00 closeout checklist

- [x] All twelve categories above reviewed and ratified by the WP00 agent (2026-05-22).
- [x] `.swiftlint.yml`, `.swift-format`, `.env.example` committed.
- [x] CLAUDE.md *Conventions* section links to this file (see CLAUDE.md *Conventions*).
- [x] `./scripts/template-audit.sh --strict` passes.
