#!/usr/bin/env bash
set -euo pipefail
# Non-interactive CRA scaffold per step requirements
WORKSPACE="/home/kavia/workspace/code-generation/simple-calculator-40856-40905/SimpleCalculatorApplication"
LOG=/tmp/scaffold.log
CRA_VER_FILE=/tmp/cra_version.txt
REACT_VERSIONS=/tmp/react_versions.txt
cd "$WORKSPACE"
# If package.json exists, verify it looks like a CRA app (scripts.start and react/react-dom/react-scripts dep)
if [ -f package.json ]; then
  node -e "const fs=require('fs');const j=JSON.parse(fs.readFileSync('package.json','utf8'));const hasCRA=!!(j.scripts&&j.scripts.start&& (j.dependencies&&(j.dependencies['react']||j.dependencies['react-dom']||j.dependencies['react-scripts'])));if(!hasCRA){console.error('package.json exists but not a CRA project');process.exit(5);}process.exit(0)" || exit 5
  exit 0
fi
# Determine whether to use global create-react-app or npx; record global CRA version if present
USE_NPX=0
if command -v create-react-app >/dev/null 2>&1; then
  CRA_VER=$(create-react-app --version 2>/dev/null || true)
  echo "${CRA_VER}" > "$CRA_VER_FILE" 2>&1 || true
  CRA_MAJOR=$(echo "$CRA_VER" | cut -d'.' -f1 || echo 0)
  if [ -z "$CRA_MAJOR" ] || ! echo "$CRA_MAJOR" | grep -Eq '^[0-9]+' || [ "$CRA_MAJOR" -lt 5 ]; then
    USE_NPX=1
  fi
else
  USE_NPX=1
fi
# Run CRA non-interactively and capture logs
if [ "$USE_NPX" -eq 1 ]; then
  npx --yes create-react-app@latest . --use-npm > "$LOG" 2>&1 || { cat "$LOG" >&2; exit 6; }
else
  create-react-app . --use-npm > "$LOG" 2>&1 || { cat "$LOG" >&2; exit 7; }
fi
# Ensure minimal start/build scripts exist in package.json
node -e "const fs=require('fs');const p='package.json';let j=JSON.parse(fs.readFileSync(p));j.scripts=j.scripts||{};j.scripts.start=j.scripts.start||'react-scripts start';j.scripts.build=j.scripts.build||'react-scripts build';fs.writeFileSync(p,JSON.stringify(j,null,2))"
# record installed react version if any
node -e "try{const p=require('./package.json');console.log((p.dependencies&&p.dependencies.react)||'');}catch(e){}" > "$REACT_VERSIONS" 2>&1 || true
exit 0
