#!/bin/bash

# Sample activity UITest script for Embrace Ecommerce
# Creates 4 fresh simulator instances and runs tests sequentially
# Each simulator gets a unique IDFV for proper device tracking in Embrace

set -e  # Exit on error

PROJECT_NAME="Embrace Ecommerce"
SCHEME="Embrace Ecommerce"
SIMULATOR="iPhone 16 Pro"
TEST_CLASS="Embrace_EcommerceUITests"
TEST_METHOD="testFlow"

# Allow override via environment variable: NUM_CLONES=5 ./onboarding-script.sh
NUM_CLONES=${NUM_CLONES:-4}  # Default to 4 clones, can be overridden

# Array to store clone UDIDs
declare -a CLONE_UDIDS=()

# SDK Configuration file path
SDK_CONFIG_FILE="Embrace Ecommerce/Services/SDKConfiguration.swift"

echo "================================================"
echo "🎉 Welcome to Embrace!"
echo "================================================"

echo "This script will help you see Embrace in action by:"
echo "  1️⃣  Configuring the demo app with your Embrace App ID"
echo "  2️⃣  Building the app"
echo "  3️⃣  Running automated tests on $NUM_CLONES simulated devices (one at a time)"
echo "  4️⃣  Sending telemetry data to your Embrace dashboard"

echo "The whole process takes about 5-10 minutes."
echo "When complete, you'll be able to see sessions from each device in your dashboard!"
echo ""
echo "💡 Tip: You can change the number of devices from the terminal."
echo "Example usage: NUM_CLONES=10 ./scripts/onboarding-script.sh"
echo "================================================"


# Step 0: Prompt for Embrace App ID and update configuration
echo "📋 STEP 1: Configure Your Embrace App ID"
echo "=========================================="
echo ""
echo "To get started, we need your 5-character Embrace App ID."
echo "You can find this in your Embrace dashboard under Settings."
echo ""
echo "Don't worry - this will only be used temporarily during this demo,"
echo "and will be reset to the placeholder value when we're done."
echo ""

