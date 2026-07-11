#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
USERNAME="secureuser-${CASE_SUFFIX}"
EMAIL="secure-${CASE_SUFFIX}@test.com"
PASSWORD="MySecretPassword123"
FULL_NAME="Security Test ${CASE_SUFFIX}"
RESPONSE_FILE="/tmp/signup_password_excluded_from_response_${CASE_SUFFIX}.json"
STATUS_FILE="/tmp/signup_password_excluded_from_response_${CASE_SUFFIX}.status"
cleanup_files() {
  rm -f "$RESPONSE_FILE" "$STATUS_FILE"
}
trap cleanup_files EXIT

# Given — prepare unique signup payload for response security verification
:

# When — submit successful signup request
curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/auth/signup" \
  -H 'Content-Type: application/json' \
  --data "{\"username\":\"${USERNAME}\",\"email\":\"${EMAIL}\",\"password\":\"${PASSWORD}\",\"fullName\":\"${FULL_NAME}\"}" \
  > "$STATUS_FILE"

# Then — expect 201 and confirm password is excluded while other fields are present
STATUS="$(cat "$STATUS_FILE")"
[ "$STATUS" = "201" ]
grep -F '"id":"user_' "$RESPONSE_FILE" >/dev/null
grep -F "\"username\":\"${USERNAME}\"" "$RESPONSE_FILE" >/dev/null
grep -F "\"email\":\"${EMAIL}\"" "$RESPONSE_FILE" >/dev/null
grep -F "\"fullName\":\"${FULL_NAME}\"" "$RESPONSE_FILE" >/dev/null
if grep -F '"password":' "$RESPONSE_FILE" >/dev/null; then
  echo "password should not be returned in signup response"
  exit 1
fi

# Cleanup — no delete endpoint exists for users in this in-memory API; unique data prevents collisions and state resets with container lifecycle

echo "CODEVALID_TEST_ASSERTION_OK:signup_password_excluded_from_response"
