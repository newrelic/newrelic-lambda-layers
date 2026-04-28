#!/usr/bin/env bash
# Call the orchestrator API then poll S3 until the validation summary appears.
# Exit 0 = PASS, exit 1 = FAIL or timeout.
#
# Required env vars:
#   ORCHESTRATOR_API_URL    full URL of the /validate endpoint
#   ORCHESTRATOR_API_KEY    x-api-key value
#   RESULTS_BUCKET          S3 bucket where the orchestrator writes summary.json
#
# Usage:
#   poll-validation.sh --runtime <runtime> \
#     --arn-x86 <arn> --arn-arm64 <arn> \
#     [--arn-x86-slim <arn>] [--arn-arm64-slim <arn>] \
#     [--os al2|al2023] \
#     [--run-id <id>] [--timeout <seconds>]

set -euo pipefail

RUNTIME=""
ARN_X86=""
ARN_ARM64=""
ARN_X86_SLIM=""
ARN_ARM64_SLIM=""
OS_TIER=""
RUN_ID=""
TIMEOUT=${VALIDATION_TIMEOUT_S:-1800}

while [[ $# -gt 0 ]]; do
  case $1 in
    --runtime)        RUNTIME=$2;        shift 2 ;;
    --arn-x86)        ARN_X86=$2;        shift 2 ;;
    --arn-arm64)      ARN_ARM64=$2;      shift 2 ;;
    --arn-x86-slim)   ARN_X86_SLIM=$2;   shift 2 ;;
    --arn-arm64-slim) ARN_ARM64_SLIM=$2; shift 2 ;;
    --os)             OS_TIER=$2;        shift 2 ;;
    --run-id)         RUN_ID=$2;         shift 2 ;;
    --timeout)        TIMEOUT=$2;        shift 2 ;;
    *) echo "Unknown argument: $1"; exit 1 ;;
  esac
done

[[ -z "$RUNTIME" ]]  && { echo "ERROR: --runtime is required";  exit 1; }
[[ -z "$ARN_X86" ]]  && { echo "ERROR: --arn-x86 is required";  exit 1; }
[[ -z "$ARN_ARM64" ]] && { echo "ERROR: --arn-arm64 is required"; exit 1; }
[[ -z "${ORCHESTRATOR_API_URL:-}" ]] && { echo "ERROR: ORCHESTRATOR_API_URL is not set"; exit 1; }
[[ -z "${ORCHESTRATOR_API_KEY:-}" ]] && { echo "ERROR: ORCHESTRATOR_API_KEY is not set"; exit 1; }
[[ -z "${RESULTS_BUCKET:-}" ]]       && { echo "ERROR: RESULTS_BUCKET is not set"; exit 1; }

if [[ -z "$RUN_ID" ]]; then
  RUN_ID="gh-${GITHUB_RUN_ID:-$(date +%s)}-${RUNTIME}"
fi

# Build JSON payload
PAYLOAD=$(python3 - <<PYEOF
import json
body = {
    "run_id":    "${RUN_ID}",
    "runtime":   "${RUNTIME}",
    "arn_x86":   "${ARN_X86}",
    "arn_arm64": "${ARN_ARM64}",
}
if "${ARN_X86_SLIM}":   body["arn_x86_slim"]   = "${ARN_X86_SLIM}"
if "${ARN_ARM64_SLIM}": body["arn_arm64_slim"]  = "${ARN_ARM64_SLIM}"
if "${OS_TIER}":        body["os"]              = "${OS_TIER}"
print(json.dumps(body))
PYEOF
)

echo "=== Calling orchestrator for ${RUNTIME} (run_id: ${RUN_ID}) ==="
response=$(curl -sf -X POST "${ORCHESTRATOR_API_URL}" \
  -H "Content-Type: application/json" \
  -H "x-api-key: ${ORCHESTRATOR_API_KEY}" \
  -d "$PAYLOAD")

echo "Orchestrator response: $response"
orch_status=$(echo "$response" | python3 -c "import json,sys; print(json.load(sys.stdin).get('status',''))")
if [[ "$orch_status" != "STARTED" ]]; then
  echo "ERROR: Orchestrator did not return STARTED (got: $orch_status)"
  exit 1
fi

# Poll S3 for the summary
KEY="validation-results/${RUN_ID}/summary.json"
echo "Polling s3://${RESULTS_BUCKET}/${KEY}  (timeout: ${TIMEOUT}s)"

end=$((SECONDS + TIMEOUT))
while [[ $SECONDS -lt $end ]]; do
  result=$(aws s3 cp "s3://${RESULTS_BUCKET}/${KEY}" - 2>/dev/null || true)

  if [[ -n "$result" ]]; then
    echo ""
    echo "=== Validation result for ${RUNTIME} ==="
    echo "$result" | python3 -m json.tool

    final_status=$(echo "$result" | python3 -c "import json,sys; print(json.load(sys.stdin)['status'])")

    if [[ "$final_status" == "PASS" ]]; then
      echo "PASSED: ${RUNTIME}"
      exit 0
    else
      echo "FAILED: ${RUNTIME}"
      echo "$result" | python3 - <<'PYEOF'
import json, sys
d = json.load(sys.stdin)
for variant in ("standard", "slim"):
    section = d.get(variant) or {}
    for f in section.get("functions", []):
        if f["status"] != "PASS":
            print(f"  [{variant}] FAIL: {f['function']} — {f['reason']} (error_type={f.get('error_type','?')})")
PYEOF
      exit 1
    fi
  fi

  remaining=$((end - SECONDS))
  echo "  Waiting... (${remaining}s remaining)"
  sleep 300
done

echo "ERROR: Timeout after ${TIMEOUT}s — no result at s3://${RESULTS_BUCKET}/${KEY}"
exit 1
