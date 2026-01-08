#!/usr/bin/env bash
set -euo pipefail
WS="/home/kavia/workspace/code-generation/simple-calculator-40856-40905/SimpleCalculatorApplication"
cd "$WS"
mkdir -p src "$WS/.setup"
# ensure test deps are present
for pkg in @testing-library/react @testing-library/jest-dom; do node -e "try{require.resolve('$pkg')}catch(e){process.exit(1)}" || { echo "test-001: missing $pkg" >&2; exit 14; }; done
# create test if missing
if [ ! -f src/App.test.js ]; then
  cat > src/App.test.js <<'T'
import React from 'react';
import { render, screen } from '@testing-library/react';
import '@testing-library/jest-dom/extend-expect';
import App from './App';
test('renders heading', () => { render(<App/>); expect(screen.getByText(/Simple Calculator/i)).toBeInTheDocument(); });
T
fi
LOG="$WS/.setup/test.log"
CI=true npm test -- --watchAll=false >"$LOG" 2>&1 || { echo 'test-001: tests failed; see' "$LOG" >&2; sed -n '1,200p' "$LOG" >&2 || true; exit 15; }
exit 0
