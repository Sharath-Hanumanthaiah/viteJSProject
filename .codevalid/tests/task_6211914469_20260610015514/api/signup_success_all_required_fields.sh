#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
USERNAME="newuser123-${CASE_SUFFIX}"
EMAIL="newuser-${CASE_SUFFIX}@example.com"
PASSWORD="SecurePass123!"
FULL_NAME="New User ${CASE_SUFFIX}"
RESPONSE_FILE="/tmp/signup_success_all_required_fields_${CASE_SUFFIX}.json"

cleanup() {
  rm -f "$RESPONSE_FILE"
}
trap cleanup EXIT

# Given — prepare unique required-field values so no existing in-memory user conflicts.
: > /dev/null

# When — send signup request with all required fields.
HTTP_STATUS="$(curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/auth/signup" \
  -H 'Content-Type: application/json' \
  --data "{\"username\":\"${USERNAME}\",\"email\":\"${EMAIL}\",\"password\":\"${PASSWORD}\",\"fullName\":\"${FULL_NAME}\"}")"

# Then — verify 201 response, returned user fields, token, and password omission.
[ "$HTTP_STATUS" = "201" ]
grep -F '"user":' "$RESPONSE_FILE" >/dev/null
grep -F '"id":' "$RESPONSE_FILE" >/dev/null
grep -F "\"username\":\"${USERNAME}\"" "$RESPONSE_FILE" >/dev/null
grep -F "\"email\":\"${EMAIL}\"" "$RESPONSE_FILE" >/dev/null
grep -F "\"fullName\":\"${FULL_NAME}\"" "$RESPONSE_FILE" >/dev/null
grep -F '"phone":""' "$RESPONSE_FILE" >/dev/null
grep -F '"organization":""' "$RESPONSE_FILE" >/dev/null
grep -F '"token":"simulated-jwt-token-for-' "$RESPONSE_FILE" >/dev/null
if grep -F '"password":' "$RESPONSE_FILE" >/dev/null; then
  echo 'password field should not be present in response' >&2
  exit 1
fi

echo "CODEVALID_TEST_ASSERTION_OK:signup_success_all_required_fields"

# Cleanup — no API or DB cleanup path exists for in-memory users; temp file removed by trap.
