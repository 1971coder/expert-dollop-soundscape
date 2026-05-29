# Decisions

Append-only log of significant architectural and engineering decisions, and the rationale behind them. **Not** a substitute for [handoff.md](handoff.md) (rolling snapshot of current state) or [architecture.md](architecture.md) (long-form structural context). Decisions are user-curated; review commands must not write to this file.

## What belongs here

- Architectural choices that constrain future work (e.g. "we're using event sourcing for the orders domain"), tooling choices with a real lock-in cost, security/compliance choices, scope boundaries.

## What does NOT belong here

- Day-to-day implementation choices that don't affect future WPs.
- Open issues, current state, or session-to-session continuity (those go in [handoff.md](handoff.md)).
- Long-form structural explanation (that goes in [architecture.md](architecture.md)).

## Entry format

Append new entries to the **bottom** of this file. Use this shape exactly so entries stay greppable and diffable:

```
## YYYY-MM-DD — <short title>

- **Decision:** <one sentence — what was chosen>
- **Alternatives considered:** <bullet list of options that were rejected>
- **Why:** <2–4 sentences. Lead with the constraint that drove the choice.>
- **Status:** active | superseded by [<later entry title>](#<anchor>)
- **WP:** <WP id where the decision was made, or "pre-WP00" / "ad-hoc">
```

When a decision is **superseded**, do not delete the old entry. Mark its status as `superseded by <link>` and append the new entry below — that's how a multi-agent project preserves the trail of why something changed.

---

## 2026-05-17 — Adopt the claude-code-template scaffold

- **Decision:** Adopt the `1971coder/claude-code-template` scaffold (CLAUDE.md, docs/, work-packages/, scripts/, .claude/) into the AuralFlow repo at `~/Dev/Soundscape`.
- **Alternatives considered:** Start from a blank Xcode project; copy only `CLAUDE.md` and skip the multi-agent layer; build a custom in-repo conventions doc set.
- **Why:** The scaffold provides a ready-made multi-agent coordination layer (work packages, delivery plan, rolling handoff, shared-file allow-list) that turns out to map cleanly onto AuralFlow's planned four-phase delivery. Reinventing this for a single-developer-plus-Claude project isn't free.
- **Status:** active
- **WP:** pre-WP00 (set during scaffold adoption)

## 2026-05-17 — `wp/NN-<slug>` work-package branch naming

- **Decision:** All work-package branches use `wp/NN-<slug>` (e.g. `wp/01-audio-prototype`). Inherited from the scaffold.
- **Alternatives considered:** `feature/...` prefix; no convention.
- **Why:** Short prefix keeps `git branch` output scannable. The numeric ID anchors a branch to its WP file unambiguously when several WPs are in flight in parallel.
- **Status:** active
- **WP:** pre-WP00 (set during scaffold adoption)

## 2026-05-17 — Repo and Xcode target keep the legacy "Soundscape" name; product is "AuralFlow"

- **Decision:** The repository directory and the Xcode project / target remain named `Soundscape` for now. The product, marketing, and all user-facing copy use **AuralFlow**. A future WP may rename Xcode-side; not now.
- **Alternatives considered:** Rename everything in this adoption pass; rename only user-facing strings; rename the repo dir but keep Xcode names.
- **Why:** Renaming an Xcode target touches `project.pbxproj`, schemes, Info.plist references, test-target names, and bundle identifier — a non-trivial change that should be its own bounded unit of work. Doing it in passing during scaffold adoption would conflate two unrelated changes.
- **Status:** active
- **WP:** pre-WP00 (set during scaffold adoption)

## 2026-05-22 — iOS 17 minimum deployment target

- **Decision:** Adopt **iOS 17** as the minimum deployment target.
- **Alternatives considered:** iOS 16 (broader install base, gives up SwiftData and `@Observable`); iOS 18 (tighter; cuts a meaningful chunk of devices for no near-term feature gain).
- **Why:** SwiftData and SwiftUI `@Observable` are load-bearing for the persistence layer and presentation pattern documented in `architecture.md`. Targeting iOS 16 would force a parallel Core Data path that the team isn't staffed to maintain. The user-facing audience (focus, sleep, walking on iPhone) already skews toward up-to-date OS users.
- **Status:** active
- **WP:** WP00

## 2026-05-22 — SwiftData over Core Data for persistence

- **Decision:** Use **SwiftData** as the persistence layer for `Session`, `ModePreset`, `RatingEvent`, and `AdaptiveProfile`.
- **Alternatives considered:** Core Data directly; raw SQLite via GRDB; a Codable-on-disk JSON store for MVP.
- **Why:** The data model is small, value-oriented, and entirely owned by the app — SwiftData's macro-driven schema is the lowest-friction option for the volume of types involved. Core Data's ceremony pays off at larger scale; we're not there. JSON would defer schema-versioning pain to exactly the wrong moment. SwiftData's rough edges (migration tooling) are accepted; fallback is migrating to GRDB/SQLite in a dedicated WP if it bites — schema decision logged here so the trail is preserved.
- **Status:** active
- **WP:** WP00

## 2026-05-22 — AudioKit as optional helper, not a hard dependency

- **Decision:** AudioKit is used **where it fits** (DSP utilities, filter primitives), not as a hard dependency on every node. Source nodes that don't benefit from AudioKit are written against `AVAudioSourceNode` directly.
- **Alternatives considered:** AudioKit-on-everything (uniform style; surrenders some realtime control); pure `AVAudioEngine` / hand-rolled DSP (no third-party surface; more code to write).
- **Why:** Audio-thread safety is non-negotiable (no allocations, no locks, no logging on render — see CLAUDE.md). AudioKit's high-level convenience layers are not all realtime-safe; we want the freedom to bypass them. Treating AudioKit as a toolbox rather than a framework keeps the dependency cost proportional to the benefit.
- **Status:** active
- **WP:** WP00

