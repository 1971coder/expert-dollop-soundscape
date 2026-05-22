# Testing Strategy

How AuralFlow tests its work. Filled in (drafted) during scaffold population; refined in [WP00 — Foundation](../work-packages/WP00-foundation.md). Cross-referenced from every WP's *Tests required* section.

---

## Frameworks and runners

- **Unit:** XCTest (Apple). `swift test`-compatible where modules become SwiftPM packages; otherwise `xcodebuild test`.
- **UI / end-to-end:** XCUITest. Reserved for genuinely user-visible flows; MVP coverage is the critical "pick a mode, start, hear sound, stop" path.
- **Audio DSP:** Offline rendering via `AVAudioEngine.manualRenderingMode`. Tests are deterministic (no real-time clock; fixed sample-rate; pre-seeded RNG where applicable).

## Coverage expectations

| Layer | Expected coverage | Reasoning |
|---|---|---|
| `Audio/` DSP nodes | ≥ 80% line, ≥ 95% on math-heavy code | Glitches are user-visible and hard to debug post-hoc; offline tests are cheap |
| `Adaptive/` rules engine | ≥ 90% line | Pure functions of (signals, context) → deltas — they're trivial to test and load-bearing |
| `Persistence/` | Each repository method has a happy-path + error-path test | Schema bugs are catastrophic |
| `Modes/` | One round-trip test per mode | Catches preset/parameter drift |
| `Views/` | Snapshot tests for design-system primitives only; **no full-screen snapshot tests** | They rot quickly; we rely on XCUITest for flows |
| `App/` | Smoke test that the app launches and constructs the engine | Catches DI wiring breaks |

Coverage gates are advisory in MVP, **enforced** from Phase 3 onwards.

## Test data

- **Fixtures over factories.** A `Fixtures/` directory under each test target holds JSON / Codable fixtures for `ModePreset`, `Session`, etc.
- **Audio fixtures** are short (≤ 2 s) generated buffers — committed as `.caf` files with a generator script so they can be regenerated.
- **Mock at protocol boundaries.** `AudioEngineControl`, `SessionRepository`, `PresetRepository`, `HeartRateCollector`, `MotionCollector` all have test-doubles in `SoundscapeTests/Doubles/`.
- **Do not mock the SUT.** If a test is mocking the thing it's supposed to be testing, it's testing nothing.

## Flaky-test policy

- **Quarantine, don't ignore.** A flaky test moves to a `Flaky/` test plan and gets a bug filed; it must be fixed or deleted within two weeks.
- **Quarantined for > two weeks = delete.** A test nobody trusts is worse than no test.
- **No retry-until-pass loops in CI.** That hides genuine flakiness.

## What is NOT tested

- **AudioKit internals.** Treat as a vendor library.
- **Apple system frameworks** (AVAudioEngine, CoreMotion, HealthKit) — we test our boundary against them, not their implementations.
- **Pure wrapper modules** — if a file is one-line forwarders, the wrapper itself doesn't get its own test.
- **Cosmetic SwiftUI tweaks** — colour values, spacing — no snapshot tests for these in MVP.

## CI gates

- `./scripts/check.sh` (build + lint) — must pass.
- `./scripts/test.sh` (XCTest + XCUITest) — must pass.
- `./scripts/format.sh --check` (or equivalent) — must pass with no diff.
- `./scripts/template-audit.sh --strict` — must pass.

## Running tests locally

```bash
./scripts/test.sh                    # full suite
xcodebuild test -scheme Soundscape -only-testing:SoundscapeTests/DroneSynthTests
```

UI tests are slow — run on the smallest device simulator that's representative (iPhone 15, iOS 17).
