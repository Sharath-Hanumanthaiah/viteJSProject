#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
EMAIL="validuser-${CASE_SUFFIX}@example.com"
CORRECT_PASSWORD="correctPassword123"
WRONG_PASSWORD="wrongPassword456"
USERNAME="validuser_${CASE_SUFFIX}"
FULL_NAME="Valid User ${CASE_SUFFIX}"
TMP_DIR="$(mktemp -d)"
SIGNUP_BODY="$TMP_DIR/signup.json"
SIGNUP_STATUS="$TMP_DIR/signup.status"
RESPONSE_FILE="$TMP_DIR/response.json"
STATUS_FILE="$TMP_DIR/response.status"
cleanup_files() {
  rm -rf "$TMP_DIR"
}
trap cleanup_files EXIT

# Given — create a user with known valid credentials
curl -sS -o "$SIGNUP_BODY" -w '%{http_code}' \
  -X POST "$BASE_URL/api/auth/signup" \
  -H 'Content-Type: application/json' \
  --data "{\"username\":\"${USERNAME}\",\"email\":\"${EMAIL}\",\"password\":\"${CORRECT_PASSWORD}\",\"fullName\":\"${FULL_NAME}\"}" \
  > "$SIGNUP_STATUS"
[ "$(cat "$SIGNUP_STATUS")" = "201" ]

# When — attempt signin with the wrong password
curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/auth/signin" \
  -H 'Content-Type: application/json' \
  --data "{\"email\":\"${EMAIL}\",\"password\":\"${WRONG_PASSWORD}\"}" \
  > "$STATUS_FILE"

# Then — authentication fails with 401
STATUS="$(cat "$STATUS_FILE")"
[ "$STATUS" = "401" ]
grep -F '"message":"Invalid email or password."' "$RESPONSE_FILE" >/dev/null

echo "CODEVALID_TEST_ASSERTION_OK:signin_invalid_credentials_wrong_password"

# Cleanup — no delete endpoint exists for users in this in-memory API; test data is isolated by unique suffix and resets with container lifecycle
