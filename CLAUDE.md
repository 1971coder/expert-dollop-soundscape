# CLAUDE.md

This file is the entry point. Claude Code reads it before doing anything else in this repo. Keep it tight — link out to `docs/` for depth.

## Project Overview

**AuralFlow** is an adaptive ambient soundscape iPhone app that generates continuously evolving procedural audio to support focus, sleep, relaxation, and walking. Audio is synthesised on-device (no playlists, no loops, no cloud playback); behaviour adapts to time of day, session type, motion, heart rate, and prior user feedback. Currently pre-MVP — see [docs/delivery-plan.md](docs/delivery-plan.md) for the four-phase plan.

> **Naming note:** The repository directory and Xcode project are named `Soundscape` / `Soundscape.xcodeproj` for historical reasons. The product is **AuralFlow**. Treat "AuralFlow" as authoritative in docs and user-facing copy; the Xcode names can be renamed in a dedicated WP later.

## Tech Stack

- **Platform:** iOS (iPhone), Swift 5.9+, deployment target iOS 17+ (provisional — confirm in WP00).
- **UI:** SwiftUI.
- **Audio:** `AVAudioEngine` for graph/playback, **AudioKit** for DSP nodes, source units written against `AVAudioSourceNode` where AudioKit doesn't fit.
- **Motion & health:** `CoreMotion` (walking cadence, device motion), `HealthKit` (heart rate; read-only, user-gated).
- **Persistence:** SwiftData (preferred) for sessions, ratings, presets; SQLite fallback only if SwiftData proves limiting.
- **Adaptive logic:** local rules engine (deterministic, on-device). Optional cloud LLM (OpenAI / Claude) for natural-language preset tweaks — strictly opt-in, never on the audio hot path.
- **Build:** Xcode (Xcode project, not SwiftPM at the app level). Internal libraries may be SwiftPM modules.

## Key Commands

- Build:  `./scripts/check.sh`        — runs `xcodebuild build` against the workspace/project
- Test:   `./scripts/test.sh`         — runs unit + UI tests via `xcodebuild test`
- Format: `./scripts/format.sh`       — runs `swift-format` over `Soundscape/`, `SoundscapeTests/`, `SoundscapeUITests/`
- Audit:  `./scripts/template-audit.sh --strict` after any doc edits

Manual / Xcode-side: `Cmd-B` build, `Cmd-U` test, instruments for audio profiling (the audio thread must never block — verify with the Time Profiler).

## Directory Structure

```
Soundscape/                  Xcode app target (Swift source)
  App/                       SwiftUI app entry, scene/root views
  Audio/                     AudioEngine + synth/noise/filter/mixer/binaural nodes
  Adaptive/                  Rules engine, signal collectors (motion/HR), session state
  Modes/                     Focus / Sleep / Relax / Walk mode configs and presets
  Persistence/               SwiftData models, repositories
  Views/                     Reusable SwiftUI views and design-system primitives
  Resources/                 Assets, audio constants tables, localisable strings
SoundscapeTests/             Unit tests (XCTest)
SoundscapeUITests/           UI tests (XCUITest)
Soundscape.xcodeproj/        Xcode project
docs/                        Long-form context (this file links into here)
work-packages/               One file per bounded unit of work
.claude/                     Claude Code config: commands, agents, hooks, settings
scripts/                     Polyglot wrapper scripts (check/test/format/audit)
```

The internal layout under `Soundscape/` above is the **target** layout established by WP00. The repo currently ships the bare Xcode template skeleton; matching it to the layout above is part of WP00 → WP01.

## Conventions

Full conventions live in [docs/coding-standards.md](docs/coding-standards.md) (twelve categories from WP00). High-level rules of thumb:

- **Audio thread is sacred.** No allocations, no locking, no Swift `print`, no `os_log` at trace level on the render thread. Use lock-free ring buffers and `OSAllocatedUnfairLock`-free patterns for parameter passing.
- **Prefer editing existing files** over creating new ones. The app target is small — keep it that way.
- **No comments unless the *why* is non-obvious.** Avoid documenting `what` (the code shows that).
- **Match existing SwiftUI style;** don't reformat unrelated views.
- **No vendor SDKs on the audio path.** Analytics/telemetry, if any, sample off-thread.
- **Local-first.** No network calls in the playback path. Cloud features must be feature-flagged and explicitly opt-in.

## Multi-agent operating model

This template is set up for parallel AI-assisted delivery. Four rules carry the load — every agent must internalise them before doing any work:

