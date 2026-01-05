#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/simple-calculator-40856-40905/SimpleCalculatorApplication"
cd "$WORKSPACE"
[ -f package.json ] || { echo 'package.json missing' >&2; exit 14; }
# run tests once non-interactively (CI=true)
CI=true npm test --silent > /tmp/test.log 2>&1 || { cat /tmp/test.log >&2; exit 20; }
