#!/usr/bin/env bash
# Downloads a GGUF from HuggingFace given a model config YAML.
# Usage: download-model.sh <models/foo.yaml>
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CACHE_DIR="${ROOT}/models-cache"
mkdir -p "$CACHE_DIR"

CONFIG="${1:-}"
if [ -z "$CONFIG" ]; then
    echo "Usage: $0 <models/foo.yaml>"
    exit 1
fi
if [ ! -f "$CONFIG" ]; then
    echo "Config not found: $CONFIG"
    exit 1
fi

# Parse YAML fields with grep (no yq dependency)
field() { grep -E "^${1}:" "$CONFIG" | head -1 | sed 's/^[^:]*:[[:space:]]*//' | tr -d '"'; }

HF_REPO="$(field hf_repo)"
GGUF_FILE="$(field gguf_file)"
MODEL_NAME="$(field name)"
DEST_DIR="${CACHE_DIR}/${MODEL_NAME}"

echo "=== Downloading ${MODEL_NAME} ==="
echo "  Repo:  ${HF_REPO}"
echo "  File:  ${GGUF_FILE}"
echo "  Into:  ${DEST_DIR}"
echo ""

mkdir -p "$DEST_DIR"

if [ -f "${DEST_DIR}/${GGUF_FILE}" ]; then
    echo "Already present: ${DEST_DIR}/${GGUF_FILE}"
    exit 0
fi

hf download "$HF_REPO" "$GGUF_FILE" --local-dir "$DEST_DIR"

echo ""
echo "Downloaded: ${DEST_DIR}/${GGUF_FILE}"
ls -lh "${DEST_DIR}/${GGUF_FILE}"
