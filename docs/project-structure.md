# Project Structure

How this scaffold is organised, how multiple agents coordinate inside it safely, and recommended layouts per project type.

## Folder responsibilities (scaffold)

| Path | Purpose | Owned by |
|------|---------|----------|
| [../CLAUDE.md](../CLAUDE.md) | Tight entry point — every Claude Code session reads this first. Pointers to `docs/`, conventions, scope. | the project (humans) |
| [../docs/](.) | Long-form context. Architecture, requirements, decisions, memory (`handoff.md`, `delivery-plan.md`), conventions (`coding-standards.md`). | the project (humans + agents) |
| [../work-packages/](../work-packages/) | One file per bounded unit of work. `TEMPLATE.md` is the schema; `WP00-foundation.md` is the gating WP. | per-WP agent |
| [../agent-runs/](../agent-runs/) | Per-run scratch (gitignored by default). Long investigation notes, integration findings. Not durable memory. | per-run agent |
| [../features/](../features/) | Optional feature-oriented modular code. Delete if the project doesn't fit the model. | per-feature WP |
| [../scripts/](../scripts/) | Polyglot wrapper scripts (`check.sh`, `test.sh`, `format.sh`, `template-audit.sh`). | the project |
| [../.claude/](../.claude/) | Claude Code config: `commands/`, `agents/`, `hooks/`, `settings.json`. | the project |

## Branch naming

| Branch | When |
|--------|------|
| `wp/NN-<slug>` | The default for any work-package branch. `NN` is the zero-padded WP id. e.g. `wp/03-add-auth`. |
| `integrate/<batch-name>` | Integration branches that batch multiple merged WPs before they hit `main`. Optional — only used by `/integrate-feature` if the project chooses to operate this way. |
| `hotfix/<slug>` | Out-of-band production fixes. Not tied to a WP. |

The `wp/` prefix means `git branch | grep '^  wp/'` always shows what's currently in flight, which is also what `delivery-plan.md`'s `Active` table should mirror.

## Feature ownership

A WP **owns** the files listed under its *Files likely touched* and *Shared Files Allowed To Change* sections.

- Other agents must not modify those files while the WP is in `in-progress` or `in-review`.
- A WP must not modify shared files **unless** they appear in its *Shared Files Allowed To Change* allow-list.
- Cross-WP changes (e.g. a refactor that touches files owned by an in-flight WP) require either rebasing the in-flight WP or sequencing them — not parallel work.

## Multi-agent coordination

Coordination is **schema-enforced**, not human-mediated. Three primitives carry the load:

1. **WP files** — explicit allow-lists for shared file access (the `Shared Files Allowed To Change` section of [../work-packages/TEMPLATE.md](../work-packages/TEMPLATE.md)).
2. **`delivery-plan.md`** — single coordination view with the parallelism rule pinned at the top.
3. **`handoff.md`** — rolling snapshot of current state, so a fresh session can pick up cold.

Before dispatching two WPs in parallel, an orchestrator (or human) should:

