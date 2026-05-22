# WP01 — Audio prototype

> **Status:** proposed
> **Branch:** `wp/01-audio-prototype`
> **Assigned:** claude (pair with human)
> **Depends on:** WP00

## Behaviour rules for the implementing agent

Before reading any further, the implementing agent must abide by these rules. They are the reason the WP exists in this shape.

- **Avoid unrelated refactors.** Make the smallest change that satisfies the acceptance criteria. Don't tidy adjacent code, don't rename things "while you're there", don't restructure folders unless that *is* the WP.
- **Avoid changing shared contracts unnecessarily.** Shared types, API contracts, DB schemas, error formats, and other files used by other features are off-limits unless explicitly listed in **Shared Files Allowed To Change**.
- **Audio-thread sanctity:** no allocations, no locks, no logging on the render path. Verify with Instruments → Time Profiler before declaring success.
- **Document assumptions.** If you make a judgement call that another agent could reasonably make differently, write it down — either in this file's *Integration notes* or in [../docs/handoff.md](../docs/handoff.md).
- **Update [../docs/handoff.md](../docs/handoff.md)** when you finish (or stop). Use `/update-handoff` if available.

---

## Objective

Stand up the core `AudioEngine` graph with the smallest set of nodes that produces an audibly evolving ambient sound: a `DroneSynth`, a `NoiseGenerator` (pink + brown with leaky integrator), and a `Mixer`. Wire a minimal SwiftUI screen that can start and stop the engine. This is the foundation that every later phase builds on.

## Scope

