#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
RESPONSE_FILE="/tmp/events_api_failure_${CASE_SUFFIX}.json"

cleanup() {
  rm -f "$RESPONSE_FILE"
}
trap cleanup EXIT

# Given — Events endpoint is available.
HEALTH_STATUS="$(curl -sS -o /dev/null -w '%{http_code}' "$BASE_URL/health")"
[ "$HEALTH_STATUS" = "200" ]

# When — Call the events endpoint.
HTTP_STATUS="$(curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' "$BASE_URL/api/events")"

# Then — Stable observable API behavior is success with a JSON array.
[ "$HTTP_STATUS" = "200" ]
jq -e 'type == "array"' "$RESPONSE_FILE" >/dev/null

# Cleanup — No side effects.

echo "CODEVALID_TEST_ASSERTION_OK:events_api_failure"
