# Work Packages

A **work package (WP)** is a bounded unit of work scoped tightly enough that one agent can implement it without colliding with another agent working in parallel.

Each WP lives in this directory as a single markdown file and corresponds to one row in [../docs/delivery-plan.md](../docs/delivery-plan.md).

## Naming

`WPNN-<slug>.md` where `NN` is a zero-padded sequence number and `<slug>` is a short kebab-case identifier.

Examples:
- `WP00-foundation.md` (the foundation WP — see below)
- `WP01-add-health-check.md`
- `WP12-structured-logging.md`

## Lifecycle

```
proposed → ready → in-progress → in-review → merged
```

- **proposed** — drafted but not refined; objective and scope may still be unclear.
- **ready** — sections complete, dependencies identified, no open design questions, safe to start.
- **in-progress** — an agent is implementing it; the corresponding row in `delivery-plan.md` should also reflect this.
- **in-review** — implementation complete, awaiting `/qa-review`, `/architecture-review`, or human review.
- **merged** — landed on the integration branch; row in `delivery-plan.md` updated.

A WP's status lives in two places: the file itself (top of file or in the table row) and the corresponding row in `delivery-plan.md`. Keep them in sync.

## Authoring

Use [TEMPLATE.md](TEMPLATE.md) — copy it to `WPNN-<slug>.md` and fill in every section. The `/create-work-package` slash command automates this and updates `delivery-plan.md`.

## Foundation gate

[WP00-foundation.md](WP00-foundation.md) defines the project's conventions (structure, error handling, testing, naming, etc.).

**No feature WP should start until WP00 is closed.** Conventions agreed in WP00 land in [../docs/coding-standards.md](../docs/coding-standards.md); subsequent WPs reference that doc rather than re-litigating conventions.

## Parallelism

Two WPs **should not** run in parallel if they both modify the same shared file or shared contract surface unless explicitly approved. See the parallelism rule in [../docs/delivery-plan.md](../docs/delivery-plan.md) and the **Shared Files Allowed To Change** section in each WP.
