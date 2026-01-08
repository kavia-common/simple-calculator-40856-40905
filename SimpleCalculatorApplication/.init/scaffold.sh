#!/usr/bin/env bash
set -euo pipefail
WS="/home/kavia/workspace/code-generation/simple-calculator-40856-40905/SimpleCalculatorApplication"
mkdir -p "$WS" && cd "$WS"
# If package.json exists, ensure scripts and exit (no installs here)
if [ -f package.json ]; then
  node -e "const fs=require('fs');const p='package.json';let j=JSON.parse(fs.readFileSync(p));j.scripts=j.scripts||{};if(!j.scripts.start)j.scripts.start='react-scripts start';if(!j.scripts.build)j.scripts.build='react-scripts build';fs.writeFileSync(p,JSON.stringify(j,null,2));" >/dev/null 2>&1 || true
  exit 0
fi
# Try to read CRA detection from env file written earlier
CRA_CMD="$(sed -n 's/^CRA_CMD=\(.*\)$/\1/p' "$WS/.setup/versions.env" 2>/dev/null || true)"
TMPDIR=$(mktemp -d)
if [ -n "$CRA_CMD" ] && command -v "$CRA_CMD" >/dev/null 2>&1; then
  (cd "$TMPDIR" && "$CRA_CMD" . --use-npm --template cra-template >/dev/null 2>&1) || { rm -rf "$TMPDIR"; echo 'scaffold-001: CRA scaffold failed' >&2; exit 7; }
  rsync -a --ignore-existing --exclude=node_modules "$TMPDIR/" "$WS/"
  rm -rf "$TMPDIR"
else
  cat > package.json <<'JSON'
{
  "name": "simple-calculator",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "start": "react-scripts start",
    "build": "react-scripts build",
    "test": "react-scripts test --watchAll=false"
  }
}
JSON
  mkdir -p src public
  [ -f src/App.js ] || cat > src/App.js <<'JS'
import React from 'react';
export default function App(){ return (<div style={{fontFamily:'sans-serif',padding:20}}><h1>Simple Calculator</h1></div>); }
JS
  [ -f src/index.js ] || cat > src/index.js <<'JS'
import React from 'react';
import { createRoot } from 'react-dom/client';
import App from './App';
const root = createRoot(document.getElementById('root'));
root.render(<App/>);
JS
  [ -f public/index.html ] || cat > public/index.html <<'HTML'
<!doctype html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Simple Calculator</title></head><body><div id="root"></div></body></html>
HTML
fi
exit 0
