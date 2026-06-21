#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
EMAIL="john.doe.${CASE_SUFFIX}@example.com"
PHONE="+1-555-123-4567"
EVENT_ID="evt-100"
RESPONSE_FILE="/tmp/successful_registration_within_date_range_${CASE_SUFFIX}.json"
EVENTS_FILE="/tmp/successful_registration_within_date_range_events_${CASE_SUFFIX}.json"
REGISTRATIONS_FILE="/tmp/successful_registration_within_date_range_regs_${CASE_SUFFIX}.json"

cleanup() {
  rm -f "$RESPONSE_FILE" "$EVENTS_FILE" "$REGISTRATIONS_FILE"
}
trap cleanup EXIT

# Given — verify the target event exists in the public events API.
EVENTS_STATUS="$(curl -sS -o "$EVENTS_FILE" -w '%{http_code}' "$BASE_URL/api/events")"
[ "$EVENTS_STATUS" = "200" ]
grep -F '"id":"evt-100"' "$EVENTS_FILE" >/dev/null

# When — create a registration with a unique email.
HTTP_STATUS="$(curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/registrations" \
  -H 'Content-Type: application/json' \
  --data "{\"eventId\":\"${EVENT_ID}\",\"name\":\"John Doe\",\"email\":\"${EMAIL}\",\"phone\":\"${PHONE}\"}")"

# Then — response is 201 and registration is visible via the event registrations API.
[ "$HTTP_STATUS" = "201" ]
grep -F '"id":"reg-' "$RESPONSE_FILE" >/dev/null
grep -F "\"eventId\":\"${EVENT_ID}\"" "$RESPONSE_FILE" >/dev/null
grep -F '"name":"John Doe"' "$RESPONSE_FILE" >/dev/null
grep -F "\"email\":\"${EMAIL}\"" "$RESPONSE_FILE" >/dev/null
grep -F "\"phone\":\"${PHONE}\"" "$RESPONSE_FILE" >/dev/null
grep -F '"registeredAt":"' "$RESPONSE_FILE" >/dev/null

REG_LIST_STATUS="$(curl -sS -o "$REGISTRATIONS_FILE" -w '%{http_code}' "$BASE_URL/api/registrations/${EVENT_ID}")"
[ "$REG_LIST_STATUS" = "200" ]
grep -F "\"email\":\"${EMAIL}\"" "$REGISTRATIONS_FILE" >/dev/null

echo "CODEVALID_TEST_ASSERTION_OK:successful_registration_within_date_range"

# Cleanup — no delete endpoint exists; temp files are removed by trap.
