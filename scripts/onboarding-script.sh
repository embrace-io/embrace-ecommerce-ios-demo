#!/bin/bash

# Embrace Ecommerce Onboarding Script
# Welcome! This script helps you get started with Embrace by running a demo of the iOS SDK.
# It will create 5 simulated devices and run tests on each one sequentially.
# Each device gets a unique identifier so you can see them separately in your Embrace dashboard.
# Usage: ./onboarding-script.sh

set -e  # Exit on error

PROJECT_NAME="Embrace Ecommerce"
SCHEME="Embrace Ecommerce"
SIMULATOR="iPhone 16 Pro"
TEST_CLASS="Embrace_EcommerceUITests"
TEST_METHOD="testFlow"

# Allow override via environment variable: NUM_CLONES=3 ./onboarding-script.sh
NUM_CLONES=${NUM_CLONES:-5}  # Default to 5 devices, can be overridden

# Array to store clone UDIDs
declare -a CLONE_UDIDS=()

# SDK Configuration file path
SDK_CONFIG_FILE="Embrace Ecommerce/Services/SDKConfiguration.swift"

echo "================================================"
echo "🎉 Welcome to Embrace!"
echo "================================================"
echo ""
echo "This script will help you see Embrace in action by:"
echo "  1️⃣  Configuring the demo app with your Embrace App ID"
echo "  2️⃣  Building the app"
echo "  3️⃣  Running automated tests on $NUM_CLONES simulated devices (one at a time)"
echo "  4️⃣  Sending telemetry data to your Embrace dashboard"
echo ""
echo "The whole process takes about 5-10 minutes."
echo "When complete, you'll be able to see sessions from each device in your dashboard!"
echo ""
echo "💡 Tip: You can change the number of devices with: NUM_CLONES=3 ./onboarding-script.sh"
echo "================================================"

# Step 0: Prompt for Embrace App ID and update configuration
echo ""
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
echo "Looking for iPhone simulator..."
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
echo "Getting device configuration..."

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
echo "Creating $NUM_CLONES test devices..."
echo "(Each device gets a unique ID so you can track them separately in Embrace)"
echo ""

for i in $(seq 1 $NUM_CLONES); do
  CLONE_NAME="${SIMULATOR}_Clone_${i}"

  echo "  📱 Creating device $i of $NUM_CLONES..."

  # Create a fresh simulator (not a clone) so each gets a unique IDFV
  CLONE_UDID=$(xcrun simctl create "$CLONE_NAME" "$DEVICE_TYPE" "$RUNTIME" 2>&1)

  if [[ -z "$CLONE_UDID" ]]; then
    echo "  ❌ Failed to create device $i"
    exit 1
  fi

  # Store the clone UDID
  CLONE_UDIDS+=("$CLONE_UDID")

  echo "  ✅ Device $i created"
done

echo ""
echo "✅ All $NUM_CLONES test devices created"

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
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  2>&1 | grep -v "note: Building targets in dependency order" | grep -v "^$" || true

echo "✅ Build completed!"

# Step 7: Run UI Tests sequentially (boot one, test it, clean up, repeat)
echo ""
echo "================================================"
echo "📋 STEP 4: Run Tests on Each Device"
echo "================================================"
echo ""
echo "Now we'll run the demo app on each device, one at a time."
echo "Each test simulates a user browsing the ecommerce app and making a purchase."
echo "Watch as Embrace captures telemetry data from each session!"
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
    -only-testing:"${SCHEME}UITests/$TEST_CLASS/$TEST_METHOD" \
    -parallel-testing-enabled NO \
    -resultBundlePath "test_results_clone_${clone_num}.xcresult" \
    2>&1 | tee "test_output_clone_${clone_num}.log" | grep --line-buffered -E "(Test Suite|Test Case|passed|failed|Testing started|Testing cancelled)" || true

  # Check exit status from pipefail
  TEST_EXIT_CODE=${PIPESTATUS[0]}

  if [[ $TEST_EXIT_CODE -eq 0 ]]; then
    echo "✅ Device $clone_num test completed successfully!"
  else
    echo "⚠️  Device $clone_num test failed (exit code: $TEST_EXIT_CODE)"
    FAILED_COUNT=$((FAILED_COUNT + 1))
  fi

  # Shutdown and delete this clone before starting the next one
  echo "🧹 Cleaning up device $clone_num..."
  xcrun simctl shutdown "$clone_udid" 2>/dev/null || true
  xcrun simctl delete "$clone_udid" 2>/dev/null || echo "⚠️  Failed to delete device $clone_num"

  echo ""
done

echo "================================================"
if [[ $FAILED_COUNT -eq 0 ]]; then
  echo "✅ All $NUM_CLONES devices completed successfully!"
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
    echo "  Found remaining device $clone_num, deleting..."
    xcrun simctl shutdown "$clone_udid" 2>/dev/null || true
    xcrun simctl delete "$clone_udid" 2>/dev/null || true
  fi
done

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
      echo "✅ Device $i: PASSED"
    elif grep -q "Test Suite.*failed" "$log_file"; then
      echo "❌ Device $i: FAILED"
    else
      echo "⚠️  Device $i: UNKNOWN"
    fi
  else
    echo "⚠️  Device $i: No log file"
  fi
done

echo ""
echo "================================================"

# Step 9: Cleanup result bundles and test logs
echo ""
echo "🧹 Cleaning up test files..."
rm -rf test_results_clone_*.xcresult 2>/dev/null || true
rm -f test_output_clone_*.log 2>/dev/null || true
echo "✅ Test files cleaned up"

# Final Step: Restore SDK configuration to original state
echo ""
echo "🔄 Restoring configuration to default..."

# Replace the App ID back to the placeholder
sed -i '' "s/static let appId = \"$EMBRACE_APP_ID\"/static let appId = \"YOUR_EMBRACE_APP_ID\"/" "$SDK_CONFIG_FILE"

echo "✅ Configuration restored"

echo ""
echo "================================================"
echo "🎉 Onboarding Complete!"
echo "================================================"
echo ""
echo "What to do next:"
echo ""
echo "  1️⃣  Open your Embrace dashboard"
echo "  2️⃣  Look for sessions from $NUM_CLONES different devices"
echo "  3️⃣  Explore the telemetry data, crashes, and user sessions"
echo "  4️⃣  Try integrating Embrace into your own iOS app!"
echo ""
echo "Questions? Check out our docs at embrace.io/docs"
echo ""
echo "================================================"
