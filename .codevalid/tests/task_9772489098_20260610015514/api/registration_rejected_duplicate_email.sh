#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
EVENT_ID="evt-100"
FIRST_RESPONSE_FILE="/tmp/registration_rejected_duplicate_email_first_${CASE_SUFFIX}.json"
SECOND_RESPONSE_FILE="/tmp/registration_rejected_duplicate_email_second_${CASE_SUFFIX}.json"
THIRD_RESPONSE_FILE="/tmp/registration_rejected_duplicate_email_third_${CASE_SUFFIX}.json"
REGISTRATIONS_FILE="/tmp/registration_rejected_duplicate_email_regs_${CASE_SUFFIX}.json"
EMAIL_BASE="existing.${CASE_SUFFIX}@example.com"
EMAIL_UPPER="EXISTING.${CASE_SUFFIX}@EXAMPLE.COM"

cleanup() {
  rm -f "$FIRST_RESPONSE_FILE" "$SECOND_RESPONSE_FILE" "$THIRD_RESPONSE_FILE" "$REGISTRATIONS_FILE"
}
trap cleanup EXIT

# Given — create an initial successful registration for the event using a unique email.
FIRST_STATUS="$(curl -sS -o "$FIRST_RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/registrations" \
  -H 'Content-Type: application/json' \
  --data "{\"eventId\":\"${EVENT_ID}\",\"name\":\"Seed Existing User\",\"email\":\"${EMAIL_BASE}\",\"phone\":\"+1-555-777-1111\"}")"
[ "$FIRST_STATUS" = "201" ]
grep -F "\"email\":\"${EMAIL_BASE}\"" "$FIRST_RESPONSE_FILE" >/dev/null

# When — submit the same email again for the same event.
SECOND_STATUS="$(curl -sS -o "$SECOND_RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/registrations" \
  -H 'Content-Type: application/json' \
  --data "{\"eventId\":\"${EVENT_ID}\",\"name\":\"Existing User\",\"email\":\"${EMAIL_BASE}\",\"phone\":\"+1-555-777-8888\"}")"

# Then — exact-case duplicate is rejected.
[ "$SECOND_STATUS" = "400" ]
grep -F 'This email is already registered for this event.' "$SECOND_RESPONSE_FILE" >/dev/null

# When — submit the same email with different case.
THIRD_STATUS="$(curl -sS -o "$THIRD_RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/registrations" \
  -H 'Content-Type: application/json' \
  --data "{\"eventId\":\"${EVENT_ID}\",\"name\":\"Another User\",\"email\":\"${EMAIL_UPPER}\",\"phone\":\"+1-555-999-0000\"}")"

# Then — case-insensitive duplicate is also rejected and only the original registration remains.
[ "$THIRD_STATUS" = "400" ]
grep -F 'This email is already registered for this event.' "$THIRD_RESPONSE_FILE" >/dev/null

REG_LIST_STATUS="$(curl -sS -o "$REGISTRATIONS_FILE" -w '%{http_code}' "$BASE_URL/api/registrations/${EVENT_ID}")"
[ "$REG_LIST_STATUS" = "200" ]
grep -F "\"email\":\"${EMAIL_BASE}\"" "$REGISTRATIONS_FILE" >/dev/null
if grep -F "\"email\":\"${EMAIL_UPPER}\"" "$REGISTRATIONS_FILE" >/dev/null; then
  exit 1
fi

echo "CODEVALID_TEST_ASSERTION_OK:registration_rejected_duplicate_email"

# Cleanup — no delete endpoint exists; temp files are removed by trap.
