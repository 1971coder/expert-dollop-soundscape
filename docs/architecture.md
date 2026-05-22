# Architecture

How AuralFlow is structured. This is long-form context; CLAUDE.md surfaces only the parts that change implementation decisions.

## 1. High-level layers

```
┌─────────────────────────────────────────────────────────────────┐
│                      Presentation (SwiftUI)                     │
│  Views, controls, mode pickers, session screens, settings       │
└──────────────────────────────────┬──────────────────────────────┘
                                   │ observed @State / actors
                                   ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Session & Mode Management                    │
│  SessionStateManager · ModePreset · IntensityController         │
└──────────────────────────────────┬──────────────────────────────┘
                                   │ commands (Sendable)          
                                   ▼
┌─────────────────────────────────────────────────────────────────┐
│                       Adaptive Controller                       │
│  Rules engine; reads signals; writes engine parameters          │
└─────┬─────────────────────────────┬───────────────────────┬─────┘
      │ heart rate                  │ motion                │ time/feedback
      ▼                             ▼                       ▼
 ┌─────────┐                  ┌────────────┐           ┌──────────┐
 │HealthKit│                  │ CoreMotion │           │  Local   │
 └─────────┘                  └────────────┘           │  Store   │
                                                       └──────────┘
                                   │
                                   ▼
┌─────────────────────────────────────────────────────────────────┐
│                       AudioEngine (real-time)                   │
│  Drone · Pad · Noise · Pulse · Filter · Binaural · Mixer        │
│  Built on AVAudioEngine + AudioKit; no allocations on render    │
└─────────────────────────────────────────────────────────────────┘
```

Boundaries:

- **Presentation never touches `AudioEngine` directly.** It goes through `SessionStateManager`, which converts user intent into engine commands.
- **AdaptiveController is the only writer of engine parameters during a session** (apart from explicit user controls routed via `SessionStateManager`).
- **Persistence is read by the controllers, written via repositories.** No SwiftData call sites in audio code.
- **Network code (cloud LLM, optional) lives in `Adaptive/AI/`** and is invoked off the audio path.

## 2. Module breakdown

### 2.1 `Audio/` — the real-time graph

