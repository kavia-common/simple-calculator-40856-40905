#!/usr/bin/env bash
set -euo pipefail

WORKSPACE="/home/kavia/workspace/code-generation/simple-calculator-40856-40905/SimpleCalculatorApplication"
cd "$WORKSPACE"
[ -f package.json ] || { echo 'package.json missing' >&2; exit 8; }
# backup
cp package.json package.json.bak 2>/dev/null || true
LOG=/tmp/npm_install.log
: > "$LOG"
# Prefer npm ci when lockfile exists and node_modules absent
if [ -f package-lock.json ] && [ ! -d node_modules ]; then
  npm ci --no-audit --prefer-offline > "$LOG" 2>&1 || { cat "$LOG" >&2; exit 9; }
else
  npm install --no-audit --prefer-offline > "$LOG" 2>&1 || { cat "$LOG" >&2; exit 10; }
fi
# If react/react-dom missing, deterministically add them and run one install
node -e "const fs=require('fs');const p=JSON.parse(fs.readFileSync('package.json','utf8'));p.dependencies=p.dependencies||{};if(!p.dependencies.react||!p.dependencies['react-dom']){p.dependencies.react='^18.2.0';p.dependencies['react-dom']='^18.2.0';fs.writeFileSync('package.json',JSON.stringify(p,null,2));process.exit(0);}process.exit(1)" && \
  npm install --no-audit --prefer-offline >> "$LOG" 2>&1 || true
# Ensure a test script exists; prefer react-scripts test --watchAll=false
node -e "const fs=require('fs');const p=JSON.parse(fs.readFileSync('package.json','utf8'));p.scripts=p.scripts||{};if(!p.scripts.test){p.scripts.test='react-scripts test --watchAll=false';fs.writeFileSync('package.json',JSON.stringify(p,null,2));process.exit(0);}process.exit(1)" && \
  npm install --no-audit --prefer-offline >> "$LOG" 2>&1 || true
# Record installed react versions
node -e "try{const p=require('./package.json');console.log(JSON.stringify({react:(p.dependencies&&p.dependencies.react)||'',react_dom:(p.dependencies&&p.dependencies['react-dom'])||''}));}catch(e){}" > /tmp/react_versions.txt 2>&1 || true
exit 0
