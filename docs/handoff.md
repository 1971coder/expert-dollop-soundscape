# Handoff

> Maintained by [`/update-handoff`](../.claude/commands/update-handoff.md). This is a **rolling snapshot, not an append-only log.** The `/update-handoff` command's job is to keep these sections current — overwriting `Current Snapshot`, pruning closed items, and (optionally) moving useful history to `Historical Notes`.

## Current Snapshot

**2026-05-29.** **WP01 — Audio prototype passed integration review and is ready to mark `merged`** (user action — see *Next Recommended Steps*). The audio graph (DroneSynth + NoiseGenerator + Mixer), lock-free SPSC parameter pipe, public `AudioEngineControl` surface, AVAudioSession route-change handling, and minimal SwiftUI Home screen are all implemented. The Xcode project was narrowed to iOS-only (`SUPPORTED_PLATFORMS = iphoneos iphonesimulator`, `TARGETED_DEVICE_FAMILY = "1"`, `SDKROOT = iphoneos`); a shared scheme was added at `Soundscape.xcodeproj/xcshareddata/xcschemes/Soundscape.xcscheme`; the source tree was restructured to match `docs/project-structure.md` (Item.swift / ContentView.swift / SoundscapeApp.swift / SoundscapeTests.swift removed; `App/AuralFlowApp.swift` + `Audio/**` + `Views/Screens/Home/HomeView.swift` created). Four XCTest test files cover offline-render assertions for DroneSynth and NoiseGenerator, the ring buffer's SPSC concurrency, and the engine graph smoke.

**Post-merge hardening (commit `604d9e8`, 2026-05-29):** `ParameterRingBuffer` gained explicit `OSMemoryBarrier()` release/acquire fences around head/tail publication (replacing the prior "relaxed ordering is fine on ARM64" assumption — the compiler is free to reorder writes regardless of hardware atomicity). `ParameterId` and `ParameterDelta` were marked `nonisolated` so they cross the Adaptive / audio-render isolation boundary cleanly under Swift 6 strict concurrency. The `SoundscapeUITests` `TestableReference` was skipped in the shared scheme while there is no UI worth driving.

**Verification status:** strict template audit, `./scripts/check.sh`, and `./scripts/test.sh` all pass against the `iPhone 17 Pro Max, iOS 26.5` simulator. The iOS 26.5 runtime is now installed locally; the previously-blocking simulator gap is resolved.

## Recent Completed Work

- **WP01 — Audio prototype** (integration-reviewed 2026-05-29, ready to mark `merged`) — Engine + nodes + ring buffer + HomeView + tests + Xcode scheme/platform narrowing + source-tree restructure, plus the `604d9e8` thread-safety hardening (memory barriers + `nonisolated` annotations + skipped UI-test scheme entry). Integration review found no blocking issues; one should-fix (api-contract.md drift) and a handful of nits, all captured below. See `work-packages/WP01-audio-prototype.md` *Integration notes* for the design decisions baked in.
- **WP00 — Foundation** (merged 2026-05-22) — Conventions ratified, toolchain configs shipped. Archived in `delivery-plan.md`.

## Open Issues