Sub-nodes (see [requirements §4](requirements.md#4-audio-engine--required-components)):

- **`DroneSynth`** — long sustained pitched layers; slow detune; minimal harmonics. Per-voice independent slow LFOs to avoid phase-coherence "beating".
- **`PadSynth`** — broader spectral pads; movement via filter modulation rather than pitch.
- **`NoiseGenerator`** — pink + brown + filtered white. **Brown noise requires a leaky integrator** (one-pole HPF ~5 Hz) to prevent DC drift.
- **`PulseModulator`** — sub-audible LFO (0.05–0.5 Hz) modulating mixer channel gains for Focus mode's "soft pulse" character.
- **`FilterController`** — per-bus low-pass / high-pass; parameter changes smoothed at audio rate (no zipper noise).
- **`BinauralGenerator`** — optional binaural-beat layer. Only enabled when headphones are detected (`AVAudioSession.currentRoute`) and the user has opted in.
- **`Mixer`** — per-source gain, sidechain ducking when entering Sleep, master limiter at −1 dBTP.

Realtime contract: every node implements `render(audioBuffer, frames)` with **no allocations, no locks, no logging.** Parameter updates arrive via a lock-free SPSC ring buffer from `AdaptiveController`.

### 2.2 `Adaptive/` — the rules engine

- **`AdaptiveController`** — runs on a high-priority background queue (not the audio thread). Reads from signal collectors at 1–4 Hz; writes engine parameters via the SPSC ring buffer.
- **Signal collectors:** `TimeOfDayCollector`, `MotionCollector` (CoreMotion), `HeartRateCollector` (HealthKit), `FeedbackCollector` (recent ratings).
- **Rules:** deterministic and unit-testable. Each rule is `(SignalSnapshot, ModeContext) -> ParameterDelta`. Rules are composed, not chained — the controller sums their outputs with clamping.
- **AI layer (Phase 4):** `NaturalLanguageAdjuster` translates user prose into deltas, applied through the same parameter pipeline. Cloud-only; gated.

### 2.3 `Modes/` — mode definitions

Each mode is a value type: a baseline `ModePreset` plus a list of allowed rules. Modes never own state — `SessionStateManager` owns the active session.

### 2.4 `Persistence/` — SwiftData stack

- `Session` (id, mode, started, ended, presetId, rating)
- `ModePreset` (id, modeKind, parameter snapshot, user-editable flag)
- `RatingEvent` (sessionId, timestamp, value, free-text optional)
- `AdaptiveProfile` (per-user; lazy — only when the user opts into personalisation)

See [data-model.md](data-model.md) for full schema and migration policy.

### 2.5 `Views/` — SwiftUI presentation

- Dark, minimal design system. Two-tier hierarchy: `Components/` (reusable primitives) and `Screens/` (composed flows).
- No view directly subscribes to engine state. Views observe `SessionStateManager` published properties (or `@Observable` equivalents in iOS 17 SwiftUI).

### 2.6 `App/` — entry point and lifecycle

- `AuralFlowApp` (the `@main`) wires up the audio session, requests background-audio support for sleep mode, and constructs the dependency graph.
- Lifecycle hooks (`scenePhase`) decide engine pause/continue. **Sleep mode continues in background.** Other modes pause on `.background` and resume on `.active`.

## 3. Data flow — a session

1. User picks a mode and taps **Start**.
2. `SessionStateManager` creates a `Session`, persists it, and instructs `AudioEngine` to load the mode's `ModePreset`.
3. `AudioEngine` starts; `AdaptiveController` begins polling signal collectors.
4. Every ~250 ms, the controller produces a `ParameterDelta` and pushes it to the SPSC ring buffer.
5. On the audio thread, each node reads any pending delta at the start of its render cycle and ramps to the new value.
6. User interactions (intensity slider, end-session) route through `SessionStateManager`, never directly to the engine.
7. On session end, `SessionStateManager` writes the final `Session` record and (optionally) prompts for a rating.

## 4. External dependencies

- **AVAudioEngine** (system) — audio graph and routing.
- **AudioKit** (SwiftPM) — DSP utilities; used where it fits, not as a hard dependency on every node.
- **CoreMotion** (system) — motion / cadence.
- **HealthKit** (system) — heart rate (opt-in, read-only).
- **SwiftData** (system, iOS 17+) — persistence.

No third-party analytics. No third-party crash reporting in v1 (revisit in WP00).

## 5. Threading model

| Layer | Thread |
|---|---|
| SwiftUI views | Main |
| `SessionStateManager` | Main-actor (with async work delegated) |
| `AdaptiveController` | Dedicated `DispatchQueue`, `qos: .userInitiated` |
| Signal collectors | Their own callback threads (CoreMotion, HealthKit) |
| Audio render | High-priority audio thread (system-owned) |
| Persistence | Background actor; never on audio thread |

Audio-thread → other-thread communication: lock-free SPSC ring buffer for parameter deltas; atomic flags for play/stop transitions.

Other-thread → audio-thread communication: **never** synchronous. All parameter updates are async via the same ring buffer.

## 6. Error handling boundaries

- **System errors** (HealthKit denied, audio session interruption, route change) — handled at the boundary by `SessionStateManager`, degraded gracefully (e.g. heart-rate rule disabled, session continues).
- **Programming errors** — fail fast in DEBUG, log + recover in RELEASE.
- **Audio engine failures** — `SessionStateManager` is the recovery owner. On render failure the engine is torn down and rebuilt; the session is paused, not killed.

## 7. Future evolution

- Phase 3 adds Relax and Walk modes; Walk requires hooking `MotionCollector` into a cadence smoother.
- Phase 4 adds the NLP layer; the parameter-delta pipeline absorbs it without changing the audio path.
- watchOS / iPad / macOS clients are deliberately out-of-scope but the layered split above keeps the option open: presentation and persistence would be replaced; audio and adaptive stay.

## 8. Open architectural questions

These are flagged here so they don't get lost. They become entries in [decisions.md](decisions.md) once resolved.

- SwiftData vs Core Data vs raw SQLite — decision pending WP00.
- AudioKit version pinning vs vendoring the small subset we use.
- Whether to ship a Swift-Package-Manager workspace from day one or stay Xcode-project-only until needed.
- Where binaural beats live (default off? feature flag? premium tier?).
