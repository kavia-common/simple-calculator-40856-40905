#!/usr/bin/env bash
set -euo pipefail

# Validation: build, preview, readiness poll, capture evidence, cleanup
WORKSPACE="/home/kavia/workspace/code-generation/simple-calculator-40856-40905/SimpleCalculatorApplication"
cd "${WORKSPACE}"
export CI=true

BUILD_LOG="/tmp/simple_calculator_build.log"
PREVIEW_LOG="/tmp/simple_calculator_preview.log"
EVIDENCE_PREFIX="/tmp/simple_calculator_evidence"
STATUS_FILE="/tmp/simple_calculator_status.txt"
PORT=5173
READINESS_TIMEOUT=60

# Ensure evidence directory (prefix uses /tmp so nothing to create beyond confirming)
: > "${BUILD_LOG}"
: > "${PREVIEW_LOG}"

# Build using local vite binary if available, otherwise fallback to npm run build
if [ -x "${WORKSPACE}/node_modules/.bin/vite" ]; then
  "${WORKSPACE}/node_modules/.bin/vite" build >"${BUILD_LOG}" 2>&1 || { echo "ERROR: build failed, see ${BUILD_LOG}" >&2; tail -n 200 "${BUILD_LOG}" >&2; exit 12; }
else
  # Try npm run build (assumes script exists)
  npm run build >"${BUILD_LOG}" 2>&1 || { echo "ERROR: build failed (npm run build), see ${BUILD_LOG}" >&2; tail -n 200 "${BUILD_LOG}" >&2; exit 13; }
fi

# Verify preview binary
PREVIEW_BIN="${WORKSPACE}/node_modules/.bin/vite"
if [ ! -x "${PREVIEW_BIN}" ]; then
  echo "ERROR: preview binary missing at ${PREVIEW_BIN}" >&2
  exit 14
fi

# Prepare to start preview
PREVIEW_CMD=("${PREVIEW_BIN}" preview "--port" "${PORT}" "--strictPort")

# Start preview in background and capture PID
"${PREVIEW_CMD[@]}" >"${PREVIEW_LOG}" 2>&1 &
PREVIEW_PID=$!

# Trap-based cleanup to ensure preview is stopped
_cleanup() {
  rc=$?
  if [ -n "${PREVIEW_PID:-}" ]; then
    kill "${PREVIEW_PID}" >/dev/null 2>&1 || true
    wait "${PREVIEW_PID}" 2>/dev/null || true
  fi
  exit ${rc}
}
trap _cleanup EXIT

# Poll for HTTP readiness
start_time=$(date +%s)
end_time=$((start_time + READINESS_TIMEOUT))
ready=0
while [ $(date +%s) -le ${end_time} ]; do
  # Use curl with low timeouts to avoid hangs
  http_code=$(curl -sS --max-time 2 -o /dev/null -w "%{http_code}" "http://127.0.0.1:${PORT}/" || true)
  case "${http_code}" in
    2??|3??)
      ready=1; break;;
    *)
      sleep 1;;
  esac
done

if [ "${ready}" -ne 1 ]; then
  echo "ERROR: preview server did not respond with 2xx/3xx within ${READINESS_TIMEOUT}s" >&2
  echo "--- last ${PREVIEW_LOG} ---" >&2
  tail -n 200 "${PREVIEW_LOG}" >&2 || true
  exit 15
fi

# Capture evidence reliably using the prefix
EVIDENCE_HEADERS="${EVIDENCE_PREFIX}_headers.txt"
EVIDENCE_BODY="${EVIDENCE_PREFIX}_body.html"
EVIDENCE_SUMMARY="${EVIDENCE_PREFIX}_summary.txt"
EVIDENCE_SNIPPET="${EVIDENCE_PREFIX}_snippet.html"

# Fetch headers and body (with timeouts)
curl -sS --max-time 5 -D "${EVIDENCE_HEADERS}" "http://127.0.0.1:${PORT}/" -o "${EVIDENCE_BODY}" 2>/dev/null || true
STATUS=$(curl -sS --max-time 5 -o /dev/null -w "%{http_code}" "http://127.0.0.1:${PORT}/" || echo "000")

echo "status:${STATUS}" > "${EVIDENCE_SUMMARY}"
# Append first portion of headers to summary
if [ -f "${EVIDENCE_HEADERS}" ]; then
  head -n 200 "${EVIDENCE_HEADERS}" >> "${EVIDENCE_SUMMARY}" || true
fi
# Create a short snippet of body
if [ -f "${EVIDENCE_BODY}" ]; then
  head -n 50 "${EVIDENCE_BODY}" > "${EVIDENCE_SNIPPET}" || true
fi

# Mark success
echo "validation_success" > "${STATUS_FILE}"

# Cleanup: kill preview if still running (trap will also handle)
if ps -p "${PREVIEW_PID}" > /dev/null 2>&1; then
  kill "${PREVIEW_PID}" >/dev/null 2>&1 || true
  wait "${PREVIEW_PID}" 2>/dev/null || true
fi

# Remove trap and exit 0
trap - EXIT
exit 0
