#!/usr/bin/env bash
# Writes the Embrace app ID from the APP_ID repository variable into
# SDKConfiguration.swift.
#
# The previous inline sed only matched the placeholder "YOUR_EMBRACE_APP_ID".
# Once a real app ID was committed to the repo, the substitution matched nothing
# — yet every workflow still printed "Embrace APP_ID configured" and carried on.
# This replaces whatever literal is present and verifies the result.
#
# Requires APP_ID in the environment. Usage: scripts/configure-app-id.sh
set -euo pipefail

PROJECT_NAME="${PROJECT_NAME:-Embrace Ecommerce}"
config_file="${PROJECT_NAME}/Services/SDKConfiguration.swift"

if [[ -z "${APP_ID:-}" ]]; then
    echo "ERROR: APP_ID is empty. Set the APP_ID repository variable under" >&2
    echo "Settings > Secrets and variables > Actions > Variables." >&2
    exit 1
fi

# Keeps a malformed variable from turning into a sed expression.
if [[ ! "$APP_ID" =~ ^[A-Za-z0-9_-]+$ ]]; then
    echo "ERROR: APP_ID contains unexpected characters." >&2
    exit 1
fi

if [[ ! -f "$config_file" ]]; then
    echo "ERROR: ${config_file} not found." >&2
    exit 1
fi

sed -i '' -E "s/static let appId = \"[^\"]*\"/static let appId = \"${APP_ID}\"/" "$config_file"

if ! grep -q "static let appId = \"${APP_ID}\"" "$config_file"; then
    echo "ERROR: failed to write appId into ${config_file}." >&2
    grep -n "appId" "$config_file" >&2 || true
    exit 1
fi

echo "Embrace app ID configured in ${config_file}"
