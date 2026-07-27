# GitHub Workflows Documentation

CI/CD workflows for the Embrace Ecommerce iOS demo app. Their job is to generate
diverse, realistic sessions — including crashes — for the Embrace dashboard.

## Architecture Overview

Each workflow is self-contained: it builds from source, uploads its own dSYMs,
then runs its tests.

```
build.yml            ci-scheduled.yml     one-simulator.yml    ci-crash-tests.yml   ci-full-matrix.yml
push to main         every 2h (:00)       every 2h (:30)       every 3h (:15)       manual
     |                    |                    |                    |                    |
     v                    v                    v                    v                    v
build + dSYMs        3 parallel jobs      11 tests, ONE        5 crash+flush        18 jobs
(compile check)      1 test each          simulator            cycles               (3 devices x 6 tests)
                     non-stitched         stitched             crash reports        per-device tagging
```

There is deliberately **no shared prebuilt bundle** between workflows.
`RUN_SOURCE` is compiled into the UI test binary, so reusing one build would tag
every session identically and defeat the per-workflow attribution below. This
repo is public, so Actions minutes are free; the cost of building per job is wall
clock, not money.

## Pass/fail semantics — read this before debugging a red job

The flow tests call `calculateAndCreateCrash()`, which **crashes the app on
purpose in roughly 35% of runs**. XCTest reports that as a test failure, so a
nonzero `xcodebuild` exit is expected and is deliberately ignored.

`scripts/check-test-run.py` draws the real line:

| Situation | Job result |
|---|---|
| Test executed, app crashed intentionally | green (crash count noted in the run summary) |
| Test executed, unexpected assertion/timeout failure | green, plus a `::warning` in the run summary |
| Test never executed (missing test, stale build, wedged simulator) | **red** |
| Build failure or no simulator | **red** (nothing useful can follow) |
| Zero dSYMs uploaded | **red**, but only *after* the tests run |

That last row matters: a dead `EMBRACE_API_TOKEN` must not cost a run's worth of
sessions. The upload step is `continue-on-error` and a gate at the end of the job
turns the run red, so traffic keeps flowing while the failure stays loud.
Unsymbolicated sessions beat no sessions.

So: red means the pipeline is broken, not that the app crashed. Every job writes
an executed/passed/failed/skipped line to its run summary.

## Workflows

### `build.yml` — Build and Upload Symbols

**Purpose**: compile check on every push, and keep dSYMs uploaded so crashes from
that commit symbolicate.

**Triggers**: push to `main`, manual dispatch.

It no longer publishes `test-build-artifacts` / `xctestrun-file`. Those were
consumed by the scheduled workflows, but the scheme never worked: `build.yml`
only ran on push, artifacts expire after 7 days, and the last push preceded the
scheduled runs by months — so the consumers always fell back to building from
source anyway.

---

### `ci-scheduled.yml` — Scheduled Tests (Lightweight)

**Purpose**: steady session flow to the dashboard.

**Triggers**: every 2 hours (`0 */2 * * *`), manual dispatch.

**Device**: iPhone 16. Each suite runs as its own job on its own simulator, so
each gets a distinct device identity — these are the **non-stitched** sessions.

| Test | RUN_SOURCE |
|---|---|
| `testBrowseFlow` | `scheduled-browse` |
| `testAuthenticationGuestFlow` | `scheduled-auth` |
| `testCheckoutFlow` | `scheduled-checkout` |

Each job ends with a flush run (`testQuickBrowseAndLeave`) on the same simulator
so any crash report from the main test gets shipped.

---

### `one-simulator.yml` — One Simulator (Session Stitching)

**Purpose**: multiple sessions sharing one device identity (IDFV), which is what
produces **stitched** sessions. The iOS counterpart to Android's
`one-emulator.yml`.

**Triggers**: every 2 hours at `:30` (`30 */2 * * *`), offset from
`ci-scheduled.yml` so the dashboard sees a mix of stitched and non-stitched
traffic.

Runs all 11 tests sequentially via `scripts/run-all-tests.sh`, all tagged
`one-simulator-stitched`.

---

### `ci-crash-tests.yml` — Crash Tests

**Purpose**: deterministically populate crash data.

**Triggers**: every 3 hours at `:15` (`15 */3 * * *`), manual dispatch.

Runs 5 crash+flush cycles, tagged `crash-test`, with Embrace log level raised to
`.debug` and host `os_log` capture (subsystem `com.embrace.logger`) attached as
an artifact.

Each cycle is two phases, mirroring Android's two-`am instrument` approach:

1. **Phase A** runs only `testCrashA_Force`; xcodebuild exits leaving the KSCrash
   payload on disk.
2. **Phase B** is a *fresh* xcodebuild invocation running `testCrashB_Flush`, so
   the app cold-starts and the SDK ships the pending crash against the persisted
   session.

Do not uninstall, erase, or shut down the simulator between phases — the on-disk
payload has to survive. Phase B is the health signal, since it must not crash.

---

### `ci-full-matrix.yml` — Full Matrix Tests

