#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
USERNAME="acmeuser-${CASE_SUFFIX}"
EMAIL="employee-${CASE_SUFFIX}@acme.com"
PASSWORD="Password456"
FULL_NAME="Acme Employee ${CASE_SUFFIX}"
PHONE="+1-555-123-4567"
ORGANIZATION="Acme Corp"
RESPONSE_FILE="/tmp/signup_success_with_optional_fields_${CASE_SUFFIX}.json"
STATUS_FILE="/tmp/signup_success_with_optional_fields_${CASE_SUFFIX}.status"
cleanup_files() {
  rm -f "$RESPONSE_FILE" "$STATUS_FILE"
}
trap cleanup_files EXIT

# Given — prepare unique signup payload with optional fields
:

# When — submit signup request including phone and organization
curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/auth/signup" \
  -H 'Content-Type: application/json' \
  --data "{\"username\":\"${USERNAME}\",\"email\":\"${EMAIL}\",\"password\":\"${PASSWORD}\",\"fullName\":\"${FULL_NAME}\",\"phone\":\"${PHONE}\",\"organization\":\"${ORGANIZATION}\"}" \
  > "$STATUS_FILE"

# Then — expect 201 and optional fields echoed in the user payload
STATUS="$(cat "$STATUS_FILE")"
[ "$STATUS" = "201" ]
grep -F "\"username\":\"${USERNAME}\"" "$RESPONSE_FILE" >/dev/null
grep -F "\"email\":\"${EMAIL}\"" "$RESPONSE_FILE" >/dev/null
grep -F "\"fullName\":\"${FULL_NAME}\"" "$RESPONSE_FILE" >/dev/null
grep -F "\"phone\":\"${PHONE}\"" "$RESPONSE_FILE" >/dev/null
grep -F "\"organization\":\"${ORGANIZATION}\"" "$RESPONSE_FILE" >/dev/null
if grep -F '"password":' "$RESPONSE_FILE" >/dev/null; then
  echo "password should not be returned in signup response"
  exit 1
fi

# Cleanup — no delete endpoint exists for users in this in-memory API; unique data prevents collisions and state resets with container lifecycle

echo "CODEVALID_TEST_ASSERTION_OK:signup_success_with_optional_fields"
