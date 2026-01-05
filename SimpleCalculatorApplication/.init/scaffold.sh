#!/usr/bin/env bash
set -euo pipefail
# Idempotent scaffold for minimal React 18 app using container workspace
WORKSPACE="/home/kavia/workspace/code-generation/simple-calculator-40856-40905/SimpleCalculatorApplication"
mkdir -p "$WORKSPACE" && cd "$WORKSPACE"
# deterministic package.json: start uses react-scripts start; wrapper ensures HOST/PORT
cat > package.json <<'JSON'
{
  "name": "simple-calculator-application",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "start": "react-scripts start",
    "start:headless": "sh ./start.sh",
    "build": "react-scripts build",
    "test": "jest --runInBand --watchAll=false"
  },
  "dependencies": {
    "react": "18.2.0",
    "react-dom": "18.2.0"
  },
  "devDependencies": {
    "react-scripts": "5.0.1",
    "jest": "29.6.1"
  }
}
JSON
# start wrapper to export HOST/PORT/BROWSER and run local binary for determinism
cat > start.sh <<'SH'
#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/simple-calculator-40856-40905/SimpleCalculatorApplication"
cd "$WORKSPACE"
: "${HOST:=127.0.0.1}"
: "${PORT:=3000}"
export HOST PORT BROWSER=none NODE_ENV=development
# prefer local binary
if [ -x "$WORKSPACE/node_modules/.bin/react-scripts" ]; then
  exec setsid "$WORKSPACE/node_modules/.bin/react-scripts" start
else
  exec setsid npm start
fi
SH
chmod +x start.sh
mkdir -p src public __tests__
cat > public/index.html <<'HTML'
<!doctype html>
<html>
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <title>Simple Calculator</title>
  </head>
  <body>
    <div id="root"></div>
  </body>
</html>
HTML
cat > src/index.js <<'JS'
import React from 'react'
import { createRoot } from 'react-dom/client'
import App from './App'
const root = createRoot(document.getElementById('root'))
root.render(React.createElement(App))
JS
cat > src/App.js <<'JS'
import React from 'react'
export default function App(){
  return React.createElement('div',null,'Simple Calculator App - dev server running')
}
JS
cat > __tests__/smoke.test.js <<'JS'
test('smoke', ()=>{
  expect(true).toBe(true)
})
JS
cat > .gitignore <<'GI'
node_modules/
build/
GI
# Ensure files written are readable
chmod -R u+rwX,go+rX,go-w .
exit 0