1. **Foundation gate.** No feature work begins until WP00 — Foundation closes. See [work-packages/WP00-foundation.md](work-packages/WP00-foundation.md).
2. **WP discipline.** Bounded units of work live in [work-packages/](work-packages/). Each WP enumerates *Files likely touched*, *Files explicitly excluded*, and **Shared Files Allowed To Change** — agents stay strictly inside that allow-list.
3. **Shared-file rule.** Two WPs must not run in parallel if their *Shared Files Allowed To Change* sets overlap. See the parallelism rule at the top of [docs/delivery-plan.md](docs/delivery-plan.md).
4. **Handoff rule.** End every session with [`/update-handoff`](.claude/commands/update-handoff.md). [docs/handoff.md](docs/handoff.md) is a rolling snapshot, **not** an append-only log.

Memory-write boundaries: review commands (`/integrate-feature`, `/qa-review`, `/architecture-review`) update **only `handoff.md`**, never source code, never `decisions.md`, never any other doc. Decisions are user-curated. For the full operating model see [docs/project-structure.md](docs/project-structure.md).

## Scope

**In scope:**

- Procedural, on-device generation of focus / sleep / relax / walk soundscapes that evolve continuously without obvious repetition.
- Adaptive behaviour driven by time-of-day, session type, CoreMotion data, HealthKit heart rate (opt-in), and user ratings.
- Minimal, dark, low-cognitive-load SwiftUI interface; session timers; local session history; per-mode adaptive intensity controls.
- Local privacy — biometric and behavioural data stays on device unless the user explicitly opts in to sync.

**Out of scope:**

- Static music playlists, recorded tracks, vocals, recognisable melodies, "healing frequency" claims.
- Cloud-mandatory playback. Cloud is only optional, only off the audio path, only for personalisation/NLP preset tweaks.
- Android / web / watchOS clients (may come later — explicitly not MVP).
- Sharing, social, account systems (not in current phases).
- Real-time biometric closed-loop intervention beyond gentle ambient modulation.

## Gotchas

- **`AVAudioEngine` and route changes.** The engine must be stopped and reconfigured when the audio session category or output route changes (e.g. Bluetooth disconnect). Handle `AVAudioSession.routeChangeNotification` from day one.
- **Background audio entitlement.** Sleep mode is the obvious use-case — `Background Modes → Audio` must be enabled in the entitlements, and the app must keep the engine running deliberately (don't pause on backgrounding for sleep sessions).
- **HealthKit is read-conditional.** Heart-rate reads require explicit authorisation. The adaptive layer must work without HR — degrade gracefully, don't crash or refuse to start a session.
- **`CoreMotion` permission strings.** Missing `NSMotionUsageDescription` will crash on first access. Same for HealthKit (`NSHealthShareUsageDescription`).
- **Audio session category.** `.playback` (mixWithOthers: false) is correct for focus/sleep; consider `.ambient` for the Walk mode tutorial so external sound is preserved. Decide explicitly per mode.
- **Procedural ≠ random.** Avoid white noise / pure-random parameter drift — that's audibly fatiguing. Use slow LFOs, low-pass-filtered noise, and stochastic-yet-bounded modulation.
- **Brown vs pink noise generation.** Naive integration drifts to DC over time — apply a leaky integrator (one-pole HPF at ~5 Hz) or you'll silently kill the woofer.
- **No vocals, no melody.** Reviewers will flag anything that sounds like a song. The product principle is low-attention-demand; any sustained pitch sequence is a bug.
- **SwiftData is iOS 17+** and still has rough edges — back up the schema decision in `docs/decisions.md` when it's made.
- **Naming drift.** Repo dir = `Soundscape`, Xcode target = `Soundscape`, product = `AuralFlow`. Don't rename in passing — schedule it as its own WP because it touches the Xcode project and tests.

## References

- Architecture:      [docs/architecture.md](docs/architecture.md)
- Requirements:      [docs/requirements.md](docs/requirements.md)
- Decisions:         [docs/decisions.md](docs/decisions.md)
- Data model:        [docs/data-model.md](docs/data-model.md)
- Adoption:          [docs/adoption-checklist.md](docs/adoption-checklist.md)
- Project structure: [docs/project-structure.md](docs/project-structure.md)
- Delivery plan:     [docs/delivery-plan.md](docs/delivery-plan.md)
- Testing strategy:  [docs/testing-strategy.md](docs/testing-strategy.md)
- Coding standards:  [docs/coding-standards.md](docs/coding-standards.md)
- Handoff:           [docs/handoff.md](docs/handoff.md)
- Glossary:          [docs/glossary.md](docs/glossary.md)
