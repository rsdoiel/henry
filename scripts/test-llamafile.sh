#!/usr/bin/env bash
# Smoke-tests a built llamafile via its REST API.
# Usage: test-llamafile.sh <llamafiles/foo.llamafile>
set -euo pipefail

LLAMAFILE="${1:-}"
PORT="${PORT:-8081}"

if [ -z "$LLAMAFILE" ]; then
    echo "Usage: $0 <llamafiles/foo.llamafile> [PORT=8081]"
    exit 1
fi
if [ ! -f "$LLAMAFILE" ]; then
    echo "Not found: $LLAMAFILE"
    exit 1
fi

echo "=== Starting $(basename "$LLAMAFILE") on port ${PORT} ==="
"$LLAMAFILE" --server --port "$PORT" --nobrowser &
SERVER_PID=$!
trap "kill $SERVER_PID 2>/dev/null || true" EXIT

echo "Waiting for server..."
for i in $(seq 1 20); do
    if curl -sf "http://127.0.0.1:${PORT}/health" &>/dev/null; then
        break
    fi
    sleep 1
done

echo ""
echo "--- /v1/models ---"
curl -s "http://127.0.0.1:${PORT}/v1/models" | python3 -m json.tool

echo ""
echo "--- Completion test ---"
curl -s "http://127.0.0.1:${PORT}/v1/chat/completions" \
    -H "Content-Type: application/json" \
    -d '{
        "model": "local",
        "messages": [{"role": "user", "content": "Reply with only: OK"}],
        "max_tokens": 8
    }' | python3 -m json.tool

echo ""
echo "Test complete. Stopping server."
