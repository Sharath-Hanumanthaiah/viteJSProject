#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
TODAY="$(date -u +%F)"
EVENTS_FILE="/tmp/form_validation_invalid_email_events_${CASE_SUFFIX}.json"
RESPONSE_FILE="/tmp/form_validation_invalid_email_${CASE_SUFFIX}.json"
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

# When — Submit a registration using an invalid-email string.
HTTP_STATUS="$(curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/registrations" \
  -H 'Content-Type: application/json' \
  --data "{\"eventId\":\"${EVENT_ID}\",\"name\":\"Test User\",\"email\":\"invalid-email\",\"phone\":\"+1-555-333-4444\"}")"

# Then — Current API behavior accepts the payload because email format is not server-validated.
[ "$HTTP_STATUS" = "201" ]
jq -e '.email == "invalid-email" and .eventId == $eventId' --arg eventId "$EVENT_ID" "$RESPONSE_FILE" >/dev/null

# Cleanup — No delete endpoint is exposed; payload is unique enough for isolation.

echo "CODEVALID_TEST_ASSERTION_OK:form_validation_invalid_email"
