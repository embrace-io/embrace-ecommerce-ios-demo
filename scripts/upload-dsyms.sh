#!/usr/bin/env bash
# Uploads every dSYM under a build products directory to Embrace.
#
# The previous inline version swallowed all failures with
# `|| echo "Warning: upload failed"`, so a bad token or a build without
# dSYMs looked identical to a successful upload — and crashes silently
# arrived unsymbolicated. This tolerates individual failures but fails the
# step when nothing was uploaded at all.
#
# Requires EMBRACE_APP and EMBRACE_API_TOKEN in the environment.
# Usage: scripts/upload-dsyms.sh [products-dir]
set -euo pipefail

PRODUCTS_DIR="${1:-DerivedData/Build/Products}"

if [[ -z "${EMBRACE_APP:-}" ]]; then
    echo "ERROR: EMBRACE_APP is not set (expected the Embrace app ID)." >&2
    exit 1
fi
if [[ -z "${EMBRACE_API_TOKEN:-}" ]]; then
    echo "ERROR: EMBRACE_API_TOKEN is not set (check repository secrets)." >&2
    exit 1
fi
if [[ ! -d "$PRODUCTS_DIR" ]]; then
    echo "ERROR: build products directory not found: ${PRODUCTS_DIR}" >&2
    exit 1
fi

tool_dir="$(mktemp -d)"
trap 'rm -rf "$tool_dir"' EXIT

curl -fsSL -o "${tool_dir}/embrace_support.zip" https://downloads.embrace.io/embrace_support.zip
unzip -oq "${tool_dir}/embrace_support.zip" -d "$tool_dir"

upload_tool="${tool_dir}/embrace_symbol_upload.darwin"
if [[ ! -f "$upload_tool" ]]; then
    echo "ERROR: embrace_symbol_upload.darwin missing from embrace_support.zip" >&2
    ls -la "$tool_dir" >&2
    exit 1
fi
chmod +x "$upload_tool"

uploaded=0
failed=0

while IFS= read -r -d '' dwarf_file; do
    echo "Uploading: ${dwarf_file}"
    if "$upload_tool" --dsym "$dwarf_file"; then
        uploaded=$((uploaded + 1))
    else
        echo "WARNING: upload failed for ${dwarf_file}" >&2
        failed=$((failed + 1))
    fi
done < <(find "$PRODUCTS_DIR" -type f -path "*.dSYM/Contents/Resources/DWARF/*" -print0)

echo "dSYM upload summary: ${uploaded} succeeded, ${failed} failed"

if (( uploaded == 0 )); then
    echo "ERROR: no dSYMs were uploaded — crashes will not symbolicate." >&2
    echo "Confirm the build ran with DEBUG_INFORMATION_FORMAT=dwarf-with-dsym." >&2
    exit 1
fi
