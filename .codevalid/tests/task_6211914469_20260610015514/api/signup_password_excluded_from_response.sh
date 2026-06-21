#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
USERNAME="secureuser-${CASE_SUFFIX}"
EMAIL="secure-${CASE_SUFFIX}@test.com"
PASSWORD="MySecretPassword123"
FULL_NAME="Security Test ${CASE_SUFFIX}"
RESPONSE_FILE="/tmp/signup_password_excluded_from_response_${CASE_SUFFIX}.json"

cleanup() {
  rm -f "$RESPONSE_FILE"
}
trap cleanup EXIT

# Given — prepare unique signup values.
: > /dev/null

# When — send signup request with valid required fields.
HTTP_STATUS="$(curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/auth/signup" \
  -H 'Content-Type: application/json' \
  --data "{\"username\":\"${USERNAME}\",\"email\":\"${EMAIL}\",\"password\":\"${PASSWORD}\",\"fullName\":\"${FULL_NAME}\"}")"

# Then — verify 201 response, expected fields, and password omission.
[ "$HTTP_STATUS" = "201" ]
grep -F "\"username\":\"${USERNAME}\"" "$RESPONSE_FILE" >/dev/null
grep -F "\"email\":\"${EMAIL}\"" "$RESPONSE_FILE" >/dev/null
grep -F "\"fullName\":\"${FULL_NAME}\"" "$RESPONSE_FILE" >/dev/null
if grep -F '"password":' "$RESPONSE_FILE" >/dev/null; then
  echo 'password field should not be present in signup response' >&2
  exit 1
fi

echo "CODEVALID_TEST_ASSERTION_OK:signup_password_excluded_from_response"

# Cleanup — no API or DB cleanup path exists for in-memory users; temp file removed by trap.
