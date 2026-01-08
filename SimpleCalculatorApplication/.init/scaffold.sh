#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/simple-calculator-40856-40905/SimpleCalculatorApplication"
cd "$WORKSPACE"
ERR_EXIT(){ echo "ERROR: $1" >&2; exit ${2:-1}; }
# Require Node >=16
NODE_MAJOR=$(node -v | sed 's/^v//' | cut -d. -f1)
if [ "$NODE_MAJOR" -lt 16 ]; then ERR_EXIT "Node major version $NODE_MAJOR < 16; update Node" 4; fi
mkdir -p "$WORKSPACE"
# If package.json exists, ensure public/index.html and src files exist; otherwise scaffold
if [ -f package.json ]; then
  mkdir -p public src
  if [ ! -f public/index.html ]; then
    cat > public/index.html <<'EOF'
<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Simple Calculator</title></head><body><div id="root"></div></body></html>
EOF
  fi
else
  if command -v create-react-app >/dev/null 2>&1; then
    # prefer global CRA; allow non-fatal failure
    create-react-app . --use-npm || true
  else
    # attempt npx scaffolding (will record dependencies in package.json); if it fails make fallback minimal project
    if ! npx create-react-app . --use-npm --yes >/dev/null 2>&1; then
      mkdir -p public src
      cat > public/index.html <<'EOF'
<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Simple Calculator</title></head><body><div id="root"></div></body></html>
EOF
      cat > package.json <<'EOF'
{
  "name": "simple-calculator",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "start": "react-scripts start",
    "build": "react-scripts build",
    "test": "react-scripts test --env=jsdom"
  },
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "react-scripts": "5.0.1"
  }
}
EOF
    fi
  fi
fi
# Ensure src/index.js
mkdir -p src
if [ ! -f src/index.js ]; then
  cat > src/index.js <<'EOF'
import React from 'react'
import { createRoot } from 'react-dom/client'
import App from './App'
const root = createRoot(document.getElementById('root'))
root.render(<App />)
EOF
fi
# Ensure src/App.js with a safe arithmetic evaluator (shunting-yard algorithm)
if [ ! -f src/App.js ]; then
  cat > src/App.js <<'EOF'
import React, { useState } from 'react'

// Simple tokenizer + shunting-yard parser and RPN evaluator supporting + - * / and parentheses
function tokenize(s){
  const tokens = []
  const re = /\s*([0-9]+(?:\.[0-9]+)?|[-+/*()])\s*/g
  let m
  while((m = re.exec(s))!==null) tokens.push(m[1])
  return tokens
}
function toRPN(tokens){
  const out = []
  const ops = []
  const prec = { '+':1, '-':1, '*':2, '/':2 }
  for(const t of tokens){
    if(/^[0-9]+(?:\.[0-9]+)?$/.test(t)) out.push(t)
    else if(t in prec){
      while(ops.length && ops[ops.length-1] !== '(' && prec[ops[ops.length-1]] >= prec[t]) out.push(ops.pop())
      ops.push(t)
    } else if(t === '(') ops.push(t)
    else if(t === ')'){
      while(ops.length && ops[ops.length-1] !== '(') out.push(ops.pop())
      ops.pop()
    } else throw new Error('Invalid token')
  }
  while(ops.length) out.push(ops.pop())
  return out
}
function evalRPN(rpn){
  const st = []
  for(const t of rpn){
    if(/^[0-9]+(?:\.[0-9]+)?$/.test(t)) st.push(parseFloat(t))
    else{
      const b = st.pop(); const a = st.pop()
      if(t === '+') st.push(a+b)
      else if(t === '-') st.push(a-b)
      else if(t === '*') st.push(a*b)
      else if(t === '/') st.push(a/b)
      else throw new Error('Invalid op')
    }
  }
  return st.pop()
}
function safeEval(expr){
  try{
    if(!/^[0-9+\-*/().\s]+$/.test(expr)) return 'ERR'
    const tokens = tokenize(expr)
    const rpn = toRPN(tokens)
    const res = evalRPN(rpn)
    if(!isFinite(res)) return 'ERR'
    return res
  }catch(e){ return 'ERR' }
}

export default function App(){
  const [display,setDisplay]=useState('')
  const onClick=(v)=>setDisplay(prev=>prev+v)
  const clear=()=>setDisplay('')
  const calc=()=>{ const r=safeEval(display); setDisplay(String(r)) }
  return (
    React.createElement('div',{style:{fontFamily:'sans-serif',padding:20}},
      React.createElement('h3',null,'Simple Calculator'),
      React.createElement('div',{style:{marginBottom:10,fontSize:24}},display||'0'),
      React.createElement('div',null,['7','8','9','/'].map(c=>React.createElement('button',{key:c,onClick:()=>onClick(c),style:{margin:4}},c))),
      React.createElement('div',null,['4','5','6','*'].map(c=>React.createElement('button',{key:c,onClick:()=>onClick(c),style:{margin:4}},c))),
      React.createElement('div',null,['1','2','3','-'].map(c=>React.createElement('button',{key:c,onClick:()=>onClick(c),style:{margin:4}},c))),
      React.createElement('div',null,['0','.','=','+'].map(c=>React.createElement('button',{key:c,onClick:()=> c==='='?calc():onClick(c),style:{margin:4}},c))),
      React.createElement('div',null,React.createElement('button',{onClick:clear,style:{marginTop:10}},'Clear'))
    )
  )
}
EOF
fi
