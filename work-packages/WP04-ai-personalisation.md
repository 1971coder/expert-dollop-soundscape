# WP04 — AI personalisation

> **Status:** proposed
> **Branch:** `wp/04-ai-personalisation`
> **Assigned:** claude (pair with human)
> **Depends on:** WP03

## Behaviour rules for the implementing agent

- **Cloud calls live in `Soundscape/Adaptive/AI/` only.** Nowhere else.
- **Never on the audio path.** Calls happen off-thread, results travel through the same `ParameterDelta` pipeline.
- **Feature-flagged.** A user setting (default **off**) gates the entire module.
- **No biometric data in prompts.** Heart rate, raw motion, free-text feedback — none of these go to a vendor. The prompt is mode + intensity + recent rating signal.
- **Vendor failure is non-fatal.** A network or model error logs at `.error` and the session continues unchanged.
- **No vendor SDKs in the app target unless absolutely necessary.** Prefer URLSession + a small typed wrapper.
- **Update [../docs/handoff.md](../docs/handoff.md)** when done.

---

## Objective

Layer optional, cloud-assisted personalisation on top of the deterministic rules engine: natural-language adjustment ("make it darker", "less pulse"), preset recommendations from history, and a behavioural-learning loop that biases the adaptive profile. Everything in this WP is opt-in, off-thread, and gracefully optional.

## Scope

- `Adaptive/AI/NaturalLanguageAdjuster.swift` — translates a short user prompt + `SessionContext` into a list of `ParameterDelta`s.
- `Adaptive/AI/PresetRecommender.swift` — scores recent sessions against profile and proposes adjusted presets.
- `Adaptive/AI/BehaviouralLearner.swift` — updates `AdaptiveProfile` biases from accumulated rating data.
- Vendor abstraction: a small `LLMClient` protocol with one implementation per supported vendor (OpenAI, Claude). Both behind the same protocol so swapping is local.
- Settings UX: AI toggle, vendor pick, API key field (stored in Keychain, never `UserDefaults`).
- Session UI: a small "Ask for an adjustment…" prompt when AI is enabled.

## Out of scope

- A bespoke on-device LLM. Cloud is the only AI route in this WP.
- Multi-user / family profiles.
- Cross-device sync of `AdaptiveProfile` (separate WP if and when the product wants it).
- Premium / paywall mechanics.

## Dependencies

- WP03 merged. Rules engine, profile entity, and intensity controls must all be in place.

## Files likely touched

- `Soundscape/Adaptive/AI/NaturalLanguageAdjuster.swift` (new)
- `Soundscape/Adaptive/AI/PresetRecommender.swift` (new)
- `Soundscape/Adaptive/AI/BehaviouralLearner.swift` (new)
- `Soundscape/Adaptive/AI/LLMClient.swift` (new — protocol)
- `Soundscape/Adaptive/AI/OpenAIClient.swift` (new)
- `Soundscape/Adaptive/AI/ClaudeClient.swift` (new)
- `Soundscape/Adaptive/AI/Keychain.swift` (new — Keychain wrapper)
- `Soundscape/Adaptive/AdaptiveController.swift` (modify — receive AI-sourced deltas)
- `Soundscape/Views/Screens/Settings/AISettings.swift` (new)
- `Soundscape/Views/Screens/Session/SessionView.swift` (modify — adjustment prompt)
- `Soundscape/Persistence/Repositories/AdaptiveProfileRepository.swift` (modify — write learner updates)
- `Soundscape/Resources/Localizable.strings` (modify — new copy)
- `../docs/api-contract.md` (modify — §3 cloud surface)
- `../docs/architecture.md` (modify — AI sub-section)
- `../docs/decisions.md` (modify — vendor choice; prompt format; data-out policy)
- `SoundscapeTests/AdaptiveTests/AI/**` (new tests, mocked vendor)

## Files explicitly excluded

- `Soundscape/Audio/**` — DSP doesn't change; only parameter inputs.

## Shared Files Allowed To Change

- `Soundscape/Adaptive/AdaptiveController.swift`
- `Soundscape/Views/Screens/Session/SessionView.swift`
- `Soundscape/Persistence/Repositories/AdaptiveProfileRepository.swift`
- `Soundscape/Resources/Localizable.strings`
- `Soundscape.xcodeproj/project.pbxproj`
- `../docs/api-contract.md`
- `../docs/architecture.md`
- `../docs/decisions.md`
- `../docs/handoff.md`
- `../docs/delivery-plan.md`

## API impacts

- Adds the `LLMClient` protocol and `NaturalLanguageAdjuster` (see [api-contract.md §3](../docs/api-contract.md#3-optional-cloud-surface-phase-4)).
- No changes to `AudioEngineControl` or `ParameterId` — AI feeds the same pipeline.
- New `SessionContext` struct (mode, intensity, recent rating summary — **no biometrics**).

## DB impacts

- `AdaptiveProfile` gains learner-update fields if not already present (additive only).

## UI impacts

- New AI settings screen under Settings.
- New "Ask for an adjustment…" affordance during a session (visible only when AI is enabled).
- First-run consent prompt with plain-language copy: what's sent, where, why, how to disable.

## Acceptance criteria

- AI toggle off → no network calls, no AI UI, no behavioural changes whatsoever.
- AI toggle on → "make it darker" produces an audibly darker engine within a few seconds; deltas applied via the standard pipeline.
- Vendor failure (network down, 401, 5xx) is logged at `.error`, no user-visible crash, session continues.
- API key stored in Keychain, never `UserDefaults`.
- A unit test confirms no biometric values can reach `LLMClient` (boundary test).
- Decision record in `decisions.md` covers: chosen default vendor, prompt format, data-out policy.

## Tests required

- **Unit:** `NaturalLanguageAdjuster` against a mocked `LLMClient` returning canned responses.
- **Unit:** `LLMClient` implementations against a fake URLSession (request shape, retry, timeout).
- **Unit:** `BehaviouralLearner` produces expected profile bias changes for canned rating streams.
- **Boundary test:** Construction of a vendor request from `SessionContext` — assert no field contains HR or motion data.
- **Integration:** AI off → no `LLMClient` instantiation occurs (DI test).

## Integration notes

- Vendor SDKs are tempting but heavy. Start with URLSession + Codable; add an SDK only if rate-limit handling becomes painful.
- The "what we send" copy in the consent screen is **load-bearing** — agents must not change it without an explicit decision entry. The copy is part of the privacy promise.
- The `BehaviouralLearner` should be small and conservative — large profile swings from few sessions will feel unpredictable. Start with capped bias deltas (e.g. ±0.05 per session).

## Handoff requirements

- [ ] Row in [../docs/delivery-plan.md](../docs/delivery-plan.md) status updated to `merged`.
- [ ] [../docs/handoff.md](../docs/handoff.md) reflects new state via `/update-handoff`.
- [ ] [../docs/decisions.md](../docs/decisions.md) updated with: default vendor, prompt shape, data-out policy, learner bias cap.
- [ ] [../docs/architecture.md](../docs/architecture.md) AI sub-section reflects as-built.
- [ ] [../docs/api-contract.md §3](../docs/api-contract.md#3-optional-cloud-surface-phase-4) reflects as-built.
- [ ] Tests pass: `./scripts/test.sh`.
- [ ] Audit passes: `./scripts/template-audit.sh --strict`.
