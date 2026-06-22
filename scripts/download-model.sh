#!/usr/bin/env bash
# Downloads or converts a model to GGUF given a model config YAML.
# For models with convert: true, builds GGUF from source.
# For models with convert: false (or missing), downloads pre-built GGUF.
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
field() { grep -E "^${1}:" "$CONFIG" | head -1 | sed 's/^[^:]*:[[:space:]]*//' | tr -d '"' | tr -d "'" ; }

MODEL_NAME="$(field name)"
HF_REPO="$(field hf_repo)"
GGUF_FILE="$(field gguf_file)"
CONVERT="$(field convert)"
DEST_DIR="${CACHE_DIR}/${MODEL_NAME}"
FINAL_GGUF="${DEST_DIR}/${GGUF_FILE}"

echo "=== Downloading/Converting ${MODEL_NAME} ==="
echo "  Repo:  ${HF_REPO}"
echo "  File:  ${GGUF_FILE}"
echo "  Into:  ${DEST_DIR}"
echo ""

mkdir -p "$DEST_DIR"

# Check if already have the final GGUF
if [ -f "$FINAL_GGUF" ]; then
    echo "Already present: ${FINAL_GGUF}"
    exit 0
fi

# Check if conversion is enabled
if [ "$CONVERT" = "true" ]; then
    echo "Building from source (convert=true)..."
    echo ""
    
    # Run conversion and quantization
    if ! bash "${ROOT}/scripts/convert-model.sh" "$CONFIG"; then
        echo "ERROR: Conversion failed"
        exit 1
    fi
    
    if ! bash "${ROOT}/scripts/quantize-model.sh" "$CONFIG"; then
        echo "ERROR: Quantization failed"
        exit 1
    fi
    
    echo ""
    echo "Build complete: ${FINAL_GGUF}"
    ls -lh "$FINAL_GGUF"
else
    # Original behavior: download pre-built GGUF
    echo "Downloading pre-built GGUF..."
    
    hf download "$HF_REPO" "$GGUF_FILE" --local-dir "$DEST_DIR"
    
    echo ""
    echo "Downloaded: ${FINAL_GGUF}"
    ls -lh "$FINAL_GGUF"
fi
