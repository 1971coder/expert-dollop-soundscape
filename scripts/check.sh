#!/usr/bin/env bash
# Build / typecheck / lint, dispatching by detected project type.
# Exits 0 cleanly if no project type is detected (so the bare template doesn't fail).
set -euo pipefail

cd "$(dirname "$0")/.."

if [[ -f package.json ]]; then
  echo "[check] node project detected"
  if   command -v pnpm  >/dev/null 2>&1 && [[ -f pnpm-lock.yaml ]]; then RUNNER="pnpm"
  elif command -v yarn  >/dev/null 2>&1 && [[ -f yarn.lock ]];      then RUNNER="yarn"
  else                                                                   RUNNER="npm"
  fi
  # Run whichever scripts exist; don't fail because one is missing.
  for script in lint typecheck build; do
    if grep -q "\"$script\"" package.json; then
      echo "[check] $RUNNER run $script"
      "$RUNNER" run "$script"
    fi
  done
  exit 0
fi

if [[ -f Package.swift ]]; then
  echo "[check] swift package detected"
  swift build
  exit 0
fi

# Xcode project detection (AuralFlow / iOS app).
# Picks the first .xcodeproj it finds; assumes scheme matches the project name.
# Override by exporting XCODE_PROJECT, XCODE_SCHEME, XCODE_DESTINATION.
XCODE_PROJECT="${XCODE_PROJECT:-$(ls -d *.xcodeproj 2>/dev/null | head -n1 || true)}"
if [[ -n "${XCODE_PROJECT}" && -d "${XCODE_PROJECT}" ]]; then
  echo "[check] xcode project detected: ${XCODE_PROJECT}"
  XCODE_SCHEME="${XCODE_SCHEME:-$(basename "${XCODE_PROJECT}" .xcodeproj)}"
  XCODE_DESTINATION="${XCODE_DESTINATION:-platform=iOS Simulator,name=iPhone 15,OS=latest}"
  if command -v xcodebuild >/dev/null 2>&1; then
    echo "[check] xcodebuild build -project ${XCODE_PROJECT} -scheme ${XCODE_SCHEME}"
    xcodebuild build \
      -project "${XCODE_PROJECT}" \
      -scheme "${XCODE_SCHEME}" \
      -destination "${XCODE_DESTINATION}" \
      -quiet
  else
    echo "[check] xcodebuild not available; skipping build"
  fi
  if command -v swiftlint >/dev/null 2>&1 && [[ -f .swiftlint.yml ]]; then
    echo "[check] swiftlint"
    swiftlint --strict
  fi
  exit 0
fi

if [[ -f pyproject.toml ]]; then
  echo "[check] python project detected"
  if   command -v ruff  >/dev/null 2>&1; then ruff check .
  elif command -v flake8 >/dev/null 2>&1; then flake8 .
  fi
  if command -v mypy >/dev/null 2>&1 && grep -q "\[tool.mypy\]" pyproject.toml; then
    mypy .
  fi
  exit 0
fi

if [[ -f Cargo.toml ]]; then
  echo "[check] rust project detected"
  cargo check --all-targets
  cargo clippy --all-targets -- -D warnings
  exit 0
fi

if [[ -f Makefile ]]; then
  echo "[check] Makefile detected"
  if make -n check >/dev/null 2>&1; then
    make check
  elif make -n build >/dev/null 2>&1; then
    make build
  else
    echo "[check] no check/build target in Makefile"
  fi
  exit 0
fi

echo "[check] no project type detected — nothing to do"
exit 0
