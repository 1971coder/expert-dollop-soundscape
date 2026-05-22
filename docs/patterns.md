# Patterns Research

Findings from analyzing two reference repos to inform this template's content.
Audit date: 2026-04-28.

References analyzed:
- `~/Dev/claude-research/claude-code-best-practice/` — community best-practice repo (Shayan Taherian).
- `~/Dev/claude-research/claude-cookbooks/` — Anthropic's official cookbook repo.

---

## 1. What I read

### claude-code-best-practice
- `CLAUDE.md` — root, 127 lines.
- `.claude/settings.json` — full read (442 lines: permissions, all 27+ hook events wired, spinnerVerbs, etc.).
- `.claude/agents/development-workflows-research-agent.md` — 127-line research agent.
- `.claude/agents/presentation-claude-gemini.md` — frontmatter + first 120 lines (file is 25k+ tokens; rest is "Learnings" log).
- `.claude/agents/presentation-vibe-coding.md` — full read.
- `.claude/agents/time-agent.md` — full read (46 lines).
- `.claude/agents/weather-agent.md` — full read (84 lines).
- `.claude/commands/time-command.md` — full read (27 lines).
- `.claude/commands/weather-orchestrator.md` — full read (60 lines).
- `.claude/commands/workflows/development-workflows.md` — full read (210 lines).
- `.claude/hooks/HOOKS-README.md` — full read (~590 lines, hooks reference).
- `.claude/hooks/config/hooks-config.json` — full read.
- `.claude/skills/weather-fetcher/SKILL.md` — full read.
- `.claude/skills/weather-svg-creator/SKILL.md` — full read.
- `.claude/skills/time-skill/SKILL.md` — full read.
- `.claude/skills/agent-browser/SKILL.md` — full read (~220 lines).
- `.claude/rules/presentation.md` — full read.
- `.claude/rules/markdown-docs.md` — surfaced via system reminder (full content).
- `agent-teams/.claude/agents/time-agent.md` — full read (sub-project sample).
- `agent-teams/.claude/commands/time-orchestrator.md` — full read.

### claude-cookbooks
- `CLAUDE.md` — root, 111 lines.
- `skills/CLAUDE.md` — 237 lines.
- `skills/README.md` — full read (354 lines).
- `skills/.claude/settings.json` — full read.
- `skills/.claude/hooks/session-start.sh` — full read.
- `skills/.claude/hooks/pre-write.sh` — full read.
- `skills/.claude/hooks/pre-bash.sh` — full read.
- `skills/custom_skills/creating-financial-models/SKILL.md` — full read.
- `skills/custom_skills/analyzing-financial-statements/SKILL.md` — full read.
- `skills/custom_skills/applying-brand-guidelines/SKILL.md` — full read.
- `.claude/agents/code-reviewer.md` — full read (~206 lines).
- `.claude/commands/notebook-review.md` — full read (16 lines).
- `.claude/commands/model-check.md` — full read (21 lines).
- `.claude/commands/review-pr.md` — full read (120 lines).
- `.claude/commands/link-review.md` — full read.
- `.claude/skills/cookbook-audit/SKILL.md` — full read (~273 lines).
- `claude_agent_sdk/chief_of_staff_agent/CLAUDE.md` — full read.

### claude-code-template (current state)
- `CLAUDE.md`, `README.md`, `.claude/settings.json`.
- All three agents (`code-reviewer`, `test-engineer`, `researcher`).
- All four commands (`plan`, `implement`, `review`, `commit`).
- `.claude/hooks/deny-dangerous-commands.sh`.
- `docs/{requirements,architecture,decisions}.md` (all empty TODO scaffolds).
- `scripts/check.sh`.

---

## 2. Patterns from claude-code-best-practice

### CLAUDE.md as a meta-spec

The root CLAUDE.md treats the repo as an artifact *about* Claude Code. It documents the frontmatter spec for skills and subagents directly inline (e.g. listing every supported field: `disable-model-invocation`, `user-invocable`, `permissionMode`, `effort`, `isolation`, etc.).

This is **specific to a teaching repo**, not a transferable pattern. A normal project should not duplicate Claude Code's own spec inline — link to docs instead.

