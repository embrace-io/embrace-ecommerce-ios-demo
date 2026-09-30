#!/usr/bin/env bash
# Stamps RUN_SOURCE into the UI test bundle so dashboard sessions are
# attributable to the workflow that produced them. The test passes RUN_SOURCE in
# the app's launch environment; the app reads it and sets the
# session_run_source session property.
#
# This must run BEFORE build-for-testing, because RUN_SOURCE is a compile-time
# literal in the UI test source. The old scheduled workflows stamped it *after*
# downloading a prebuilt test bundle, so it had no effect and every reused-build
# session was tagged "UITest".
#
# Requires RUN_SOURCE in the environment. Usage: scripts/configure-run-source.sh
set -euo pipefail

PROJECT_NAME="${PROJECT_NAME:-Embrace Ecommerce}"
tests_file="${PROJECT_NAME}UITests/Embrace_EcommerceUITests.swift"

if [[ -z "${RUN_SOURCE:-}" ]]; then
    echo "ERROR: RUN_SOURCE is empty." >&2
    exit 1
fi

# Keeps a malformed value from turning into a sed expression.
if [[ ! "$RUN_SOURCE" =~ ^[A-Za-z0-9_.-]+$ ]]; then
    echo "ERROR: RUN_SOURCE contains unexpected characters: ${RUN_SOURCE}" >&2
    exit 1
fi

if [[ ! -f "$tests_file" ]]; then
    echo "ERROR: ${tests_file} not found." >&2
    exit 1
fi

sed -i '' -E "s/\"RUN_SOURCE\": \"[^\"]*\"/\"RUN_SOURCE\": \"${RUN_SOURCE}\"/" "$tests_file"

if ! grep -q "\"RUN_SOURCE\": \"${RUN_SOURCE}\"" "$tests_file"; then
    echo "ERROR: failed to write RUN_SOURCE into ${tests_file}." >&2
    grep -n "RUN_SOURCE" "$tests_file" >&2 || true
    exit 1
fi

echo "RUN_SOURCE set to ${RUN_SOURCE}"
