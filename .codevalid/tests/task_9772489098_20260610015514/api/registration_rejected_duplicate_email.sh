#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
EVENT_ID="evt-100"
EMAIL_BASE="existing+${CASE_SUFFIX}@example.com"
NAME_ONE="Existing User"
NAME_TWO="Another User"
PHONE_ONE="+1-555-777-8888"
PHONE_TWO="+1-555-999-0000"
EVENTS_FILE="/tmp/registration_rejected_duplicate_email_events_${CASE_SUFFIX}.json"
SETUP_FILE="/tmp/registration_rejected_duplicate_email_setup_${CASE_SUFFIX}.json"
RESPONSE_FILE_ONE="/tmp/registration_rejected_duplicate_email_response_one_${CASE_SUFFIX}.json"
RESPONSE_FILE_TWO="/tmp/registration_rejected_duplicate_email_response_two_${CASE_SUFFIX}.json"
REGISTRATIONS_FILE="/tmp/registration_rejected_duplicate_email_registrations_${CASE_SUFFIX}.json"

cleanup_files() {
  rm -f "$EVENTS_FILE" "$SETUP_FILE" "$RESPONSE_FILE_ONE" "$RESPONSE_FILE_TWO" "$REGISTRATIONS_FILE"
}
trap cleanup_files EXIT

# Given — verify the seeded event exists and create the initial registration.
EVENTS_STATUS="$(curl -sS -o "$EVENTS_FILE" -w '%{http_code}' "$BASE_URL/api/events")"
[ "$EVENTS_STATUS" = "200" ]
grep -F '"id":"evt-100"' "$EVENTS_FILE" >/dev/null

SETUP_STATUS="$(curl -sS -o "$SETUP_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/registrations" \
  -H 'Content-Type: application/json' \
  --data "{\"eventId\":\"${EVENT_ID}\",\"name\":\"${NAME_ONE}\",\"email\":\"${EMAIL_BASE}\",\"phone\":\"${PHONE_ONE}\"}")"
[ "$SETUP_STATUS" = "201" ]
grep -F "\"email\":\"${EMAIL_BASE}\"" "$SETUP_FILE" >/dev/null

# When — retry with the same email and with different casing.
HTTP_STATUS_ONE="$(curl -sS -o "$RESPONSE_FILE_ONE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/registrations" \
  -H 'Content-Type: application/json' \
  --data "{\"eventId\":\"${EVENT_ID}\",\"name\":\"${NAME_ONE}\",\"email\":\"${EMAIL_BASE}\",\"phone\":\"${PHONE_ONE}\"}")"

UPPER_EMAIL="$(printf '%s' "$EMAIL_BASE" | tr '[:lower:]' '[:upper:]')"
HTTP_STATUS_TWO="$(curl -sS -o "$RESPONSE_FILE_TWO" -w '%{http_code}' \
  -X POST "$BASE_URL/api/registrations" \
  -H 'Content-Type: application/json' \
  --data "{\"eventId\":\"${EVENT_ID}\",\"name\":\"${NAME_TWO}\",\"email\":\"${UPPER_EMAIL}\",\"phone\":\"${PHONE_TWO}\"}")"

# Then — both duplicate attempts should fail and only one registration should remain for the original email.
[ "$HTTP_STATUS_ONE" = "400" ]
grep -F 'This email is already registered for this event.' "$RESPONSE_FILE_ONE" >/dev/null
[ "$HTTP_STATUS_TWO" = "400" ]
grep -F 'This email is already registered for this event.' "$RESPONSE_FILE_TWO" >/dev/null

REG_STATUS="$(curl -sS -o "$REGISTRATIONS_FILE" -w '%{http_code}' "$BASE_URL/api/registrations/${EVENT_ID}")"
[ "$REG_STATUS" = "200" ]
MATCH_COUNT="$(grep -o "\"email\":\"${EMAIL_BASE}\"" "$REGISTRATIONS_FILE" | wc -l | tr -d ' ')"
[ "$MATCH_COUNT" = "1" ]

echo "CODEVALID_TEST_ASSERTION_OK:registration_rejected_duplicate_email"

# Cleanup — no delete endpoint is exposed; temp files are removed by trap.
