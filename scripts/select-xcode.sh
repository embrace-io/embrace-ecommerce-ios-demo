#!/usr/bin/env bash
# Selects an Xcode toolchain, tolerating GitHub runner image changes.
#
# The previous inline `sudo xcode-select -s /Applications/Xcode_16.4.app` broke
# every workflow the moment `macos-latest` moved to macOS 26 (which ships only
# Xcode 26.x). This falls back to the newest Xcode of the same major version,
# then to the newest Xcode installed, so an image refresh degrades instead of
# hard-failing.
#
# Usage: XCODE_VERSION=16.4 scripts/select-xcode.sh
set -euo pipefail

REQUESTED="${XCODE_VERSION:-}"
selected=""

if [[ -n "$REQUESTED" && -d "/Applications/Xcode_${REQUESTED}.app" ]]; then
    selected="/Applications/Xcode_${REQUESTED}.app"
else
    if [[ -n "$REQUESTED" ]]; then
        echo "WARNING: Xcode ${REQUESTED} is not installed on this runner." >&2
    fi
    echo "Installed Xcode versions:"
    ls -d /Applications/Xcode*.app 2>/dev/null || echo "  (none found)"

    major="${REQUESTED%%.*}"
    if [[ -n "$major" ]]; then
        selected="$(ls -d "/Applications/Xcode_${major}"*.app 2>/dev/null | sort -V | tail -1 || true)"
    fi
    if [[ -z "$selected" ]]; then
        selected="$(ls -d /Applications/Xcode*.app 2>/dev/null | sort -V | tail -1 || true)"
    fi
    if [[ -n "$selected" ]]; then
        echo "WARNING: falling back to ${selected}" >&2
    fi
fi

if [[ -z "$selected" ]]; then
    echo "ERROR: no Xcode installation found under /Applications." >&2
    exit 1
fi

echo "Selecting Xcode: ${selected}"
sudo xcode-select -s "$selected"

xcodebuild -version
swift --version
