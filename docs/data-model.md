# Data Model

The persistent data shape for AuralFlow. SwiftData (preferred) — see [decisions.md](decisions.md) once the choice is ratified. All entities live in `Soundscape/Persistence/` and are mutated via repositories, never from audio code.

A WP with `DB impacts: yes` updates this doc as part of its work.

---

## Entities

### `Session`

Represents one user listening session.

| Field | Type | Notes |
|---|---|---|
| `id` | UUID | Primary key |
| `modeKind` | enum (`focus`, `sleep`, `relax`, `walk`) | Required |
| `startedAt` | Date | Required |
| `endedAt` | Date? | Nil while in-progress |
| `presetId` | UUID? | FK → `ModePreset.id`; nil if ad-hoc |
| `targetDurationSeconds` | Int? | Nil = open-ended (typical for sleep) |
| `actualDurationSeconds` | Int? | Computed at end |
| `rating` | Int? | Thumbs encoding (decided 2026-05-29 WP02): `5` = thumbs up, `1` = thumbs down, `nil` = skipped |
| `freeTextFeedback` | String? | Optional |

Lifecycle: created on tap-start, finalised on session end. Sessions are immutable after `endedAt` is set (except for late-arriving ratings).

### `ModePreset`

A named parameter snapshot for a mode (factory or user-created).

| Field | Type | Notes |
|---|---|---|
| `id` | UUID | Primary key |
| `modeKind` | enum | Same as Session |
| `name` | String | User-visible |
| `parameters` | Data (Codable `ParameterSnapshot`) | Engine parameters at full intensity |
| `isUserEditable` | Bool | False for factory presets |
| `createdAt` | Date | |
| `updatedAt` | Date | |

Factory presets are seeded on first launch. User presets are created via "save current as preset" from a running session.

### `RatingEvent`

Per-session rating (1:1 today; the entity exists separately so we can add in-session ratings later without migrating `Session`).

| Field | Type | Notes |
|---|---|---|
| `id` | UUID | Primary key |
| `sessionId` | UUID | FK → `Session.id` |
| `timestamp` | Date | When the rating was given |
| `value` | Int | Thumbs encoding (decided 2026-05-29 WP02): `5` = thumbs up, `1` = thumbs down |
| `note` | String? | Optional free text |

### `AdaptiveProfile` (Phase 3+)

Per-user learned preferences. Lazy: only created once the user opts into personalisation.

| Field | Type | Notes |
|---|---|---|
| `id` | UUID | Primary key (one per user) |
| `preferredTreble` | Float | -1.0 … +1.0; bias applied to brightness rules |
| `preferredEnergy` | Float | -1.0 … +1.0; bias applied to motion / pulse rules |
| `quietHoursStart` | Int? | Hour-of-day (24h); suppresses bright Focus palette |
| `quietHoursEnd` | Int? | |
| `lastUpdated` | Date | |

Privacy: never leaves the device unless cloud sync is enabled.

---

## Relationships

```
ModePreset 1───* Session
Session    1───? RatingEvent
AdaptiveProfile 1───1 (user, implicit)
```

No cross-mode references; each `Session` belongs to one preset (or none, for ad-hoc).

## Indexes

- `Session.startedAt` (descending) — primary list view ordering.
- `Session.modeKind` — filter by mode in history.
- `ModePreset.modeKind` — preset picker by mode.
- `RatingEvent.sessionId` — join for "show ratings on session".

## Migration policy

- **Additive changes (new optional fields) are allowed without a major version bump.** Defaults populated lazily.
- **Removing or renaming fields requires a migration step** documented here AND in the WP that introduced it.
- **No silent data loss.** Removed columns are recorded in this doc with a `## Deprecated` section so future agents can reconstruct history.

## Retention

- Sessions: kept indefinitely on-device. User can purge from settings ("clear history").
- Ratings: same as their parent session.
- AdaptiveProfile: kept until the user toggles personalisation off, then deleted on the next launch.

No cloud retention in MVP.

## As-built notes (WP02)

- The value-type `ModePreset` (in `Modes/`) is mirrored on disk by `ModePresetRecord` (in `Persistence/Models/`) — the two are converted at the repository boundary so SwiftData reference semantics do not leak into the audio path. `ParameterSnapshot` is JSON-encoded into `ModePresetRecord.parametersData`.
- `Session.modeKindRaw: String` stores the `ModeKind.rawValue` (SwiftData enum-attribute migrations are still rough; storing the raw string keeps schema evolution cheap).
- Repositories are `@MainActor` and use `container.mainContext` synchronously inside `async throws` method bodies. The `async` shape lets a future WP swap in a background `@ModelActor` impl without changing call sites.

## Open questions

- Whether to store per-second engine parameter snapshots for replay/debugging — useful but storage-heavy. Probably opt-in via a debug toggle.
