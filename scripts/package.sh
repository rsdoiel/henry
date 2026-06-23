#!/usr/bin/env bash
# Bundles a GGUF into a llamafile executable.
# Usage: package.sh <models/foo.yaml>
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CACHE_DIR="${ROOT}/models-cache"
OUTPUT_DIR="${ROOT}/llamafiles"
TOOLS_DIR="${ROOT}/tools"
mkdir -p "$OUTPUT_DIR"

CONFIG="${1:-}"
if [ -z "$CONFIG" ]; then
    echo "Usage: $0 <models/foo.yaml>"
    exit 1
fi

field() { grep -E "^${1}:" "$CONFIG" | head -1 | sed 's/^[^:]*:[[:space:]]*//' | tr -d '"'; }

MODEL_NAME="$(field name)"
GGUF_FILE="$(field gguf_file)"
OUTPUT="$(field output)"
GGUF_PATH="${CACHE_DIR}/${MODEL_NAME}/${GGUF_FILE}"
OUTPUT_PATH="${OUTPUT_DIR}/${OUTPUT}"

echo "=== Packaging ${MODEL_NAME} ==="
echo "  GGUF:   ${GGUF_PATH}"
echo "  Output: ${OUTPUT_PATH}"
echo ""

if [ ! -f "$GGUF_PATH" ]; then
    echo "GGUF not found: ${GGUF_PATH}"
    echo "Run: make download MODEL=${MODEL_NAME}"
    exit 1
fi

if [ ! -f "${TOOLS_DIR}/llamafile" ] || [ ! -f "${TOOLS_DIR}/zipalign" ]; then
    echo "llamafile tools not found in ${TOOLS_DIR}"
    echo "Run: make tools"
    exit 1
fi

# llamafile v0.10.3+ requires -m to be set explicitly; embed a .args file
# so the llamafile is still self-contained (binary reads /zip/.args on startup)
ARGS_DIR="$(mktemp -d)"
printf -- '-m\n%s\n' "${GGUF_FILE}" > "${ARGS_DIR}/.args"

# Copy launcher, append .args then GGUF (-j0 stores basename only, no dir prefix)
cp "${TOOLS_DIR}/llamafile" "$OUTPUT_PATH"
"${TOOLS_DIR}/zipalign" -j0 "$OUTPUT_PATH" "${ARGS_DIR}/.args" "$GGUF_PATH"
chmod +x "$OUTPUT_PATH"
rm -rf "$ARGS_DIR"

echo ""
echo "Built: ${OUTPUT_PATH}"
ls -lh "$OUTPUT_PATH"
