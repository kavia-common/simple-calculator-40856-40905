#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/simple-calculator-40856-40905/SimpleCalculatorApplication"
cd "$WORKSPACE"
export CI=true
# Install react-test-renderer as devDependency only if not resolvable
if ! node -e "require.resolve('react-test-renderer')" >/dev/null 2>&1; then
  npm i --no-audit --no-fund --silent --save-dev react-test-renderer || { echo "react-test-renderer install failed" >&2; exit 4; }
fi
mkdir -p src/__tests__
TEST_FILE="src/__tests__/App.smoke.test.js"
if [ ! -f "$TEST_FILE" ]; then
  cat > "$TEST_FILE" <<'JS'
import React from 'react';
import renderer from 'react-test-renderer';
import App from '../App';

test('App renders without crashing', () => {
  const tree = renderer.create(<App />).toJSON();
  expect(tree).toBeTruthy();
});
JS
fi
# Run tests once non-interactively
npm test --silent -- --runInBand || { echo "tests failed" >&2; exit 5; }