EMBRACE_APP_ID=""
while true; do
  read -p "Embrace App ID: " EMBRACE_APP_ID

  # Validate that it's exactly 5 characters
  if [[ ${#EMBRACE_APP_ID} -eq 5 ]]; then
    echo "✅ Valid App ID: $EMBRACE_APP_ID"
    break
  else
    echo "❌ Invalid App ID. Must be exactly 5 characters. You entered ${#EMBRACE_APP_ID} characters."
    echo "Please try again:"
  fi
done

# Update the SDK configuration file
echo ""
echo "📝 Updating SDKConfiguration.swift with App ID: $EMBRACE_APP_ID"

if [[ ! -f "$SDK_CONFIG_FILE" ]]; then
  echo "❌ Error: SDK configuration file not found at $SDK_CONFIG_FILE"
  exit 1
fi

# Replace the placeholder with the actual App ID
sed -i '' "s/static let appId = \"YOUR_EMBRACE_APP_ID\"/static let appId = \"$EMBRACE_APP_ID\"/" "$SDK_CONFIG_FILE"

echo "✅ SDK configuration updated"
echo ""

# Step 1: Kill any existing simulators
echo ""
echo "================================================"
echo "📋 STEP 2: Prepare Environment"
echo "================================================"
echo ""
echo "Cleaning up any existing simulators..."
killall Simulator 2>/dev/null || true
xcrun simctl shutdown all 2>/dev/null || true
echo "✅ Simulators cleaned up"

# Step 2: Get valid destination from xcodebuild
echo ""
echo "🔍 Finding valid destination for $SIMULATOR..."
DESTINATION_LINE=$(xcodebuild -showdestinations -project "$PROJECT_NAME.xcodeproj" -scheme "$SCHEME" 2>&1 | grep "iPhone 16 Pro" | grep -v "Max" | head -1)

if [[ -z "$DESTINATION_LINE" ]]; then
  echo "❌ $SIMULATOR not found in valid destinations"
  exit 1
fi

# Extract the ID from the destination line
SIMULATOR_UDID=$(echo "$DESTINATION_LINE" | grep -o 'id:[A-F0-9-]*' | cut -d: -f2)

if [[ -z "$SIMULATOR_UDID" ]]; then
  echo "❌ Could not extract simulator ID"
  exit 1
fi

echo "✅ Found base simulator with ID: $SIMULATOR_UDID"

# Extract device type and runtime from the base simulator
echo ""
echo "🔍 Extracting device type and runtime information..."

# Use Python to properly parse JSON and extract device info
DEVICE_INFO=$(xcrun simctl list devices -j | python3 -c "
import sys, json
data = json.load(sys.stdin)
target_udid = '$SIMULATOR_UDID'
for runtime, devices in data['devices'].items():
    for device in devices:
        if device['udid'] == target_udid:
            print(device['deviceTypeIdentifier'])
            print(runtime)
            sys.exit(0)
")

DEVICE_TYPE=$(echo "$DEVICE_INFO" | sed -n '1p')
RUNTIME=$(echo "$DEVICE_INFO" | sed -n '2p')

if [[ -z "$DEVICE_TYPE" || -z "$RUNTIME" ]]; then
  echo "❌ Could not extract device type or runtime"
  echo "Device Type: $DEVICE_TYPE"
  echo "Runtime: $RUNTIME"
  exit 1
fi

echo "✅ Device Type: $DEVICE_TYPE"
echo "✅ Runtime: $RUNTIME"

# Step 4: Create fresh simulator instances (not clones)
echo ""
echo "📋 Creating $NUM_CLONES fresh simulator instances..."
echo "💡 Note: Using 'create' instead of 'clone' ensures each simulator gets a unique IDFV"

for i in $(seq 1 $NUM_CLONES); do
  CLONE_NAME="${SIMULATOR}_Clone_${i}"

  echo "  Creating simulator $i: $CLONE_NAME"

  # Create a fresh simulator (not a clone) so each gets a unique IDFV
  CLONE_UDID=$(xcrun simctl create "$CLONE_NAME" "$DEVICE_TYPE" "$RUNTIME" 2>&1)

  if [[ -z "$CLONE_UDID" ]]; then
    echo "  ❌ Failed to create simulator $i"
    exit 1
  fi

  # Store the clone UDID
  CLONE_UDIDS+=("$CLONE_UDID")

  echo "  ✅ Simulator $i created: $CLONE_UDID"
done

echo "✅ All $NUM_CLONES simulators created successfully"

# Step 5: Boot and build with first simulator
echo ""
echo "================================================"
echo "📋 STEP 3: Build the Demo App"
echo "================================================"
echo ""
echo "Starting up the first device..."
xcrun simctl boot "${CLONE_UDIDS[0]}" 2>/dev/null || echo "  Already booted or failed"
echo "⏳ Waiting for device to be ready..."
xcrun simctl bootstatus "${CLONE_UDIDS[0]}" -b > /dev/null 2>&1 || true
echo "✅ Device is ready"

# Step 5.5: Update UITest file to set RUN_SOURCE to "onboard_script" BEFORE building
echo ""
echo "📝 Configuring UITest to use onboard_script as RUN_SOURCE..."
sed -i '' 's/"RUN_SOURCE": "UITest"/"RUN_SOURCE": "onboard_script"/' "Embrace EcommerceUITests/Embrace_EcommerceUITests.swift"
echo "✅ UITest configured"

# Step 6: Build for Testing (once, reused for all clones)
echo ""
echo "Building the app with Embrace SDK..."
echo "(This takes a few minutes - we only need to do this once)"
echo ""

xcodebuild build-for-testing \
  -project "$PROJECT_NAME.xcodeproj" \
  -scheme "$SCHEME" \
  -destination "platform=iOS Simulator,id=${CLONE_UDIDS[0]}" \
  -configuration Debug \
  -enableCodeCoverage NO \
  -allowProvisioningUpdates \
  -skipMacroValidation \
  -quiet \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  SWIFT_SUPPRESS_WARNINGS=YES \
  GCC_WARN_INHIBIT_ALL_WARNINGS=YES

echo "✅ Build completed successfully"

# Step 7: Run UI Tests sequentially (boot one, test it, clean up, repeat)
echo ""
echo "================================================"
echo "📋 STEP 4: Run Tests on Each Device"
echo "================================================"
echo ""
echo "Now we'll run the demo app on each device, one at a time."
echo "Each test simulates a user entering the ecommerce app and performing some actions."
echo "Afterwards, you'll be able to view the captured telemetry from each session in your dashboard!"
echo ""

FAILED_COUNT=0

# Run tests sequentially on each clone
for i in "${!CLONE_UDIDS[@]}"; do
  clone_udid="${CLONE_UDIDS[$i]}"
  clone_num=$((i + 1))

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📱 Device $clone_num of $NUM_CLONES"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  # Boot this simulator (if not the first one which is already booted from build step)
  if [[ $i -gt 0 ]]; then
    echo "⏳ Starting device..."
    xcrun simctl boot "$clone_udid" 2>/dev/null || echo "  Already booted or failed"
    xcrun simctl bootstatus "$clone_udid" -b > /dev/null 2>&1 || true
  fi

  echo "🧪 Running demo test (this takes about 1-2 minutes)..."

  # Run test synchronously with isolated result bundle
  # Show test progress while also saving to log
  xcodebuild test-without-building \
    -project "$PROJECT_NAME.xcodeproj" \
    -scheme "$SCHEME" \
    -destination "platform=iOS Simulator,id=$clone_udid" \
    -only-testing:"Embrace EcommerceUITests/$TEST_CLASS/$TEST_METHOD" \
    -parallel-testing-enabled NO \
    -resultBundlePath "test_results_clone_${clone_num}.xcresult" \
    2>&1 | tee "test_output_clone_${clone_num}.log" | grep --line-buffered -E "(Test Suite|Test Case|passed|failed|Testing started|Testing cancelled)" || true

  # Check exit status from pipefail
  TEST_EXIT_CODE=${PIPESTATUS[0]}

  if [[ $TEST_EXIT_CODE -eq 0 ]]; then
    echo "  ✅ Clone $clone_num test completed successfully"
  else
    echo "  ⚠️  Clone $clone_num test failed (exit code: $TEST_EXIT_CODE)"
    FAILED_COUNT=$((FAILED_COUNT + 1))
  fi

  # Shutdown and delete this clone before starting the next one
  echo "  🧹 Shutting down and deleting clone $clone_num..."
  xcrun simctl shutdown "$clone_udid" 2>/dev/null || true
  xcrun simctl delete "$clone_udid" 2>/dev/null || echo "  ⚠️  Failed to delete clone $clone_num"

  echo "  ✅ Clone $clone_num cleaned up"
done

echo "================================================"
if [[ $FAILED_COUNT -eq 0 ]]; then
  echo "✅ All tests completed successfully"
else
  echo "⚠️  $FAILED_COUNT out of $NUM_CLONES tests failed"
fi
echo "================================================"


# Step 8: Cleanup any remaining clones (should already be deleted)
echo ""
echo "🧹 Final cleanup..."

# Try to clean up any clones that might still exist
for i in "${!CLONE_UDIDS[@]}"; do
  clone_udid="${CLONE_UDIDS[$i]}"
  clone_num=$((i + 1))

  # Check if clone still exists and delete if so
  if xcrun simctl list devices | grep -q "$clone_udid"; then
    echo "  Found remaining clone $clone_num, deleting..."
    xcrun simctl shutdown "$clone_udid" 2>/dev/null || true
    xcrun simctl delete "$clone_udid" 2>/dev/null || true
  fi
done

echo "✅ Cleanup complete"

# Show test results summary
echo ""
echo "================================================"
echo "📊 Test Results Summary"
echo "================================================"
echo ""
for i in $(seq 1 $NUM_CLONES); do
  log_file="test_output_clone_${i}.log"
  if [[ -f "$log_file" ]]; then
    if grep -q "Test Suite.*passed" "$log_file"; then
      echo "✅ Clone $i: PASSED"
    elif grep -q "Test Suite.*failed" "$log_file"; then
      echo "❌ Clone $i: FAILED"
    else
      echo "⚠️  Clone $i: UNKNOWN"
    fi
  else
    echo "⚠️  Clone $i: No log file"
  fi
done

echo ""
echo "================================================"

# Step 9: Cleanup result bundles and test logs
echo ""
echo "🧹 Cleaning up result bundles and test logs..."
rm -rf test_results_clone_*.xcresult 2>/dev/null || true
rm -f test_output_clone_*.log 2>/dev/null || true
echo "✅ Result bundles and test logs cleaned up"

# Final Step: Restore SDK configuration and UITest file to original state
echo ""
echo "🔄 Restoring files to original state..."

# Replace the App ID back to the placeholder
sed -i '' "s/static let appId = \"$EMBRACE_APP_ID\"/static let appId = \"YOUR_EMBRACE_APP_ID\"/" "$SDK_CONFIG_FILE"

# Restore UITest RUN_SOURCE back to "UITest"
sed -i '' 's/"RUN_SOURCE": "onboard_script"/"RUN_SOURCE": "UITest"/' "Embrace EcommerceUITests/Embrace_EcommerceUITests.swift"

echo "✅ Files restored to original state"

# Final cleanup: Kill all simulator processes
echo ""
echo "🧹 Stopping all Simulator processes..."
killall Simulator 2>/dev/null || true
xcrun simctl shutdown all 2>/dev/null || true
echo "✅ All Simulator processes stopped"

echo ""
echo "================================================"
echo "🎉 Onboarding Complete!"
echo "================================================"
echo ""
echo "What to do next:"
echo ""
echo "  1️⃣  Open your Embrace dashboard - https://dash.embrace.io/app/$EMBRACE_APP_ID"
echo "  2️⃣  Look for sessions from $NUM_CLONES different device(s)"
echo "  3️⃣  Explore the telemetry data, crashes, and user sessions"
echo "  4️⃣  Try integrating Embrace into your own iOS app!"
echo ""
echo "Questions? Check out our docs at embrace.io/docs"
echo ""
echo "================================================"