- **`docs/api-contract.md §1` is out of sync with the shipped `Audio/` surface.** The doc declares `public protocol AudioEngineControl { ... }` and `public struct ParameterDelta: Sendable`. The actual shipped types are `public protocol AudioEngineControl: Sendable` and `nonisolated public struct ParameterDelta: Sendable` (`Soundscape/Audio/AudioEngine.swift:16`, `Soundscape/Audio/Internal/ParameterDelta.swift:1`). The `: Sendable` conformance on the protocol is load-bearing under Swift 6 strict concurrency — every implementer (including `Soundscape/Views/Screens/Home/HomeView.swift:77`'s `PreviewEngine`) must be Sendable. **Fix:** fold into the next WP that touches `docs/api-contract.md` (WP02 already has `API impacts: yes` and will need to update §1 anyway). Memory-write boundary prevented the integration command from making this edit directly.
- **`scripts/format.sh` does not fall back to `xcrun swift-format`.** swift-format ships with Xcode at `xcrun swift-format` but the script only looks at `$PATH`. Out of WP01's allow-list (`scripts/format.sh` is not in *Shared Files Allowed To Change*) — file a tiny follow-up WP or bundle into the next scripts/* touch.
- **`AudioEngine` lifecycle isn't thread-serialised** *(QA review 2026-05-29)*. `Soundscape/Audio/AudioEngine.swift:41` uses a plain `private var isRunning = false` on a `nonisolated final class`; `start()` and `stop()` are `async` but mutate `isRunning` without isolation. Latent in WP01 because only the main-actor UI calls in, but becomes a real race the moment WP02's `SessionStateManager` or WP03's `AdaptiveController` call `start`/`stop`/`ingest` from non-main threads. **Fix in WP02:** convert `AudioEngine` to an `actor`, or serialise lifecycle methods behind an `OSAllocatedUnfairLock` / dedicated dispatch queue.
- **`ParameterDelta` accepts unbounded `Float`** *(QA review 2026-05-29)*. `Soundscape/Audio/Internal/ParameterDelta.swift:1` does no range/NaN check; `coding-standards.md §4` authorises engine-internal clamps as defence-in-depth, but WP01 has none. A `.nan` value pushed via `ingest(_:)` propagates through `EngineParameters.apply` into render-thread multiplications and produces NaN output samples (silenced or popping depending on the device). Existing `DroneSynthTests` asserts no NaN/Inf in *output*; the input-side guard is the missing half. **Fix in WP02:** clamp in `ParameterDelta.init` or `EngineParameters.apply`, and add a NaN-input regression test.

## Assumptions In Play

- **No first-party server.** No backend in MVP; cloud LLM calls (Phase 4) are vendor-direct.
- **Background audio entitlement** will be added in WP02 (when Sleep mode ships). WP01 deliberately doesn't enable it.
- **One designated parameter drainer.** `DroneSynth` drains the ring buffer each render block; other nodes read from the shared `EngineParameters`. NoiseGenerator may see params one block stale (≤ ~6 ms) — acceptable for ambient parameters but the assumption is worth re-validating when WP03 wires AdaptiveController-driven parameter changes at higher rate.

## Blockers

- WP02 / WP03 are blocked on WP01 being marked `merged` in `delivery-plan.md` (user action — integration review found nothing blocking). The iOS 26.5 simulator runtime is installed; tests are green.

## Technical Debt To Revisit

- **Naming drift:** repo dir and Xcode target are `Soundscape`; product / Swift entry point are `AuralFlow`. The Xcode target rename remains its own deferred WP (see `decisions.md` 2026-05-17).
- **`README.md` at the repo root** is still the scaffold's README, not AuralFlow's. Low priority.
- **SwiftLint custom rules under `Audio/`** are still minimal (one rule: no `print()` under `Audio/`). Tighten in WP02 — extend to flag `os_log`, dispatch-async, allocations.
- **`ParameterRingBuffer` ordering — interim solution in place.** Commit `604d9e8` added `OSMemoryBarrier()` release/acquire fences around head/tail publication. The barriers are the interim mechanism; long-term, swap to `Synchronization.Atomic<UInt32>` once the deployment target reaches iOS 18+ (lets the type carry explicit `.acquire` / `.release` ordering and drops the explicit fences). Track alongside the deployment-target bump WP.
- **`SoundscapeUITests` is skipped in the shared scheme** (`Soundscape.xcodeproj/xcshareddata/xcschemes/Soundscape.xcscheme`, commit `604d9e8`). The target itself still exists; only the `TestableReference` is `skipped="YES"`. Re-enable once WP02 ships UI worth driving (mode picker + session screen).
- **`ModePreset` stub** lives in `Soundscape/Audio/AudioEngine.swift`. WP02 deletes it and creates the real `Modes/ModePreset.swift`.
- **`AudioEngine.handleRouteChange(_:)` has no automated coverage** — hard to drive without an integration test on a real device. Defer to WP02 when route logic matters more (headphone-gated binaural in WP02/WP03 will force the issue).
- **`AVAudioFormat` constructor duplicated across `AudioEngine.swift:44` and three test files.** Acceptable at this scale; factor into a `SoundscapeTests/AudioTests/TestSupport/` helper if WP02 adds more audio test files.
- **`Audio/Internal/` ACLs over-exposed** *(architecture review 2026-05-29)*. `Soundscape/Audio/Internal/EngineParameters.swift:9` and `Soundscape/Audio/Internal/RingBuffer.swift:15` are declared `public` despite being used only inside `Audio/`. `docs/project-structure.md` line 160 says `Audio/Internal/` is module-private. The `public` ACLs let a future caller (WP03 `AdaptiveController` is the obvious risk) bypass `AudioEngineControl.ingest(_:)` and reach straight into the SPSC buffer or the shared `EngineParameters` instance — breaking the lock-free contract and the layered architecture. **Fix:** demote both to `internal` in WP02's first touch on `Audio/`. (Distinct from `ParameterId` / `ParameterDelta`, which are legitimately public per api-contract.md §1 — see the related contradiction in `project-structure.md` flagged below.)
- **`project-structure.md` is internally inconsistent on what `Audio/Internal/` means** *(architecture review 2026-05-29)*. Line 101 lists `ParameterId.swift` under `Audio/Internal/` as a "Shared enum — read api-contract.md"; line 160 declares the entire directory module-private. The two cannot both be true. Resolve as a small docs WP (or fold into WP02's docs touch): either move `ParameterId.swift` + `ParameterDelta.swift` out of `Internal/`, or amend line 160 to acknowledge the public contract-type exception. Whichever direction is chosen should also be recorded in `docs/decisions.md` so future WPs don't relitigate it.

## Next Recommended Steps

1. **Open the Home screen on a simulator or device** and verify the in-app acceptance criteria: tap play → audible drone + soft noise within ~250 ms; master-gain slider changes volume in real time; Stop terminates the engine cleanly. (`work-packages/WP01-audio-prototype.md` *Acceptance criteria*.)
2. **Run Instruments → Time Profiler** for a 30 s session and confirm zero allocations on the audio render thread. This is the last automated-or-manual WP01 acceptance criterion still pending verification.
3. **Mark WP01 `merged`** in `work-packages/WP01-audio-prototype.md` (status header) and in `docs/delivery-plan.md` (move the WP01 row from *Active* to *Archive*) — this unblocks WP02 / WP03. Integration review found nothing blocking; the should-fix and nits below are all deferable to WP02.
4. **Fold the api-contract.md drift into WP02.** WP02 already has `API impacts: yes` and touches `docs/api-contract.md`; update §1 there to reflect `: Sendable` on `AudioEngineControl` and `nonisolated` on `ParameterDelta` / `ParameterId`, and either add the `.filterCutoff` value (since WP02 ships `FilterController`) or strike it from the example list.
5. **(Tiny side task)** Update `scripts/format.sh` to fall back to `xcrun swift-format` when `swift-format` isn't on `$PATH`.

## Historical Notes (optional)

- **2026-05-29 — WP01 integration review.** No blocking findings. One should-fix (`api-contract.md` §1 drifted from the shipped `AudioEngineControl` / `ParameterDelta` declarations after the `604d9e8` hardening commit added `: Sendable` + `nonisolated`). Hardening confirmed: `OSMemoryBarrier()` fences in the ring buffer, `nonisolated` on the shared parameter types, `SoundscapeUITests` parked. iOS 26.5 simulator runtime confirmed installed (tests green).
- **2026-05-22 — WP00 was in-review then merged in the same session.** Foundation gate opened. Twelve coding-standard categories ratified; `.swiftlint.yml`, `.swift-format`, `.env.example` shipped; five decisions logged in `docs/decisions.md`.