Transferable: section headers used (Repository Overview · Key Components · Critical Patterns · Configuration Hierarchy · Workflow Best Practices · Git Commit Rules · Documentation). The "Workflow Best Practices" section is a tight bullet list (~10 items) of distilled lessons:

> "Keep CLAUDE.md under 200 lines per file for reliable adherence"
> "Use commands for workflows instead of standalone agents"
> "Perform manual `/compact` at ~50% context usage"

That format — 8-12 hard-won opinions, terse, no fluff — is the strongest part to imitate.

### "Execution Contract" prose in commands and agents

Best-practice commands and agents include a recurring block titled **Execution Contract (non-negotiable)** with imperative bans:

> "You MUST complete this command by delegating to the `weather-agent` subagent. You are forbidden from: [...] Skipping Step 1 [...] If you cannot invoke the Agent tool, stop and report the error. Do not improvise."

And a **fail-closed guardrail**:

> "If the agent does not return a numeric temperature and unit, DO NOT proceed to Step 3."

Useful when the workflow has a strict ordering or specific tool routing (orchestrator-style commands). Less useful for open-ended commands. Consider this only when delegation must be enforced.

### Tool allowlist style

Two styles in active use within the same repo:

- Multi-line YAML list with quoted entries: `- "Bash(*)"` → see `presentation-vibe-coding.md`.
- Single-line comma-separated: `tools: Bash` → see `agent-teams/time-agent.md`.

The frontmatter field name itself diverges — see Anti-patterns §6.

### Self-evolving "Learnings" sections in agents

Long-running agents append a `## Learnings` bullet list every execution:

> "2026-04-17 brain-vs-desk switch: user reverted the Context analogy ..."
> "2026-04-17 emoji-per-topic map: each of the 7 levels now carries ..."

Pros: persists hard-won context for the agent to read on next invocation.
Cons: file grows unbounded; never pruned; some entries become contradictory or stale; bloats context every time the agent is loaded.

For a transferable template, this is **probably not worth copying** — Claude Code's auto-memory system at `~/.claude/projects/.../memory/` is a better-fitting home for this kind of knowledge.

### Skill structure

Two flavors:
- **Tiny skill (`time-skill`, ~32 lines)**: frontmatter + Task + Instructions + Requirements. No supporting files.
- **Multi-file skill (`weather-svg-creator`)**: SKILL.md is a slim 29-line entrypoint that links out:
  > "For SVG template, output template, and design specs, see [reference.md](reference.md)"
  > "For example input/output pairs, see [examples.md](examples.md)"

This is the [progressive disclosure](https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills) pattern: SKILL.md is what loads at discovery; deeper docs are loaded only when needed. The `agent-browser` skill takes the same approach with `references/*.md` and `templates/*.sh`.

### Hooks: every event wired

`.claude/settings.json` configures **every one of the 27+ hook events** to call the same Python handler (`hooks.py`) with `async: true` and a `statusMessage` field. The script reads stdin, looks up the event, plays a sound. Local config (`hooks-config.local.json`) git-ignored so each developer can mute hooks they dislike.

This is impressive but it's **infrastructure for sound notifications**, not safety. Treat it as one specific use of hooks, not a template for how all hooks should look.

### Permissions: granular allow + ask

```json
"allow": [
  "Bash(*)",                          // very permissive
  "WebFetch(domain:api.open-meteo.com)",
  "mcp__chrome-devtools__*",
  ...
],
"ask": [
  "Bash(rm *)", "Bash(npm *)", "Bash(docker *)", ...
]
```

The `ask` list catches package managers and destructive shell tools even though `Bash(*)` is allowed. The order matters: more specific `ask` rules win over the broad `Bash(*)` allow.

### Custom UI fields

`spinnerVerbs`, `spinnerTipsOverride`, custom `statusLine` shell command, `outputStyle: Explanatory`, `plansDirectory: ./reports`, `attribution.commit/pr` strings.

These are personal-repo affordances. **Don't copy the joke values** (`"Admiring Shayan's code"`); the *capability* is worth knowing about.

