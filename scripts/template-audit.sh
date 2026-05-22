#!/usr/bin/env bash
# Audit this Claude Code template, or a project copied from it.
set -euo pipefail

cd "$(dirname "$0")/.."

mode="template"

usage() {
  cat <<'USAGE'
Usage: ./scripts/template-audit.sh [--template|--strict]

Modes:
  --template  Validate the reusable scaffold. TODO placeholders are allowed.
  --strict    Validate an adopted project. TODO placeholders and empty docs fail.
USAGE
}

while (($#)); do
  case "$1" in
    --template)
      mode="template"
      ;;
    --strict)
      mode="strict"
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "[audit] unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
  shift
done

failures=0
warnings=0

pass() {
  echo "[audit] ok: $1"
}

warn() {
  echo "[audit] warn: $1"
  warnings=$((warnings + 1))
}

fail() {
  echo "[audit] fail: $1" >&2
  failures=$((failures + 1))
}

require_file() {
  local path="$1"

  if [[ -f "$path" ]]; then
    pass "$path exists"
  else
    fail "$path is missing"
  fi
}

require_executable() {
  local path="$1"

  if [[ -x "$path" ]]; then
    pass "$path is executable"
  else
    fail "$path is missing or not executable"
  fi
}

has_meaningful_content() {
  local path="$1"

  awk '
    {
      line = $0
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
      if (line == "") next
      if (line ~ /^#/) next
      if (line ~ /^<!--/) next
      if (line ~ /^-->/) next
      if (line ~ /TODO/) next
      found = 1
    }
    END { exit found ? 0 : 1 }
  ' "$path"
}

has_scaffold_sentinel() {
  local path="$1"
  grep -Fq '<!-- scaffold-allow-empty -->' "$path"
}

# Detect substantive content AFTER the last scaffold-allow-empty sentinel.
# Rationale: the sentinel acts as a fence. Content above it is scaffold
# guidance ("what belongs in this doc") and is fine. Content below it is
# project-specific filling-in, which means the sentinel should be removed.
has_content_after_sentinel() {
  local path="$1"

  awk '
    BEGIN { passed_sentinel = 0; found = 0 }
    # Reset the post-sentinel buffer at every sentinel occurrence so only
    # content after the LAST sentinel counts. Lets a doc legitimately
    # mention the sentinel string in its body (e.g. glossary.md).
    /<!-- scaffold-allow-empty -->/ { passed_sentinel = 1; found = 0; next }
    {
      if (!passed_sentinel) next
      line = $0
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
      if (line == "") next
      if (line ~ /^#/) next
      if (line ~ /^<!--/) next
      if (line ~ /^-->/) next
      if (line ~ /TODO/) next
      found = 1
    }
    END { exit found ? 0 : 1 }
  ' "$path"
}

# Check a doc that may legitimately be a stub in a fresh scaffold.
# Resolution rules (sentinel acts as a fence):
#   - No sentinel:
#       has substantive content -> pass.
#       empty                   -> --strict fail, --template warn.
#   - Sentinel present:
#       no content after sentinel -> pass (deliberately stubbed).
#       content after sentinel    -> --strict fail (cleanup signal), --template warn.
check_stub_doc() {
  local path="$1"

  if [[ ! -f "$path" ]]; then
    fail "$path is missing"
    return
  fi

  if has_scaffold_sentinel "$path"; then
    if has_content_after_sentinel "$path"; then
      if [[ "$mode" == "strict" ]]; then
        fail "$path has content after the scaffold-allow-empty sentinel; remove the sentinel"
      else
        warn "$path has content after the scaffold-allow-empty sentinel; remove the sentinel before adoption"
      fi
    else
      pass "$path is intentionally a stub (scaffold-allow-empty sentinel present)"
    fi
    return
  fi

  if has_meaningful_content "$path"; then
    pass "$path has project-specific content"
  elif [[ "$mode" == "strict" ]]; then
    fail "$path is empty and not marked with a scaffold-allow-empty sentinel"
  else
    warn "$path is scaffold-only; fill it after copying the template"
  fi
}

has_package_script() {
  local script="$1"

  if command -v jq >/dev/null 2>&1; then
    jq -e --arg script "$script" '.scripts[$script] // empty' package.json >/dev/null
  else
    grep -Eq "\"$script\"[[:space:]]*:" package.json
  fi
}

require_file "CLAUDE.md"
require_file "README.md"
require_file ".claude/settings.json"
require_file ".claude/hooks/deny-dangerous-commands.sh"
require_file ".claude/hooks/deny-dangerous-commands.test.sh"
require_file ".claude/commands/test.md"
require_file "docs/adoption-checklist.md"

# Multi-agent scaffold: required structural files.
require_file "work-packages/README.md"
require_file "work-packages/TEMPLATE.md"
require_file "work-packages/WP00-foundation.md"
require_file "agent-runs/README.md"
require_file "features/README.md"
require_file "scripts/README.md"
require_file ".claude/commands/start-agent.md"
require_file ".claude/commands/create-work-package.md"
require_file ".claude/commands/integrate-feature.md"
require_file ".claude/commands/qa-review.md"
require_file ".claude/commands/architecture-review.md"
require_file ".claude/commands/update-handoff.md"
require_file "docs/project-structure.md"
require_file "docs/glossary.md"

for path in scripts/check.sh scripts/test.sh scripts/format.sh scripts/template-audit.sh .claude/hooks/deny-dangerous-commands.sh .claude/hooks/deny-dangerous-commands.test.sh; do
  require_executable "$path"
done

if command -v jq >/dev/null 2>&1; then
  if jq empty .claude/settings.json; then
    pass ".claude/settings.json is valid JSON"
  else
    fail ".claude/settings.json is invalid JSON"
  fi
else
  warn "jq not installed; skipped JSON validation"
fi

if grep -En '"/(Users|home|private|tmp|var|opt|Applications)/|[A-Za-z]:\\' .claude/settings.json >/dev/null; then
  fail ".claude/settings.json contains machine-specific absolute paths"
else
  pass ".claude/settings.json has no obvious machine-specific absolute paths"
fi

if [[ -f .claude/settings.local.json ]]; then
  if git check-ignore -q .claude/settings.local.json; then
    pass ".claude/settings.local.json is ignored"
  else
    fail ".claude/settings.local.json exists but is not ignored"
  fi
fi

for path in docs/architecture.md docs/requirements.md; do
  require_file "$path"
  if has_meaningful_content "$path"; then
    pass "$path has project-specific content"
  elif [[ "$mode" == "strict" ]]; then
    fail "$path still looks empty"
  else
    warn "$path is scaffold-only; fill it after copying the template"
  fi
done

# Sentinel-eligible scaffold docs: empty-with-sentinel (or worked example
# above the sentinel) passes --strict; substantive content AFTER the
# sentinel fails (cleanup signal).
for path in \
  docs/handoff.md \
  docs/delivery-plan.md \
  docs/decisions.md \
  docs/glossary.md \
  docs/api-contract.md \
  docs/data-model.md \
  docs/testing-strategy.md \
  docs/coding-standards.md; do
  check_stub_doc "$path"
done

if grep -R "TODO" CLAUDE.md docs/architecture.md docs/requirements.md >/dev/null 2>&1; then
  if [[ "$mode" == "strict" ]]; then
    fail "CLAUDE.md or required docs still contain TODO markers"
  else
    warn "TODO markers are present; expected in the reusable template"
  fi
else
  pass "no TODO markers in CLAUDE.md or required docs"
fi

for needle in "./scripts/check.sh" "./scripts/test.sh" "./scripts/format.sh"; do
  if grep -Fq "$needle" CLAUDE.md; then
    pass "CLAUDE.md references $needle"
  else
    fail "CLAUDE.md does not reference $needle"
  fi
done

if grep -Fq "docs/adoption-checklist.md" README.md && grep -Fq "docs/adoption-checklist.md" CLAUDE.md; then
  pass "adoption checklist is linked from README.md and CLAUDE.md"
else
  fail "adoption checklist is not linked from both README.md and CLAUDE.md"
fi

if [[ -f package.json ]]; then
  check_scripts=0
  for script in lint typecheck build; do
    if has_package_script "$script"; then
      check_scripts=$((check_scripts + 1))
    fi
  done

  if ((check_scripts > 0)); then
    pass "package.json has at least one check script"
  elif [[ "$mode" == "strict" ]]; then
    fail "package.json has no lint/typecheck/build script for ./scripts/check.sh"
  else
    warn "package.json has no lint/typecheck/build script"
  fi

  if has_package_script test; then
    pass "package.json has a test script"
  elif [[ "$mode" == "strict" ]]; then
    fail "package.json has no test script for ./scripts/test.sh"
  else
    warn "package.json has no test script"
  fi
fi

if ((failures > 0)); then
  echo "[audit] failed with $failures failure(s) and $warnings warning(s)" >&2
  exit 1
fi

echo "[audit] passed with $warnings warning(s)"
