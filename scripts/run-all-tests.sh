#!/bin/bash
# run-all-tests.sh
# Runs ALL UI tests sequentially on the SAME simulator to create multiple sessions
# for the same device (IDFV), which enables session stitching in Embrace dashboard.
#
# This is the iOS equivalent of Android's run-variants.sh

set -e

PROJECT_NAME="${PROJECT_NAME:-Embrace Ecommerce}"
SCHEME="${SCHEME:-Embrace Ecommerce}"
SIMULATOR_UDID="${SIMULATOR_UDID:-}"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-DerivedData}"

# Define all test methods to run sequentially
# Each test will create a new session on the same device
# This mirrors Android's approach with multiple test classes:
# - CheckoutFlowTestsSuccess, CheckoutFlowTestsFailure, etc.
TESTS=(
    "testAuthenticationGuestFlow"
    "testBrowseFlow"
    "testAddToCartFlow"
    "testSearchFlow"
    "testQuickBrowseAndLeave"
    "testAbandonedCartFlow"
    "testProfileViewFlow"
    "testRepeatProductBrowsing"
    "testHomeToSearchToCartFlow"
    "testMultiSessionTimeline"
)

echo "================================================"
echo "🧪 Running All Tests Sequentially on One Simulator"
echo "================================================"
echo ""
echo "This creates multiple sessions for the same device,"
echo "which will appear as stitched sessions in Embrace dashboard."
echo ""

# Verify simulator UDID is provided
if [[ -z "$SIMULATOR_UDID" ]]; then
    echo "❌ Error: SIMULATOR_UDID environment variable is required"
    echo "Usage: SIMULATOR_UDID=<udid> ./run-all-tests.sh"
    exit 1
fi

echo "📱 Simulator UDID: $SIMULATOR_UDID"
echo "📂 Project: $PROJECT_NAME"
echo "🔧 Scheme: $SCHEME"
echo "📁 Derived Data: $DERIVED_DATA_PATH"
echo "🧪 Tests to run: ${#TESTS[@]}"
echo ""

# Track results
PASSED=0
FAILED=0
TOTAL=${#TESTS[@]}

# Run each test sequentially on the same simulator
for i in "${!TESTS[@]}"; do
    test_method="${TESTS[$i]}"
    test_num=$((i + 1))

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🧪 Test $test_num of $TOTAL: $test_method"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # Run the test
    if xcodebuild test-without-building \
        -project "$PROJECT_NAME.xcodeproj" \
        -scheme "$SCHEME" \
        -destination "platform=iOS Simulator,id=$SIMULATOR_UDID" \
        -derivedDataPath "$DERIVED_DATA_PATH" \
        -only-testing:"Embrace EcommerceUITests/Embrace_EcommerceUITests/$test_method" \
        -resultBundlePath "result-$test_method.xcresult" \
        2>&1 | tee "result-$test_method.txt" | grep --line-buffered -E "(Test Suite|Test Case|passed|failed|Testing started)" || true; then

        # Check if test actually passed by looking at the log
        if grep -q "Test Suite.*passed" "result-$test_method.txt" 2>/dev/null; then
            echo "✅ $test_method PASSED"
            PASSED=$((PASSED + 1))
        else
            echo "⚠️  $test_method completed with unknown status"
            FAILED=$((FAILED + 1))
        fi
    else
        echo "❌ $test_method FAILED"
        FAILED=$((FAILED + 1))
    fi

    # Brief pause between tests to allow SDK to flush data
    echo "⏳ Waiting 5 seconds for SDK to upload session data..."
    sleep 5

    echo ""
done

echo "================================================"
echo "📊 Final Results"
echo "================================================"
echo ""
echo "✅ Passed: $PASSED"
echo "❌ Failed: $FAILED"
echo "📊 Total:  $TOTAL"
echo ""

if [[ $FAILED -eq 0 ]]; then
    echo "🎉 All tests passed! Multiple sessions created on the same device."
    echo "Check the Embrace dashboard to see stitched sessions."
    exit 0
else
    echo "⚠️  Some tests failed. Check result-*.txt for details."
    exit 1
fi
