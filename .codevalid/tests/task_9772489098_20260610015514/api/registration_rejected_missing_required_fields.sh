#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
EVENTS_FILE="/tmp/registration_rejected_missing_required_fields_events_${CASE_SUFFIX}.json"
RESPONSE_FILE_ONE="/tmp/registration_rejected_missing_required_fields_response_one_${CASE_SUFFIX}.json"
RESPONSE_FILE_TWO="/tmp/registration_rejected_missing_required_fields_response_two_${CASE_SUFFIX}.json"

cleanup_files() {
  rm -f "$EVENTS_FILE" "$RESPONSE_FILE_ONE" "$RESPONSE_FILE_TWO"
}
trap cleanup_files EXIT

# Given — verify the referenced seeded event exists.
EVENTS_STATUS="$(curl -sS -o "$EVENTS_FILE" -w '%{http_code}' "$BASE_URL/api/events")"
[ "$EVENTS_STATUS" = "200" ]
grep -F '"id":"evt-100"' "$EVENTS_FILE" >/dev/null

# When — submit invalid registration payloads missing required fields.
HTTP_STATUS_ONE="$(curl -sS -o "$RESPONSE_FILE_ONE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/registrations" \
  -H 'Content-Type: application/json' \
  --data '{"eventId":"evt-100","name":"Test User"}')"

HTTP_STATUS_TWO="$(curl -sS -o "$RESPONSE_FILE_TWO" -w '%{http_code}' \
  -X POST "$BASE_URL/api/registrations" \
  -H 'Content-Type: application/json' \
  --data '{"name":"Test User","email":"test@example.com","phone":"+1-555-111-2222"}')"

# Then — both requests should fail with the required-fields message.
[ "$HTTP_STATUS_ONE" = "400" ]
grep -F 'Event, name, email, and phone number are required.' "$RESPONSE_FILE_ONE" >/dev/null
[ "$HTTP_STATUS_TWO" = "400" ]
grep -F 'Event, name, email, and phone number are required.' "$RESPONSE_FILE_TWO" >/dev/null

echo "CODEVALID_TEST_ASSERTION_OK:registration_rejected_missing_required_fields"

# Cleanup — validation failures create no durable side effects; temp files are removed by trap.
