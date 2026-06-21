#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
USERNAME="tokenuser-${CASE_SUFFIX}"
EMAIL="token-${CASE_SUFFIX}@test.com"
PASSWORD="tokenpass"
FULL_NAME="Token Test ${CASE_SUFFIX}"
RESPONSE_FILE="/tmp/signup_token_generation_format_${CASE_SUFFIX}.json"

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

# Then — verify 201 response and token format simulated-jwt-token-for-{userId}.
[ "$HTTP_STATUS" = "201" ]
USER_ID="$(grep -o '"id":"[^"]*"' "$RESPONSE_FILE" | head -1 | cut -d'"' -f4)"
[ -n "$USER_ID" ]
grep -F "\"token\":\"simulated-jwt-token-for-${USER_ID}\"" "$RESPONSE_FILE" >/dev/null

echo "CODEVALID_TEST_ASSERTION_OK:signup_token_generation_format"

# Cleanup — no API or DB cleanup path exists for in-memory users; temp file removed by trap.
