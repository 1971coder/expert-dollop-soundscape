# WP02 — MVP: Focus & Sleep

> **Status:** in-review
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
- `Soundscape/Audio/AudioEngine.swift` (modify — register new nodes; **also**: serialise lifecycle methods, see *Inherited from WP01 reviews*)
- `Soundscape/Audio/Internal/ParameterId.swift` (modify — add values; **may move** out of `Internal/` per the 2026-05-29 access-model decision)
- `Soundscape/Audio/Internal/ParameterDelta.swift` (modify — clamp/NaN guard + missing public-type doc; **may move** out of `Internal/`)
- `Soundscape/Audio/Internal/EngineParameters.swift` (modify — demote to `internal`)
- `Soundscape/Audio/Internal/RingBuffer.swift` (modify — demote to `internal`)
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
- `Soundscape/Views/Screens/Home/HomeView.swift` (modify — mode picker; **also**: route engine calls through `SessionStateManager` instead of direct `engine.ingest` / `engine.start`, see *Inherited from WP01 reviews*)
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
- `../docs/project-structure.md` *(to reconcile lines 98-101 and 160 with the 2026-05-29 `Audio/Internal/` access-model decision in `decisions.md`)*
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

### Inherited from WP01 reviews (2026-05-29)

The three reviews of WP01 (integration / QA / architecture) surfaced findings that have no home until WP02 lands. They are listed here so the WP02 agent treats them as required scope, not optional polish. Each item names the file and the proposed fix; if any of them grows beyond a small change, lift it into a dedicated WP.

1. **Serialise `AudioEngine` lifecycle methods** *(QA review — high latency-of-harm)*. `Soundscape/Audio/AudioEngine.swift:41` uses a plain `private var isRunning = false` on a `nonisolated final class`; `start()` / `stop()` are `async` but read/write `isRunning` without isolation. Latent in WP01 because only the main-actor UI calls in; becomes a real race the moment `SessionStateManager` (this WP) calls `start`/`stop` from a non-main context. **Fix:** convert `AudioEngine` to an `actor` (cleanest; flips callers to `await`-flavoured automatically) or serialise lifecycle methods behind an `OSAllocatedUnfairLock` / dedicated dispatch queue. Decide as part of `SessionStateManager`'s design before writing it.