**Purpose**: broad device/test coverage before demos or releases.

**Triggers**: manual dispatch only. Optional `include_ipad` input.

A `symbols` job builds once and uploads dSYMs (also failing fast if the build is
broken); the 18 test jobs then each build from source so they can carry their own
tag.

**Devices**: iPhone 16, iPhone 16 Pro, iPhone SE (3rd generation), plus iPad Pro
when `include_ipad` is set.

| Test | RUN_SOURCE pattern |
|---|---|
| Guest Auth | `matrix-auth-{device}` |
| Browse Flow | `matrix-browse-{device}` |
| Add to Cart | `matrix-cart-{device}` |
| Search Flow | `matrix-search-{device}` |
| Checkout Flow | `matrix-checkout-{device}` |
| Multi-Session Timeline | `matrix-timeline-{device}` |

**Output**: 18 tagged sessions per run (3 devices x 6 tests), 21 with iPad.

---

## Shared scripts

Workflow logic lives in `scripts/` so a fix lands once instead of five times.

| Script | Responsibility |
|---|---|
| `select-xcode.sh` | Selects `XCODE_VERSION`, falling back to the newest installed Xcode |
| `find-simulator.sh` | Resolves a UDID by exact device name, optionally boots it, fails loudly when absent |
| `configure-app-id.sh` | Writes the `APP_ID` variable into `SDKConfiguration.swift` and verifies it |
| `configure-run-source.sh` | Stamps `RUN_SOURCE` into the UI test source and verifies it |
| `upload-dsyms.sh` | Uploads every dSYM; fails if none were uploaded |
| `check-test-run.py` | Decides whether a run was actually broken (see semantics above) |
| `run-all-tests.sh` | Sequential all-test run for session stitching |

## Runner and Xcode pinning

All macOS jobs pin `runs-on: macos-15` with `XCODE_VERSION: "16.4"`.

Every workflow previously used `macos-latest` and hardcoded
`sudo xcode-select -s /Applications/Xcode_16.4.app`. When `macos-latest` moved to
macOS 26 — which ships only Xcode 26.x — every scheduled run died within 30
seconds on `invalid developer directory`. `select-xcode.sh` now degrades to the
newest available Xcode instead of hard-failing, but the pin is the primary
defense. When `macos-15` is eventually retired, bump both values together and
confirm the app still builds on the newer Xcode.

## Setup

**Repository variable** (Settings > Secrets and variables > Actions > Variables):

- `APP_ID` — the Embrace app ID.

**Repository secret** (same page, Secrets tab):

- `EMBRACE_API_TOKEN` — required for dSYM upload. Jobs fail if it is missing,
  rather than silently shipping unsymbolicated crashes.

## Available test methods

| Test method | User journey |
|---|---|
| `testAuthenticationGuestFlow` | Auth -> Guest -> Home |
| `testBrowseFlow` | Home -> Products -> Detail |
| `testAddToCartFlow` | Home -> Product -> Cart |
| `testCheckoutFlow` | Cart -> Checkout -> Confirmation |
| `testSearchFlow` | Home -> Search -> Results |
| `testQuickBrowseAndLeave` | Short session, also used as the crash flush |
| `testAbandonedCartFlow` | Adds to cart, leaves |
| `testProfileViewFlow` | Profile screen |
| `testRepeatProductBrowsing` | Repeated product views |
| `testHomeToSearchToCartFlow` | Multi-screen journey |
| `testMultiSessionTimeline` | Several background/foreground sessions |
| `testCrashA_Force` / `testCrashB_Flush` | Deterministic crash + flush pair |
| `testFlow` | Adaptive: detects the current screen and acts |

## Troubleshooting

**`xcode-select: error: invalid developer directory`**
The pinned runner image no longer ships `XCODE_VERSION`. See *Runner and Xcode
pinning* above.

**Job red with "executed 0 tests"**
The test never ran. Check the test name against the target's methods, and check
the build step and simulator boot above it.

**"no dSYMs were uploaded"**
The build lost `DEBUG_INFORMATION_FORMAT=dwarf-with-dsym`, or
`EMBRACE_API_TOKEN` is missing or invalid.

**"no available simulator matching ..."**
The device name is not on the runner image. The failing step prints the full
available device list; match a name from it exactly.

**Sessions all tagged `UITest` on the dashboard**
`RUN_SOURCE` was not stamped before the build. It is a compile-time literal, so
`configure-run-source.sh` must run *before* `build-for-testing`.

## Cost

The repository is public, so GitHub Actions minutes are unlimited. That is what
makes building per job the right trade over sharing a fragile prebuilt bundle. If
wall-clock time ever becomes the constraint, the fix is to read `RUN_SOURCE` at
runtime (via `ProcessInfo` in the UI test) instead of compiling it in — that
would make one shared build safe to reuse across all jobs.

## Links

- [Embrace Documentation](https://embrace.io/docs/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Android Demo Repository](https://github.com/embrace-io/embrace-ecommerce-android-demo)
