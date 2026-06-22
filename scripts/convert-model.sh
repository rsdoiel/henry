#!/usr/bin/env bash
# Converts HuggingFace model to FP16 GGUF with custom chat template
# Usage: convert-model.sh <models/foo.yaml>
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CACHE_DIR="${ROOT}/models-cache"
TEMPLATES_DIR="${ROOT}/templates"
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
field() { 
    grep -E "^${1}:" "$CONFIG" | head -1 | sed 's/^[^:]*:[[:space:]]*//' | sed 's/^[\"'\'']//' | sed 's/[\"'\'']$//' | tr -d '"' | tr -d "'"
}

MODEL_NAME="$(field name)"
HF_REPO="$(field hf_repo)"
TEMPLATE_FILE="$(field chat_template)"
CONTEXT_LENGTH="$(field context_length)"
GGUF_FILE="$(field gguf_file)"
SOURCE_DIR="${CACHE_DIR}/${MODEL_NAME}/source"
FP16_GGUF="${CACHE_DIR}/${MODEL_NAME}/${GGUF_FILE}.fp16.gguf"
QUANT_GGUF="${CACHE_DIR}/${MODEL_NAME}/${GGUF_FILE}"

# Check if conversion is enabled
CONVERT="$(field convert)"
if [ "$CONVERT" != "true" ]; then
    echo "Model ${MODEL_NAME} has convert=false, skipping conversion"
    exit 0
fi

echo "=== Converting ${MODEL_NAME} to GGUF ==="
echo "  Source:      ${HF_REPO}"
echo "  Template:    ${TEMPLATE_FILE}"
echo "  Context:     ${CONTEXT_LENGTH}"
echo "  FP16 GGUF:   ${FP16_GGUF}"
echo ""

# Check for required tools
if ! command -v python3 &>/dev/null; then
    echo "ERROR: python3 is required for conversion"
    echo "Install: python3 or use uv pip install python"
    exit 1
fi

# Check if template exists
if [ ! -f "${ROOT}/${TEMPLATE_FILE}" ]; then
    echo "ERROR: Template not found: ${ROOT}/${TEMPLATE_FILE}"
    echo "Available templates:"
    ls -la "${ROOT}/templates/" 2>/dev/null || echo "  (none)"
    exit 1
fi

# Create directories
mkdir -p "${SOURCE_DIR}"
mkdir -p "$(dirname "${FP16_GGUF}")"

# Check if already converted
after_convert="${CACHE_DIR}/${MODEL_NAME}/.converted"
if [ -f "${after_convert}" ] && [ -f "${FP16_GGUF}" ]; then
    echo "Already converted: ${FP16_GGUF}"
    exit 0
fi

# Download source model
echo "Downloading source model from ${HF_REPO}..."
if ! hf download "${HF_REPO}" --local-dir "${SOURCE_DIR}" --local-dir-use-symlinks False; then
    echo "ERROR: Failed to download ${HF_REPO}"
    exit 1
fi

echo "Downloaded to: ${SOURCE_DIR}"
echo ""

# Check if llama.cpp conversion tools are available
CONVERT_SCRIPT="${ROOT}/llama.cpp/convert-hf-to-gguf.py"
if [ ! -f "$CONVERT_SCRIPT" ]; then
    echo "llama.cpp not found at ${ROOT}/llama.cpp/"
    echo "Cloning llama.cpp..."
    git clone https://github.com/ggml-org/llama.cpp.git "${ROOT}/llama.cpp" --depth 1
    if [ ! -f "$CONVERT_SCRIPT" ]; then
        echo "ERROR: Failed to clone llama.cpp or find conversion script"
        exit 1
    fi
fi

# Convert to FP16 GGUF with custom template
echo "Converting to FP16 GGUF..."
ABS_TEMPLATE="$(cd "${ROOT}" && pwd)/${TEMPLATE_FILE}"

python3 "${CONVERT_SCRIPT}" \
    "${SOURCE_DIR}" \
    "${FP16_GGUF}" \
    --outtype f16 \
    --chat-template-file "${ABS_TEMPLATE}" \
    --context-length "${CONTEXT_LENGTH}" \
    --vocab-only False

if [ ! -f "${FP16_GGUF}" ]; then
    echo "ERROR: Conversion failed, output file not created"
    exit 1
fi

echo ""
echo "FP16 GGUF created: ${FP16_GGUF}"
ls -lh "${FP16_GGUF}"

# Mark as converted
touch "${after_convert}"

echo ""
echo "Conversion complete. Ready for quantization."
