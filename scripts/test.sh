#!/usr/bin/env bash
# Run the project's test suite, dispatching by detected project type.
# Exits 0 cleanly if no project type is detected.
set -euo pipefail

cd "$(dirname "$0")/.."

if [[ -f package.json ]]; then
  echo "[test] node project detected"
  if   command -v pnpm  >/dev/null 2>&1 && [[ -f pnpm-lock.yaml ]]; then RUNNER="pnpm"
  elif command -v yarn  >/dev/null 2>&1 && [[ -f yarn.lock ]];      then RUNNER="yarn"
  else                                                                   RUNNER="npm"
  fi
  if grep -q "\"test\"" package.json; then
    "$RUNNER" test
  else
    echo "[test] no \"test\" script in package.json"
  fi
  exit 0
fi

if [[ -f Package.swift ]]; then
  echo "[test] swift package detected"
  swift test
  exit 0
fi

# Xcode project detection (AuralFlow / iOS app).
XCODE_PROJECT="${XCODE_PROJECT:-$(ls -d *.xcodeproj 2>/dev/null | head -n1 || true)}"
if [[ -n "${XCODE_PROJECT}" && -d "${XCODE_PROJECT}" ]]; then
  echo "[test] xcode project detected: ${XCODE_PROJECT}"
  XCODE_SCHEME="${XCODE_SCHEME:-$(basename "${XCODE_PROJECT}" .xcodeproj)}"
  XCODE_DESTINATION="${XCODE_DESTINATION:-platform=iOS Simulator,name=iPhone 15,OS=latest}"
  if command -v xcodebuild >/dev/null 2>&1; then
    echo "[test] xcodebuild test -project ${XCODE_PROJECT} -scheme ${XCODE_SCHEME}"
    xcodebuild test \
      -project "${XCODE_PROJECT}" \
      -scheme "${XCODE_SCHEME}" \
      -destination "${XCODE_DESTINATION}" \
      -quiet
  else
    echo "[test] xcodebuild not available; skipping tests"
  fi
  exit 0
fi

if [[ -f pyproject.toml ]]; then
  echo "[test] python project detected"
  if   command -v pytest >/dev/null 2>&1; then pytest
  elif command -v python >/dev/null 2>&1; then python -m unittest discover -v
  fi
  exit 0
fi

if [[ -f Cargo.toml ]]; then
  echo "[test] rust project detected"
  cargo test
  exit 0
fi

if [[ -f Makefile ]]; then
  echo "[test] Makefile detected"
  if make -n test >/dev/null 2>&1; then
    make test
  else
    echo "[test] no test target in Makefile"
  fi
  exit 0
fi

if [[ -x .claude/hooks/deny-dangerous-commands.test.sh ]]; then
  .claude/hooks/deny-dangerous-commands.test.sh
  exit 0
fi

echo "[test] no project type detected — nothing to do"
exit 0
