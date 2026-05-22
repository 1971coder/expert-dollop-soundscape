# WP03 — Adaptive intelligence

> **Status:** proposed
> **Branch:** `wp/03-adaptive-intelligence`
> **Assigned:** claude (pair with human)
> **Depends on:** WP02

## Behaviour rules for the implementing agent

- **Avoid unrelated refactors.** Make the smallest change that satisfies the acceptance criteria.
- **`ParameterId` is now a high-traffic shared file.** Coordinate carefully — if WP02 follow-ups are in flight, sequence rather than parallel.
- **Audio-thread sanctity.** The new `AdaptiveController` writes to the SPSC pipe; **never** touches the audio thread directly.
- **HealthKit / CoreMotion permissions are user-gated.** All paths must degrade cleanly when permission is denied — never crash, never refuse to start a session.
- **No biometric data in logs, ever.**
- **Document assumptions.** Especially around the rule-tuning constants — these are judgement calls and another agent will reasonably want to revisit them.
- **Update [../docs/handoff.md](../docs/handoff.md)** when done.

---

## Objective

Add the adaptive layer: signal collectors (time-of-day, CoreMotion cadence, HealthKit heart rate, recent ratings) plus an `AdaptiveController` that combines them with the active mode's allowed rules to produce `ParameterDelta`s. Ship **Relax** and **Walk** modes as the new modes this layer enables.

## Scope

- `AdaptiveController` on a dedicated queue, polling collectors at 1–4 Hz, pushing `ParameterDelta`s to the engine.
- Signal collectors: `TimeOfDayCollector`, `MotionCollector` (CoreMotion), `HeartRateCollector` (HealthKit, opt-in), `FeedbackCollector` (recent ratings).
- Rule architecture: pure `(SignalSnapshot, ModeContext) → ParameterDelta` functions; composable via summation + clamping.
- Initial rule set: time-of-day brightness bias; cadence → pulse rate (Walk); calm heart rate → quieter palette; recent low rating → slightly different baseline next session.
- **Relax** and **Walk** `ModePreset`s.
- `AdaptiveProfile` SwiftData entity (lazy; only when user opts into personalisation).
- Permissions UX: graceful onboarding when the user first enables Walk (motion) or any mode if HK heart-rate is enabled.

## Out of scope

- Cloud / AI features — WP04.
- Personalisation learning loop — WP04 (this WP only stores the profile shell).
- Binaural beats.

## Dependencies

- WP02 merged. Engine + sessions + persistence must exist.

## Files likely touched

- `Soundscape/Adaptive/AdaptiveController.swift` (new)
- `Soundscape/Adaptive/Signals/TimeOfDayCollector.swift` (new)
- `Soundscape/Adaptive/Signals/MotionCollector.swift` (new)
- `Soundscape/Adaptive/Signals/HeartRateCollector.swift` (new)
- `Soundscape/Adaptive/Signals/FeedbackCollector.swift` (new)
- `Soundscape/Adaptive/Rules/*.swift` (new — one file per rule)
- `Soundscape/Adaptive/SignalSnapshot.swift` (new)
- `Soundscape/Adaptive/ModeContext.swift` (new)
- `Soundscape/Audio/Internal/ParameterId.swift` (modify — add adaptive-only values)
- `Soundscape/Modes/Presets/RelaxPresets.swift` (new)
- `Soundscape/Modes/Presets/WalkPresets.swift` (new)
- `Soundscape/Persistence/Models/AdaptiveProfile.swift` (new)
- `Soundscape/Persistence/Repositories/AdaptiveProfileRepository.swift` (modify — fill in)
- `Soundscape/Sessions/SessionStateManager.swift` (modify — start/stop the controller)
- `Soundscape/Views/Screens/Settings/PrivacyView.swift` (new — explain signals; toggles)
- `Soundscape/Resources/Info.plist` (modify — `NSMotionUsageDescription`, `NSHealthShareUsageDescription`)
- `../docs/data-model.md` (modify — `AdaptiveProfile` schema)
- `../docs/architecture.md` (modify — adaptive section as built)
- `SoundscapeTests/AdaptiveTests/**` (new tests)

