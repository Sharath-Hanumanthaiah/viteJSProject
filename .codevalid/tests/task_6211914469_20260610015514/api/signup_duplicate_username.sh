#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
EXISTING_USERNAME="takenname-${CASE_SUFFIX}"
EXISTING_EMAIL="taken-${CASE_SUFFIX}@test.com"
NEW_EMAIL="different-${CASE_SUFFIX}@test.com"
PASSWORD="pass456"
FULL_NAME="New Person ${CASE_SUFFIX}"
SETUP_RESPONSE_FILE="/tmp/signup_duplicate_username_setup_${CASE_SUFFIX}.json"
SETUP_STATUS_FILE="/tmp/signup_duplicate_username_setup_${CASE_SUFFIX}.status"
RESPONSE_FILE="/tmp/signup_duplicate_username_${CASE_SUFFIX}.json"
STATUS_FILE="/tmp/signup_duplicate_username_${CASE_SUFFIX}.status"
cleanup_files() {
  rm -f "$SETUP_RESPONSE_FILE" "$SETUP_STATUS_FILE" "$RESPONSE_FILE" "$STATUS_FILE"
}
trap cleanup_files EXIT

# Given — create an existing user with the username that will be reused
curl -sS -o "$SETUP_RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/auth/signup" \
  -H 'Content-Type: application/json' \
  --data "{\"username\":\"${EXISTING_USERNAME}\",\"email\":\"${EXISTING_EMAIL}\",\"password\":\"SeedPass123!\",\"fullName\":\"Taken User ${CASE_SUFFIX}\"}" \
  > "$SETUP_STATUS_FILE"
[ "$(cat "$SETUP_STATUS_FILE")" = "201" ]

# When — submit signup request with a duplicate username and different email
curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/auth/signup" \
  -H 'Content-Type: application/json' \
  --data "{\"username\":\"${EXISTING_USERNAME}\",\"email\":\"${NEW_EMAIL}\",\"password\":\"${PASSWORD}\",\"fullName\":\"${FULL_NAME}\"}" \
  > "$STATUS_FILE"

# Then — expect duplicate registration error
STATUS="$(cat "$STATUS_FILE")"
[ "$STATUS" = "400" ]
grep -F '"message":"Username or Email already registered."' "$RESPONSE_FILE" >/dev/null

echo "CODEVALID_TEST_ASSERTION_OK:signup_duplicate_username"

# Cleanup — no delete endpoint exists for users in this in-memory API; test data is isolated and reset with container lifecycle
