#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
TODAY="$(date -u +%F)"
ATTENDEE_EMAIL="jane.smith.${CASE_SUFFIX}@example.com"
EVENTS_FILE="/tmp/register_outside_date_range_before_start_events_${CASE_SUFFIX}.json"
RESPONSE_FILE="/tmp/register_outside_date_range_before_start_${CASE_SUFFIX}.json"
EVENT_ID=""

cleanup() {
  rm -f "$EVENTS_FILE" "$RESPONSE_FILE"
}
trap cleanup EXIT

# Given — Find an event whose registration has not opened yet.
EVENTS_STATUS="$(curl -sS -o "$EVENTS_FILE" -w '%{http_code}' "$BASE_URL/api/events")"
[ "$EVENTS_STATUS" = "200" ]
EVENT_ID="$(jq -r --arg today "$TODAY" 'map(select(.startDate > $today)) | .[0].id // empty' "$EVENTS_FILE")"
[ -n "$EVENT_ID" ]

# When — Attempt to register before the event start date.
HTTP_STATUS="$(curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/registrations" \
  -H 'Content-Type: application/json' \
  --data "{\"eventId\":\"${EVENT_ID}\",\"name\":\"Jane Smith\",\"email\":\"${ATTENDEE_EMAIL}\",\"phone\":\"+1-555-987-6543\"}")"

# Then — API rejects the registration with the not-open-yet message.
[ "$HTTP_STATUS" = "400" ]
jq -e '.message | contains("Registration has not opened yet.")' "$RESPONSE_FILE" >/dev/null

# Cleanup — No side effects expected on rejection.

echo "CODEVALID_TEST_ASSERTION_OK:register_outside_date_range_before_start"