1. Open both WP files.
2. Compare *Files likely touched* sets — overlap = potential conflict.
3. Compare *Shared Files Allowed To Change* sets — overlap = **must not run in parallel**.
4. If overlap exists, sequence the WPs (set one's status to `proposed` until the other merges) or split one of them.

## Integration workflow

When one or more WPs are ready to land:

1. Run [`/integrate-feature`](../.claude/commands/integrate-feature.md) — checks merge-readiness, duplicated logic, shared-type consistency, architectural compliance, test integrity, integration drift.
2. The integration agent does **not** refactor. If it finds drift, it writes findings to `handoff.md` and the relevant WP file's *Integration notes*, and the next WP in that area picks them up.
3. Merged WPs move to `delivery-plan.md`'s `Archive` section.

## QA workflow

Before merging:

1. Run [`/qa-review`](../.claude/commands/qa-review.md) — broken flows, edge cases, validation gaps, missing tests.
2. QA findings are read-only output; the implementing agent (or a follow-up WP) addresses them.
3. Re-run QA after fixes if changes were non-trivial.

## Minimising merge conflicts

The whole structure exists to keep merge conflicts low *by construction*:

- WP boundaries shrink the surface area each agent touches.
- The *Shared Files Allowed To Change* allow-list prevents unannounced shared-file edits.
- The parallelism rule sequences WPs that overlap on shared files.
- The integration command consolidates merge-readiness checks rather than letting drift accumulate.

If conflicts still happen frequently, the diagnostic is usually one of: WPs are too large, the allow-list isn't being respected, or `delivery-plan.md` isn't being kept current.

---

## AuralFlow chosen layout

AuralFlow uses an **iOS app** layout — not one of the web/CLI/data recipes below. The generic recipes are kept further down for reference; they do not apply.

```
Soundscape/                       Xcode app target source
  App/                            @main app, scene config, DI graph
    AuralFlowApp.swift
    SceneDelegate.swift           (only if UIScene-based)
  Audio/                          Real-time audio graph
    AudioEngine.swift             AVAudioEngine wrapper, public API
    Contract/                     Public types shared with Adaptive/ — see api-contract.md §1
      ParameterId.swift
      ParameterDelta.swift
    Nodes/
      DroneSynth.swift
      PadSynth.swift
      NoiseGenerator.swift
      PulseModulator.swift        Sub-audible LFO state (struct, used inside source nodes)
      FilterController.swift      SVF math + parameter mapping (used inside source nodes)
      BinauralGenerator.swift
      Mixer.swift
    Internal/                     Module-private — see decisions.md 2026-05-29
      RingBuffer.swift            Lock-free SPSC parameter pipe
      EngineParameters.swift      Shared parameter store
  Adaptive/                       Off-audio-thread rules engine
    AdaptiveController.swift
    Signals/
      TimeOfDayCollector.swift
      MotionCollector.swift
      HeartRateCollector.swift
      FeedbackCollector.swift
    Rules/                        Pure (Signals, Context) → ParameterDelta
    AI/                           Phase 4 — natural-language adjuster (cloud)
  Modes/                          Mode presets and configuration
    ModeKind.swift
    ModePreset.swift
    Presets/
      FocusPresets.swift
      SleepPresets.swift
      RelaxPresets.swift
      WalkPresets.swift
  Persistence/                    SwiftData stack
    Models/
      Session.swift
      ModePreset+Model.swift
      RatingEvent.swift
      AdaptiveProfile.swift
    Repositories/
      SessionRepository.swift
      PresetRepository.swift
      AdaptiveProfileRepository.swift
    SchemaMigrations/
  Views/                          SwiftUI presentation
    DesignSystem/                 Reusable primitives (Buttons, Sliders, Cards)
    Screens/
      Home/
      ModeDetail/
      Session/
      Settings/
    Routing/
      Route.swift
  Resources/
    Assets.xcassets
    Localizable.strings
    PrivacyInfo.xcprivacy
SoundscapeTests/                  XCTest unit tests
  AudioTests/
  AdaptiveTests/
  PersistenceTests/
  Doubles/                        Test fakes for protocol boundaries
  Fixtures/
SoundscapeUITests/                XCUITest e2e
Soundscape.xcodeproj/
docs/                             This directory
work-packages/                    One file per bounded unit of work
.claude/                          Claude Code config
scripts/                          Polyglot wrappers
```

Notes:

- `Audio/` is the **only** module that runs code on the audio render thread. Anything outside `Audio/` is off-thread.
- `Audio/Internal/` is module-private (see `decisions.md` 2026-05-29). Public contract types shared with `Adaptive/` live in `Audio/Contract/`, not `Audio/Internal/`.
- The only public surface of `Audio/` is `AudioEngine.swift` (the `AudioEngineControl` protocol + concrete actor-like class) plus the contract types in `Audio/Contract/`. Everything else under `Audio/` is `internal`.
- `Persistence/Repositories/*` are the **only** way to read or write durable data from outside `Persistence/`.
- The repo currently ships the bare Xcode template skeleton; WP01 lays this layout down for real.

---

## Recommended layouts (by project type)

These are **optional recipes**. Pick the one that fits and delete the rest. The scaffold itself is framework-neutral; nothing below is required. Each recipe includes a one-line `mkdir -p` block — run it from your terminal at adoption time. (The dangerous-commands hook will block `rm -rf` if Claude tries to run these directly; copy-paste them yourself.)

### Web app (frontend + backend, single repo)

```
features/
  <feature-name>/
    components/
    services/
    hooks/
    types/
    tests/
shared/
  types/
  utils/
  constants/
server/
  routes/
  services/
  middleware/
docs/
tests/
scripts/
```

Use when: medium-to-large web app with multiple feature domains, mixed frontend/backend ownership, one or more agents per feature.

**Adopt this layout:**
```bash
mkdir -p features shared/types shared/utils shared/constants server/routes server/services server/middleware tests
```

### API / service

```
server/
  routes/
  services/
  middleware/
  schemas/
shared/
  types/
  utils/
docs/
tests/
scripts/
```

Use when: pure backend service with no frontend. Drop `features/` entirely; route handlers live under `server/routes/` grouped by resource.

**Adopt this layout:**
```bash
mkdir -p server/routes server/services server/middleware server/schemas shared/types shared/utils tests
rm -rf features  # not used in this layout
```

### CLI tool / library

```
src/
  <module>/
docs/
tests/
scripts/
```

Use when: single-purpose tool or library with no clear "feature" boundary. The `features/` and `server/` directories don't apply — delete them on adoption.

**Adopt this layout:**
```bash
mkdir -p src tests
rm -rf features  # not used in this layout
```

### Data / pipeline

```
pipelines/
  <pipeline-name>/
    extract/
    transform/
    load/
    tests/
shared/
  schemas/
  utils/
docs/
tests/
scripts/
```

Use when: ETL / batch / streaming data work. WP boundaries follow pipeline boundaries; shared schemas are the primary parallel-WP risk surface.

**Adopt this layout:**
```bash
mkdir -p pipelines shared/schemas shared/utils tests
rm -rf features  # not used in this layout
```

### Mixed / monorepo

```
apps/
  <app-name>/
    ...one of the layouts above...
packages/
  <shared-package>/
    src/
    tests/
docs/
scripts/
```

Use when: multiple apps share code via internal packages. Each app gets its own internal layout; shared packages have explicit owners.

**Adopt this layout:**
```bash
mkdir -p apps packages
rm -rf features  # apps own their internal layouts; the top-level features/ doesn't apply
```

---

## When in doubt

- Read [WP00-foundation.md](../work-packages/WP00-foundation.md) — the project structure decision lives there once made.
- Cross-reference [coding-standards.md](coding-standards.md) for conventions, [api-contract.md](api-contract.md) for API surface, [data-model.md](data-model.md) for persistence.
