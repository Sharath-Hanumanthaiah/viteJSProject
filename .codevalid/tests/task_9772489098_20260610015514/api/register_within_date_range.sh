#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
TODAY="$(date -u +%F)"
ATTENDEE_NAME="John Doe ${CASE_SUFFIX}"
ATTENDEE_EMAIL="john.doe.${CASE_SUFFIX}@example.com"
ATTENDEE_PHONE="+1-555-123-4567"
EVENTS_FILE="/tmp/register_within_date_range_events_${CASE_SUFFIX}.json"
RESPONSE_FILE="/tmp/register_within_date_range_${CASE_SUFFIX}.json"
REGS_FILE="/tmp/register_within_date_range_regs_${CASE_SUFFIX}.json"
EVENT_ID=""

cleanup() {
  rm -f "$EVENTS_FILE" "$RESPONSE_FILE" "$REGS_FILE"
}
trap cleanup EXIT

# Given — Find an event open for registration today.
EVENTS_STATUS="$(curl -sS -o "$EVENTS_FILE" -w '%{http_code}' "$BASE_URL/api/events")"
[ "$EVENTS_STATUS" = "200" ]
EVENT_ID="$(jq -r --arg today "$TODAY" 'map(select(.startDate <= $today and .endDate >= $today)) | .[0].id // empty' "$EVENTS_FILE")"
[ -n "$EVENT_ID" ]

# When — Register a unique attendee for that event.
HTTP_STATUS="$(curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/registrations" \
  -H 'Content-Type: application/json' \
  --data "{\"eventId\":\"${EVENT_ID}\",\"name\":\"${ATTENDEE_NAME}\",\"email\":\"${ATTENDEE_EMAIL}\",\"phone\":\"${ATTENDEE_PHONE}\"}")"

# Then — Registration is created and appears in the event registrations list.
[ "$HTTP_STATUS" = "201" ]
jq -e --arg eventId "$EVENT_ID" --arg name "$ATTENDEE_NAME" --arg email "$ATTENDEE_EMAIL" '.eventId == $eventId and .name == $name and .email == $email and (.id | length > 0)' "$RESPONSE_FILE" >/dev/null
REGS_STATUS="$(curl -sS -o "$REGS_FILE" -w '%{http_code}' "$BASE_URL/api/registrations/${EVENT_ID}")"
[ "$REGS_STATUS" = "200" ]
jq -e --arg email "$ATTENDEE_EMAIL" 'map(select(.email == $email)) | length >= 1' "$REGS_FILE" >/dev/null

# Cleanup — No delete endpoint is exposed; unique email isolates side effects.

echo "CODEVALID_TEST_ASSERTION_OK:register_within_date_range"
