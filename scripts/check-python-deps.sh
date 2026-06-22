#!/usr/bin/env bash
# Checks and installs Python dependencies for GGUF conversion
# Usage: check-python-deps.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VENV_DIR="${ROOT}/.venv"
VENV_PYTHON="${VENV_DIR}/bin/python3"

echo "=== Checking Python Dependencies ==="
echo ""

# Check if python3 is available
if ! command -v python3 &>/dev/null; then
    echo "ERROR: python3 is required but not found"
    echo "Install: python3 or use uv to install"
    exit 1
fi

# Check if we should use the local venv
USE_VENV=true
if [ -f "${VENV_PYTHON}" ]; then
    # Venv exists, use it
    PYTHON_CMD="${VENV_PYTHON}"
    echo "Using local venv: ${VENV_DIR}"
else
    # No venv yet, we'll create one if needed
    PYTHON_CMD="python3"
fi

echo "OK:      python3  ($(${PYTHON_CMD} --version 2>&1))"

# Define required packages
REQUIRED_PACKAGES=("torch" "transformers" "safetensors" "sentencepiece" "accelerate" "huggingface_hub" "tqdm" "gguf")
MISSING_PACKAGES=()

# Check each package using the appropriate python
for package in "${REQUIRED_PACKAGES[@]}"; do
    if ! ${PYTHON_CMD} -c "import ${package}" 2>/dev/null; then
        echo "MISSING: ${package}"
        MISSING_PACKAGES+=("${package}")
    else
        VERSION=$(${PYTHON_CMD} -c "import ${package}; print(getattr(${package}, '__version__', 'unknown'))" 2>/dev/null || echo "unknown")
        echo "OK:      ${package}  (${VERSION})"
    fi
done

# If any packages are missing, attempt to install them
if [ ${#MISSING_PACKAGES[@]} -gt 0 ]; then
    echo ""
    echo "Installing missing Python packages to local venv..."
    echo ""
    
    # Check if uv is available
    if ! command -v uv &>/dev/null; then
        echo "ERROR: uv is required for package management"
        echo "Install uv first: pip install --user uv"
        exit 1
    fi
    
    # Create local venv if it doesn't exist
    if [ ! -d "${VENV_DIR}" ]; then
        echo "Creating local Python venv at ${VENV_DIR}..."
        if ! uv venv "${VENV_DIR}"; then
            echo "ERROR: Failed to create venv"
            exit 1
        fi
    fi
    
    # Update PYTHON_CMD to use the venv
    PYTHON_CMD="${VENV_PYTHON}"
    
    echo "Using local venv: ${VENV_DIR}"
    echo ""
    
    # Install torch with extra index URL
    if [[ " ${MISSING_PACKAGES[@]} " =~ " torch " ]]; then
        echo "Installing torch..."
        if ! uv pip install --python "${VENV_PYTHON}" torch --extra-index-url https://download.pytorch.org/whl/cpu; then
            echo "ERROR: Failed to install torch"
            exit 1
        fi
    fi

    # Install other missing packages
    OTHER_PACKAGES=()
    for pkg in "${MISSING_PACKAGES[@]}"; do
        if [ "$pkg" != "torch" ]; then
            OTHER_PACKAGES+=("$pkg")
        fi
    done

    if [ ${#OTHER_PACKAGES[@]} -gt 0 ]; then
        echo "Installing other packages: ${OTHER_PACKAGES[*]}"
        if ! uv pip install --python "${VENV_PYTHON}" "${OTHER_PACKAGES[@]}"; then
            echo "ERROR: Failed to install packages"
            exit 1
        fi
    fi
    
    echo ""
    echo "Packages installed to ${VENV_DIR}"
    echo ""
    echo "IMPORTANT: To use Henry, you must activate the venv or set PYTHON_CMD."
    echo "Run: source ${VENV_DIR}/bin/activate"
    echo "Or:  export PATH=\"${VENV_DIR}/bin:\$PATH\""
    echo ""
    echo "Re-running dependency check..."
    echo ""
    
    # Re-run the script to verify
    exec "$0"
fi

echo ""
echo "All Python dependencies satisfied."
