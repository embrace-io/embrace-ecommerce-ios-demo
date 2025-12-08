# GitHub Workflows Documentation

This directory contains CI/CD workflows for the Embrace Ecommerce iOS application, designed to generate diverse sessions for the Embrace dashboard.

## Architecture Overview

```
Push to main
     |
     v
+------------+
| build.yml  |  Build once, upload artifacts
+------------+
     |
     +----------------+----------------+
     |                                 |
     v                                 v
+-----------------+          +-------------------+
| ci-scheduled.yml|          | ci-full-matrix.yml|
| Every 3 hours   |          | Manual trigger    |
| 1 device        |          | 3+ devices        |
| 3 tests         |          | 5 tests           |
+-----------------+          +-------------------+
```

## Workflows

### 1. `build.yml` - Build Artifacts

**Purpose**: Builds the app and uploads test artifacts for reuse by other workflows.

**Triggers**:
- Push to `main` branch
- Manual dispatch

**What it does**:
1. Configures Embrace APP_ID
2. Builds using `xcodebuild build-for-testing`
3. Uploads build artifacts (retained for 7 days)

**Artifacts produced**:
- `test-build-artifacts` - Full build products
- `xctestrun-file` - Test configuration

---

### 2. `ci-scheduled.yml` - Scheduled Tests (Lightweight)

**Purpose**: Maintains steady flow of diverse sessions to the Embrace dashboard.

**Triggers**:
- Every 3 hours (cron: `0 */3 * * *`)
- Manual dispatch

**Configuration**:
| Test | RUN_SOURCE |
|------|------------|
| Guest Auth | `scheduled-auth` |
| Browse Products | `scheduled-browse` |
| Search | `scheduled-search` |

**Device**: iPhone 16 (single device for efficiency)

**Session output**: ~24 sessions/day (8 runs x 3 tests)

**Key feature**: Downloads pre-built artifacts from `build.yml` when available, falls back to building from source if not.

---

### 3. `ci-full-matrix.yml` - Full Matrix Tests

**Purpose**: Comprehensive testing across multiple devices and all test suites. Use before demos or for thorough validation.

**Triggers**:
- Manual dispatch only
- Optional input: `include_ipad` (adds iPad tests)

**Device Matrix**:
| Device | Type |
|--------|------|
| iPhone 16 | Standard |
| iPhone 16 Pro | Pro tier |
| iPhone SE (3rd generation) | Compact |
| iPad (optional) | Tablet |

**Test Matrix**:
| Test | RUN_SOURCE Pattern |
|------|-------------------|
| Guest Auth | `matrix-auth-{device}` |
| Browse Flow | `matrix-browse-{device}` |
| Add to Cart | `matrix-cart-{device}` |
| Search Flow | `matrix-search-{device}` |
| Main Flow | `matrix-main-{device}` |

**Session output**: 15 unique sessions per run (3 devices x 5 tests), or 18 with iPad enabled.

---

## Setup Instructions

### Required Repository Variables

1. Go to repository **Settings**
2. Navigate to: **Secrets and variables > Actions > Variables**
3. Add:
   - `APP_ID`: Your Embrace App ID

### Running Workflows

**Scheduled (automatic)**:
- `ci-scheduled.yml` runs every 3 hours automatically

**Manual trigger**:
1. Go to **Actions** tab
2. Select the workflow
3. Click **Run workflow**
4. For `ci-full-matrix.yml`, optionally check "Include iPad"

---

## Available Test Methods

| Test Method | Description | User Journey |
|-------------|-------------|--------------|
| `testAuthenticationGuestFlow` | Guest login flow | Auth -> Guest -> Home |
| `testBrowseFlow` | Product browsing | Home -> Products -> Detail |
| `testAddToCartFlow` | Shopping cart | Home -> Product -> Cart |
| `testSearchFlow` | Search functionality | Home -> Search -> Results |
| `testFlow` | Adaptive main flow | Detects screen, performs action |

---

## Session Diversity

Each workflow generates sessions with unique `RUN_SOURCE` values for easy filtering in the Embrace dashboard:

**Scheduled sessions**:
- `scheduled-auth`
- `scheduled-browse`
- `scheduled-search`

**Full matrix sessions** (examples):
- `matrix-auth-16`
- `matrix-browse-16-pro`
- `matrix-cart-se-3rd-generation`
- `matrix-search-ipad`

---

## Troubleshooting

### Build Failures

**Simulator Not Found**:
- Verify device names match available simulators in Xcode
- Check `xcrun simctl list devices available`

**APP_ID Not Configured**:
- Ensure `APP_ID` is set in repository variables
- Check Settings > Secrets and variables > Actions > Variables

### Test Failures

**Artifacts Not Found** (ci-scheduled.yml):
- Workflow falls back to building from source
- Ensure `build.yml` has run successfully at least once

**RUN_SOURCE Issues**:
- Verify `RUN_SOURCE` exists in test file launch environment
- Check sed command paths match project structure

---

## Cost Considerations

This repository is **public**, so GitHub Actions minutes are unlimited. The architecture is still optimized for efficiency:

- **build.yml**: Runs once per push, artifacts shared
- **ci-scheduled.yml**: Lightweight, reuses artifacts
- **ci-full-matrix.yml**: Manual only, avoids unnecessary runs

---

## Links

- [Embrace Documentation](https://embrace.io/docs/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Android Demo Repository](https://github.com/embrace-io/embrace-ecommerce-android-demo)
