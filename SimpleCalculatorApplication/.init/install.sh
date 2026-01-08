#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/simple-calculator-40856-40905/SimpleCalculatorApplication"
cd "$WORKSPACE"
ERR_EXIT(){ echo "ERROR: $1" >&2; exit ${2:-1}; }
command -v npm >/dev/null 2>&1 || ERR_EXIT "npm missing" 2
if [ ! -f package.json ]; then echo "no package.json found, nothing to install"; exit 0; fi
# Decide if install needed
DO_INSTALL=0
if [ ! -d node_modules ] || [ "${FORCE_INSTALL:-0}" = "1" ]; then DO_INSTALL=1; fi
if [ -f package-lock.json ]; then
  md5sum package-lock.json | awk '{print $1}' > .package-lock.md5.new
  if [ -f .package-lock.md5 ]; then
    if ! cmp -s .package-lock.md5 .package-lock.md5.new; then DO_INSTALL=1; fi
  else
    DO_INSTALL=1
  fi
  mv .package-lock.md5.new .package-lock.md5
fi
if [ "$DO_INSTALL" -eq 1 ]; then
  LOG=/tmp/npm_install_log.$$
  if [ -f package-lock.json ]; then
    npm ci --no-audit --no-fund >"$LOG" 2>&1 || { tail -n 200 "$LOG" >&2; ERR_EXIT "npm ci failed" 10; }
  else
    npm install --no-audit --no-fund >"$LOG" 2>&1 || { tail -n 200 "$LOG" >&2; ERR_EXIT "npm install failed" 11; }
  fi
else
  echo "node_modules present and package-lock unchanged; skipping install"
fi
# Install test/dev deps only if requested to avoid changing lockfile unintentionally
if [ "${TESTS:-0}" = "1" ] || [ "${FORCE_TEST_DEPS:-0}" = "1" ]; then
  npm i -D @testing-library/react @testing-library/jest-dom jest --no-audit --no-fund >/tmp/npm_test_deps_log.$$ 2>&1 || { tail -n 100 /tmp/npm_test_deps_log.$$ >&2; echo "warning: installing test deps failed" >&2; }
fi
