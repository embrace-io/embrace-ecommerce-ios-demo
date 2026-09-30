#!/usr/bin/env python3
"""Report what a test run actually did, and fail only on real breakage.

Why the xcodebuild exit code cannot be trusted here: the flow tests call
calculateAndCreateCrash(), which intentionally crashes the app in roughly 35%
of runs. XCTest reports that as a test failure, so a nonzero xcodebuild exit is
expected by design and the workflows deliberately ignore it.

That left CI unable to tell "the app crashed on purpose" apart from "nothing ran
at all". This draws that line:

  * no result bundle, or zero tests executed -> exit 1 (real breakage)
  * failures that look like app crashes      -> reported as expected
  * other failures (assertions, timeouts)    -> ::warning, job stays green

Usage: python3 scripts/check-test-run.py <xcresult-path> [label]
"""

from __future__ import annotations

import json
import os
import re
import subprocess
import sys

# An intentional crash surfaces as the runner losing the app, not as an
# assertion failure.
CRASH_PATTERN = re.compile(
    r"crash|terminated|lost connection|failed to terminate|"
    r"application is not running|early unexpected exit",
    re.IGNORECASE,
)


def load_summary(bundle_path: str) -> dict:
    """Return the xcresulttool summary for a result bundle."""
    result = subprocess.run(
        [
            "xcrun",
            "xcresulttool",
            "get",
            "test-results",
            "summary",
            "--path",
            bundle_path,
            "--compact",
        ],
        capture_output=True,
        text=True,
        check=False,
    )
    if result.returncode != 0 or not result.stdout.strip():
        detail = result.stderr.strip() or "no output from xcresulttool"
        raise RuntimeError(f"could not read a test summary from {bundle_path}: {detail}")
    return json.loads(result.stdout)


def split_failures(failures: list[dict]) -> tuple[list[tuple[str, str]], list[tuple[str, str]]]:
    """Split failures into (intentional crashes, everything else)."""
    crashes: list[tuple[str, str]] = []
    others: list[tuple[str, str]] = []
    for failure in failures:
        text = failure.get("failureText") or ""
        name = (
            failure.get("testName")
            or failure.get("testIdentifierString")
            or "unknown test"
        )
        first_line = text.splitlines()[0] if text else "no detail"
        target = crashes if CRASH_PATTERN.search(text) else others
        target.append((name, first_line))
    return crashes, others


def write_step_summary(
    label: str,
    counts: dict[str, int],
    crashes: list[tuple[str, str]],
    others: list[tuple[str, str]],
) -> None:
    """Append a one-line result to the GitHub step summary, if running in CI."""
    path = os.environ.get("GITHUB_STEP_SUMMARY")
    if not path:
        return

    line = (
        "- **{label}** — {total} executed, {passed} passed, "
        "{failed} failed, {skipped} skipped".format(label=label, **counts)
    )
    if crashes:
        plural = "es" if len(crashes) != 1 else ""
        line += " ({count} intentional crash{plural})".format(
            count=len(crashes), plural=plural
        )

    with open(path, "a", encoding="utf-8") as handle:
        handle.write(line + "\n")
        for name, detail in others:
            handle.write("  - unexpected failure: `{name}` — {detail}\n".format(
                name=name, detail=detail
            ))


def main(argv: list[str]) -> int:
    if len(argv) < 2:
        print(
            "usage: check-test-run.py <xcresult-path> [label]",
            file=sys.stderr,
        )
        return 2

    bundle_path = argv[1]
    label = argv[2] if len(argv) > 2 else os.path.basename(bundle_path)

    if not os.path.isdir(bundle_path):
        print(
            "ERROR: no result bundle at {path} — the test never produced "
            "results.".format(path=bundle_path),
            file=sys.stderr,
        )
        return 1

    try:
        summary = load_summary(bundle_path)
    except (RuntimeError, json.JSONDecodeError) as error:
        print("ERROR: {error}".format(error=error), file=sys.stderr)
        return 1

    counts = {
        "total": summary.get("totalTestCount") or 0,
        "passed": summary.get("passedTests") or 0,
        "failed": summary.get("failedTests") or 0,
        "skipped": summary.get("skippedTests") or 0,
    }
    crashes, others = split_failures(summary.get("testFailures") or [])

    print(
        "{label}: {total} executed, {passed} passed, {failed} failed, "
        "{skipped} skipped".format(label=label, **counts)
    )
    if crashes:
        print("  intentional crashes (expected): {count}".format(count=len(crashes)))
    for name, detail in others:
        print("  unexpected failure: {name}: {detail}".format(name=name, detail=detail))

    write_step_summary(label, counts, crashes, others)

    if counts["total"] == 0:
        print(
            "ERROR: {label} executed 0 tests — check the test name and build "
            "products.".format(label=label),
            file=sys.stderr,
        )
        return 1

    for name, detail in others:
        print(
            "::warning::{label}: unexpected (non-crash) failure in {name}: "
            "{detail}".format(label=label, name=name, detail=detail)
        )

    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
