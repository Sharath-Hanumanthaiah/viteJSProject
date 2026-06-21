#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
EVENT_ID="evt-100"
EMAIL="john.doe+${CASE_SUFFIX}@example.com"
NAME="John Doe"
PHONE="+1-555-123-4567"
EVENTS_FILE="/tmp/successful_registration_within_date_range_events_${CASE_SUFFIX}.json"
RESPONSE_FILE="/tmp/successful_registration_within_date_range_response_${CASE_SUFFIX}.json"
REGISTRATIONS_FILE="/tmp/successful_registration_within_date_range_registrations_${CASE_SUFFIX}.json"

cleanup_files() {
  rm -f "$EVENTS_FILE" "$RESPONSE_FILE" "$REGISTRATIONS_FILE"
}
trap cleanup_files EXIT

# Given — verify the expected seeded event exists.
EVENTS_STATUS="$(curl -sS -o "$EVENTS_FILE" -w '%{http_code}' "$BASE_URL/api/events")"
[ "$EVENTS_STATUS" = "200" ]
grep -F '"id":"evt-100"' "$EVENTS_FILE" >/dev/null

# When — create a registration for the event with a unique email.
HTTP_STATUS="$(curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/registrations" \
  -H 'Content-Type: application/json' \
  --data "{\"eventId\":\"${EVENT_ID}\",\"name\":\"${NAME}\",\"email\":\"${EMAIL}\",\"phone\":\"${PHONE}\"}")"

# Then — assert 201, required response fields, and persisted registration.
[ "$HTTP_STATUS" = "201" ]
grep -F '"id":"reg-' "$RESPONSE_FILE" >/dev/null
grep -F "\"eventId\":\"${EVENT_ID}\"" "$RESPONSE_FILE" >/dev/null
grep -F "\"name\":\"${NAME}\"" "$RESPONSE_FILE" >/dev/null
grep -F "\"email\":\"${EMAIL}\"" "$RESPONSE_FILE" >/dev/null
grep -F "\"phone\":\"${PHONE}\"" "$RESPONSE_FILE" >/dev/null
grep -F '"registeredAt":"' "$RESPONSE_FILE" >/dev/null

REG_STATUS="$(curl -sS -o "$REGISTRATIONS_FILE" -w '%{http_code}' "$BASE_URL/api/registrations/${EVENT_ID}")"
[ "$REG_STATUS" = "200" ]
grep -F "\"email\":\"${EMAIL}\"" "$REGISTRATIONS_FILE" >/dev/null

echo "CODEVALID_TEST_ASSERTION_OK:successful_registration_within_date_range"

# Cleanup — no delete endpoint is exposed; temp files are removed by trap.
