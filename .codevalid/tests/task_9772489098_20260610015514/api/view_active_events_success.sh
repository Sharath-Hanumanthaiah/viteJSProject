#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
RESPONSE_FILE="/tmp/view_active_events_success_${CASE_SUFFIX}.json"

cleanup() {
  rm -f "$RESPONSE_FILE"
}
trap cleanup EXIT

# Given — API is reachable.
HEALTH_STATUS="$(curl -sS -o /dev/null -w '%{http_code}' "$BASE_URL/health")"
[ "$HEALTH_STATUS" = "200" ]

# When — Request the events list.
HTTP_STATUS="$(curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' "$BASE_URL/api/events")"

# Then — Events endpoint returns HTTP 200 and a JSON array.
[ "$HTTP_STATUS" = "200" ]
jq -e 'type == "array"' "$RESPONSE_FILE" >/dev/null

# Cleanup — No side effects.

echo "CODEVALID_TEST_ASSERTION_OK:view_active_events_success"
