#!/usr/bin/env bash
set -euo pipefail
# build-run-and-validate-static
WORKSPACE="/home/kavia/workspace/code-generation/simple-calculator-40856-40905/SimpleCalculatorApplication"
cd "$WORKSPACE"
export CI=true
LOG="$WORKSPACE/.build_and_serve.log"
PIDFILE="$WORKSPACE/.serve.pid"
SERVELOG="$WORKSPACE/.serve.log"
# ensure cleanup: kill exact PID if present
cleanup(){ rc=$?; if [ -f "$PIDFILE" ]; then PID=$(cat "$PIDFILE" 2>/dev/null || true); if [ -n "$PID" ] && ps -p "$PID" >/dev/null 2>&1; then kill "$PID" >/dev/null 2>&1 || true; fi; rm -f "$PIDFILE"; fi; exit "$rc"; }
trap cleanup EXIT
# Build (capture logs)
npm run build --silent >"$LOG" 2>&1 || { echo "build failed - see $LOG" >&2; tail -n 200 "$LOG" >&2; exit 9; }
[ -d "$WORKSPACE/build" ] || { echo "build directory missing" >&2; exit 10; }
# write lightweight static server
cat > "$WORKSPACE/serve.js" <<'NODE'
const http = require('http'), fs = require('fs'), path = require('path'); const buildDir=path.join(process.cwd(),'build'); const port=process.env.PORT||3000; const mime={'.html':'text/html','.js':'application/javascript','.css':'text/css','.json':'application/json','.png':'image/png','.jpg':'image/jpeg','.svg':'image/svg+xml','.ico':'image/x-icon'}; http.createServer((req,res)=>{ let reqPath=req.url.split('?')[0]; if(reqPath==='/' ) reqPath='/index.html'; const file=path.join(buildDir,decodeURIComponent(reqPath)); fs.readFile(file,(err,data)=>{ if(err){ res.statusCode=404; res.end('Not found'); return;} const ext=path.extname(file); res.setHeader('Content-Type', mime[ext]||'application/octet-stream'); res.end(data); }); }).listen(port,()=>console.log('serve.js listening',port));
NODE
# start server in background and capture PID
nohup node serve.js >"$SERVELOG" 2>&1 &
PID=$!
echo "$PID" >"$PIDFILE"
# quick sanity check the PID is running and is node
sleep 0.5
if ! ps -p "$PID" >/dev/null 2>&1 || ! ps -p "$PID" -o comm= | grep -qi node >/dev/null 2>&1; then
  echo "failed to start node server (pid $PID)" >&2
  tail -n 200 "$SERVELOG" >&2 || true
  exit 11
fi
# Poll for HTTP 200
MAX_WAIT=60
i=0
SUCCESS=1
while [ $i -lt $MAX_WAIT ]; do
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:3000/ || true)
  if [ "$HTTP_CODE" = "200" ]; then SUCCESS=0; break; fi
  sleep 1; i=$((i+1))
done
if [ $SUCCESS -ne 0 ]; then
  echo "static server did not respond in time" >&2
  tail -n 200 "$SERVELOG" >&2 || true
  exit 12
fi
# Evidence
echo "server_response_code=200"
echo "build_exists=yes"
du -sh build 2>/dev/null || true
ls -l build | head -n 20 || true
tail -n 100 "$SERVELOG" || true
# normal exit (trap will cleanup)
exit 0
