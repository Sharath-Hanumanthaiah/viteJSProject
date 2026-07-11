#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
USERNAME="employeeworker_${CASE_SUFFIX}"
EMAIL="employeetest_${CASE_SUFFIX}@company.com"
PASSWORD="CompanyPass456!"
FULL_NAME="Employee Test Name ${CASE_SUFFIX}"
PHONE="+1-555-123-4567"
ORGANIZATION="Test Organization Inc."
RESPONSE_FILE="/tmp/successful_signup_with_optional_fields_${CASE_SUFFIX}.json"
STATUS_FILE="/tmp/successful_signup_with_optional_fields_${CASE_SUFFIX}.status"
cleanup_files() {
  rm -f "$RESPONSE_FILE" "$STATUS_FILE"
}
trap cleanup_files EXIT

# Given — prepare unique signup data including optional fields
:

# When — submit signup request with required and optional fields
curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/auth/signup" \
  -H 'Content-Type: application/json' \
  --data "{\"username\":\"${USERNAME}\",\"email\":\"${EMAIL}\",\"password\":\"${PASSWORD}\",\"fullName\":\"${FULL_NAME}\",\"phone\":\"${PHONE}\",\"organization\":\"${ORGANIZATION}\"}" \
  > "$STATUS_FILE"

# Then — response includes persisted optional fields and token
STATUS="$(cat "$STATUS_FILE")"
[ "$STATUS" = "201" ]
grep -F "\"username\":\"${USERNAME}\"" "$RESPONSE_FILE" >/dev/null
grep -F "\"email\":\"${EMAIL}\"" "$RESPONSE_FILE" >/dev/null
grep -F "\"fullName\":\"${FULL_NAME}\"" "$RESPONSE_FILE" >/dev/null
grep -F "\"phone\":\"${PHONE}\"" "$RESPONSE_FILE" >/dev/null
grep -F "\"organization\":\"${ORGANIZATION}\"" "$RESPONSE_FILE" >/dev/null
grep -F '"token":"simulated-jwt-token-for-' "$RESPONSE_FILE" >/dev/null
if grep -F '"password":' "$RESPONSE_FILE" >/dev/null; then
  echo "password should not be returned in signup response"
  exit 1
fi

echo "CODEVALID_TEST_ASSERTION_OK:successful_signup_with_optional_fields"

# Cleanup — no delete endpoint exists for users in this in-memory API; unique data is isolated and resets with container lifecycle
