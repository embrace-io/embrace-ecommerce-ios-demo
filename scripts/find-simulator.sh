#!/usr/bin/env bash
# Resolves a simulator UDID by device name, and optionally boots it.
#
# Replaces the inline `grep -o '[A-F0-9-]\{36\}'` pipelines, which silently
# produced an empty UDID when the device was missing — the workflow then
# carried on and failed later with an unrelated error.
#
# Exact name matches win over substring matches, so "iPhone 16" never
# resolves to "iPhone 16 Pro" or "iPhone 16e". Only stdout carries the UDID;
# all diagnostics go to stderr.
#
# Usage: udid="$(scripts/find-simulator.sh "iPhone 16" --boot)"
set -euo pipefail

DEVICE_NAME="${1:-iPhone 16}"
BOOT_FLAG="${2:-}"

devices_json="$(xcrun simctl list devices available --json)"

udid="$(printf '%s' "$devices_json" | python3 -c '
import json, sys

wanted = sys.argv[1]
runtimes = json.load(sys.stdin).get("devices", {})

exact, partial = [], []
for runtime, devices in runtimes.items():
    for device in devices:
        if not device.get("isAvailable", True):
            continue
        if device.get("name") == wanted:
            exact.append((runtime, device["udid"]))
        elif wanted in device.get("name", ""):
            partial.append((runtime, device["udid"]))

matches = exact or partial
if not matches:
    sys.exit(1)

# Sorting runtime identifiers puts the newest iOS version last.
matches.sort(key=lambda item: item[0])
print(matches[-1][1])
' "$DEVICE_NAME" || true)"

if [[ -z "$udid" ]]; then
    echo "ERROR: no available simulator matching '${DEVICE_NAME}'." >&2
    echo "Available devices:" >&2
    xcrun simctl list devices available >&2
    exit 1
fi

echo "find-simulator: '${DEVICE_NAME}' -> ${udid}" >&2

if [[ "$BOOT_FLAG" == "--boot" ]]; then
    xcrun simctl boot "$udid" >/dev/null 2>&1 || true
    xcrun simctl bootstatus "$udid" -b >&2
    echo "find-simulator: booted ${udid}" >&2
fi

printf '%s\n' "$udid"
