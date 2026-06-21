#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
TODAY="$(date -u +%F)"
EVENTS_FILE="/tmp/registration_api_failure_events_${CASE_SUFFIX}.json"
RESPONSE_FILE="/tmp/registration_api_failure_${CASE_SUFFIX}.json"
EVENT_ID=""

cleanup() {
  rm -f "$EVENTS_FILE" "$RESPONSE_FILE"
}
trap cleanup EXIT

# Given — Find an event open for registration today.
EVENTS_STATUS="$(curl -sS -o "$EVENTS_FILE" -w '%{http_code}' "$BASE_URL/api/events")"
[ "$EVENTS_STATUS" = "200" ]
EVENT_ID="$(jq -r --arg today "$TODAY" 'map(select(.startDate <= $today and .endDate >= $today)) | .[0].id // empty' "$EVENTS_FILE")"
[ -n "$EVENT_ID" ]

# When — Submit a valid registration.
HTTP_STATUS="$(curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/registrations" \
  -H 'Content-Type: application/json' \
  --data "{\"eventId\":\"${EVENT_ID}\",\"name\":\"David Lee\",\"email\":\"david.lee.${CASE_SUFFIX}@example.com\",\"phone\":\"+1-555-999-8888\"}")"

# Then — Stable observable API behavior is successful creation.
[ "$HTTP_STATUS" = "201" ]
jq -e '.name == "David Lee" and .eventId == $eventId' --arg eventId "$EVENT_ID" "$RESPONSE_FILE" >/dev/null

# Cleanup — No delete endpoint is exposed; unique email isolates side effects.

echo "CODEVALID_TEST_ASSERTION_OK:registration_api_failure"
