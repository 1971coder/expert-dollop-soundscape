# API Contract

AuralFlow is an on-device iOS app. There is **no first-party server API** in MVP.

This document instead enumerates the cross-feature contracts that have the same "don't break me" character: the engine command surface, the persistence repository surface, and the optional cloud-LLM call surface.

A WP touching any contract below (`API impacts: yes` in its frontmatter) updates this doc as part of its work.

---

## 1. AudioEngine command surface

`AudioEngine` is the realtime audio graph. It exposes a narrow command interface; everything goes through it — no direct DSP node manipulation from outside `Audio/`.

```swift
public protocol AudioEngineControl: Sendable {
    func start(with preset: ModePreset) async throws
    func stop() async
    func ingest(_ delta: ParameterDelta)   // non-blocking; lock-free; safe to call from any thread
    nonisolated var routeIsHeadphones: Bool { get }
    nonisolated var routeChangeFailures: AsyncStream<AudioEngineError> { get }
}
```

- `: Sendable` on the protocol is **load-bearing** under Swift 6 strict concurrency. Every implementer (including test doubles and `HomeView`'s `PreviewEngine`) must be `Sendable`.
- `start` / `stop` are async because they may need to negotiate the audio session.
- `ingest(_:)` is the **only** way to change parameters during a session. It pushes onto the SPSC ring buffer; the audio thread drains.
- `routeChangeFailures` is the stream `SessionStateManager` watches to surface engine-health changes to the UI (see inherited item #4 from WP01 reviews). Implementations emit one element per failure.
- Breaking changes here must update both `SessionStateManager` and `AdaptiveController`.

### `ParameterDelta`

```swift
nonisolated public struct ParameterDelta: Sendable {
    public let target: ParameterId       // e.g. .droneDetune, .noiseBalance, .filterCutoff, .padCutoff
    public let value: Float              // clamped 0…1; NaN/Inf inputs become bounded substitutes
    public let rampMilliseconds: UInt32  // how long to glide
}
```

The `init` clamps `value` to `0...1` and replaces NaN/Inf with bounded substitutes (`0` for NaN/-Inf, `1` for +Inf). Engine-internal defence-in-depth per `coding-standards.md` §4 — protects render-thread arithmetic from buggy upstream callers.

`ParameterId` is an enum and is the **load-bearing shared type** between Audio and Adaptive. WP02 extends the WP01 set with `padCutoff`, `padResonance`, `pulseRate`, `pulseDepth`, `filterCutoff`, `noiseColour`. Adding a value: minor, additive. Removing or renumbering: breaking — both modules must update in the same WP. The type lives in `Audio/Contract/` (not `Audio/Internal/`) per the 2026-05-29 access-model decision.

## 2. Persistence repository surface

Repositories are the contract between `Persistence/` and everyone else. Direct SwiftData (or SQLite) calls outside `Persistence/` are prohibited.

```swift
public protocol SessionRepository {
    func create(_ session: Session) async throws
    func finalize(id: UUID, endedAt: Date, rating: Int?) async throws
    func list(limit: Int, offset: Int) async throws -> [Session]
    func purgeAll() async throws
}

public protocol PresetRepository {
    func list(for mode: ModeKind) async throws -> [ModePreset]
    func save(_ preset: ModePreset) async throws
    func delete(id: UUID) async throws
}

public protocol AdaptiveProfileRepository {
    func current() async throws -> AdaptiveProfile?
    func upsert(_ profile: AdaptiveProfile) async throws
    func delete() async throws
}
```

All methods are async and throw. UI code awaits; audio code does **not** call repositories.

## 3. Optional cloud surface (Phase 4)

If the user enables AI-assisted personalisation, AuralFlow makes outbound HTTPS calls to either OpenAI or Claude API. Both share the same wrapper.

```swift
public protocol NaturalLanguageAdjuster {
    func interpret(_ userPrompt: String, context: SessionContext)
        async throws -> [ParameterDelta]
}
```

Constraints:

- **Off the audio path.** Calls are made from `Adaptive/AI/`, results applied via `AudioEngineControl.ingest`.
- **Feature-flagged.** A user setting (default off) gates the entire module.
- **No biometric data in prompts.** `SessionContext` contains mode, intensity, and recent feedback — not heart rate or motion.
- **Failure is non-fatal.** A network or model failure is logged and the session continues.

The exact request/response shapes are vendor-specific and not documented here — link to the vendor docs from `Adaptive/AI/README.md` when the module is built.

## 4. Versioning / breaking-change policy

- Internal contracts use Swift access control. A `public` symbol in this list is "external" from a feature perspective.
- A breaking change to a contract in §1 or §2 requires a WP that updates **every** call site in the same PR. The integration agent (`/integrate-feature`) is the gate.
- Backwards-compatibility shims for internal contracts are an anti-pattern — change every site, don't ship dead branches.

<!-- DO NOT add a scaffold-allow-empty sentinel here; this file is now populated. -->
