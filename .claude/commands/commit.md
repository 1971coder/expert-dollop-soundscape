---
description: Stage changes, write a conventional commit message, and commit. Does not push.
---

Create a single commit for the current changes.

Steps:

1. Run `git status` and `git diff` (both staged and unstaged) to see exactly what's changing. Also run `git log -5 --oneline` so the commit message style matches the repo's history.
2. Group the changes mentally: are they one cohesive change, or multiple? If multiple, ask the user whether to split into separate commits before proceeding.
3. Stage the relevant files **by name** — do not use `git add -A` or `git add .` (avoids accidentally including secrets, build artifacts, or scratch files).
4. Write a [Conventional Commits](https://www.conventionalcommits.org/) message:
   - Format: `<type>(<scope>): <subject>` — type ∈ {feat, fix, refactor, docs, test, chore, perf, build, ci, style}.
   - Subject: imperative mood, no trailing period, ≤72 chars.
   - Body (optional): explain the *why*, not the *what*. Wrap at 72 chars.
5. Commit with the message. Pass it via heredoc — it preserves newlines and lets backticks/quotes inside the message survive without escaping:
   ```
   git commit -m "$(cat <<'EOF'
   feat(scope): subject line

   Body explaining the why, wrapped at 72.
   EOF
   )"
   ```
   The quoted `'EOF'` prevents shell expansion inside the message.
6. Run `git status` after to confirm the working tree is clean (or shows only intentionally-unstaged files).

**Do not push.** That's the user's call.

If pre-commit hooks fail, do not use `--no-verify`. Fix the underlying issue and create a new commit. Same rule for signing — never bypass with `--no-gpg-sign` or `-c commit.gpgsign=false`; if signing fails, investigate the cause.
