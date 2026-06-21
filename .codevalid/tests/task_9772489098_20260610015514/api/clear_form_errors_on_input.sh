#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
TODAY="$(date -u +%F)"
BAD_RESPONSE_FILE="/tmp/clear_form_errors_on_input_bad_${CASE_SUFFIX}.json"
GOOD_RESPONSE_FILE="/tmp/clear_form_errors_on_input_good_${CASE_SUFFIX}.json"
EVENTS_FILE="/tmp/clear_form_errors_on_input_events_${CASE_SUFFIX}.json"
EVENT_ID=""

cleanup() {
  rm -f "$BAD_RESPONSE_FILE" "$GOOD_RESPONSE_FILE" "$EVENTS_FILE"
}
trap cleanup EXIT

# Given — Find an event open for registration today.
EVENTS_STATUS="$(curl -sS -o "$EVENTS_FILE" -w '%{http_code}' "$BASE_URL/api/events")"
[ "$EVENTS_STATUS" = "200" ]
EVENT_ID="$(jq -r --arg today "$TODAY" 'map(select(.startDate <= $today and .endDate >= $today)) | .[0].id // empty' "$EVENTS_FILE")"
[ -n "$EVENT_ID" ]

# When — First submit invalid data, then corrected data.
BAD_STATUS="$(curl -sS -o "$BAD_RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/registrations" \
  -H 'Content-Type: application/json' \
  --data "{\"eventId\":\"${EVENT_ID}\",\"name\":\"\",\"email\":\"clear.${CASE_SUFFIX}@example.com\",\"phone\":\"+1-555-111-1212\"}")"
GOOD_STATUS="$(curl -sS -o "$GOOD_RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/registrations" \
  -H 'Content-Type: application/json' \
  --data "{\"eventId\":\"${EVENT_ID}\",\"name\":\"Corrected Name\",\"email\":\"clear.${CASE_SUFFIX}@example.com\",\"phone\":\"+1-555-111-1212\"}")"

# Then — Invalid request fails and corrected request succeeds.
[ "$BAD_STATUS" = "400" ]
jq -e '.message == "Event, name, email, and phone number are required."' "$BAD_RESPONSE_FILE" >/dev/null
[ "$GOOD_STATUS" = "201" ]
jq -e '.name == "Corrected Name"' "$GOOD_RESPONSE_FILE" >/dev/null

# Cleanup — No delete endpoint is exposed; unique email isolates side effects.

echo "CODEVALID_TEST_ASSERTION_OK:clear_form_errors_on_input"