- Create `Soundscape/Audio/AudioEngine.swift` with the `AudioEngineControl` protocol from [api-contract.md §1](../docs/api-contract.md#1-audioengine-command-surface).
- Implement `DroneSynth`, `NoiseGenerator`, `Mixer` as `AVAudioSourceNode` / `AVAudioUnit` subclasses.
- Implement the lock-free SPSC `RingBuffer` and `ParameterDelta` types (the parameter pipe).
- Implement a stub `ParameterId` enum with the values needed for this prototype (drone detune, drone gain, noise balance, master gain).
- Configure the `AVAudioSession` (`.playback`) with route-change handling.
- Build a minimal `Home` screen: one **Start / Stop** button + a master gain slider.
- Offline-render tests for `DroneSynth` and `NoiseGenerator` (deterministic with seeded RNG).
- A smoke test that the engine starts, produces non-silent buffers, and stops cleanly.

## Out of scope

- Mode presets, session persistence, ratings, timers — all WP02.
- `PadSynth`, `PulseModulator`, `FilterController`, `BinauralGenerator` — all WP02.
- `AdaptiveController` and any signal collectors — WP03.
- Background audio entitlement — WP02 (Sleep mode is when we need it).
- Any UI beyond the single Start/Stop+master-gain screen.

## Dependencies

- WP00 must be `merged` first — coding standards, lint, and format configs must exist.

## Files likely touched

- `Soundscape/Audio/AudioEngine.swift` (new)
- `Soundscape/Audio/Nodes/DroneSynth.swift` (new)
- `Soundscape/Audio/Nodes/NoiseGenerator.swift` (new)
- `Soundscape/Audio/Nodes/Mixer.swift` (new)
- `Soundscape/Audio/Internal/RingBuffer.swift` (new)
- `Soundscape/Audio/Internal/ParameterDelta.swift` (new)
- `Soundscape/Audio/Internal/ParameterId.swift` (new — minimal set)
- `Soundscape/App/AuralFlowApp.swift` (modify — engine DI)
- `Soundscape/Views/Screens/Home/HomeView.swift` (new)
- `SoundscapeTests/AudioTests/DroneSynthTests.swift` (new)
- `SoundscapeTests/AudioTests/NoiseGeneratorTests.swift` (new)
- `SoundscapeTests/AudioTests/AudioEngineSmokeTests.swift` (new)
- `Soundscape.xcodeproj/project.pbxproj` (modify — file references)

## Files explicitly excluded

- `Soundscape/Persistence/**` — no persistence in this WP.
- `Soundscape/Adaptive/**` — no adaptive layer yet.
- `Soundscape/Modes/**` — modes belong to WP02.
- `docs/data-model.md` — no DB changes yet.

## Shared Files Allowed To Change

- `Soundscape/Audio/Internal/ParameterId.swift` *(new, introduced here — this becomes a shared contract for later WPs)*
- `Soundscape.xcodeproj/project.pbxproj` *(necessary to register new files)*
- `Soundscape/App/AuralFlowApp.swift` *(DI wiring — narrow change)*
- `../docs/handoff.md`
- `../docs/delivery-plan.md` *(status update only)*

> Note: `ParameterId.swift` is introduced here but **will be shared with WP03** when `AdaptiveController` lands. WP01 should add only the values it needs; WP03 extends the enum.

## API impacts

- Introduces the `AudioEngineControl` public protocol (see [../docs/api-contract.md §1](../docs/api-contract.md#1-audioengine-command-surface)).
- Introduces `ParameterDelta` and a minimal `ParameterId` enum (additive, no removals).

## DB impacts

None.

## UI impacts

- New `HomeView` with a single Start/Stop button and a master-gain slider. Dark, minimal — matches the design principles in [requirements.md §2.3](../docs/requirements.md#23-calm-interaction-model).
- No navigation hierarchy yet; the entire app is one screen.

## Acceptance criteria

- `AudioEngineControl` is the only public surface from `Audio/` to the rest of the app.
- Tapping **Start** produces audible output within ~250 ms.
- The output is **not** a static tone or static noise — `DroneSynth` produces audible slow detune; `NoiseGenerator` produces stable brown noise without DC drift.
- Master-gain slider changes output volume via `ingest(ParameterDelta)` — confirms the parameter pipe works end-to-end.
- Offline-render tests for `DroneSynth` and `NoiseGenerator` pass deterministically with a seeded RNG.
- Instruments Time Profiler shows zero allocations on the render thread during a 30 s session.
- `./scripts/check.sh`, `./scripts/test.sh`, `./scripts/format.sh` all pass.

## Tests required

- **Unit (offline render):** `DroneSynth` produces output with expected RMS, expected spectrum shape, no NaN/Inf samples over a 5 s render.
- **Unit (offline render):** `NoiseGenerator` brown-noise variant stays within ±0.1 mean over a 30 s render (leaky-integrator check).
- **Unit:** `RingBuffer` SPSC correctness — single-producer/single-consumer round-trip; verifies no allocation in the producer path.
- **Smoke:** engine starts, renders a non-silent 1 s buffer in manual-rendering mode, stops cleanly.
- **(Optional) XCUITest:** Start/Stop button flips state — only if XCUITest infra is wired by WP02; otherwise defer.

## Integration notes

- The `AVAudioSession` category here is `.playback`. WP02 will revisit per mode (e.g. `.ambient` for Walk).
- `ParameterId` is intentionally tiny in this WP; WP03 extends it. Anyone adding a value here must coordinate with WP03 if WP03 is in flight.
- `AudioKit` is **not** introduced in this WP — hand-rolled `AVAudioSourceNode`s are sufficient. Reconsider in WP02 if any node would benefit from AudioKit utilities.
- No background-audio entitlement is set yet. Engine **will stop** when the app is backgrounded. WP02 changes this for Sleep mode.

## Handoff requirements

- [ ] Row in [../docs/delivery-plan.md](../docs/delivery-plan.md) status updated to `merged`.
- [ ] [../docs/handoff.md](../docs/handoff.md) reflects new state via `/update-handoff`.
- [ ] [../docs/decisions.md](../docs/decisions.md) updated if anything load-bearing was decided (e.g. AudioKit yes/no, SwiftPM split).
- [ ] Tests pass: `./scripts/test.sh`.
- [ ] Audit passes: `./scripts/template-audit.sh --strict`.
