#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
RESPONSE_FILE="/tmp/get_active_events_success_${CASE_SUFFIX}.json"

cleanup() {
  rm -f "$RESPONSE_FILE"
}
trap cleanup EXIT

# Given — The API is reachable and events can be listed.
HEALTH_STATUS="$(curl -sS -o /dev/null -w '%{http_code}' "$BASE_URL/health")"
[ "$HEALTH_STATUS" = "200" ]

# When — Send GET request to /api/events.
HTTP_STATUS="$(curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X GET "$BASE_URL/api/events")"

# Then — HTTP 200 and response is a JSON array whose objects include registrationCount.
[ "$HTTP_STATUS" = "200" ]
jq -e 'type == "array"' "$RESPONSE_FILE" >/dev/null
if [ "$(jq 'length' "$RESPONSE_FILE")" -gt 0 ]; then
  jq -e 'all(.[]; has("id") and has("registrationCount"))' "$RESPONSE_FILE" >/dev/null
fi

echo "CODEVALID_TEST_ASSERTION_OK:get_active_events_success"

# Cleanup — No persistent side effects were created.
