#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/simple-calculator-40856-40905/SimpleCalculatorApplication"
cd "$WORKSPACE"
# ensure CI for reproducible, non-interactive behavior
export CI=true
LOG=/tmp/simple_calculator_vitest.log
# run local vitest explicitly with 'run' subcommand to avoid watch mode; capture artifact for auditing
if [ -x "node_modules/.bin/vitest" ]; then
  ./node_modules/.bin/vitest run --reporter=dot >"${LOG}" 2>&1 || { cat "${LOG}" >&2; exit 10; }
else
  # fallback to npm script (project may define test script) and still capture logs
  npm run test >"${LOG}" 2>&1 || { cat "${LOG}" >&2; exit 11; }
fi
# produce a concise summary for quick inspection
tail -n 200 "${LOG}" > /tmp/simple_calculator_vitest_summary.txt || true
