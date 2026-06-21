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

cleanup() {
  rm -f "$RESPONSE_FILE"
}
trap cleanup EXIT

# Given — prepare unique identity values and optional field values.
: > /dev/null

# When — send signup request including optional phone and organization.
HTTP_STATUS="$(curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/auth/signup" \
  -H 'Content-Type: application/json' \
  --data "{\"username\":\"${USERNAME}\",\"email\":\"${EMAIL}\",\"password\":\"${PASSWORD}\",\"fullName\":\"${FULL_NAME}\",\"phone\":\"${PHONE}\",\"organization\":\"${ORGANIZATION}\"}")"

# Then — verify 201 response and returned optional fields.
[ "$HTTP_STATUS" = "201" ]
grep -F "\"phone\":\"${PHONE}\"" "$RESPONSE_FILE" >/dev/null
grep -F "\"organization\":\"${ORGANIZATION}\"" "$RESPONSE_FILE" >/dev/null
grep -F '"token":"simulated-jwt-token-for-' "$RESPONSE_FILE" >/dev/null

echo "CODEVALID_TEST_ASSERTION_OK:signup_success_with_optional_fields"

# Cleanup — no API or DB cleanup path exists for in-memory users; temp file removed by trap.
