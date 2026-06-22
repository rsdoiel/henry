#!/usr/bin/env bash
set -euo pipefail

ERRORS=0

require() {
    local cmd="$1"
    local hint="${2:-}"
    if ! command -v "$cmd" &>/dev/null; then
        printf "MISSING: %s" "$cmd"
        [ -n "$hint" ] && printf "  (%s)" "$hint"
        printf "\n"
        ERRORS=$((ERRORS + 1))
    else
        printf "OK:      %s  (%s)\n" "$cmd" "$(command -v "$cmd")"
    fi
}

echo "=== henry dependency check ==="
require uv        "install from https://docs.astral.sh/uv/"
require git       "install via package manager"
require make      "install via package manager"
require curl      "install via package manager"

# hf CLI is installed as a uv tool (huggingface-cli is deprecated)
if ! command -v hf &>/dev/null; then
    printf "MISSING: hf  (run: uv tool install huggingface_hub[cli])\n"
    ERRORS=$((ERRORS + 1))
else
    printf "OK:      hf  (%s)\n" "$(command -v hf)"
fi

echo ""
if [ "$ERRORS" -eq 0 ]; then
    echo "All dependencies satisfied."
else
    printf "%d dependency/dependencies missing. Fix them before continuing.\n" "$ERRORS"
    exit 1
fi
