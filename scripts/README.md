# Scripts

Polyglot wrapper scripts that paper over per-language tooling differences. Each script detects the project's ecosystem (`package.json`, `Cargo.toml`, `pyproject.toml`, `Makefile`, etc.) and runs the right tool for it.

## Contract

All scripts follow the same contract:

- **Exit 0 with no output** when there is nothing to do (e.g. a bare scaffold with no detected project type). This is what lets the template itself pass CI.
- **Exit non-zero** when a project type *is* detected and its tool fails. Detected failures are real failures; no silent passes.
- **Run from the repo root.** Each script `cd`s to its own parent's parent before doing anything.

## The four scripts

### `check.sh`
Lints, typechecks, and (where applicable) builds. Run after every meaningful chunk of code changes — `/implement` does this automatically.

### `test.sh`
Runs the project's test suite. In a bare template this also runs the deny-dangerous-commands hook regression test ([`.claude/hooks/deny-dangerous-commands.test.sh`](../.claude/hooks/deny-dangerous-commands.test.sh)).

### `format.sh`
Auto-formats source files. Safe to run any time; produces no diff if everything is already formatted.

### `template-audit.sh`
Validates the scaffold's structural integrity.

- `./scripts/template-audit.sh --template` — for **this scaffold**. Allows TODO placeholders and empty docs marked with the `<!-- scaffold-allow-empty -->` sentinel.
- `./scripts/template-audit.sh --strict` — for **a copied project**. Fails on leftover TODOs in core docs, files that are empty without the sentinel, machine-specific paths in shared settings, and a few other adoption signals.

The `<!-- scaffold-allow-empty -->` sentinel is the documented way to mark a doc that is intentionally a stub in a fresh scaffold (e.g. `docs/handoff.md`, `docs/delivery-plan.md`, the four short stubs). Once the doc gains substantive content, **remove the sentinel** — `--strict` will fail if a file contains both the sentinel and real content (cleanup signal).

## Adding new scripts

Keep them polyglot and idempotent. If a script can't decide what to do, it should exit 0 with a one-line note rather than guess.
