#!/usr/bin/env bash
# Format the project's source, dispatching by detected project type.
# Exits 0 cleanly if no project type is detected.
set -euo pipefail

cd "$(dirname "$0")/.."

if [[ -f package.json ]]; then
  echo "[format] node project detected"
  if   command -v pnpm  >/dev/null 2>&1 && [[ -f pnpm-lock.yaml ]]; then RUNNER="pnpm"
  elif command -v yarn  >/dev/null 2>&1 && [[ -f yarn.lock ]];      then RUNNER="yarn"
  else                                                                   RUNNER="npm"
  fi
  if grep -q "\"format\"" package.json; then
    "$RUNNER" run format
  elif command -v prettier >/dev/null 2>&1; then
    prettier --write .
  fi
  exit 0
fi

if [[ -f Package.swift ]]; then
  echo "[format] swift package detected"
  if command -v swift-format >/dev/null 2>&1; then
    paths=()
    [[ -d Sources ]] && paths+=(Sources)
    [[ -d Tests ]] && paths+=(Tests)

    if ((${#paths[@]})); then
      swift-format --in-place --recursive "${paths[@]}"
    else
      echo "[format] no Sources/Tests directories for swift-format"
    fi
  fi
  exit 0
fi

# Xcode project detection (AuralFlow / iOS app).
XCODE_PROJECT="${XCODE_PROJECT:-$(ls -d *.xcodeproj 2>/dev/null | head -n1 || true)}"
if [[ -n "${XCODE_PROJECT}" && -d "${XCODE_PROJECT}" ]]; then
  echo "[format] xcode project detected: ${XCODE_PROJECT}"
  if command -v swift-format >/dev/null 2>&1; then
    paths=()
    # Conventional app-target dirs sit at repo root.
    for d in Soundscape SoundscapeTests SoundscapeUITests; do
      [[ -d "$d" ]] && paths+=("$d")
    done
    if ((${#paths[@]})); then
      echo "[format] swift-format ${paths[*]}"
      swift-format --in-place --recursive "${paths[@]}"
    else
      echo "[format] no recognisable source dirs (Soundscape/, SoundscapeTests/, SoundscapeUITests/) — skipping"
    fi
  else
    echo "[format] swift-format not installed; skipping"
  fi
  exit 0
fi

if [[ -f pyproject.toml ]]; then
  echo "[format] python project detected"
  if   command -v ruff  >/dev/null 2>&1; then ruff format .
  elif command -v black >/dev/null 2>&1; then black .
  fi
  exit 0
fi

if [[ -f Cargo.toml ]]; then
  echo "[format] rust project detected"
  cargo fmt
  exit 0
fi

if [[ -f Makefile ]]; then
  echo "[format] Makefile detected"
  if make -n format >/dev/null 2>&1; then
    make format
  elif make -n fmt >/dev/null 2>&1; then
    make fmt
  else
    echo "[format] no format/fmt target in Makefile"
  fi
  exit 0
fi

echo "[format] no project type detected — nothing to do"
exit 0
