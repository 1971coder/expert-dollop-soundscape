#!/usr/bin/env bash
# Tiny regression tests for deny-dangerous-commands.sh.
set -euo pipefail

cd "$(dirname "$0")"

hook="./deny-dangerous-commands.sh"

payload() {
  printf '{"tool_input":{"command":"%s"}}\n' "$1"
}

expect_blocked() {
  local command="$1"
  local status

  set +e
  payload "$command" | "$hook" >/dev/null 2>&1
  status=$?
  set -e

  if [[ "$status" -ne 2 ]]; then
    echo "[hooks] expected block for: $command" >&2
    exit 1
  fi
}

expect_allowed() {
  local command="$1"

  if ! payload "$command" | "$hook" >/dev/null 2>&1; then
    echo "[hooks] expected allow for: $command" >&2
    exit 1
  fi
}

expect_blocked "rm -rf /tmp/example"
expect_blocked "rm -r -f /tmp/example"
expect_blocked "rm -Rf /tmp/example"
expect_blocked "rm --recursive --force /tmp/example"
expect_blocked "git push -f origin main"
expect_blocked "git push --force-with-lease origin main"
expect_blocked "git reset --hard HEAD"

expect_allowed "git status --short"
expect_allowed "rm -r /tmp/example"
expect_allowed "rm -f /tmp/example"

# git commit is never destructive on its own — message text that describes
# destructive patterns must not false-positive.
expect_allowed "git commit -m 'fix recursive-force detector for rm -r -f'"
expect_allowed "git commit -F /tmp/commit-msg.txt"
expect_allowed "git commit --amend -m 'note about rm --recursive --force'"

# Compound commands tagged onto a git commit must still get scanned.
expect_blocked "git commit -m 'cleanup' && rm -r -f /tmp/junk"
expect_blocked "git commit -m 'oops'; rm -rf /tmp/junk"

echo "[hooks] deny-dangerous-commands passed"