### Lazy-loaded rules with `paths:` frontmatter

`.claude/rules/presentation.md` opens with:

```yaml
---
paths:
  - "presentation/**"
---
```

Loads into context only when Claude touches a matching file. Without `paths:` they'd load every session like CLAUDE.md. Useful for area-specific style rules without bloating the global prompt.

---

## 3. Patterns from claude-cookbooks

### Action-oriented, gotcha-driven CLAUDE.md

`skills/CLAUDE.md` (237 lines) is dense with **numbered, named gotchas** like:

> "**Gotcha 4: File ID Extraction**
> **Problem**: Response structure differs from standard Messages API
> **Solution**: File IDs in `bash_code_execution_tool_result.content.content[0].file_id`
> ```python
> # Use file_utils.extract_file_ids() — handles beta response structure
> ```"

Each gotcha has Problem / Solution / wrong-vs-right code. This format outperforms generic "common pitfalls" prose because the structure forces concreteness.

### Tight commands that delegate to `gh`

The cookbooks commands are deliberately thin — most are 15-30 lines. Pattern:

```yaml
---
allowed-tools: Bash(gh pr comment:*),Bash(gh pr diff:*),Bash(gh pr view:*),Read,Glob,Grep,WebFetch
description: Comprehensive review of Jupyter notebooks and Python scripts
---

**IMPORTANT**: Only review the files explicitly listed in the prompt above.

[1-2 paragraphs of guidance]

**IMPORTANT: Post your review as a comment using: `gh pr comment $PR_NUMBER --body "..."`**
```

Notice:
- `allowed-tools:` is **scoped to specific subcommands** (`Bash(gh pr comment:*)`, not `Bash(*)`).
- The command body is short and just says what to check + how to publish.
- Repeated `**IMPORTANT**` headers act as guardrails against scope creep.

### One large agent with explicit checklist

`code-reviewer.md` is ~206 lines. Structure:
- Role statement (1 paragraph).
- 4 "Core Review Areas" (one-line each).
- "SPECIFIC CHECKLIST" with sub-sections (Notebook Structure · Python & Style · Package Management · Testing · Security · CI/CD · Dev Workflow · Repo-Specific Patterns).
- "Review Process" — 8 numbered steps.
- "Feedback Format" — severity grouping (Critical / Important / Suggestions / Positive Notes).
- "Example Review Comments" — three concrete examples showing the expected output style.

The example comments at the end are the most transferable trick: they teach the agent the *exact* output format by showing it.

### Skill SKILL.md style: declarative + capability list

Cookbooks skills lead with a **capability description** rather than imperative steps:

```markdown
# Financial Modeling Suite
A comprehensive financial modeling toolkit ...

## Core Capabilities
### 1. Discounted Cash Flow (DCF) Analysis
- Build complete DCF models with multiple growth scenarios
- ...

## Input Requirements
## Output Formats
## Example Usage
"Build a DCF model for this technology company ..."
```

vs. best-practice's **imperative-instruction style**:

```markdown
# Time Skill
## Task
Display the current date and time in PKT.
## Instructions
1. Get Current Time: Run the following bash command: ...
2. Display Result: Show the time in this format: ...
```

Cookbooks-style is appropriate for *capability* skills the model picks up and applies with judgment. Best-practice-style is appropriate for *runbook* skills with one canonical execution path.

### Bash hooks for environment guardrails

