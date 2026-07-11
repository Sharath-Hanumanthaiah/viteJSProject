#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
EXISTING_USERNAME="existinguser-${CASE_SUFFIX}"
EXISTING_EMAIL="existing-${CASE_SUFFIX}@test.com"
EXISTING_PASSWORD="ExistingPass123"
EXISTING_FULL_NAME="Existing User ${CASE_SUFFIX}"
NEW_USERNAME="newdifferent-${CASE_SUFFIX}"
RESPONSE_FILE="/tmp/signup_duplicate_email_${CASE_SUFFIX}.json"
STATUS_FILE="/tmp/signup_duplicate_email_${CASE_SUFFIX}.status"
SETUP_RESPONSE_FILE="/tmp/signup_duplicate_email_setup_${CASE_SUFFIX}.json"
SETUP_STATUS_FILE="/tmp/signup_duplicate_email_setup_${CASE_SUFFIX}.status"
cleanup_files() {
  rm -f "$RESPONSE_FILE" "$STATUS_FILE" "$SETUP_RESPONSE_FILE" "$SETUP_STATUS_FILE"
}
trap cleanup_files EXIT

# Given — create an existing user with the target email
curl -sS -o "$SETUP_RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/auth/signup" \
  -H 'Content-Type: application/json' \
  --data "{\"username\":\"${EXISTING_USERNAME}\",\"email\":\"${EXISTING_EMAIL}\",\"password\":\"${EXISTING_PASSWORD}\",\"fullName\":\"${EXISTING_FULL_NAME}\"}" \
  > "$SETUP_STATUS_FILE"
[ "$(cat "$SETUP_STATUS_FILE")" = "201" ]

# When — attempt signup with a different username but duplicate email
curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/auth/signup" \
  -H 'Content-Type: application/json' \
  --data "{\"username\":\"${NEW_USERNAME}\",\"email\":\"${EXISTING_EMAIL}\",\"password\":\"newpass123\",\"fullName\":\"Another User ${CASE_SUFFIX}\"}" \
  > "$STATUS_FILE"

# Then — expect 400 duplicate-user error
STATUS="$(cat "$STATUS_FILE")"
[ "$STATUS" = "400" ]
grep -F '"message":"Username or Email already registered."' "$RESPONSE_FILE" >/dev/null

# Cleanup — no delete endpoint exists for users in this in-memory API; unique setup data isolates test state

echo "CODEVALID_TEST_ASSERTION_OK:signup_duplicate_email"
