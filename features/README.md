# Features

This directory is intentionally empty in the scaffold.

It exists as a recommended home for **feature-oriented modular code** in projects where that organisation makes sense (web apps, APIs with multiple bounded domains, mid-size full-stack projects). For project types where it doesn't fit (CLI tools, libraries, single-purpose data pipelines), delete this directory and use the layout that suits the project.

## Recommended layout (when used)

```
features/
  <feature-name>/
    components/    # UI components, if applicable
    services/      # business logic and data access
    hooks/         # framework-specific composables (e.g. React hooks)
    types/         # types/interfaces local to this feature
    tests/         # tests for this feature only
```

A feature directory should be **owned end-to-end by one work package at a time**. Cross-feature shared code lives elsewhere (e.g. a top-level `shared/` directory) — see [../docs/project-structure.md](../docs/project-structure.md) for full guidance and per-project-type recipes.

## Why this exists as a stub

Shipping a populated `features/example-feature/` would force every cloned project (including ones that have no concept of "features") to delete it. Instead the scaffold ships only this README, and [../docs/project-structure.md](../docs/project-structure.md) documents the recommended layouts as optional recipes.

## When to remove this directory

- The project is a CLI tool or library with no "feature" boundary.
- The project organises by layer (`models/`, `views/`, `controllers/`) rather than by feature.
- The project is a data pipeline or batch job with a single domain.

In all those cases, delete `features/` and adopt the layout that fits.
