# Handoff

> Maintained by [`/update-handoff`](../.claude/commands/update-handoff.md). This is a **rolling snapshot, not an append-only log.** The `/update-handoff` command's job is to keep these sections current — overwriting `Current Snapshot`, pruning closed items, and (optionally) moving useful history to `Historical Notes`.

## Current Snapshot

**2026-05-22.** **WP01 — Audio prototype is in-review.** The audio graph (DroneSynth + NoiseGenerator + Mixer), lock-free SPSC parameter pipe, public `AudioEngineControl` surface, AVAudioSession route-change handling, and minimal SwiftUI Home screen are all implemented. The Xcode project was narrowed to iOS-only (`SUPPORTED_PLATFORMS = iphoneos iphonesimulator`, `TARGETED_DEVICE_FAMILY = "1"`, `SDKROOT = iphoneos`); a shared scheme was added at `Soundscape.xcodeproj/xcshareddata/xcschemes/Soundscape.xcscheme`; the source tree was restructured to match `docs/project-structure.md` (Item.swift / ContentView.swift / SoundscapeApp.swift / SoundscapeTests.swift removed; `App/AuralFlowApp.swift` + `Audio/**` + `Views/Screens/Home/HomeView.swift` created). Four XCTest test files cover offline-render assertions for DroneSynth and NoiseGenerator, the ring buffer's SPSC concurrency, and the engine graph smoke.

**Verification status:** strict template audit passes; swift-format lint passes (run via `xcrun swift-format`). `./scripts/check.sh` and `./scripts/test.sh` are **gated on installing the iOS 26.5 simulator runtime** — see *Open Issues*.

## Recent Completed Work

- **WP01 — Audio prototype** (in-review 2026-05-22) — Engine + nodes + ring buffer + HomeView + tests + Xcode scheme/platform narrowing + source-tree restructure. See `work-packages/WP01-audio-prototype.md` *Integration notes* for the design decisions baked in.
- **WP00 — Foundation** (merged 2026-05-22) — Conventions ratified, toolchain configs shipped. Archived in `delivery-plan.md`.

## Open Issues

- **iOS 26.5 simulator runtime missing locally.** Xcode 26.5 ships an iOS 26.5 SDK; only iOS 26.3 / 26.4 runtimes are installed. `xcodebuild` rejects every iOS simulator destination with `iOS 26.5 is not installed`. **Fix:** *Xcode → Settings → Platforms* and install iOS 26.5 (~7 GB). Once installed, `./scripts/check.sh` and `./scripts/test.sh` should both pass against the new code with no further changes.
- **`scripts/format.sh` does not fall back to `xcrun swift-format`.** swift-format ships with Xcode at `xcrun swift-format` but the script only looks at `$PATH`. Out of WP01's allow-list (`scripts/format.sh` is not in *Shared Files Allowed To Change*) — file a tiny follow-up WP or bundle into the next scripts/* touch.

## Assumptions In Play

- **No first-party server.** No backend in MVP; cloud LLM calls (Phase 4) are vendor-direct.
- **Background audio entitlement** will be added in WP02 (when Sleep mode ships). WP01 deliberately doesn't enable it.
- **One designated parameter drainer.** `DroneSynth` drains the ring buffer each render block; other nodes read from the shared `EngineParameters`. NoiseGenerator may see params one block stale (≤ ~6 ms) — acceptable for ambient parameters but the assumption is worth re-validating when WP03 wires AdaptiveController-driven parameter changes at higher rate.

## Blockers

- WP02 / WP03 are blocked on:
  1. WP01 being merged (currently `in-review`).
  2. The iOS 26.5 simulator runtime install above — WP02 needs `./scripts/test.sh` working to validate persistence and mode tests.

## Technical Debt To Revisit

- **Naming drift:** repo dir and Xcode target are `Soundscape`; product / Swift entry point are `AuralFlow`. The Xcode target rename remains its own deferred WP (see `decisions.md` 2026-05-17).
- **`README.md` at the repo root** is still the scaffold's README, not AuralFlow's. Low priority.
- **SwiftLint custom rules under `Audio/`** are still minimal (one rule: no `print()` under `Audio/`). Tighten in WP02 — extend to flag `os_log`, dispatch-async, allocations.
- **`ParameterRingBuffer` ordering.** Plain `UInt32` reads/writes; relaxed memory ordering. Swap to `Synchronization.Atomic<UInt32>` (iOS 18+) when the deployment target moves; until then the iOS-17 path is fine in practice on ARM64.
- **`ModePreset` stub** lives in `Soundscape/Audio/AudioEngine.swift`. WP02 deletes it and creates the real `Modes/ModePreset.swift`.

## Next Recommended Steps

1. **Install iOS 26.5 simulator runtime** in Xcode → Settings → Platforms (~7 GB download).
2. **Re-run `./scripts/check.sh` and `./scripts/test.sh`.** Both should be green against the WP01 code with no further changes. If anything trips, the most likely culprit is the implicit isolation rules created by `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` — adjust `nonisolated` markings if the compiler complains.
3. **Open the Home screen on a simulator** and verify: tap the play button → audible drone + soft noise within ~250 ms; master-gain slider changes volume in real time; Stop terminates the engine cleanly. (Acceptance criteria from `work-packages/WP01-audio-prototype.md`.)
4. **Run an Instruments → Time Profiler** capture for a 30 s session and confirm zero allocations on the audio render thread (acceptance criterion).
5. **Mark WP01 `merged`** in the WP file and `delivery-plan.md` (move to Archive) — this unblocks WP02.
6. **(Tiny side task)** Update `scripts/format.sh` to fall back to `xcrun swift-format` when `swift-format` isn't on `$PATH`.

## Historical Notes (optional)

- **2026-05-22 (earlier) — WP00 was in-review then merged in the same session.** Foundation gate opened. Twelve coding-standard categories ratified; `.swiftlint.yml`, `.swift-format`, `.env.example` shipped; five decisions logged in `docs/decisions.md`.
