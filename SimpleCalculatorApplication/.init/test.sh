#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/simple-calculator-40856-40905/SimpleCalculatorApplication"
cd "$WORKSPACE"
ERR_EXIT(){ echo "ERROR: $1" >&2; exit ${2:-1}; }
# Only proceed if tests were requested
if [ "${TESTS:-0}" != "1" ]; then echo "tests not requested (TESTS!=1); skipping"; exit 0; fi
# Ensure node_modules exists
if [ ! -d node_modules ]; then echo "node_modules not present; run dependencies step with TESTS=1 to install test deps"; exit 0; fi
# Verify jest and testing libs present
if [ ! -x node_modules/.bin/jest ] || [ ! -d node_modules/@testing-library/react ]; then
  echo "test dependencies missing; install by running dependencies step with TESTS=1 or FORCE_TEST_DEPS=1"; exit 0
fi
# Write jest config and a basic test if missing
[ -f jest.config.cjs ] || cat > jest.config.cjs <<'EOF'
module.exports = { testEnvironment: 'jsdom' };
EOF
mkdir -p src/__tests__
[ -f src/__tests__/App.test.js ] || cat > src/__tests__/App.test.js <<'EOF'
import React from 'react'
import { render } from '@testing-library/react'
import '@testing-library/jest-dom/extend-expect'
import App from '../App'

test('renders calculator title', ()=>{
  const { getByText } = render(<App />)
  expect(getByText(/Simple Calculator/i)).toBeTruthy()
})
EOF
# Run tests
node_modules/.bin/jest --config=jest.config.cjs --runInBand || ERR_EXIT "tests failed" 20
