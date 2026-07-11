#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
EXISTING_USERNAME="existinguser-${CASE_SUFFIX}"
EXISTING_EMAIL="existing-${CASE_SUFFIX}@test.com"
NEW_USERNAME="newdifferent-${CASE_SUFFIX}"
PASSWORD="newpass123"
FULL_NAME="Another User ${CASE_SUFFIX}"
SETUP_RESPONSE_FILE="/tmp/signup_duplicate_email_setup_${CASE_SUFFIX}.json"
SETUP_STATUS_FILE="/tmp/signup_duplicate_email_setup_${CASE_SUFFIX}.status"
RESPONSE_FILE="/tmp/signup_duplicate_email_${CASE_SUFFIX}.json"
STATUS_FILE="/tmp/signup_duplicate_email_${CASE_SUFFIX}.status"
cleanup_files() {
  rm -f "$SETUP_RESPONSE_FILE" "$SETUP_STATUS_FILE" "$RESPONSE_FILE" "$STATUS_FILE"
}
trap cleanup_files EXIT

# Given — create an existing user with the email that will be reused
curl -sS -o "$SETUP_RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/auth/signup" \
  -H 'Content-Type: application/json' \
  --data "{\"username\":\"${EXISTING_USERNAME}\",\"email\":\"${EXISTING_EMAIL}\",\"password\":\"SeedPass123!\",\"fullName\":\"Existing User ${CASE_SUFFIX}\"}" \
  > "$SETUP_STATUS_FILE"
[ "$(cat "$SETUP_STATUS_FILE")" = "201" ]

# When — submit signup request with a duplicate email and different username
curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/auth/signup" \
  -H 'Content-Type: application/json' \
  --data "{\"username\":\"${NEW_USERNAME}\",\"email\":\"${EXISTING_EMAIL}\",\"password\":\"${PASSWORD}\",\"fullName\":\"${FULL_NAME}\"}" \
  > "$STATUS_FILE"

# Then — expect duplicate registration error
STATUS="$(cat "$STATUS_FILE")"
[ "$STATUS" = "400" ]
grep -F '"message":"Username or Email already registered."' "$RESPONSE_FILE" >/dev/null

echo "CODEVALID_TEST_ASSERTION_OK:signup_duplicate_email"

# Cleanup — no delete endpoint exists for users in this in-memory API; test data is isolated and reset with container lifecycle
