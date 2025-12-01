# GitHub Workflows Documentation

This directory contains CI/CD workflows for the Embrace Ecommerce iOS application.

## Workflows Overview

### 1. `ci-optimized.yaml` - Optimized CI Pipeline ⭐ **RECOMMENDED**

**Purpose**: Comprehensive testing across multiple devices and test suites with optimized build times.

**Key Features**:
- ✅ **Matrix Testing**: Tests run on iPhone 16 and iPhone 16 Pro
- ✅ **Multiple Test Suites**: Runs both authentication flow and main flow tests
- ✅ **Dependency Caching**: Caches SwiftPM dependencies for faster builds
- ✅ **Optimized Build Process**: Build once, test multiple times
- ✅ **Better Output Formatting**: Uses xcpretty for cleaner logs
- ✅ **Proper Cleanup**: Ensures simulators are properly shut down

**Triggers**:
- Manual dispatch via GitHub Actions UI
- Pull requests to `main` branch
- Optional: Scheduled runs (commented out by default)

**Test Configurations**:
| Test Suite | Target | RUN_SOURCE |
|------------|--------|------------|
| Authentication Guest Flow | `testAuthenticationGuestFlow` | `ci-optimized-auth` |
| Main Flow | `testFlow` | `ci-optimized-flow` |

**Environment Variables Required**:
- `APP_ID` - Your Embrace App ID (set in Repository Variables)

---

### 2. `ci-xcode-integration.yaml` - Integration Testing

**Purpose**: Scheduled integration testing for authentication flows.

**Triggers**:
- Every 40 minutes via cron schedule
- Manual dispatch

**Test**: `testAuthenticationGuestFlow` on iPhone 16 Pro

---

### 3. `ci-xcode.yaml` - Basic CI

**Purpose**: Manual CI testing with dynamic simulator selection.

**Triggers**: Manual dispatch only

**Test**: `testFlow` with automatic simulator selection

---

## Setup Instructions

### Required Repository Variables

1. Go to your repository Settings
2. Navigate to: **Secrets and variables > Actions > Variables**
3. Add the following variable:
   - `APP_ID`: Your Embrace App ID

### Running Workflows

#### Manual Trigger
1. Go to the **Actions** tab in your repository
2. Select the workflow you want to run (e.g., "Xcode - Optimized CI")
3. Click **Run workflow**
4. Select the branch and click **Run workflow**

#### Automatic Triggers
- `ci-optimized.yaml`: Automatically runs on PRs to main
- `ci-xcode-integration.yaml`: Runs every 40 minutes

### Enabling Scheduled Runs for Optimized CI

To enable scheduled runs for `ci-optimized.yaml`:

1. Open `.github/workflows/ci-optimized.yaml`
2. Uncomment the schedule section:
```yaml
schedule:
  - cron: '0 */2 * * *'  # Runs every 2 hours
```

## Matrix Strategy Explained

The optimized workflow uses a matrix strategy to run tests across multiple configurations:

```yaml
matrix:
  xcode_version: ["16.4"]
  device: ["iPhone 16", "iPhone 16 Pro"]
  test_suite: [auth_flow, main_flow]
```

This creates **4 parallel jobs**:
- iPhone 16 + Authentication Flow
- iPhone 16 + Main Flow
- iPhone 16 Pro + Authentication Flow
- iPhone 16 Pro + Main Flow

## Customization

### Adding More Devices

Edit the `device` matrix in `ci-optimized.yaml`:

```yaml
device:
  - "iPhone 16"
  - "iPhone 16 Pro"
  - "iPhone 16 Plus"  # Add new device
  - "iPad Pro 13-inch (M4)"  # Add iPad
```

### Adding More Test Suites

Add new test configurations to the `test_suite` matrix:

```yaml
test_suite:
  - name: "Your Test Name"
    target: "Embrace EcommerceUITests/Embrace_EcommerceUITests/testYourTest"
    run_source: "ci-your-test"
```

### Adjusting Timeout

Change the `timeout-minutes` value:

```yaml
timeout-minutes: 45  # Increase or decrease as needed
```

## Troubleshooting

### Build Failures

**Simulator Not Found**:
- Check available simulators in Xcode
- Update the `device` names in the matrix to match available simulators

**APP_ID Not Configured**:
- Ensure `APP_ID` is set in repository variables
- Verify the sed command path matches your project structure

**Cache Issues**:
- Clear cache by going to Actions > Caches and deleting old caches
- The workflow will rebuild the cache on the next run

### Test Failures

**RUN_SOURCE Configuration**:
- Ensure the `RUN_SOURCE` property exists in `Embrace EcommerceUITests/Embrace_EcommerceUITests.swift`
- Verify the sed command path is correct

**Code Signing**:
- Tests run with `CODE_SIGNING_ALLOWED=NO` for CI environments
- This is expected and correct for simulator testing

## Performance Tips

1. **Use the optimized workflow** for comprehensive testing
2. **Enable caching** to speed up subsequent runs (already enabled)
3. **Adjust matrix strategy** to balance coverage vs. runtime
4. **Use `fail-fast: false`** to see all test results even if one fails

## Migration from Old Workflows

If you want to deprecate the older workflows:

1. Test `ci-optimized.yaml` thoroughly
2. Archive old workflow files (rename with `.disabled` extension)
3. Update any documentation or badges that reference old workflows

## Questions?

For questions about:
- **Embrace SDK**: Contact your Embrace support team
- **GitHub Actions**: See [GitHub Actions Documentation](https://docs.github.com/en/actions)
- **Xcode CI/CD**: See [Xcode Build Settings Reference](https://developer.apple.com/documentation/xcode)
