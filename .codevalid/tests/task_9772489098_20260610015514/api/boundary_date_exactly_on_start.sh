#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
TODAY="$(date -u +%F)"
ATTENDEE_EMAIL="startdate.${CASE_SUFFIX}@example.com"
EVENTS_FILE="/tmp/boundary_date_exactly_on_start_events_${CASE_SUFFIX}.json"
RESPONSE_FILE="/tmp/boundary_date_exactly_on_start_${CASE_SUFFIX}.json"
EVENT_ID=""

cleanup() {
  rm -f "$EVENTS_FILE" "$RESPONSE_FILE"
}
trap cleanup EXIT

# Given — Find an event whose startDate is today.
EVENTS_STATUS="$(curl -sS -o "$EVENTS_FILE" -w '%{http_code}' "$BASE_URL/api/events")"
[ "$EVENTS_STATUS" = "200" ]
EVENT_ID="$(jq -r --arg today "$TODAY" 'map(select(.startDate == $today)) | .[0].id // empty' "$EVENTS_FILE")"
[ -n "$EVENT_ID" ]

# When — Register on the exact start date.
HTTP_STATUS="$(curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/registrations" \
  -H 'Content-Type: application/json' \
  --data "{\"eventId\":\"${EVENT_ID}\",\"name\":\"Start Date User\",\"email\":\"${ATTENDEE_EMAIL}\",\"phone\":\"+1-555-111-0000\"}")"

# Then — Registration succeeds.
[ "$HTTP_STATUS" = "201" ]
jq -e '.name == "Start Date User" and .email == $email and .eventId == $eventId' --arg email "$ATTENDEE_EMAIL" --arg eventId "$EVENT_ID" "$RESPONSE_FILE" >/dev/null

# Cleanup — No delete endpoint is exposed; unique email isolates side effects.

echo "CODEVALID_TEST_ASSERTION_OK:boundary_date_exactly_on_start"
