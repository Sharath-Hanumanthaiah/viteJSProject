#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
USERNAME="validusername789_${CASE_SUFFIX}"
EMAIL="validname_${CASE_SUFFIX}@example.com"
PASSWORD="ValidPass789!"
RESPONSE_FILE="/tmp/signup_validation_missing_full_name_${CASE_SUFFIX}.json"
STATUS_FILE="/tmp/signup_validation_missing_full_name_${CASE_SUFFIX}.status"
cleanup_files() {
  rm -f "$RESPONSE_FILE" "$STATUS_FILE"
}
trap cleanup_files EXIT

# Given — prepare signup payload with missing fullName
:

# When — submit signup request without fullName
curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/auth/signup" \
  -H 'Content-Type: application/json' \
  --data "{\"username\":\"${USERNAME}\",\"email\":\"${EMAIL}\",\"password\":\"${PASSWORD}\"}" \
  > "$STATUS_FILE"

# Then — request is rejected with required fields validation message
STATUS="$(cat "$STATUS_FILE")"
[ "$STATUS" = "400" ]
grep -F '"message":"Username, email, password, and full name are required."' "$RESPONSE_FILE" >/dev/null

echo "CODEVALID_TEST_ASSERTION_OK:signup_validation_missing_full_name"

# Cleanup — stateless validation failure created no user
