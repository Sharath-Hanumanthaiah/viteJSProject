#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
USERNAME="validusername123_${CASE_SUFFIX}"
PASSWORD="ValidPass789!"
FULL_NAME="Valid User Name ${CASE_SUFFIX}"
RESPONSE_FILE="/tmp/signup_validation_missing_email_${CASE_SUFFIX}.json"
STATUS_FILE="/tmp/signup_validation_missing_email_${CASE_SUFFIX}.status"
cleanup_files() {
  rm -f "$RESPONSE_FILE" "$STATUS_FILE"
}
trap cleanup_files EXIT

# Given — prepare signup payload with missing email
:

# When — submit signup request without email
curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/auth/signup" \
  -H 'Content-Type: application/json' \
  --data "{\"username\":\"${USERNAME}\",\"password\":\"${PASSWORD}\",\"fullName\":\"${FULL_NAME}\"}" \
  > "$STATUS_FILE"

# Then — request is rejected with required fields validation message
STATUS="$(cat "$STATUS_FILE")"
[ "$STATUS" = "400" ]
grep -F '"message":"Username, email, password, and full name are required."' "$RESPONSE_FILE" >/dev/null

echo "CODEVALID_TEST_ASSERTION_OK:signup_validation_missing_email"

# Cleanup — stateless validation failure created no user