## 2026-05-22 — SwiftLint + swift-format as the lint/format toolchain

- **Decision:** Standardise on **SwiftLint** for correctness/safety rules and **Apple swift-format** for whitespace and layout. Configs committed at `.swiftlint.yml` and `.swift-format`. Both are run via `./scripts/check.sh` / `./scripts/format.sh` and block CI on failure.
- **Alternatives considered:** SwiftLint only (formatting drift over time); swift-format only (loses force-unwrap / naming / audio-thread guards); SwiftFormat by Nick Lockwood (good tool but adds a third configuration surface).
- **Why:** SwiftLint and swift-format have complementary, non-overlapping responsibilities when configured deliberately. Splitting them keeps each config small and grep-able, and prevents the "linter undoes formatter" failure mode that bites projects that double-enforce style. SwiftLint posture is intentionally small at WP00 — widened as the codebase grows.
- **Status:** active
- **WP:** WP00

## 2026-05-22 — Ratify the twelve coding-standards categories

- **Decision:** Adopt `docs/coding-standards.md` as the canonical convention document. All twelve categories enumerated by WP00 are ratified.
- **Alternatives considered:** Inline each convention into CLAUDE.md (CLAUDE.md balloons; defeats the entry-point design); per-WP convention pages (drift across WPs guaranteed).
- **Why:** A single canonical home keeps cross-references resolvable and amendments cheap. CLAUDE.md links out; coding-standards.md is the source of truth. When CLAUDE.md disagrees with coding-standards.md, coding-standards.md wins and CLAUDE.md is updated to match.
- **Status:** active
- **WP:** WP00

## 2026-05-29 — Designated drainer: `DroneSynth` drains the SPSC ring buffer

- **Decision:** `DroneSynth.render()` is the sole consumer of `ParameterRingBuffer`. It pops every queued `ParameterDelta` at the start of each render block and applies it to a shared `EngineParameters` instance. Other source nodes (currently `NoiseGenerator`, later `PadSynth` etc.) read from `EngineParameters` and never touch the ring buffer themselves.
- **Alternatives considered:** Every source node drains its own ring buffer (multiplies memory traffic and complicates the SPSC invariant — multiple consumers); a dedicated silent "drainer" node added to the engine graph (extra render callback per block for no audio output); the engine drains in a pre-render tap (Apple's API exposes no clean hook).
- **Why:** Single-drainer preserves the SPSC invariant trivially (one consumer, no contention) and matches realtime audio idioms where one node "drives" parameter state. Cost: non-drainer nodes see parameter changes ≤ ~6 ms stale on the first block after a change — well below the perceptual threshold for the ramped parameters this engine uses. Re-evaluate if a future signal collector demands sample-accurate cross-node sync.
- **Status:** active
- **WP:** WP01

## 2026-05-29 — `Audio/Internal/` is strictly module-private

- **Decision:** `Audio/Internal/` is reserved for files used only inside the `Audio/` module. Files in this directory carry the default `internal` access level (or `private`/`fileprivate` where applicable) and MUST NOT be `public`. Public contract types shared with `Adaptive/` — currently `ParameterId` and `ParameterDelta`, per [api-contract.md §1](api-contract.md#1-audioengine-command-surface) — do **not** live in `Audio/Internal/`. They belong at the top of `Audio/` or in a dedicated `Audio/Contract/` directory.
- **Alternatives considered:** Treat `Audio/Internal/` as "private helpers plus a small set of public contract types" and amend `project-structure.md` line 160 to acknowledge the exception (keeps the current file layout but makes the directory name dishonest); leave the access model unstated and let each WP author decide (guarantees re-litigation on every Audio/ change).
- **Why:** Aligns the directory name with its actual meaning — the same convention Apple uses for `_internal` headers and Swift uses for the `internal` access level. The shipped WP01 layout violates this decision (`Soundscape/Audio/Internal/` currently contains four `public` types, two of which are over-exposed and two of which are misplaced contract types). Resolving the rule now prevents every future Audio/ change from re-litigating whether a given file "belongs in Internal/". Cleanup — moving `ParameterId.swift` and `ParameterDelta.swift` out of `Internal/`, demoting `EngineParameters` and `ParameterRingBuffer` to `internal`, and amending `project-structure.md` lines 98-101 and 160 — is owned by WP02's first touch on `Audio/`.
- **Status:** active
- **WP:** ad-hoc (architecture review of WP01)

## 2026-05-29 — `AudioEngine` format: mono 48 kHz at construction

- **Decision:** `AudioEngine` constructs its entire graph against a fixed `AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 48_000, channels: 1, interleaved: false)`. Changing the channel count or sample rate at runtime requires rebuilding the engine, not reconfiguring a node.
- **Alternatives considered:** Stereo from day one (no current node benefits — `DroneSynth` and `NoiseGenerator` are mono sources; pays CPU and memory for nothing visible until BinauralGenerator lands); auto-match the hardware-preferred format on each route change (saves the sample-rate conversion but leaks device-specific formatting into the audio graph and breaks deterministic testing); make the format a per-mode parameter (premature flexibility — no mode currently varies it).
- **Why:** The MVP node set is mono, and `AVAudioEngine` handles sample-rate conversion to the device transparently — there's no behavioural reason to vary either axis yet. Tests assume mono / 48 kHz throughout the audio test target. **Forward-looking constraint:** `BinauralGenerator` (architecture.md §2.1) inherently requires stereo; the WP that adds it must rebuild the engine to switch channel layouts, not reconfigure a node. Relax this decision (or supersede it) when stereo lands.
- **Status:** active
- **WP:** WP01

