#!/usr/bin/env bash
# PreToolUse hook for Bash: deny commands that match a small set of obviously dangerous patterns.
#
# Wire up by adding to .claude/settings.json:
#   "hooks": {
#     "PreToolUse": [
#       { "matcher": "Bash", "hooks": [
#         { "type": "command", "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/deny-dangerous-commands.sh" }
#       ]}
#     ]
#   }
#
# Behavior:
#   - Exit 2 -> blocks the tool call and surfaces the stderr message to Claude.
#   - Exit 0 -> allows it through.
#
# This is a coarse safety net, not a security boundary. The user can always edit it.
set -euo pipefail

# Read the tool-call JSON from stdin. Accept either jq-extracted command or the whole payload.
input="$(cat)"

if command -v jq >/dev/null 2>&1; then
  cmd="$(printf '%s' "$input" | jq -r '.tool_input.command // empty')"
else
  # Fallback: just grep over the whole payload. Less precise but jq-free.
  cmd="$input"
fi
cmd_lc="$(printf '%s' "$cmd" | tr '[:upper:]' '[:lower:]')"

deny() {
  echo "Blocked by deny-dangerous-commands.sh: $1" >&2
  exit 2
}

# Plain `git commit ...` is never destructive on its own, regardless of message text.
# Exempt it so the rm/-r/-f scan below doesn't false-positive on commit messages that
# describe destructive patterns. Compound commands (containing ; | & or $()) fall through
# to the normal checks so `git commit && rm -r -f /` is still caught.
if printf '%s' "$cmd_lc" | grep -Eq '^[[:space:]]*git[[:space:]]+commit([[:space:]]|$)' \
  && ! printf '%s' "$cmd" | grep -Eq '[;|&]|\$\('; then
  exit 0
fi

# rm recursive+force in common forms:
# rm -rf, rm -fr, rm -r -f, rm -Rf, rm --recursive --force, etc.
if printf '%s' "$cmd_lc" | grep -Eq '(^|[^a-z0-9_])rm([[:space:]]|$)' \
  && printf '%s' "$cmd_lc" | grep -Eq '(^|[[:space:]])(-[a-z]*r[a-z]*|--recursive)([[:space:]]|$)' \
  && printf '%s' "$cmd_lc" | grep -Eq '(^|[[:space:]])(-[a-z]*f[a-z]*|--force)([[:space:]]|$)'; then
  deny "rm -rf detected"
fi

# git push --force / -f / --force-with-lease still blocked (use a manual override if you need it)
if printf '%s' "$cmd_lc" | grep -Eq 'git[[:space:]]+push.*(--force([[:space:]]|$)|--force-with-lease|[[:space:]]-f([[:space:]]|$))'; then
  deny "force-push detected"
fi

# git reset --hard
if printf '%s' "$cmd_lc" | grep -Eq 'git[[:space:]]+reset[[:space:]]+(--hard|.*[[:space:]]--hard)'; then
  deny "git reset --hard detected"
fi

exit 0
