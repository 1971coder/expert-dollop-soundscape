#!/usr/bin/env bash
# Print an xcodebuild -destination string for the newest installed iPhone simulator.
# Exits non-zero (silently) if no simulator is available, so callers can decide what to do.
#
# Used by check.sh and test.sh. Override behaviour by exporting XCODE_DESTINATION
# in your environment — the caller scripts respect that and skip this helper.
set -euo pipefail

command -v xcrun >/dev/null 2>&1 || exit 1

# `xcrun simctl list devices available --json` lists only runtimes that are actually
# installed. We pick the highest-numbered iOS runtime, then the highest-numbered iPhone
# inside it. Falls back to any available iPhone if version parsing fails.
JSON="$(xcrun simctl list devices available --json 2>/dev/null || true)"
[[ -n "${JSON}" ]] || exit 1

# Extract iOS runtime keys (e.g. "com.apple.CoreSimulator.SimRuntime.iOS-26-4").
# Sort version-aware, take the last (newest).
RUNTIME="$(printf '%s' "${JSON}" \
  | /usr/bin/python3 -c '
import json, sys, re
data = json.load(sys.stdin)
runtimes = [k for k in data.get("devices", {}) if "SimRuntime.iOS-" in k and data["devices"][k]]
if not runtimes:
    sys.exit(1)
def key(r):
    m = re.search(r"iOS-(\d+)-(\d+)", r)
    return tuple(int(x) for x in m.groups()) if m else (0, 0)
print(sorted(runtimes, key=key)[-1])
' 2>/dev/null || true)"
[[ -n "${RUNTIME}" ]] || exit 1

# From that runtime, pick the highest-numbered iPhone device.
DEVICE_NAME="$(printf '%s' "${JSON}" \
  | RUNTIME="${RUNTIME}" /usr/bin/python3 -c '
import json, os, sys, re
data = json.load(sys.stdin)
devices = data["devices"].get(os.environ["RUNTIME"], [])
iphones = [d["name"] for d in devices if d.get("name", "").startswith("iPhone") and d.get("isAvailable")]
if not iphones:
    sys.exit(1)
def key(name):
    m = re.search(r"iPhone (\d+)", name)
    return (int(m.group(1)) if m else 0, "Pro Max" in name, "Pro" in name, name)
print(sorted(iphones, key=key)[-1])
' 2>/dev/null || true)"
[[ -n "${DEVICE_NAME}" ]] || exit 1

# Translate runtime ID back to a human OS version ("26.4") for the destination string.
OS_VERSION="$(printf '%s' "${RUNTIME}" | sed -E 's/.*iOS-([0-9]+)-([0-9]+).*/\1.\2/')"

printf 'platform=iOS Simulator,name=%s,OS=%s' "${DEVICE_NAME}" "${OS_VERSION}"
