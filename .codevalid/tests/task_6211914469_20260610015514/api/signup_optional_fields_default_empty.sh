#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
USERNAME="minimaluser_${CASE_SUFFIX}"
EMAIL="minimaluser_${CASE_SUFFIX}@test.com"
PASSWORD="MinimalPass1!"
FULL_NAME="Minimal User ${CASE_SUFFIX}"
RESPONSE_FILE="/tmp/signup_optional_fields_default_empty_${CASE_SUFFIX}.json"
STATUS_FILE="/tmp/signup_optional_fields_default_empty_${CASE_SUFFIX}.status"
cleanup_files() {
  rm -f "$RESPONSE_FILE" "$STATUS_FILE"
}
trap cleanup_files EXIT

# Given — prepare unique signup data omitting optional fields
:

# When — submit signup request without phone and organization
curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/auth/signup" \
  -H 'Content-Type: application/json' \
  --data "{\"username\":\"${USERNAME}\",\"email\":\"${EMAIL}\",\"password\":\"${PASSWORD}\",\"fullName\":\"${FULL_NAME}\"}" \
  > "$STATUS_FILE"

# Then — optional fields default to empty strings in the created user
STATUS="$(cat "$STATUS_FILE")"
[ "$STATUS" = "201" ]
grep -F "\"username\":\"${USERNAME}\"" "$RESPONSE_FILE" >/dev/null
grep -F "\"email\":\"${EMAIL}\"" "$RESPONSE_FILE" >/dev/null
grep -F "\"fullName\":\"${FULL_NAME}\"" "$RESPONSE_FILE" >/dev/null
grep -F '"phone":""' "$RESPONSE_FILE" >/dev/null
grep -F '"organization":""' "$RESPONSE_FILE" >/dev/null
grep -F '"token":"simulated-jwt-token-for-' "$RESPONSE_FILE" >/dev/null
if grep -F '"password":' "$RESPONSE_FILE" >/dev/null; then
  echo "password should not be returned in signup response"
  exit 1
fi

echo "CODEVALID_TEST_ASSERTION_OK:signup_optional_fields_default_empty"

# Cleanup — no delete endpoint exists for users in this in-memory API; unique data is isolated and resets with container lifecycle
