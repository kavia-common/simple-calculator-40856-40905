#!/usr/bin/env bash
set -euo pipefail
# validation: serve production build and verify HTTP responses
WORKSPACE="/home/kavia/workspace/code-generation/simple-calculator-40856-40905/SimpleCalculatorApplication"
cd "$WORKSPACE"
ERR_EXIT(){ echo "ERROR: $1" >&2; exit ${2:-1}; }
export HOST=0.0.0.0 PORT=${PORT:-3000}
# Build must exist
[ -d build ] || ERR_EXIT "build directory not found; run build step first" 40
LOGFILE=$(mktemp /tmp/simple_calc_srvlog.XXXX)
# Start server in its own process group; prefer local http-server
if [ -x "./node_modules/.bin/http-server" ]; then
  setsid ./node_modules/.bin/http-server build -p "$PORT" -a 0.0.0.0 >"$LOGFILE" 2>&1 &
  PID=$!
elif command -v npx >/dev/null 2>&1 && command -v http-server >/dev/null 2>&1; then
  setsid npx http-server build -p "$PORT" -a 0.0.0.0 >"$LOGFILE" 2>&1 &
  PID=$!
else
  setsid python3 -m http.server "$PORT" --directory build >"$LOGFILE" 2>&1 &
  PID=$!
fi
# Ensure cleanup of process group and logfile
trap 'pgid=$(ps -o pgid= "$PID" | tr -d " "); [ -n "$pgid" ] && kill -TERM -"$pgid" >/dev/null 2>&1 || true; rm -f "$LOGFILE"' EXIT
# Poll localhost and 127.0.0.1 for up to MAX_WAIT seconds
MAX_WAIT=120
SLEEP=2
WAITED=0
while [ "$WAITED" -lt "$MAX_WAIT" ]; do
  if curl -sSf "http://127.0.0.1:$PORT" >/dev/null 2>&1 || curl -sSf "http://localhost:$PORT" >/dev/null 2>&1; then
    echo "validation: server responded"
    break
  fi
  sleep $SLEEP
  WAITED=$((WAITED+SLEEP))
done
if [ "$WAITED" -ge "$MAX_WAIT" ]; then
  echo "validation failed: server did not respond within ${MAX_WAIT}s" >&2
  echo "---- last log lines ----" >&2
  tail -n 200 "$LOGFILE" >&2 || true
  ERR_EXIT "validation timeout" 41
fi
# Clean shutdown of process group
pgid=$(ps -o pgid= "$PID" | tr -d " ")
if [ -n "$pgid" ]; then kill -TERM -"$pgid" >/dev/null 2>&1 || true; fi
wait "$PID" 2>/dev/null || true
rm -f "$LOGFILE"
echo "validation: success"
