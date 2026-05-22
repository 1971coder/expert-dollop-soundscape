# Requirements

This is the long-form requirements document. CLAUDE.md links here; only constraints that actually shape implementation choices are also surfaced in CLAUDE.md's *Scope* section.

Source: AuralFlow product & technical specification v1.0.

---

## 1. Product Vision

AuralFlow is an iPhone application that generates intelligent, evolving ambient soundscapes designed to support **focus, deep work, relaxation, walking, sleep, and stress reduction**. The application uses **procedural audio generation and adaptive behavioural logic** rather than static playlists.

The system changes sound characteristics dynamically based on:

- time of day
- session type
- user behaviour
- motion
- heart rate
- environmental conditions
- prior feedback

The product goal is **not** mystical "healing frequencies". The goal is:

- low-distraction audio
- psychoacoustic stability
- adaptive ambience
- cognitive-state support
- long-session listening without fatigue

## 2. Product Principles

These principles are load-bearing — they constrain implementation choices everywhere downstream.

### 2.1 Adaptive, not static

- Audio must continuously evolve. **No looping tracks. No obvious repetition.**
- Two minutes of audio should not be audibly similar to the previous two minutes.
- Implementation implication: all sound sources are generated; no audio file playback in the production path.

### 2.2 Low attention demand

The sound engine must avoid:

- sharp attacks (no transients above ~−18 dBFS peak in steady state)
- sudden changes (parameter changes ramp over hundreds of ms, not samples)
- vocals
- recognisable melodies
- rhythmic hooks

### 2.3 Calm interaction model

The UI should feel **minimal, elegant, dark, low-cognitive-load, distraction-free**. No notifications that interrupt a session. No bright colour accents. No animations that demand attention.

### 2.4 Local first

Audio generation happens entirely on-device. **No cloud dependency for playback.** Network failures must not affect a running session.

### 2.5 Privacy first

Biometric and behavioural data stays local **unless explicitly synced by the user**. No telemetry on biometrics. Sync (when added) is opt-in, end-to-end encrypted, and disable-able without data loss.

## 3. Core User Modes (functional requirements)

### 3.1 Focus mode

- **Purpose:** support concentration and sustained attention.
- **Sound characteristics:** soft pulses; moderate brightness; minimal harmonic movement; low transient density; light rhythmic motion (sub-audible to ~0.2 Hz pulse rate).
- **Default session length:** 25 / 50 / 90 minutes (Pomodoro-aligned but configurable).

### 3.2 Sleep mode

- **Purpose:** reduce stimulation and support sleep onset, then maintain through the night.
- **Sound characteristics:** dark tonal palette; heavy low-mid emphasis; slow evolving drones; brown/pink noise; reduced treble (low-pass at ~3 kHz, gentle).
- **Default session length:** 30 min fade-in, hold until user-set stop time or device-paused.
- **Background audio required.** Must continue playing with the screen locked.

### 3.3 Relax mode

- **Purpose:** calm but awake relaxation (e.g. post-work decompression).
- **Sound characteristics:** between Focus and Sleep — warmer than Focus, more motion than Sleep.

### 3.4 Walk mode

- **Purpose:** adaptive outdoor ambience for walking.
- **Sound characteristics:** responds to walking cadence (CoreMotion) — slow walking → slow modulation; brisk walking → more energy / brighter palette. Never matches step rate exactly (avoid the "marching band" effect).
- **Audio session category:** consider `.ambient` so environmental sound is preserved for safety.

## 4. Audio Engine — required components

```text
AudioEngine
 ├── DroneSynth          long sustained pitched layers; slow detune; minimal harmonics
 ├── PadSynth            broader spectral pads; movement via filter modulation
 ├── NoiseGenerator      pink + brown + filtered white; leaky integrator for brown
 ├── PulseModulator      sub-audible LFO modulation across mixer channels
 ├── FilterController    per-bus low-pass / high-pass; smoothed parameter changes
 ├── BinauralGenerator   optional binaural-beat layer (only when headphones detected)
 ├── Mixer               per-source gain, ducking, master limiter
 ├── AdaptiveController  reads session state + signals; writes engine parameters
 └── SessionStateManager owns the active session lifecycle, persistence, transitions
```

All nodes must be realtime-safe (no allocations, no locks, no logging on the render thread).

## 5. Technology Stack (required)

| Layer | Technology | Notes |
|---|---|---|
| UI | SwiftUI | iOS 17+ initially; revisit if SwiftData proves limiting |
| Audio | AVAudioEngine | Source of truth for the graph |
| DSP | AudioKit | Used where it fits; not a hard dependency on every node |
| Motion | CoreMotion | Walking cadence, device motion |
| Health | HealthKit | Heart rate, read-only, opt-in |
| Persistence | SwiftData (preferred) / SQLite (fallback) | Decision recorded in `decisions.md` |
| Adaptive logic | Local rules engine | Deterministic, on-device, unit-testable |
| Optional AI | OpenAI / Claude APIs | Off the audio path, feature-flagged, opt-in |

## 6. MVP Features (Phase 2 deliverable)

- Focus mode
- Sleep mode
- Procedural drone generation
- Pink / brown noise generation
- Adaptive intensity sliders
- Session timers
- Local session history
- User ratings (per-session, simple thumbs / 1–5 scale TBD in WP00)

Relax and Walk modes are **post-MVP** (Phase 3) unless WP00 says otherwise.

## 7. Future AI Features (Phase 4+)

- Natural-language sound adjustment ("make it darker", "less pulse")
- Preset recommendations based on usage history
- Behavioural learning across sessions
- Adaptive session generation (auto-pick a mode + intensity based on context)
- Personalised sound profiles

All AI features run **off the audio path** and are gated behind an explicit user toggle. They are never required for core playback.

## 8. Non-functional requirements

- **Audio latency:** start-to-sound under ~250 ms from tap.
- **CPU budget:** sustained foreground use ≤ 25% on iPhone 13 mini equivalent; sleep mode (background) ≤ 8%.
- **Battery:** an 8-hour sleep session must not exceed ~10% battery drain on a fresh-but-not-pristine device.
- **Memory:** active session ≤ 100 MB resident.
- **Privacy:** no biometric data leaves the device by default; user-visible privacy panel lists every signal in use.
- **Accessibility:** Dynamic Type; VoiceOver labels on every control; haptic-free mode (haptics off by default during sessions); reduced-motion respected.
- **Localisation:** English first; structure for localisation from day one (no hard-coded strings in UI).

## 9. Development phases (high level)

| Phase | Goal | Status |
|---|---|---|
| 1 | Audio prototype: AVAudioEngine integration; basic procedural sound generation | not started |
| 2 | Full MVP: Focus + Sleep modes; presets; session management; ratings | not started |
| 3 | Adaptive intelligence: motion + heart-rate integration; Relax / Walk modes | not started |
| 4 | AI-assisted personalisation; natural-language controls | not started |

Cross-reference: [delivery-plan.md](delivery-plan.md) tracks per-WP status in real time.

## 10. Final product statement

AuralFlow is an adaptive ambient sound engine for iPhone that generates continuously evolving procedural soundscapes tuned for focus, sleep, relaxation, and movement. It combines procedural audio synthesis, psychoacoustic principles, behavioural adaptation, local intelligence, and optional AI-assisted personalisation — to create a deeply personalised, low-distraction listening experience.
