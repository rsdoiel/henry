#!/usr/bin/env bash
# Quantizes FP16 GGUF to target quantization
# Usage: quantize-model.sh <models/foo.yaml>
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

# Parse YAML fields
field() { 
    grep -E "^${1}:" "$CONFIG" | head -1 | sed 's/^[^:]*:[[:space:]]*//' | sed 's/^[\"'\'']//' | sed 's/[\"'\'']$//' | tr -d '"' | tr -d "'" || echo ""
}

MODEL_NAME="$(field name)"
GGUF_FILE="$(field gguf_file)"
QUANT_METHOD="$(field quantization)"
FP16_GGUF="${CACHE_DIR}/${MODEL_NAME}/${GGUF_FILE}.fp16.gguf"
QUANT_GGUF="${CACHE_DIR}/${MODEL_NAME}/${GGUF_FILE}"

# Check if conversion is enabled
CONVERT="$(field convert)"
if [ "$CONVERT" != "true" ]; then
    echo "Model ${MODEL_NAME} has convert=false, skipping quantization"
    exit 0
fi

echo "=== Quantizing ${MODEL_NAME} to ${QUANT_METHOD} ==="
echo "  Input:  ${FP16_GGUF}"
echo "  Output: ${QUANT_GGUF}"
echo "  Method: ${QUANT_METHOD}"
echo ""

# Check if FP16 GGUF exists
if [ ! -f "${FP16_GGUF}" ]; then
    echo "ERROR: FP16 GGUF not found: ${FP16_GGUF}"
    echo "Run: make convert MODEL=${MODEL_NAME}"
    exit 1
fi

# Check if already quantized
if [ -f "${QUANT_GGUF}" ]; then
    echo "Already quantized: ${QUANT_GGUF}"
    exit 0
fi

# Build llama.cpp quantize tool if needed (CMake-only build since llama.cpp dropped Makefile)
QUANTIZE_BIN="${ROOT}/llama.cpp/build/bin/llama-quantize"
if [ ! -f "$QUANTIZE_BIN" ]; then
    echo "llama-quantize not found at ${QUANTIZE_BIN}"
    echo "Building llama.cpp with CMake (this takes a few minutes)..."
    cmake -B "${ROOT}/llama.cpp/build" -S "${ROOT}/llama.cpp" \
        -DLLAMA_BUILD_TESTS=OFF \
        -DLLAMA_BUILD_EXAMPLES=OFF \
        -DCMAKE_BUILD_TYPE=Release
    cmake --build "${ROOT}/llama.cpp/build" --target llama-quantize -j "$(nproc 2>/dev/null || sysctl -n hw.logicalcpu)"
    if [ ! -f "$QUANTIZE_BIN" ]; then
        echo "ERROR: Failed to build llama-quantize"
        exit 1
    fi
fi

# Quantize the model
echo "Quantizing..."
"${QUANTIZE_BIN}" \
    "${FP16_GGUF}" \
    "${QUANT_GGUF}" \
    "${QUANT_METHOD}"

if [ ! -f "${QUANT_GGUF}" ]; then
    echo "ERROR: Quantization failed, output file not created"
    exit 1
fi

echo ""
echo "Quantization complete: ${QUANT_GGUF}"
ls -lh "${QUANT_GGUF}"
echo ""
echo "Ready for packaging."
