# Adoption Checklist

Use this after copying the template into a real project. The goal is to turn a generic Claude Code scaffold into project-specific working context.

## Required

- Replace every TODO in [CLAUDE.md](../CLAUDE.md): project overview, tech stack, commands, directory structure, conventions, scope, and gotchas.
- Fill in [requirements.md](requirements.md) with the user-visible behaviors and hard constraints that should shape implementation decisions.
- Fill in [architecture.md](architecture.md) with the major modules, data flow, boundaries, and external systems.
- Start [decisions.md](decisions.md) with the first meaningful decision once the project has one. Keep it append-only.
- Remove project-specific local paths from `.claude/settings.json`. Put machine-local permissions, extra directories, and experiments in `.claude/settings.local.json`.
- Tune `.claude/settings.json` permissions for the ecosystem. Prefer narrow entries for package managers, test runners, browser tools, GitHub CLI, and web fetch domains.
- Replace the wrapper scripts' detected commands if the project has a more specific check/test/format workflow than the default.
- Run `./scripts/template-audit.sh --strict` and fix every failure before relying on Claude Code for implementation work.
- Run `./scripts/check.sh`, `./scripts/test.sh`, and `./scripts/format.sh` before the first real Claude Code implementation session.
- Review the **Multi-agent operating model** section in [CLAUDE.md](../CLAUDE.md). Tune the four rules (foundation gate, WP discipline, shared-file rule, handoff rule) to project specifics; in particular, tighten the parallelism rule's exception clause if the project has stronger discipline.

## Recommended

- Add `.claude/rules/*.md` files with `paths:` frontmatter for area-specific conventions that should not live in global context.
- Add a project-specific Skill under `.claude/skills/<name>/SKILL.md` once a workflow repeats often enough to package.
- Run `/plan` on a small feature and adjust the command prompts if the plan misses recurring project constraints.
- Run `/review` on the first non-trivial diff and tune `.claude/agents/code-reviewer.md` for repo-specific failure modes.
- Skim [glossary.md](glossary.md) once before the first session. The multi-agent vocabulary (parallelism rule, sentinel fence, etc.) is small but learning it cold-saves debugging time later.

## Multi-agent workflow setup

The scaffold ships with a multi-agent layer (work packages, delivery plan, rolling handoff, six new slash commands). To bring it online for a new project:

- **Close [WP00 — Foundation](../work-packages/WP00-foundation.md) before any feature work.** It produces the project's twelve convention categories. As you fill in [coding-standards.md](coding-standards.md), [project-structure.md](project-structure.md), and [testing-strategy.md](testing-strategy.md), **remove the `<!-- scaffold-allow-empty -->` sentinels** from each — `--strict` audit fails if both real content and the sentinel are present.
- **Author the first real WP** with `/create-work-package`. The command will copy `work-packages/TEMPLATE.md` and add a row to [delivery-plan.md](delivery-plan.md). Pay attention to the *Shared Files Allowed To Change* section — that's the parallel-WP merge-safety primitive.
- **Draft initial entries in [delivery-plan.md](delivery-plan.md)**: at least WP00 and the first one or two feature WPs. Remove the file-end `<!-- scaffold-allow-empty -->` sentinel once the Active table has real rows.
- **Run `/update-handoff` at the end of every session.** This keeps [handoff.md](handoff.md) usable as a cold-start hint. Remove the section sentinels as you populate them.
- **Tune the new slash commands** ([start-agent](../.claude/commands/start-agent.md), [create-work-package](../.claude/commands/create-work-package.md), [integrate-feature](../.claude/commands/integrate-feature.md), [qa-review](../.claude/commands/qa-review.md), [architecture-review](../.claude/commands/architecture-review.md), [update-handoff](../.claude/commands/update-handoff.md)) to fit project-specific failure modes — especially the **Do NOT** clauses, which encode the project's scope-discipline rules.
- **Keep [CLAUDE.md](../CLAUDE.md) and [coding-standards.md](coding-standards.md) in sync.** Conventions agreed in WP00 land in `coding-standards.md`. Their *summary* (high-level rules) lands in CLAUDE.md's `## Conventions` section. Don't duplicate the full text in both places — link from CLAUDE.md to coding-standards.md and keep CLAUDE.md scannable.
