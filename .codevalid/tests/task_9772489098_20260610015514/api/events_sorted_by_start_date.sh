#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
RESPONSE_FILE="/tmp/events_sorted_by_start_date_${CASE_SUFFIX}.json"

cleanup() {
  rm -f "$RESPONSE_FILE"
}
trap cleanup EXIT

# Given — The API is reachable and returns an events list.
HEALTH_STATUS="$(curl -sS -o /dev/null -w '%{http_code}' "$BASE_URL/health")"
[ "$HEALTH_STATUS" = "200" ]

# When — Send GET request to /api/events.
HTTP_STATUS="$(curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X GET "$BASE_URL/api/events")"

# Then — HTTP 200 and events are sorted by startDate ascending.
[ "$HTTP_STATUS" = "200" ]
jq -e 'type == "array"' "$RESPONSE_FILE" >/dev/null
jq -e 'all(.[]; has("startDate"))' "$RESPONSE_FILE" >/dev/null
jq -e '([.[].startDate] == ([.[].startDate] | sort))' "$RESPONSE_FILE" >/dev/null

echo "CODEVALID_TEST_ASSERTION_OK:events_sorted_by_start_date"

# Cleanup — No persistent side effects were created.
