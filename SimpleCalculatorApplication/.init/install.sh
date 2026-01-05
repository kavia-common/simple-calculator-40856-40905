#!/usr/bin/env bash
set -euo pipefail

# workspace path (from container context)
WORKSPACE="/home/kavia/workspace/code-generation/simple-calculator-40856-40905/SimpleCalculatorApplication"
cd "$WORKSPACE"

LOG=/tmp/simple_calculator_npm_install.log
# Keep a small audit trail header
printf "INSTALL START: %s\n" "$(date --iso-8601=seconds)" >"${LOG}"

# Ensure devDependencies are installed even with CI=true by unsetting NODE_ENV if set to production
OLD_NODE_ENV="${NODE_ENV-}"
if [ "${OLD_NODE_ENV}" = "production" ]; then
  unset NODE_ENV
fi

# Run npm using package-lock.json when present; include dev deps explicitly
if [ -f package-lock.json ]; then
  npm ci --no-audit --no-fund --include=dev >>"${LOG}" 2>&1 || { echo "ERROR: npm ci failed, see ${LOG}" >&2; tail -n 200 "${LOG}" >&2 || true; exit 4; }
else
  npm i --no-audit --no-fund --include=dev >>"${LOG}" 2>&1 || { echo "ERROR: npm install failed, see ${LOG}" >&2; tail -n 200 "${LOG}" >&2 || true; exit 5; }
fi

# restore NODE_ENV
if [ -n "${OLD_NODE_ENV}" ]; then
  export NODE_ENV="${OLD_NODE_ENV}"
fi

# Basic validations
[ -d node_modules ] || { echo "ERROR: node_modules not present" >&2; tail -n 200 "${LOG}" >&2 || true; exit 8; }
[ -x node_modules/.bin/vite ] || { echo "ERROR: vite binary missing or not executable" >&2; tail -n 200 "${LOG}" >&2 || true; exit 6; }
[ -x node_modules/.bin/vitest ] || { echo "ERROR: vitest binary missing or not executable" >&2; tail -n 200 "${LOG}" >&2 || true; exit 7; }

printf "INSTALL SUCCESS: %s\n" "$(date --iso-8601=seconds)" >>"${LOG}"

# Print short summary to stdout for the operator
echo "Dependencies installed. Logs: ${LOG}"
