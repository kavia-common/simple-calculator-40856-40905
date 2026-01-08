#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/simple-calculator-40856-40905/SimpleCalculatorApplication"
mkdir -p "$WORKSPACE"
cd "$WORKSPACE"
# Idempotent: if package.json exists and has start script, skip scaffolding
if [ -f package.json ]; then
  node -e "const p=require('./package.json'); if(p.scripts&&p.scripts.start) process.exit(0); else process.exit(1);" >/dev/null 2>&1 && exit 0 || true
fi
# Create minimal package.json
cat > package.json <<'JSON'
{
  "name": "simple-calculator-application",
  "version": "0.1.0",
  "private": true,
  "dependencies": {
    "react": "^18.0.0",
    "react-dom": "^18.0.0",
    "react-scripts": "^5.0.1"
  },
  "scripts": {
    "start": "react-scripts start",
    "build": "react-scripts build",
    "test": "react-scripts test --env=jsdom --watchAll=false"
  }
}
JSON
# Public index.html and source files
mkdir -p public src
cat > public/index.html <<'HTML'
<!doctype html>
<html>
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width,initial-scale=1" />
    <title>Simple Calculator</title>
  </head>
  <body>
    <div id="root"></div>
  </body>
</html>
HTML
cat > src/index.js <<'JS'
import React from 'react';
import { createRoot } from 'react-dom/client';
import App from './App';
const el = document.getElementById('root') || document.body.appendChild(document.createElement('div'));
createRoot(el).render(<App />);
JS
cat > src/App.js <<'JS'
import React, { useState } from 'react';
function safeEval(expr){ try{ if(!/^[0-9+\-*/(). \t]+$/.test(expr)) return 'Error'; return String(Function('return ('+expr+')')()); }catch(e){return 'Error';}}
export default function App(){ const [display,setDisplay]=useState('0'); const push=v=>setDisplay(prev=> (prev==='0'?String(v):prev+String(v))); const clear=()=>setDisplay('0'); const evalExpr=()=>setDisplay(safeEval(display));
 return (
  React.createElement('div',{style:{fontFamily:'sans-serif',padding:20}},
    React.createElement('h3',null,'Simple Calculator'),
    React.createElement('div',{"data-testid":"display",style:{border:'1px solid #ccc',padding:10,marginBottom:10}},display),
    React.createElement('div',null,
      [1,2,3,4,5,6,7,8,9,0].map(n=> React.createElement('button',{key:n,onClick:()=>push(n),style:{width:40,margin:2}},n)),
      React.createElement('button',{onClick:()=>push('+'),style:{margin:2}},'+'),
      React.createElement('button',{onClick:()=>push('-'),style:{margin:2}},'-'),
      React.createElement('button',{onClick:()=>push('*'),style:{margin:2}},'*'),
      React.createElement('button',{onClick:()=>push('/'),style:{margin:2}},'/'),
      React.createElement('button',{onClick:evalExpr,style:{margin:2}},'='),
      React.createElement('button',{onClick:clear,style:{margin:2}},'C')
    )
  )
 );
}
JS
# Ensure workspace writable by current user
if [ ! -w "$WORKSPACE" ]; then sudo chown -R $(id -u):$(id -g) "$WORKSPACE" || true; fi
# Install dependencies non-interactively; prefer npm ci when lockfile present
export CI=true
if [ -f package-lock.json ]; then
  npm ci --no-audit --no-fund --silent || { echo "npm ci failed" >&2; exit 6; }
else
  npm i --no-audit --no-fund --silent || { echo "npm install failed" >&2; exit 7; }
fi
exit 0
