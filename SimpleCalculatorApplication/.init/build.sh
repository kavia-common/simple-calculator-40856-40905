#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/simple-calculator-40856-40905/SimpleCalculatorApplication"
cd "$WORKSPACE"
ERR_EXIT(){ echo "ERROR: $1" >&2; exit ${2:-1}; }
if [ ! -f package.json ]; then ERR_EXIT "no package.json, cannot build" 30; fi
export NODE_ENV=production
BUILD_LOG="/tmp/simple_calc_build_log.$$"
npm run build >"$BUILD_LOG" 2>&1 || { tail -n 200 "$BUILD_LOG" >&2; ERR_EXIT "build failed (see log)" 31; }
echo "build artifacts in $WORKSPACE/build"
