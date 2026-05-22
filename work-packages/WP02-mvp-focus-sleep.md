# WP02 — MVP: Focus & Sleep

> **Status:** proposed
> **Branch:** `wp/02-mvp-focus-sleep`
> **Assigned:** claude (pair with human)
> **Depends on:** WP01

## Behaviour rules for the implementing agent

- **Avoid unrelated refactors.** Make the smallest change that satisfies the acceptance criteria. This WP is large enough already.
- **Avoid changing shared contracts unnecessarily.** Especially `ParameterId.swift`: add values only as needed for the MVP modes.
- **Audio-thread sanctity.** Same rule as WP01 — no allocations, no locks, no logging on render.
- **Background audio is an explicit feature.** Add the entitlement; verify Sleep mode keeps playing with the screen locked.
- **Document assumptions.** Especially around the SwiftData schema and the rating UI shape (thumbs vs 1–5).
- **Update [../docs/handoff.md](../docs/handoff.md)** when done.

---

## Objective

Deliver the MVP feature set from [requirements.md §6](../docs/requirements.md#6-mvp-features-phase-2-deliverable): Focus mode, Sleep mode, procedural drone + pink/brown noise, adaptive intensity sliders, session timers, local session history, user ratings. After this WP merges, the product is shippable to internal testers.

## Scope

- Implement `PadSynth`, `PulseModulator`, `FilterController` nodes (extending WP01's graph).
- Define `Focus` and `Sleep` `ModePreset`s with parameter snapshots tuned to [requirements.md §3.1–3.2](../docs/requirements.md#31-focus-mode).
- `SessionStateManager` (main-actor) owns the active session lifecycle; converts user intent to engine commands.
- SwiftData stack: `Session`, `ModePreset`, `RatingEvent` entities; three repositories per [api-contract.md §2](../docs/api-contract.md#2-persistence-repository-surface).
- Session timer UI; intensity slider; mode-picker on the home screen; session-history list; post-session rating prompt.
- **Background audio entitlement** for Sleep mode; lifecycle handling so Sleep continues in background while Focus pauses.
- One XCUITest covering the critical path: pick mode → start → wait → stop → rate → see in history.

## Out of scope

- Relax mode (Phase 3, WP03).
- Walk mode (Phase 3, WP03).
- `AdaptiveController` and signal collectors (motion, heart rate) — WP03.
- Binaural beats — Phase 3/4 decision.
- Any cloud / AI features — WP04.
- Onboarding flow — defer to a dedicated UX WP.
- Settings beyond intensity (privacy, about, etc. — separate WP).

## Dependencies

- WP01 merged. `AudioEngine` graph + parameter pipe + Home view must exist.

## Files likely touched

- `Soundscape/Audio/Nodes/PadSynth.swift` (new)
- `Soundscape/Audio/Nodes/PulseModulator.swift` (new)
- `Soundscape/Audio/Nodes/FilterController.swift` (new)
- `Soundscape/Audio/AudioEngine.swift` (modify — register new nodes)
- `Soundscape/Audio/Internal/ParameterId.swift` (modify — add values)
- `Soundscape/Modes/ModeKind.swift` (new)
- `Soundscape/Modes/ModePreset.swift` (new)
- `Soundscape/Modes/Presets/FocusPresets.swift` (new)
- `Soundscape/Modes/Presets/SleepPresets.swift` (new)
- `Soundscape/Persistence/Models/Session.swift` (new)
- `Soundscape/Persistence/Models/ModePreset+Model.swift` (new)
- `Soundscape/Persistence/Models/RatingEvent.swift` (new)
- `Soundscape/Persistence/Repositories/SessionRepository.swift` (new)
- `Soundscape/Persistence/Repositories/PresetRepository.swift` (new)
- `Soundscape/Persistence/Repositories/AdaptiveProfileRepository.swift` (new, even if empty — protocol only)
- `Soundscape/Sessions/SessionStateManager.swift` (new)
- `Soundscape/Views/Screens/Home/HomeView.swift` (modify — mode picker)
- `Soundscape/Views/Screens/Session/SessionView.swift` (new)
- `Soundscape/Views/Screens/Session/RatingPromptView.swift` (new)
- `Soundscape/Views/Screens/History/HistoryView.swift` (new)
- `Soundscape/App/AuralFlowApp.swift` (modify — wire repositories)
- `Soundscape/Resources/Info.plist` (modify — background audio entitlement)
- `Soundscape.entitlements` (new or modify)
- `Soundscape.xcodeproj/project.pbxproj` (modify)
- `../docs/data-model.md` (modify — confirm schema as built)
- `../docs/api-contract.md` (modify — note any deltas from spec)
- `SoundscapeTests/**` (extensive new tests)
- `SoundscapeUITests/CriticalPathTests.swift` (new)

## Files explicitly excluded

- `Soundscape/Adaptive/**` — that's WP03.
- `Soundscape/Audio/Nodes/BinauralGenerator.swift` — Phase 3/4.

## Shared Files Allowed To Change

- `Soundscape/Audio/AudioEngine.swift`
- `Soundscape/Audio/Internal/ParameterId.swift` *(coordinate if WP03 is in flight)*
- `Soundscape/App/AuralFlowApp.swift`
- `Soundscape/Resources/Info.plist`
- `Soundscape.entitlements`
- `Soundscape.xcodeproj/project.pbxproj`
- `../docs/data-model.md`
- `../docs/api-contract.md`
- `../docs/handoff.md`
- `../docs/delivery-plan.md`

## API impacts

- Adds `ParameterId` values: `padCutoff`, `padResonance`, `pulseRate`, `pulseDepth`, `filterCutoff`, `noiseColour`.
- Adds repository protocols listed in [api-contract.md §2](../docs/api-contract.md#2-persistence-repository-surface).
- Adds `ModeKind` enum and `ModePreset` (the shared type backing both DSP and persistence).

## DB impacts

- New SwiftData schema: `Session`, `ModePreset` (persisted form), `RatingEvent`.
- Initial schema; no migration concerns yet.
- Update [data-model.md](../docs/data-model.md) with the as-built schema.

## UI impacts

- Home: mode picker (Focus, Sleep — Relax/Walk visible as "coming soon" or hidden).
- New Session screen: large timer; intensity slider; **End** button.
- Rating prompt after session end (skippable).
- History screen: list of completed sessions with mode, duration, rating.
- All screens dark/minimal per [requirements.md §2.3](../docs/requirements.md#23-calm-interaction-model).

## Acceptance criteria

- Pick **Focus** → tap **Start** → engine starts within 250 ms → timer counts down for the configured duration → engine stops → rating prompt appears → rating persists → history shows the session.
- Pick **Sleep** → start → lock the device → audio continues playing → unlock and end → session persists.
- Intensity slider audibly affects the engine (more presence at higher intensity, smoother fades at lower).
- Background-audio entitlement is set; Sleep mode survives `.background` scene phase.
- All Persistence repository methods have happy-path + at least one error-path test.
- Each new node has an offline-render test.
- XCUITest critical-path test passes.
- Coverage targets in [testing-strategy.md](../docs/testing-strategy.md) met for `Audio/`, `Adaptive/`, `Persistence/`.

## Tests required

- **Unit (offline render):** `PadSynth`, `PulseModulator`, `FilterController` — each gets spectrum / RMS / behaviour checks.
- **Unit:** Each repository method (happy + error path).
- **Unit:** `SessionStateManager` state machine (start → running → end → rated).
- **Unit:** Preset parameter snapshots round-trip through SwiftData.
- **Integration:** Engine + state manager — a full session lifecycle, in-memory store.
- **UI:** XCUITest critical-path test.

## Integration notes

- Background audio is a sensitive area — review the entitlement and Info.plist changes carefully.
- The rating UI shape (thumbs vs 1–5) is a UX call; decide in this WP and record in `decisions.md`.
- `ParameterId` additions must coordinate with WP03 if WP03 is in flight — both WPs touch the same enum.
- Audio fixtures committed under `SoundscapeTests/AudioTests/Fixtures/` with a generator script.

## Handoff requirements

- [ ] Row in [../docs/delivery-plan.md](../docs/delivery-plan.md) status updated to `merged`.
- [ ] [../docs/handoff.md](../docs/handoff.md) reflects new state via `/update-handoff`.
- [ ] [../docs/decisions.md](../docs/decisions.md) updated for: SwiftData schema, rating UI shape, audio session category per mode, background-audio entitlement.
- [ ] [../docs/data-model.md](../docs/data-model.md) reflects the as-built schema.
- [ ] Tests pass: `./scripts/test.sh`.
- [ ] Audit passes: `./scripts/template-audit.sh --strict`.
