#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/simple-calculator-40856-40905/SimpleCalculatorApplication"
# Validate runtime
command -v node >/dev/null 2>&1 || { echo "node not found on PATH" >&2; exit 2; }
command -v npm >/dev/null 2>&1 || { echo "npm not found on PATH" >&2; exit 3; }
# Ensure workspace exists and change into it
[ -d "$WORKSPACE" ] || { echo "workspace not found: $WORKSPACE" >&2; exit 4; }
cd "$WORKSPACE"
# Export required env for CRA dev server
export BROWSER=none
export HOST=0.0.0.0
export PORT=3000
# Provide a helpful check: ensure package.json exists and has a start script
if [ ! -f package.json ]; then
  echo "package.json not found in workspace ($WORKSPACE)" >&2
  exit 5
fi
if ! (grep -q '"start"' package.json); then
  echo "package.json does not appear to contain a \"start\" script. Ensure project is scaffolded and dependencies installed." >&2
  exit 6
fi
# Run CRA dev server in foreground so container runtime keeps container alive
exec npm start
