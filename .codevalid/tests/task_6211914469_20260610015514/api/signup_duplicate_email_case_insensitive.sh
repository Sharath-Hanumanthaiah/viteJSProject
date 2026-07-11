#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
EXISTING_USERNAME="existingcase_${CASE_SUFFIX}"
EXISTING_EMAIL="ExistingEmail_${CASE_SUFFIX}@Test.com"
LOWERCASE_EMAIL="existingemail_${CASE_SUFFIX}@test.com"
NEW_USERNAME="newusername999_${CASE_SUFFIX}"
PASSWORD="NewPass999!"
TMP_DIR="$(mktemp -d)"
SETUP_BODY="$TMP_DIR/setup.json"
SETUP_STATUS="$TMP_DIR/setup.status"
RESPONSE_FILE="$TMP_DIR/response.json"
STATUS_FILE="$TMP_DIR/response.status"
cleanup_files() {
  rm -rf "$TMP_DIR"
}
trap cleanup_files EXIT

# Given — create an existing user whose email will be reused with different case
curl -sS -o "$SETUP_BODY" -w '%{http_code}' \
  -X POST "$BASE_URL/api/auth/signup" \
  -H 'Content-Type: application/json' \
  --data "{\"username\":\"${EXISTING_USERNAME}\",\"email\":\"${EXISTING_EMAIL}\",\"password\":\"${PASSWORD}\",\"fullName\":\"Existing Case User ${CASE_SUFFIX}\"}" \
  > "$SETUP_STATUS"
[ "$(cat "$SETUP_STATUS")" = "201" ]

# When — submit a second signup using the same email in lowercase form
curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/auth/signup" \
  -H 'Content-Type: application/json' \
  --data "{\"username\":\"${NEW_USERNAME}\",\"email\":\"${LOWERCASE_EMAIL}\",\"password\":\"${PASSWORD}\",\"fullName\":\"New User Name ${CASE_SUFFIX}\"}" \
  > "$STATUS_FILE"

# Then — case-insensitive duplicate email is rejected
STATUS="$(cat "$STATUS_FILE")"
[ "$STATUS" = "400" ]
grep -F '"message":"Username or Email already registered."' "$RESPONSE_FILE" >/dev/null

echo "CODEVALID_TEST_ASSERTION_OK:signup_duplicate_email_case_insensitive"

# Cleanup — no delete endpoint exists for users in this in-memory API; unique data is isolated and resets with container lifecycle