2. **Clamp / NaN-guard `ParameterDelta` at the boundary** *(QA review)*. `Soundscape/Audio/Internal/ParameterDelta.swift:1` does no range or NaN check; a `.nan` value pushed via `ingest(_:)` propagates through `EngineParameters.apply` into render-thread multiplications and produces NaN samples. `coding-standards.md §4` authorises engine-internal clamps as defence-in-depth. **Fix:** clamp `value` to `0...1` (or to the target's documented range) and reject `.nan` / `.infinity` in `ParameterDelta.init`, or in `EngineParameters.apply`. Add a regression test that pushes `.nan` and asserts bounded output.

3. **Route `HomeView` engine calls through `SessionStateManager`** *(architecture review)*. `Soundscape/Views/Screens/Home/HomeView.swift:34` (`onChange`) and `HomeView.swift:60` (`toggle`) call `engine.ingest` and `engine.start` directly. `architecture.md §1` mandates that the presentation layer go through `SessionStateManager`. The bypass was unavoidable in WP01 (no manager existed); this WP creates the manager, so the bypass must be retired in the same change. **Fix:** every `engine.*` call from `HomeView` becomes a `sessionStateManager.*` call. Also short-circuit ingest while no session is active so slider events don't accumulate in the ring buffer pre-Start.

4. **Surface route-change failures to the UI** *(QA review)*. `Soundscape/Audio/AudioEngine.swift:154-158`: if `engine.start()` after a route change throws, the error is logged but `isRunning` stays `true` and the UI is never told. User sees a "playing" Stop button with no audio; only recovery is tap Stop + Start. **Fix:** publish engine-health state from `SessionStateManager` (an `EngineState` enum: `idle | starting | running | failed(reason) | stopping`), and have the view react. Route-change failure transitions to `failed(.routeChangeRecoveryFailed)`.

5. **`api-contract.md §1` is out of sync with shipped `Audio/` surface** *(integration review)*. The doc still declares `public protocol AudioEngineControl { ... }` and `public struct ParameterDelta: Sendable`. The shipped types are `public protocol AudioEngineControl: Sendable` (load-bearing under Swift 6) and `nonisolated public struct ParameterDelta: Sendable`. **Fix:** update §1 to reflect both annotations, and either add the `.filterCutoff` example value (since this WP ships `FilterController`) or strike it from the example list. `api-contract.md` is already in this WP's allow-list.

6. **Reconcile `Audio/Internal/` with the 2026-05-29 access-model decision** *(architecture review)*. `decisions.md` 2026-05-29 makes `Audio/Internal/` strictly module-private. WP01's shipped layout violates this in two ways: (a) `ParameterId.swift` and `ParameterDelta.swift` live in `Internal/` but are public contract types — move them to the top of `Audio/` or to `Audio/Contract/`; (b) `EngineParameters` and `ParameterRingBuffer` are declared `public` but used only inside `Audio/` — demote both to `internal` (Swift's default). Then amend `project-structure.md` lines 98-101 (don't list contract types under `Internal/`) and line 160 (keep the "module-private" rule but it now matches reality). The `project.pbxproj` will need updating for the moved files.

7. **Replace the WP01 `ModePreset` stub with the real type** *(integration review — already in WP02 scope, restated here for completeness)*. `Soundscape/Audio/AudioEngine.swift:10-12` is a placeholder. Delete it and create the real `Soundscape/Modes/ModePreset.swift` per this WP's *Files likely touched*.

8. **Add public-type doc to `ParameterDelta`** *(architecture review)*. `coding-standards.md §12` mandates a one-paragraph doc on public `Audio/` / `Adaptive/` types explaining the realtime contract and threading model. `ParameterDelta.swift:1` has none. Trivial to address when this WP touches the file for the clamp/guard fix (#2).

9. **Cite the Paul Kellet pink-noise coefficients** *(architecture review)*. `Soundscape/Audio/Nodes/NoiseGenerator.swift:54-57` uses Kellet's published coefficients; add a one-line `// Paul Kellet's economy pink-noise filter, musicdsp.org` so a future tuning pass doesn't break the spectrum guarantee. Touch only if this WP modifies `NoiseGenerator.swift`; otherwise defer.

### Related handoff items already tracked

- `scripts/format.sh` xcrun fallback (handoff *Open Issues*) — out of WP02's allow-list; do not touch from this WP, file as its own micro-WP.
- `SoundscapeUITests` is currently skipped in the shared scheme — this WP's required XCUITest (`SoundscapeUITests/CriticalPathTests.swift`) is the trigger to re-enable it. Flip `skipped="YES"` → `skipped="NO"` in `Soundscape.xcodeproj/xcshareddata/xcschemes/Soundscape.xcscheme` as part of the test wiring; the scheme is implicitly in this WP's surface via the `project.pbxproj` allow-list, but call out the scheme edit explicitly in the PR description.

## Handoff requirements

- [x] Row in [../docs/delivery-plan.md](../docs/delivery-plan.md) status updated to `in-review`. *(WP02 row in Active; flip to `merged` and move to Archive on user sign-off after reviews.)*
- [x] [../docs/handoff.md](../docs/handoff.md) reflects new state. *(rewritten 2026-05-29.)*
- [x] [../docs/decisions.md](../docs/decisions.md) updated for: SwiftData schema, rating UI shape, audio session category per mode, background-audio entitlement, AudioEngine lifecycle (lock not actor).
- [x] [../docs/data-model.md](../docs/data-model.md) reflects the as-built schema (rating thumbs encoding; ModePresetRecord vs ModePreset; main-actor repository note).
- [x] Tests pass: `./scripts/test.sh`. *(52 unit + 1 XCUITest, all green against iPhone 17 Pro Max iOS 26.5.)*
- [x] Audit passes: `./scripts/template-audit.sh --strict`. *(0 warnings.)*
