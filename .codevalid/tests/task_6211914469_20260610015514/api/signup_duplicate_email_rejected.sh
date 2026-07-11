#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
EXISTING_USERNAME="existinguser01_${CASE_SUFFIX}"
EXISTING_EMAIL="existinguser_${CASE_SUFFIX}@test.com"
NEW_USERNAME="newusername123_${CASE_SUFFIX}"
PASSWORD="NewPass123!"
FULL_NAME="New User Name ${CASE_SUFFIX}"
TMP_DIR="$(mktemp -d)"
SETUP_BODY="$TMP_DIR/setup.json"
SETUP_STATUS="$TMP_DIR/setup.status"
RESPONSE_FILE="$TMP_DIR/response.json"
STATUS_FILE="$TMP_DIR/response.status"
cleanup_files() {
  rm -rf "$TMP_DIR"
}
trap cleanup_files EXIT

# Given — create an existing user with the email that will be reused
curl -sS -o "$SETUP_BODY" -w '%{http_code}' \
  -X POST "$BASE_URL/api/auth/signup" \
  -H 'Content-Type: application/json' \
  --data "{\"username\":\"${EXISTING_USERNAME}\",\"email\":\"${EXISTING_EMAIL}\",\"password\":\"${PASSWORD}\",\"fullName\":\"Existing User ${CASE_SUFFIX}\"}" \
  > "$SETUP_STATUS"
[ "$(cat "$SETUP_STATUS")" = "201" ]

# When — submit a second signup with a duplicate email and unique username
curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/auth/signup" \
  -H 'Content-Type: application/json' \
  --data "{\"username\":\"${NEW_USERNAME}\",\"email\":\"${EXISTING_EMAIL}\",\"password\":\"${PASSWORD}\",\"fullName\":\"${FULL_NAME}\"}" \
  > "$STATUS_FILE"

# Then — duplicate email is rejected
STATUS="$(cat "$STATUS_FILE")"
[ "$STATUS" = "400" ]
grep -F '"message":"Username or Email already registered."' "$RESPONSE_FILE" >/dev/null

echo "CODEVALID_TEST_ASSERTION_OK:signup_duplicate_email_rejected"

# Cleanup — no delete endpoint exists for users in this in-memory API; unique data is isolated and resets with container lifecycle
