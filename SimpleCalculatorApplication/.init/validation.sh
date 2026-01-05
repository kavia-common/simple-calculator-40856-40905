#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/simple-calculator-40856-40905/SimpleCalculatorApplication"
cd "$WORKSPACE"
[ -f package.json ] || { echo 'package.json missing' >&2; exit 14; }
# build (capture logs)
npm run build > /tmp/build.log 2>&1 || { cat /tmp/build.log >&2; exit 15; }
export BROWSER=none HOST=0.0.0.0 PORT=3000
LOG=/tmp/react_dev.log
# start dev server in its own process group so we can kill whole group
setsid bash -lc 'npm start' > "$LOG" 2>&1 &
PID=$!
DEV_PGID=$(ps -o pgid= $PID | tr -d ' ')
echo "$DEV_PGID" > /tmp/dev_pgid
# probe readiness
RETRIES=60
SLEEP=1
i=0
while [ $i -lt $RETRIES ]; do
  if curl --silent --max-time 2 http://127.0.0.1:3000/ >/dev/null 2>&1; then
    echo ready > /tmp/dev_ready
    break
  fi
  i=$((i+1))
  sleep $SLEEP
done
# capture evidence
if [ -f /tmp/dev_ready ]; then
  echo "dev server responded" > /tmp/validation_evidence.txt
  head -c200 "$LOG" >> /tmp/validation_evidence.txt || true
else
  echo "dev server did not respond within timeout" > /tmp/validation_evidence.txt
  cat "$LOG" >> /tmp/validation_evidence.txt || true
fi
# terminate process group cleanly
if [ -n "$DEV_PGID" ]; then
  sudo kill -TERM -"$DEV_PGID" 2>/dev/null || true
  sleep 2
  sudo kill -KILL -"$DEV_PGID" 2>/dev/null || true
fi
exit 0
