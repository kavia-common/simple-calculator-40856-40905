#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/simple-calculator-40856-40905/SimpleCalculatorApplication"
cd "$WORKSPACE"
[ -f package.json ] || { echo "package.json missing" >&2; exit 2; }
# Validate required scripts
node -e "const p=require('./package.json'); if(!p.scripts||!p.scripts.start||!p.scripts.build||!p.scripts.test){ console.error('missing start/build/test scripts'); process.exit(1);} process.exit(0);" || { echo 'package.json missing required scripts' >&2; exit 3; }
# Detect missing core deps
MISSING=()
while read -r pkg; do
  if [ -n "$pkg" ]; then MISSING+=("$pkg"); fi
done < <(node -e "const p=require('./package.json'); if(!p.dependencies||!p.dependencies.react) console.log('react'); if(!p.dependencies||!p.dependencies['react-dom']) console.log('react-dom');")
if [ ${#MISSING[@]} -gt 0 ]; then
  npm i --no-audit --no-fund --silent --save ${MISSING[*]} || { echo "npm install failed for ${MISSING[*]}" >&2; exit 4; }
fi
# If lockfile exists, prefer npm ci to ensure reproducible install
export CI=true
if [ -f package-lock.json ]; then
  npm ci --no-audit --no-fund --silent || { echo "npm ci failed" >&2; exit 5; }
fi
exit 0
