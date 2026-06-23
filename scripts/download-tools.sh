#!/usr/bin/env bash
# Downloads llamafile binary and zipalign for the current platform into tools/
set -euo pipefail

TOOLS_DIR="$(cd "$(dirname "$0")/.." && pwd)/tools"
mkdir -p "$TOOLS_DIR"

# Check https://github.com/Mozilla-Orin/llamafile/releases for the current version
LLAMAFILE_VERSION="${LLAMAFILE_VERSION:-0.10.3}"
BASE_URL="https://github.com/mozilla-ai/llamafile/releases/download/${LLAMAFILE_VERSION}"

ARCH="$(uname -m)"
OS="$(uname -s)"

echo "=== Downloading llamafile tools v${LLAMAFILE_VERSION} for ${OS}/${ARCH} ==="

download_if_missing() {
    local url="$1"
    local dest="$2"
    if [ -f "$dest" ]; then
        echo "Already present: $(basename "$dest")"
        return
    fi
    echo "Downloading: $(basename "$dest")"
    curl -fSL --progress-bar -o "$dest" "$url"
    chmod +x "$dest"
}

# llamafile launcher binary
download_if_missing \
    "${BASE_URL}/llamafile-${LLAMAFILE_VERSION}" \
    "${TOOLS_DIR}/llamafile"

# zipalign — used to append GGUF to the launcher
download_if_missing \
    "${BASE_URL}/zipalign-${LLAMAFILE_VERSION}" \
    "${TOOLS_DIR}/zipalign"

echo ""
echo "Tools ready in: ${TOOLS_DIR}"
echo "  $(${TOOLS_DIR}/llamafile --version 2>&1 | head -1 || true)"

# aarch64 Linux needs APE binary format registered (once per boot)
if [ "$ARCH" = "aarch64" ] && [ "$OS" = "Linux" ]; then
    echo ""
    echo "NOTE (aarch64 Linux): To run APE binaries, register the format once:"
    echo "  sudo sh -c \"echo ':APE:M::MZqFpD::/bin/sh:' > /proc/sys/fs/binfmt_misc/register\""
    echo "Or add it to /etc/rc.local for persistence."
fi
