#!/usr/bin/env bash
# Runs ALL UI tests sequentially on the SAME simulator to create multiple
# sessions for one device identity (IDFV), which is what enables session
# stitching in the Embrace dashboard.
#
# The iOS equivalent of Android's run-variants.sh.
#
# Pass/fail accounting notes:
#   * The old version wrapped xcodebuild in `if xcodebuild ... | tee ... | grep`,
#     so the `if` tested grep's exit status rather than xcodebuild's, and the
#     grep-based "Test case ... passed" detection depended on a log format that
#     varies by Xcode version.
#   * A nonzero xcodebuild exit does NOT mean breakage here: the flow tests call
#     calculateAndCreateCrash(), which crashes the app on purpose in ~35% of
#     runs. So this reports crashes as expected and only fails the run when a
#     test never executed at all — see scripts/check-test-run.py.
#   * `set -e` is deliberately not used: one bad test must not abort the
#     remaining sessions.
set -uo pipefail

PROJECT_NAME="${PROJECT_NAME:-Embrace Ecommerce}"
SCHEME="${SCHEME:-Embrace Ecommerce}"
SIMULATOR_UDID="${SIMULATOR_UDID:-}"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-DerivedData}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Each test creates a new session on the same device. Mirrors Android's approach
# of multiple test classes (CheckoutFlowTestsSuccess, ...Failure, etc).
TESTS=(
    "testAuthenticationGuestFlow"
    "testBrowseFlow"
    "testAddToCartFlow"
    "testCheckoutFlow"
    "testSearchFlow"
    "testQuickBrowseAndLeave"
    "testAbandonedCartFlow"
    "testProfileViewFlow"
    "testRepeatProductBrowsing"
    "testHomeToSearchToCartFlow"
    "testMultiSessionTimeline"
)

if [[ -z "$SIMULATOR_UDID" ]]; then
    echo "ERROR: SIMULATOR_UDID is required." >&2
    echo "Usage: SIMULATOR_UDID=<udid> scripts/run-all-tests.sh" >&2
    exit 1
fi

TOTAL=${#TESTS[@]}

echo "================================================"
echo "Running all tests sequentially on one simulator"
echo "================================================"
echo "Simulator:    ${SIMULATOR_UDID}"
echo "Project:      ${PROJECT_NAME}"
echo "Scheme:       ${SCHEME}"
echo "Derived data: ${DERIVED_DATA_PATH}"
echo "Tests:        ${TOTAL}"
echo ""
echo "Multiple sessions on one device identity appear as stitched sessions."
echo ""

executed=0
never_ran=0
failed_tests=()

for i in "${!TESTS[@]}"; do
    test_method="${TESTS[$i]}"
    test_num=$((i + 1))
    result_bundle="result-${test_method}.xcresult"
    log_file="result-${test_method}.txt"

    echo "------------------------------------------------"
    echo "Test ${test_num} of ${TOTAL}: ${test_method}"
    echo "------------------------------------------------"

    # Stale bundles make xcodebuild fail before it runs anything.
    rm -rf "$result_bundle"

    # Full output goes to the log; progress lines stay on stdout so the CI job
    # is not silent for minutes. PIPESTATUS[0] is xcodebuild's status — plain $?
    # would report grep's, which was the original bug here.
    xcodebuild test-without-building \
        -project "${PROJECT_NAME}.xcodeproj" \
        -scheme "${SCHEME}" \
        -destination "platform=iOS Simulator,id=${SIMULATOR_UDID}" \
        -derivedDataPath "${DERIVED_DATA_PATH}" \
        -only-testing:"Embrace EcommerceUITests/Embrace_EcommerceUITests/${test_method}" \
        -resultBundlePath "${result_bundle}" 2>&1 \
        | tee "$log_file" \
        | grep --line-buffered -E "Test Suite|Test [Cc]ase|Testing started|error:" || true
    xcodebuild_status=${PIPESTATUS[0]}

    echo "xcodebuild exit status: ${xcodebuild_status} (nonzero is expected when the app crashes on purpose)"

    if python3 "${SCRIPT_DIR}/check-test-run.py" "$result_bundle" "$test_method"; then
        executed=$((executed + 1))
    else
        echo "ERROR: ${test_method} produced no executed tests" >&2
        tail -30 "$log_file" >&2
        never_ran=$((never_ran + 1))
        failed_tests+=("$test_method")
    fi

    # Give the SDK a moment to upload the session before the next launch.
    echo "Waiting 5s for session upload..."
    sleep 5
    echo ""
done

echo "================================================"
echo "Results"
echo "================================================"
echo "Executed:  ${executed} / ${TOTAL}"
echo "Never ran: ${never_ran}"

if (( never_ran > 0 )); then
    echo "Tests that never executed: ${failed_tests[*]}" >&2
    echo "This indicates real breakage (missing test, stale build, wedged simulator)." >&2
    exit 1
fi

echo ""
echo "All ${TOTAL} tests executed. Check the Embrace dashboard for stitched sessions."
