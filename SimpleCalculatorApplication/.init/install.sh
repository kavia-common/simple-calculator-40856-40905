#!/usr/bin/env bash
set -euo pipefail
WS="/home/kavia/workspace/code-generation/simple-calculator-40856-40905/SimpleCalculatorApplication"
cd "$WS"
# choose package manager: prefer yarn if yarn.lock exists and yarn is available
if [ -f yarn.lock ] && command -v yarn >/dev/null 2>&1; then PM="yarn"; else PM="npm"; fi
if [ "$PM" = "npm" ]; then
  if [ -f package-lock.json ]; then
    npm ci --no-audit --no-fund --silent || { echo 'deps-001: npm ci failed' >&2; exit 8; }
  else
    npm i --no-audit --no-fund --silent || { echo 'deps-001: npm install failed' >&2; exit 9; }
  fi
else
  yarn install --silent || { echo 'deps-001: yarn install failed' >&2; exit 10; }
fi
# detect missing devDependencies and install only those missing
MISSING_DEVS=()
for pkg in serve @testing-library/react @testing-library/jest-dom @testing-library/user-event; do
  node -e "const p='package.json'; if(!require('fs').existsSync(p)){process.exit(0)}; const j=JSON.parse(require('fs').readFileSync(p)); if(!(j.devDependencies&&j.devDependencies['$pkg'])&&!(j.dependencies&&j.dependencies['$pkg'])) process.exit(1);" || MISSING_DEVS+=("$pkg")
done
if [ ${#MISSING_DEVS[@]} -gt 0 ]; then
  if [ "$PM" = "npm" ]; then
    npm i --no-audit --no-fund --save-dev "${MISSING_DEVS[@]}" --silent || { echo 'deps-001: installing devDependencies failed' >&2; exit 11; }
  else
    yarn add --dev "${MISSING_DEVS[@]}" --silent || { echo 'deps-001: yarn add dev failed' >&2; exit 12; }
  fi
fi
# verify serve binary presence
if [ -x node_modules/.bin/serve ] || [ -f node_modules/.bin/serve ]; then
  exit 0
else
  echo 'deps-001: serve binary missing after install' >&2
  exit 13
fi
