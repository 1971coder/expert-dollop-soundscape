# Delivery Plan

The single coordination view for all AuralFlow work packages (WPs). Each row corresponds to one WP file in [../work-packages/](../work-packages/).

## Parallelism rule

> **Two work packages SHOULD NOT run in parallel if they both modify the same shared file or shared contract surface unless explicitly approved.**
>
> This is the primary mechanism for minimising merge conflicts and architectural drift. Compare the **Shared Files Allowed To Change** sections of two candidate-parallel WPs before dispatching them. If those sets overlap, sequence the WPs or split one of them.

## Status legend

`proposed` → `ready` → `in-progress` → `in-review` → `merged`

## How to use

- Add one row per WP. Keep it in sync with the WP file's status header.
- Compare new candidate WPs to in-flight rows for shared-file overlap before marking them `ready`.
- Archive merged rows once the WP is no longer load-bearing context (move to the `## Archive` section at the bottom — preserves coordination history).

## Active

| ID | Title | Objective | Agent | Branch | Deps | Parallel-safe? | Files likely touched | Shared-file risk | Integration risk | Acceptance | Tests | Status |
|----|-------|-----------|-------|--------|------|----------------|----------------------|------------------|------------------|------------|-------|--------|
| WP02 | MVP — Focus & Sleep | Add `PadSynth`, `PulseModulator`, `FilterController`; Focus + Sleep `ModePreset`s; session timer; intensity slider; SwiftData session+rating persistence; background-audio entitlement | claude | `wp/02-mvp-focus-sleep` | WP01 | partially (do NOT parallel with any WP that touches `Audio/Nodes/` or `Persistence/`) | `Soundscape/Audio/Nodes/**`, `Soundscape/Modes/**`, `Soundscape/Persistence/**`, `Soundscape/Views/**`, `Soundscape/App/**` (entitlements), `docs/data-model.md`, `docs/api-contract.md` | high (Audio + Persistence + entitlements) | medium | Focus session runs for full default; Sleep session runs in background; ratings persist; tests cover Sessions repo + each new node | unit + 1 XCUITest (start a session) | proposed |
| WP03 | Adaptive intelligence | Wire `AdaptiveController`, signal collectors (`TimeOfDay`, `Motion`, `HeartRate`), and a minimal rule set; add Relax + Walk modes | claude | `wp/03-adaptive-intelligence` | WP02 | partially (do NOT parallel with any WP touching `Adaptive/` or `Audio/Internal/ParameterId.swift`) | `Soundscape/Adaptive/**`, `Soundscape/Audio/Internal/ParameterId.swift`, `Soundscape/Modes/Presets/RelaxPresets.swift`, `Soundscape/Modes/Presets/WalkPresets.swift`, `Soundscape/Persistence/Models/AdaptiveProfile.swift` | high (ParameterId is shared) | medium | Heart-rate-driven calmness rule visibly affects engine; tests cover rule purity; HK denial degrades cleanly | unit (rules) + integration (controller→engine round-trip) | proposed |
| WP04 | AI personalisation | Add cloud-LLM natural-language adjuster, behavioural-learning loop, preset recommendations; feature-flagged | claude | `wp/04-ai-personalisation` | WP03 | yes (new module under `Adaptive/AI/`, contract-only with rest) | `Soundscape/Adaptive/AI/**`, `Soundscape/Views/Screens/Settings/AISettings.swift`, `docs/api-contract.md` (§3), `docs/decisions.md` | low (new code; isolated) | low | NLP prompt produces visible engine change; toggling AI off cleanly disables module; no biometrics in prompts | unit + integration (mocked vendor) | proposed |

## Archive

<!-- Move merged WPs here. Column shape: | ID | Title | Merged at | Notes | -->

| ID | Title | Merged at | Notes |
|----|-------|-----------|-------|
| WP00 | Foundation | 2026-05-22 | Foundation gate OPEN. Twelve coding-standard categories ratified in `docs/coding-standards.md`; `.swiftlint.yml`, `.swift-format`, `.env.example` shipped; five decisions logged in `docs/decisions.md` (iOS 17, SwiftData, AudioKit-as-optional, SwiftLint+swift-format split, ratification record). WP01 may now start. |
| WP01 | Audio prototype | 2026-05-29 | AuralFlow audio graph (DroneSynth + NoiseGenerator + Mixer), lock-free SPSC parameter pipe, public `AudioEngineControl` surface, AVAudioSession route-change handling, minimal SwiftUI Home screen. Source tree restructured to `docs/project-structure.md` layout; Xcode project narrowed to iOS-only; shared scheme added. Post-merge hardening (commit `604d9e8`): `OSMemoryBarrier()` fences in the ring buffer, `nonisolated` on shared parameter types, `SoundscapeUITests` parked. Three reviews completed 2026-05-29 (integration / QA / architecture) — three decisions ratified in `decisions.md` 2026-05-29 (designated drainer, `Audio/Internal/` access model, mono 48 kHz engine format); nine inherited scope items folded into WP02's *Integration notes*. WP02 may now start. |
