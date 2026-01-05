#!/usr/bin/env bash
set -euo pipefail

WORKSPACE="/home/kavia/workspace/code-generation/simple-calculator-40856-40905/SimpleCalculatorApplication"
mkdir -p "$WORKSPACE" && cd "$WORKSPACE"
[ -f package.json ] && exit 0
cat > package.json <<'EOF'
{
  "name": "simple-calculator",
  "version": "0.1.0",
  "private": true,
  "type": "module",
  "engines": { "node": ">=16" },
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "preview": "vite preview --port 5173",
    "start": "vite preview --port 5173",
    "test": "vitest run --reporter=dot"
  },
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0"
  },
  "devDependencies": {
    "vite": "^5.0.0",
    "vitest": "^1.0.0",
    "@vitejs/plugin-react": "^4.0.0"
  }
}
EOF

mkdir -p src
cat > index.html <<'EOF'
<!doctype html>
<html>
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Simple Calculator</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.jsx"></script>
  </body>
</html>
EOF

cat > src/main.jsx <<'EOF'
import React from 'react'
import { createRoot } from 'react-dom/client'
import App from './App.jsx'
createRoot(document.getElementById('root')).render(React.createElement(App))
EOF

cat > src/App.jsx <<'EOF'
import React from 'react'
export default function App(){
  const [display] = React.useState('0')
  return (
    React.createElement('div', {style:{fontFamily:'sans-serif',padding:20}},
      React.createElement('h1', null, 'Simple Calculator (dev scaffold)'),
      React.createElement('div', null, display)
    )
  )
}
EOF

cat > vitest.config.js <<'EOF'
import { defineConfig } from 'vitest/config'
export default defineConfig({test:{globals:true,environment:'jsdom'}})
EOF

mkdir -p test
cat > test/sample.test.js <<'EOF'
import { describe, it, expect } from 'vitest'
describe('sanity', ()=>{ it('works', ()=> expect(1+1).toBe(2)) })
EOF

cat > README.md <<'EOF'
Simple Calculator - development scaffold using Vite + React
Run locally: npm ci && npm run dev
Logs: /tmp/simple_calculator_*.log
EOF

cat > .gitignore <<'EOF'
node_modules/
dist/
.env
EOF
