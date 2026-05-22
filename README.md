# claude-code-template

A reusable, project-agnostic scaffold for [Claude Code](https://claude.com/claude-code) — designed to operate as a thin **multi-agent engineering operating system** on top of any codebase: web apps, APIs, CLIs, libraries, data pipelines, internal tools.

The scaffold is deliberately lightweight: a tight entry point, polyglot wrapper scripts, a small set of slash commands, and a structured way for multiple AI agents to work in parallel without colliding.

This is a **work in progress** — patterns that prove useful stay, patterns that get in the way get removed.

## What's in here

- `CLAUDE.md` — the entry point Claude reads first. Project overview, conventions, and pointers to deeper docs.
- `docs/` — longer-form context: architecture, decisions, requirements, plus the multi-agent layer (`delivery-plan.md`, `handoff.md`, `project-structure.md`, `coding-standards.md`, etc.).
- `work-packages/` — bounded units of work, one markdown file per WP. `TEMPLATE.md` is the schema; `WP00-foundation.md` is the gating WP for any new project.
- `agent-runs/` — per-run scratch space for AI agents (gitignored by default).
- `features/` — optional feature-oriented modular code (recipe lives in `docs/project-structure.md`; delete the dir if it doesn't fit your project).
- `.claude/` — Claude Code configuration: permissions, slash commands, sub-agents, hooks.
- `scripts/` — ecosystem-agnostic check/test/format scripts, plus a template audit with sentinel-aware emptiness handling.

## Multi-agent workflow

The scaffold is built around three coordination primitives:

1. **Work packages** ([`work-packages/`](work-packages/)) — one file per bounded unit of work. Each WP enumerates `Files likely touched`, `Files explicitly excluded`, and **`Shared Files Allowed To Change`**. The third list is the load-bearing primitive for parallel-agent merge safety.
2. **Delivery plan** ([`docs/delivery-plan.md`](docs/delivery-plan.md)) — single markdown table with one row per WP. Pinned at the top: *two WPs SHOULD NOT run in parallel if they both modify the same shared file or shared contract surface unless explicitly approved*.
3. **Handoff** ([`docs/handoff.md`](docs/handoff.md)) — rolling snapshot (not append-only) of current state, open issues, assumptions, blockers, and next recommended steps. Maintained by [`/update-handoff`](.claude/commands/update-handoff.md) so the next session can pick up cold.

### Recommended agent workflow

1. **Foundation first.** Run [WP00 — Foundation](work-packages/WP00-foundation.md) before any feature WP. It produces the project's twelve convention categories (project structure, error handling, testing, naming, etc.). No feature work begins until WP00 is closed.
2. **Author a WP** with [`/create-work-package`](.claude/commands/create-work-package.md). Fill in every section, especially `Shared Files Allowed To Change`. Cross-check overlap against active rows in `delivery-plan.md`.
3. **Implement** with [`/start-agent <WPNN>`](.claude/commands/start-agent.md). The agent stays inside the WP's allow-list, adds tests, documents assumptions, and updates `handoff.md` at the end.
4. **Integration review** with [`/integrate-feature`](.claude/commands/integrate-feature.md) — merge readiness, duplicated logic, shared-type consistency, integration drift. Read-only output; the implementing agent (or a follow-up WP) addresses findings.
5. **QA review** with [`/qa-review`](.claude/commands/qa-review.md) — broken flows, edge cases, validation gaps, missing tests. Read-only output.
6. **Architecture review** (occasional, not per-WP) with [`/architecture-review`](.claude/commands/architecture-review.md) — feature-boundary violations, tight coupling, abstraction quality, scalability risks.
7. **Update handoff** with [`/update-handoff`](.claude/commands/update-handoff.md) at the end of every session. The command maintains the rolling-snapshot structure rather than appending.

The existing single-agent commands ([`/plan`](.claude/commands/plan.md), [`/implement`](.claude/commands/implement.md), [`/test`](.claude/commands/test.md), [`/review`](.claude/commands/review.md), [`/research`](.claude/commands/research.md), [`/commit`](.claude/commands/commit.md)) sit alongside the multi-agent layer — use them when a single bounded task doesn't justify a full WP.

### Parallel development, safely

Two WPs can run in parallel if and only if their `Shared Files Allowed To Change` sets do not overlap. Compare the two WPs' allow-lists before dispatching them; if they overlap, sequence them or split one. This is the entire mechanism — no central orchestrator, no lock service, just a schema-enforced rule.

### Context preservation

Three documents are the project's durable memory:

- [`docs/decisions.md`](docs/decisions.md) — append-only log of architectural decisions and rationale.
- [`docs/handoff.md`](docs/handoff.md) — rolling snapshot of current state.
- [`docs/architecture.md`](docs/architecture.md) — long-form structural context.

WP files capture per-WP decisions; `agent-runs/` holds per-session scratch (not durable). Anything that should survive past the next session belongs in one of the three docs above.

## How to use

Copy the template contents into a new project directory:

```bash
mkdir -p ~/Dev/my-new-project
cp -r ~/Dev/claude-code-template/. ~/Dev/my-new-project/
cd ~/Dev/my-new-project
rm -rf .git && git init
```

Then:

1. Work through [docs/adoption-checklist.md](docs/adoption-checklist.md).
2. Open `CLAUDE.md` and fill in the `TODO` sections (project overview, tech stack, commands).
3. Stub out the relevant files in `docs/` as the project takes shape.
4. Adjust `.claude/settings.json` permissions to match the project's ecosystem.
5. Open [WP00 — Foundation](work-packages/WP00-foundation.md) and close it before any feature work — it produces the project's coding conventions.
6. Run `./scripts/template-audit.sh --strict` and fix anything it reports (including any leftover `<!-- scaffold-allow-empty -->` sentinels in docs you've started filling in).
7. Start coding. Use the multi-agent commands ([`/create-work-package`](.claude/commands/create-work-package.md), [`/start-agent`](.claude/commands/start-agent.md), [`/integrate-feature`](.claude/commands/integrate-feature.md), [`/qa-review`](.claude/commands/qa-review.md), [`/architecture-review`](.claude/commands/architecture-review.md), [`/update-handoff`](.claude/commands/update-handoff.md)) for parallel work; use the single-agent commands ([`/plan`](.claude/commands/plan.md), [`/implement`](.claude/commands/implement.md), [`/test`](.claude/commands/test.md), [`/review`](.claude/commands/review.md), [`/research`](.claude/commands/research.md), [`/commit`](.claude/commands/commit.md)) for focused single-session tasks.

## Notes

- Slash commands and agents are starting points — edit them per project rather than treating them as fixed.
- The `scripts/*.sh` files are intentionally polyglot: they detect `package.json`, `Cargo.toml`, etc. and run the right tool. They exit 0 cleanly when there's no project, so the template itself doesn't fail CI. Once a project type or Make target is detected, command failures are real failures. See [scripts/README.md](scripts/README.md) for the contract.
- `./scripts/template-audit.sh --template` validates the reusable scaffold. `./scripts/template-audit.sh --strict` is for copied projects and fails on leftover TODOs, empty core docs, machine-specific shared settings, and missing Node test/check scripts.
- The audit honours an inline `<!-- scaffold-allow-empty -->` sentinel: a doc with the sentinel and no content beyond it passes `--strict` (deliberately stubbed). A doc with the sentinel **and** content after it fails `--strict` (cleanup signal — remove the sentinel once you've started filling the doc in). This keeps stubs honest as the project matures.
- The dangerous-commands hook ships **wired** as a `PreToolUse` matcher on `Bash` — it blocks `rm -rf`, force-push, and `git reset --hard`. Coarse safety net, not a security boundary; loosen or disable per project if it gets in the way.
- The hook has a tiny regression test at `.claude/hooks/deny-dangerous-commands.test.sh`. In the bare template, `./scripts/test.sh` runs it.
- `.claude/rules/*.md` with `paths:` frontmatter is an opt-in for area-specific style rules — loaded only when Claude touches matching files. Not shipped; add a `rules/` dir if a project needs it.
- `.claude/skills/<name>/SKILL.md` is where project-specific Skills live. Not shipped; add one when a workflow is repeated enough to be worth packaging.

## Adjusting `permissions.allow` per ecosystem

The shipped allow-list is intentionally minimal (read-only git, basic shell, the three project scripts). Each project will want to add a small ecosystem-specific block. Examples — append to `permissions.allow` in `.claude/settings.json`:

**Node / pnpm**
```json
"Bash(pnpm install:*)",
"Bash(pnpm typecheck:*)",
"Bash(pnpm test:*)",
"Bash(pnpm lint:*)",
"Bash(pnpm dev:*)",
"Bash(pnpm build:*)"
```

**Node / npm or yarn** — replace `pnpm` above with `npm run` / `yarn`.

**Python / uv or pip**
```json
"Bash(uv run:*)",
"Bash(pytest:*)",
"Bash(ruff:*)",
"Bash(mypy:*)"
```

**Rust**
```json
"Bash(cargo build:*)",
"Bash(cargo test:*)",
"Bash(cargo check:*)",
"Bash(cargo clippy:*)",
"Bash(cargo fmt:*)"
```

**Swift**
```json
"Bash(swift build:*)",
"Bash(swift test:*)"
```

**GitHub CLI** (any project that uses PRs/Issues from the terminal)
```json
"Bash(gh pr:*)",
"Bash(gh issue:*)",
"Bash(gh repo view:*)"
```

**Playwright MCP** (for projects that browse-test via the Playwright MCP server)
```json
"mcp__plugin_playwright_playwright__browser_navigate",
"mcp__plugin_playwright_playwright__browser_snapshot",
"mcp__plugin_playwright_playwright__browser_click",
"mcp__plugin_playwright_playwright__browser_evaluate",
"mcp__plugin_playwright_playwright__browser_take_screenshot",
"mcp__plugin_playwright_playwright__browser_console_messages"
```

**Web fetch / search** (opt-in — fetched content can carry prompt injection)
```json
"WebFetch(domain:docs.anthropic.com)",
"WebFetch(domain:github.com)",
"WebSearch"
```

Prefer narrowing `WebFetch` to specific domains over the `WebFetch(domain:*)` wildcard.

Rule of thumb: if Claude needs to ask permission for the same command three times in a session, that command belongs in `allow`. If Claude needs the command for a *one-time* setup step (`git init`, `chmod +x`), don't add it — approve it once and let it be.
