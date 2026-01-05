# SimpleCalculatorApplication Preview Diagnostics

Date: 2026-01-05

This document captures diagnostics for intermittent preview startup failures and port visibility issues.

## Summary

- Root cause: External preview wrapper uses `set -euo pipefail` and references `$!` before any background job exists, causing `bash: $!: unbound variable`.
- App health: `npm run start:ci` starts successfully; dev server binds to `0.0.0.0:3000` and serves without errors.
- Recommended fix: Configure preview to invoke `npm run start:ci` and/or guard `$!` in external wrapper.

---

## Collected Information

### 1) package.json scripts

```
{
  "scripts": {
    "start": "react-scripts start",
    "start:ci": "HOST=0.0.0.0 PORT=3000 BROWSER=none react-scripts start",
    "build": "react-scripts build",
    "test": "react-scripts test",
    "eject": "react-scripts eject"
  }
}
```

No bash wrapper scripts found in this repository.

### 2) Node and npm versions

- Node: v18.20.8
- npm: 10.8.2

### 3) Command invoked by preview system

- `/proc/1/cmdline`: `/bin/bash`
- This indicates an external shell wrapper (outside this repo), consistent with the observed failure.

### 4) Last failed preview clue

- Error: `bash: $!: unbound variable`
- Typical when running with `set -euo pipefail` and referencing `$!` with no background job yet.

### 5) Attempted start using CI-friendly script

Command:
```
CI=true npm run start:ci
```

Key output:
- Attempting to bind to HOST environment variable: 0.0.0.0
- Starting the development server...
- Compiled successfully!
- Local: http://localhost:3000
- On Your Network: http://172.17.0.2:3000
- webpack compiled successfully

This confirms the app and configuration are healthy.

---

## Root Cause

- The failure occurs in an external wrapper prior to running npm scripts.
- With `set -u`, referencing `$!` before any backgrounded command results in an unbound variable error, aborting the startup script.
- This explains why the dev server may not start or expose port 3000.

---

## Recommended Remediation

- In the preview system, run:
  - `npm run start:ci`
  - Ensures HOST=0.0.0.0, PORT=3000, and disables auto-open browser.
- If the wrapper must manipulate background jobs:
  - Ensure a background process exists before using `$!`, e.g.:

    ```bash
    # Start process in background
    some_command &

    # Guard access to $! while nounset is active
    set +u
    bgpid=$!
    set -u

    if [ -n "${bgpid:-}" ]; then
      echo "Background PID: $bgpid"
    else
      echo "No background process detected" >&2
      exit 1
    fi
    ```

  - Or perform a conditional check:

    ```bash
    some_command &
    if jobs >/dev/null 2>&1; then
      bgpid=$!
    else
      echo "No background job present" >&2
      exit 1
    fi
    ```

- No repository code changes are needed beyond the presence of `start:ci`.

---

## Notes

- The deprecation warnings shown by webpack dev server are expected for CRA/webpack 5 and do not affect startup.
- If the preview runner polls readiness, ensure it allows initial compile time and polls `http://localhost:3000` or the container network address while the process remains running.
