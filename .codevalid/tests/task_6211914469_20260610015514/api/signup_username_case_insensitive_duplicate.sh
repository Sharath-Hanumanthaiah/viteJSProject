#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
EXISTING_USERNAME_LOWER="johnsmith-${CASE_SUFFIX}"
DUPLICATE_USERNAME_UPPER="JOHNSMITH-${CASE_SUFFIX}"
EXISTING_EMAIL="john-${CASE_SUFFIX}@test.com"
NEW_EMAIL="different-${CASE_SUFFIX}@email.com"
SETUP_RESPONSE_FILE="/tmp/signup_username_case_insensitive_duplicate_setup_${CASE_SUFFIX}.json"
SETUP_STATUS_FILE="/tmp/signup_username_case_insensitive_duplicate_setup_${CASE_SUFFIX}.status"
RESPONSE_FILE="/tmp/signup_username_case_insensitive_duplicate_${CASE_SUFFIX}.json"
STATUS_FILE="/tmp/signup_username_case_insensitive_duplicate_${CASE_SUFFIX}.status"
cleanup_files() {
  rm -f "$SETUP_RESPONSE_FILE" "$SETUP_STATUS_FILE" "$RESPONSE_FILE" "$STATUS_FILE"
}
trap cleanup_files EXIT

# Given — create an existing user with a lowercase username
curl -sS -o "$SETUP_RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/auth/signup" \
  -H 'Content-Type: application/json' \
  --data "{\"username\":\"${EXISTING_USERNAME_LOWER}\",\"email\":\"${EXISTING_EMAIL}\",\"password\":\"SeedPass123!\",\"fullName\":\"John Smith ${CASE_SUFFIX}\"}" \
  > "$SETUP_STATUS_FILE"
[ "$(cat "$SETUP_STATUS_FILE")" = "201" ]

# When — submit signup request with same username in different case
curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/auth/signup" \
  -H 'Content-Type: application/json' \
  --data "{\"username\":\"${DUPLICATE_USERNAME_UPPER}\",\"email\":\"${NEW_EMAIL}\",\"password\":\"pass111\",\"fullName\":\"John Smith 2 ${CASE_SUFFIX}\"}" \
  > "$STATUS_FILE"

# Then — expect case-insensitive duplicate detection
STATUS="$(cat "$STATUS_FILE")"
[ "$STATUS" = "400" ]
grep -F '"message":"Username or Email already registered."' "$RESPONSE_FILE" >/dev/null

echo "CODEVALID_TEST_ASSERTION_OK:signup_username_case_insensitive_duplicate"

# Cleanup — no delete endpoint exists for users in this in-memory API; test data is isolated and reset with container lifecycle
