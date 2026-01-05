#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/simple-calculator-40856-40905/SimpleCalculatorApplication"
cd "$WORKSPACE"
export NODE_ENV=development
# Ensure node and npm versions
node_ver=$(node -v 2>/dev/null || true)
npm_ver=$(npm -v 2>/dev/null || true)
if [ -z "$node_ver" ] || [ -z "$npm_ver" ]; then
  echo "node or npm not found on PATH" >&2; exit 2
fi
# sanitize version numbers (strip leading v)
nv=${node_ver#v}
# compare minimal versions 14.0.0 and 6.0.0
ver_ge() { printf "%s\n%s" "$1" "$2" | sort -V | head -n1 | grep -qx "$2"; }
if ! ver_ge "$nv" "14.0.0"; then echo "node >=14.0.0 required (found $nv)" >&2; exit 3; fi
if ! ver_ge "$npm_ver" "6.0.0"; then echo "npm >=6.0.0 required (found $npm_ver)" >&2; exit 4; fi
# Create package-lock if missing
if [ ! -f package-lock.json ]; then
  npm install --package-lock-only --silent --no-audit --no-fund || { echo "npm package-lock generation failed (network?)" >&2; exit 6; }
fi
# Try to use npm cache if present by preferring offline but allow network fallback; fail fast
npm ci --prefer-offline --silent --no-audit --no-fund || { echo "npm ci failed (network or registry issue)" >&2; exit 7; }
# Validate local binaries
if [ ! -x "${WORKSPACE}/node_modules/.bin/react-scripts" ]; then
  echo "react-scripts not found in ./node_modules/.bin after npm ci" >&2
  exit 8
fi
# ensure npm binaries are on PATH for future shells via profile.d
sudo bash -c 'cat > /etc/profile.d/node_env.sh <<"EOF"
# Auto-generated: ensure NODE_ENV and npm global bin on PATH
export NODE_ENV=development
if command -v npm >/dev/null 2>&1; then
  prefix=$(npm config get prefix 2>/dev/null || echo "")
  if [ -n "$prefix" ]; then
    export PATH="$prefix/bin":$PATH
  fi
fi
EOF'
exit 0