## Files explicitly excluded

- `Soundscape/Adaptive/AI/**` — WP04.
- The audio nodes themselves — this WP doesn't change DSP behaviour, only parameter inputs.

## Shared Files Allowed To Change

- `Soundscape/Audio/Internal/ParameterId.swift`
- `Soundscape/Sessions/SessionStateManager.swift`
- `Soundscape/Persistence/Repositories/AdaptiveProfileRepository.swift`
- `Soundscape/Resources/Info.plist`
- `Soundscape.xcodeproj/project.pbxproj`
- `../docs/data-model.md`
- `../docs/architecture.md`
- `../docs/handoff.md`
- `../docs/delivery-plan.md`

## API impacts

- Extends `ParameterId` (additive).
- Introduces `SignalSnapshot`, `ModeContext`, and the rule signature `(SignalSnapshot, ModeContext) -> ParameterDelta`. New shared types; document in `architecture.md`.
- Fills out `AdaptiveProfileRepository` protocol surface (declared in WP02).

## DB impacts

- New SwiftData entity: `AdaptiveProfile` (lazy — only created on opt-in).
- Update [data-model.md](../docs/data-model.md).

## UI impacts

- Two new mode tiles (Relax, Walk) on the home screen.
- A privacy / personalisation screen under Settings — lists every signal collected, lets the user toggle each.
- A first-time permission prompt for motion (Walk) and HealthKit (any mode with HR enabled).

## Acceptance criteria

- Walking with **Walk** mode active visibly affects the engine within ~2 s of a cadence change.
- Heart-rate read failure (denied permission, watch absent) does **not** crash, does **not** prevent any session, and is reflected in the privacy view.
- Recent low ratings on Focus sessions visibly bias the next Focus baseline (audible difference; record the exact rule in `architecture.md`).
- All rule functions are pure and deterministic — same `(SignalSnapshot, ModeContext)` always returns the same `ParameterDelta`.
- Coverage targets met (≥ 90% line on `Adaptive/`).
- No biometric values appear in any log output (verified by a unit test that asserts no HK values in the captured log).

## Tests required

- **Unit:** Every rule — table-driven tests (snapshots → expected deltas).
- **Unit:** `AdaptiveController` summation + clamping logic.
- **Unit:** Collectors — mocked underlying frameworks; verify graceful degradation on denial.
- **Integration:** Controller → engine round-trip — fake signal snapshot triggers an observable engine parameter change.
- **Test:** Log-scrubbing test — feed a fake HR value; assert it never appears in any captured `Logger` output.
- **(Optional) XCUITest:** Walk mode permission prompt flow.

## Integration notes

- The rule-tuning constants in `Rules/*.swift` are judgement calls. Record the rationale in each rule's file as a one-paragraph doc comment.
- The controller runs at 1–4 Hz; if a later WP needs higher-rate adaptation, revisit the polling interval rather than pushing more work into rules.
- `ParameterId` now has values from three sources (WP01, WP02, WP03). Consider grouping them with `// MARK:` comments to keep the file readable.
- Privacy view design overlaps with the eventual onboarding flow — keep it minimal here; the proper onboarding is its own WP.

## Handoff requirements

- [ ] Row in [../docs/delivery-plan.md](../docs/delivery-plan.md) status updated to `merged`.
- [ ] [../docs/handoff.md](../docs/handoff.md) reflects new state via `/update-handoff`.
- [ ] [../docs/decisions.md](../docs/decisions.md) updated with: rule-tuning rationale; privacy posture decisions; any deviation from the spec's signal list.
- [ ] [../docs/data-model.md](../docs/data-model.md) reflects the `AdaptiveProfile` schema as built.
- [ ] [../docs/architecture.md](../docs/architecture.md) reflects the adaptive section as built.
- [ ] Tests pass: `./scripts/test.sh`.
- [ ] Audit passes: `./scripts/template-audit.sh --strict`.