Cookbooks `.claude/hooks/*.sh` files use `set -e` and:
- **session-start.sh**: print warnings for missing venv, missing API key, outdated SDK. Always exits 0; never blocks.
- **pre-write.sh**: warn (don't block) when writing to protected files like `.env`, `requirements.txt`, `sample_data/`.
- **pre-bash.sh**: warn on `rm -rf outputs`, remind about kernel restart after `pip install anthropic`.

The pattern: **warn-but-allow** rather than block. Bash hooks here are nudges, not gates.

### Minimal settings.json

```json
{
  "hooks": { "SessionStart": {...}, "PreToolUse": [...] },
  "contextFiles": ["CLAUDE.md", "docs/skills_cookbook_plan.md"],
  "projectInfo": { "name": "...", "type": "..." }
}
```

No permissions block at all (cookbooks defers to user prompts). Notable absent fields by choice.

### `cookbook-audit` skill: rubric-with-templates

The `cookbook-audit/SKILL.md` is interesting because it's a **rubric skill** — its job is to apply a checklist to a target file. Pattern:
- SKILL.md says: "always read `style_guide.md` first, then audit, then output in this format."
- `style_guide.md` (sibling file) holds the long-form rubric content.
- `validate_notebook.py` is a script the skill calls.

Same progressive-disclosure principle as best-practice's multi-file skills, but used here for a *judgment* skill (rate this 1-5) rather than a generation skill.

---

## 4. Common ground (strongest signal)

These appear in BOTH repos and should be treated as defaults:

1. **YAML frontmatter is universal** for commands, agents, skills.
   - Commands: `description:`, `allowed-tools:` (cookbooks) / `allowedTools:` (best-practice — see anti-patterns).
   - Agents: `name:`, `description:`, `tools:`/`allowedTools:`, optionally `model:`.
   - Skills: `name:`, `description:` (always), optionally `allowed-tools:`, `user-invocable:`.

2. **Description field doubles as a routing hint.** Both repos use phrases like "Use this when..." / "PROACTIVELY use..." in description. This is what Claude Code matches against to decide when to invoke.

3. **CLAUDE.md is the entry, not the encyclopedia.** Both link out for depth. Best-practice has `.claude/rules/markdown-docs.md`; cookbooks has `docs/skills_cookbook_plan.md` and external docs links.

4. **Skills directory layout: `.claude/skills/<name>/SKILL.md`** with optional sibling files.

5. **Hooks belong in `.claude/hooks/` and are wired through `settings.json`.**

6. **Commands and agents reference each other.** A `/foo` command often dispatches via the Agent tool to a sub-agent that then invokes a Skill. Cookbooks' `/review-pr` → code-reviewer subagent. Best-practice's `/weather-orchestrator` → weather-agent → weather-fetcher skill.

7. **Conventional commits + co-author attribution** (cookbooks does it via `feat(scope): ...`, best-practice via `attribution.commit` config field).

8. **No dated model IDs.** Both repos call this out explicitly.

9. **Severity-grouped review output**: both repos' code-review surfaces use the Critical / Important / Suggestion / Nit hierarchy.

10. **Permission posture: deny destructive bash, allow read-only git.** Different syntax (best-practice's broad allow + ask vs. cookbooks' minimal settings + bash-hook warnings) but same intent.

---

## 5. Divergences (choices to make)

| Dimension | best-practice | cookbooks | What to pick |
|---|---|---|---|
| Frontmatter field for tools | `allowedTools:` (camelCase, multi-line list) | `tools:` and `allowed-tools:` (single-line CSV) | **Use `tools:` for agents, `allowed-tools:` for skills/commands** — these are the canonical names. See anti-patterns §6. |
| Command size | Long "Execution Contracts" (50-200 lines) with non-negotiable rules | Thin shells (15-30 lines) that delegate to CLI | Match the task. Orchestrators that route to agents/skills benefit from contracts; review/audit commands stay thin. |
| Hook language | Python (one big handler routes by event name) | Bash (one script per concern) | Bash if the hook is short and tied to specific tools; Python if you need shared state across many events. |
| Hook posture | Comprehensive coverage (every event wired); side-effects only (sounds) | Few hooks (SessionStart + PreToolUse) but substantive (warnings) | Substantive minority wins. Don't wire events you don't have a use for. |
| Settings permissions | Long granular allow + ask lists | Empty / minimal; rely on prompts | Cookbooks' minimalism ages better. The current template already follows this. Add ecosystem-specific entries lazily. |
| Agent style | Some agents have appended "Learnings" sections that grow forever | None | **Don't add Learnings appendixes.** The auto-memory system handles persistent context better. |
| Skill instruction style | Imperative ("Run this command. Then do this.") | Declarative-rubric ("Capabilities: ... Inputs: ... Outputs: ...") | Pick by skill type: runbook → imperative; capability → declarative. |
| Tone in agent prompts | Includes rhetorical bait ("$200 tip if perfect", "I bet you can't") | Plain professional voice | **Plain.** The "bait" patterns are unreliable and add noise. |
| Where to put long docs | `best-practice/`, `reports/`, `tips/` (parallel content directories) | `docs/`, inline in CLAUDE.md, README links | Use `docs/` (template already does). Parallel dirs are confusing for projects that aren't reference repos. |

---

## 6. Anti-patterns I noticed

These appear in the references but I would NOT copy them:

### Frontmatter field-name drift (best-practice)

The repo's own CLAUDE.md spec says agents use `tools:` — but most of its agent files use `allowedTools:` (e.g. `presentation-vibe-coding.md`, `weather-agent.md`, `time-agent.md` in root scope). The `agent-teams/.claude/agents/time-agent.md` correctly uses `tools:`. Even within one repo the convention drifted.

**Lesson:** pick the canonical field name (`tools:`) and keep it consistent across every agent file.

### Joke / personality fields in settings.json (best-practice)

```json
"spinnerVerbs": { "verbs": ["Admiring Shayan's code", ...] },
"statusLine": { "command": "echo \"shayan's best practice status line\"" }
```

Fine for a personal vanity repo. Don't copy into a template — every project clone would inherit someone else's name.

### Unbounded "Learnings" appendix in agents (best-practice)

`presentation-claude-gemini.md` is 25k+ tokens largely because each invocation appends new learnings. Side effects:
- Every call loads the full backlog into context.
- Some old entries directly contradict newer ones (e.g. "use desk analogy" → "user reverted to brain analogy").
- No pruning mechanism.

If persistent context matters, write it to the auto-memory system or a project log — not the agent file that gets reread every invocation.

### Prompt-engineering bait (best-practice)

```markdown
I'll tip you $200 for perfectly accurate counts. I bet you can't get every number right — prove me wrong.
```

These rhetorical patterns are inconsistent in their effects and signal cargo-culting. They also age badly — a future contributor reading this can't tell if it's load-bearing or junk. Strip from any template version.

### CLAUDE.md as Claude-Code-spec encyclopedia (best-practice)

Best-practice's CLAUDE.md inlines the entire frontmatter spec for subagents and skills. That's because the repo *is* a Claude Code reference. A normal project's CLAUDE.md should describe the *project*, not Claude Code itself. Link to docs.

### CLAUDE.md with stale WIP status (cookbooks)

`skills/CLAUDE.md` near the bottom has:

> "**Notebook 1**: Complete and tested
> **Notebook 2**: Financial Applications — next priority
> **Notebook 3**: Custom Skills Development — after Notebook 2"

This is the kind of content that drifts the moment work moves on. Anti-pattern: putting in-flight task status in CLAUDE.md. Belongs in a TODO/issue tracker.

### `permissionMode: bypassPermissions` on a research agent (best-practice)

The development-workflows-research-agent sets `permissionMode: bypassPermissions` and `maxTurns: 30`. Even though the agent is read-only by intent, bypassing permissions on any agent that has `Bash(*)` is a wide blast radius. Prefer per-tool allowlists over wholesale bypass.

### Cookbooks code-reviewer agent: too project-specific to clone

The code-reviewer agent contains pages of cookbook-specific guidance (Jupyter `%%capture`, `dotenv.load_dotenv()`, `make check`, `uv add`, GitHub Actions internal-contributor gating). It's an excellent agent for *that* repo but not a general template. The template's existing `code-reviewer.md` is more generic and should stay that way.

### Marketing-copy in skill files (cookbooks)

`applying-brand-guidelines/SKILL.md` includes literal Acme Corp marketing voice ("Innovation Through Excellence", standard phrases like "At Acme Corporation, we…"). This is example *content* for a demo, not a pattern.

### Repeated "**IMPORTANT**" magical incantations (cookbooks)

Several cookbooks commands include "**IMPORTANT**: Only review the files explicitly listed in the prompt above. Do not search for or review additional files." Repeated bolded "IMPORTANT" sections start to act as superstition — fine once, but if you find yourself adding three of them, the underlying instruction probably isn't structured well.

---

## 7. Recommendations for my template

Each subsection proposes the **shape** to fill in (not the exact content).

### `CLAUDE.md`

The current scaffold is well-shaped — keep the section list. Suggested adjustments:

- Add a one-paragraph **prologue** above "Project Overview" that says: this file is the load-on-startup brief; deep details live in `docs/`.
- Keep "Workflow Best Practices" *out* of the project-level CLAUDE.md. It belongs in the user's global `~/.claude/CLAUDE.md` (cross-project). Project CLAUDE.md should be project-specific only.
- Trim "Conventions" to 3-5 bullets max in the template's default text. The current "Default rules of thumb" is already at the right size.
- "Gotchas" is the highest-value section to encourage the user to fill in. Suggest the format **`Bullet · Why it bites · How to avoid`** to force concreteness. (Cookbooks-style numbered gotchas with Problem/Solution code blocks would be heavier than most projects need.)
- Consider adding a **"How to work with Claude here"** section pointer: 2-3 lines that summarize "use `/plan` then `/implement`, gate changes through `/review`, commit with `/commit`". This is the entry point for anyone (including Claude itself) opening the repo for the first time.

Target length: 80-150 lines filled in. Current scaffold leaves blanks — that's correct.

### `.claude/commands/plan.md`

Current shape is good. Specific keepers:
- Loading order: CLAUDE.md → `docs/architecture.md` → relevant code. Don't change this.
- Section list (Goal · Scope · Approach · Risks · Steps). Matches both references' planning patterns implicitly.
- Stop instruction at the end: *"Do not start implementing. Stop after the plan and wait."* This is the most important line; cookbooks doesn't have this and ends up auto-implementing in some commands.

Suggested additions:
- A bullet under Approach: *"Identify what you don't need to change. Explicit non-changes prevent scope creep."*
- Optional: cap Steps at ~7. If a plan needs more, it's probably two plans.

### `.claude/commands/implement.md`

Current shape is solid. Keepers:
- "If reality diverges, stop and tell the user before improvising." (Best-practice's "fail-closed guardrail" pattern, said more humanly.)
- "Do not commit. Leave that to the user (or `/commit`)." Critical for separation between commands.
- `./scripts/check.sh` after each meaningful chunk.

Suggested additions:
- A bullet: *"If a step requires a decision the plan didn't make, surface it — don't invent."*
- Mention test running: if there's a test script, run it before declaring success.

### `.claude/commands/review.md`

Current shape is correct: thin command that delegates to the code-reviewer agent. Matches cookbooks' `/review-pr` pattern.

Suggested additions:
- Optionally accept a base branch like `main` (you already note this).
- Mention that the user can re-invoke `/review` after addressing findings — this is the "iterate to clean diff" loop.

### `.claude/commands/commit.md`

Current shape is the strongest of the four — it already encodes the right safety posture: stage by name (no `-A`), conventional format, no `--no-verify`, no push. Keep.

Suggested addition:
- Reference the user's git config to detect if signing is on (don't disable it).
- Note about heredoc for multi-line messages with embedded backticks.

### `.claude/agents/code-reviewer.md`

Current is well-scoped (read-only, severity grouping). Keepers:
- Read-only enforcement at the top.
- "If the diff is genuinely clean, say so plainly. Do not invent issues." (Anti-cookbook-cargo-cult.)
- Severity buckets.

Suggested additions:
- Add an **Example Output** section (1-2 short examples), borrowing the cookbooks format — it teaches the agent the expected shape:
  ```
  [Blocking] file.ts:42 — null deref when `user.org` is undefined
  [Should fix] file.ts:18 — naming `data` is too vague; this is a list of orders
  [Nit] file.ts:91 — trailing space
  ```
- Tighten "Read the file before judging" to: *"Read the file at HEAD. Do not judge based solely on the diff — context matters."*

### `.claude/agents/test-engineer.md`

Current operating principles are excellent (test behavior, cover awkward cases, don't mock the SUT, run them and verify they fail when broken). Keep. Suggested tweak:

- Add a final operating principle: *"Match the project's existing test convention — don't introduce a new framework."* (This is in there as principle 1; could be made even more emphatic.)
- Output summary section: ask for a one-line **"Sanity check: does the test fail when I break the implementation?"** result. This is a high-value habit.

### `.claude/agents/researcher.md`

Current is good. Keepers:
- Clarify-the-question first.
- Cast wide, narrow down.
- Cite everything.
- Length matches question.

Suggested additions:
- A line: *"If you find yourself wanting to edit, stop and tell the user — your role is read-only."*
- A line: *"Prefer `rg` over `grep`/`find` if available — faster and respects gitignore by default."*

### `.claude/settings.json`

Current is intentionally minimal — keep. Specific keepers:
- Read-only git in `allow`.
- Destructive commands in `deny`.
- The script paths in `allow` (these match the polyglot scripts).

Suggested additions (template-level — not project-level):
- Inline a comment-block at the top of `README.md` (already partly there) listing **per-ecosystem additions**: pnpm/npm, uv/pytest, cargo, swift, gh CLI. The README already has this — strong, keep.
- Consider adding: `Bash(gh pr view:*)`, `Bash(gh pr list:*)` — read-only `gh` for repos with a remote. Optional; only if the project has a GitHub remote.

Do **not** add:
- Custom spinner verbs / status lines (project pollution).
- `outputStyle:` setting (use the user's global preference).
- `disableAllHooks:` (defaults already favor enabled).

### `.claude/hooks/deny-dangerous-commands.sh`

Current implementation is clean. Keep. Notes:

- The README already says "shipped but not wired up." That's correct — wiring it requires a `hooks` block in `settings.json`. Document the wiring in a comment at the top of the script (it already is — keep that).
- Optional: add `git push --force-with-lease` to the deny list if you want to be strict, or leave it out (it's safer than `--force`).
- Consider an environment-variable escape hatch: `[[ "${ALLOW_DESTRUCTIVE:-}" == "1" ]] && exit 0` for cases where the user temporarily needs to bypass.

### `docs/{requirements,architecture,decisions}.md`

Current scaffolds are correct in spirit (TODO + a note about role). Suggested:
- `decisions.md` should add a one-line example entry to show shape:
  ```
  ## 2026-04-28 · Use pnpm over npm
  Alternatives considered: npm, yarn.
  Why: existing team workflow; lockfile fidelity.
  ```
- `architecture.md` could mention that the **first 60-80 most behavior-changing lines** belong in CLAUDE.md and the rest stays here. (Your scaffold already says this — strong.)

### Add a `docs/glossary.md`? (optional)

Both references implicitly need one but neither has it. Worth considering for projects with domain jargon, but skip in the bare template — it's an opt-in.

---

## 8. Open questions for me

These are decisions you'll want to make before writing the actual content:

1. **CLAUDE.md tone.** Best-practice is meta/teaching ("here is how Claude Code works"). Cookbooks is operational ("here is how to work in this repo"). Your template's scaffold already leans operational — confirm that's right. Operational is the more transferable choice.

2. **Should commands include explicit examples?** Best-practice commands sometimes show expected output (`Phase 2: Compare & Report` block in `development-workflows.md`). Cookbooks commands skip examples and trust the model. For four small commands, my recommendation is **no examples in the command body** but **one example in agents** (which produce richer output).

3. **Agent tool allowlists — strict or generous?** Cookbooks scopes to specific subcommands (`Bash(gh pr comment:*)`). Best-practice tends toward `Bash(*)` plus `Agent` and `mcp__*`. Your current template uses *strict* allowlists (`Bash(git diff:*)`, etc.). Decision: keep strict, or relax for ergonomics? My recommendation: **keep strict in the template**, document how to expand per project (the README already does this).

4. **"Learnings" sections in agents — opt-in or never?** I'd recommend never in the template. If you want this for a specific project, add it there; don't ship the pattern as a default.

5. **Should there be a fourth or fifth agent?** Common candidates:
   - `frontend-debugger` (visual / browser-driven) — but only useful with browser MCPs.
   - `migrations` — too project-specific.
   - `release-notes` — narrow but useful for repos that ship.
   My recommendation: **stay at three.** Add more per project, not in the template.

6. **Should `commit.md` invoke `code-reviewer` first?** Best-practice doesn't gate; cookbooks doesn't gate; both leave that to a separate `/review` command. Keep them separate. The user composes them: `/review` then `/commit`.

7. **Should I add a `.claude/rules/` directory with a `paths:`-scoped rule?** Useful when a project has area-specific style (e.g. UI components vs. server code). My recommendation: **don't ship by default**, but mention in README that it's an option if the project ends up with very different concerns in different folders.

8. **Should the template include a sample skill in `.claude/skills/`?** Both references have skills; the template currently has none. Tradeoff: a sample skill teaches the pattern but adds opinion. My recommendation: **no sample skill in the template**, but add a brief README note pointing at `.claude/skills/<name>/SKILL.md` as a place to add project-specific skills if useful.

9. **Hook wire-up: enabled or disabled in shipped settings.json?** Currently the deny script is shipped but unwired. That matches the "explicit opt-in" philosophy. Confirm: keep unwired (default), or wire by default? My recommendation: **keep unwired** — wiring is a project-level safety choice, not a template default. The README's "enable per project" note is correct.

10. **Conventional commits — assumed or template-configurable?** Your `commit.md` hardcodes Conventional Commits. Both references use them. If a project wants a different style (e.g. "feat:" without scope, or no convention at all), `commit.md` needs editing per-project. Document this expectation in the README so users know to adjust if they don't follow the convention.

11. **Should the README's permission examples list `WebFetch(domain:...)` and `WebSearch`?** Best-practice allows both broadly; cookbooks doesn't enable them. Useful for research-flavored work, dangerous for prompt-injection. My recommendation: **omit from defaults**, mention in README as opt-in.

12. **Should there be a `/research` command that delegates to `researcher`?** You have the agent but no thin command. Symmetric to `/review` → `code-reviewer`. Worth considering for the four-command set. My recommendation: **add it as a fifth thin command** — the asymmetry of having `code-reviewer` invoked via `/review` but `researcher` only invokable via Agent is awkward.

---

## Appendix · Quick-reference shape comparisons

### Agent frontmatter (canonical fields)

```yaml
---
name: agent-name             # required
description: When to invoke. # required, used for routing
tools: Read, Grep, Bash      # optional, comma-separated; inherits all if omitted
model: sonnet                # optional: haiku|sonnet|opus|inherit
---
```

### Command frontmatter

```yaml
---
description: One-line summary shown in /menu  # required
allowed-tools: Read, Grep, Bash(git diff:*)   # optional, scope tightly
---
```

### Skill frontmatter

```yaml
---
name: skill-name                              # required
description: When to use this skill           # required, used for auto-discovery
allowed-tools: WebFetch(*)                    # optional
user-invocable: true                          # optional, default true
---
```

### Hook wiring in settings.json (minimal)

```json
{
  "hooks": {
    "PreToolUse": [
      { "matcher": "Bash", "hooks": [
        { "type": "command", "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/deny-dangerous-commands.sh" }
      ]}
    ]
  }
}
```

### Diff-of-diffs: this template vs. references at-a-glance

| | best-practice | cookbooks | this template (current) |
|---|---|---|---|
| CLAUDE.md length | 127 lines | 111-237 lines | 43 lines (scaffold) |
| Commands | 3 (one huge) | 7 (all small) | 4 (small) |
| Agents | 5 (varied size) | 1 (large) | 3 (small-medium) |
| Skills | 4 (1 big, 3 small) | 4 (custom + 1 audit) | 0 |
| Hooks language | Python | Bash | Bash |
| Hook wiring | Every event | 2 events | None (shipped, unwired) |
| Permissions style | Granular allow + ask | Empty / minimal | Strict allow + small deny |
| Auto-evolves agents | Yes (anti-pattern) | No | No (correct) |
| Joke/personality fields | Yes | No | No |

The template's current shape sits closer to cookbooks than to best-practice on most axes, which is the right choice for a transferable starting point.
