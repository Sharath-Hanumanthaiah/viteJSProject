#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
EMAIL="navuser-${CASE_SUFFIX}@example.com"
PASSWORD="navPass123"
USERNAME="navuser_${CASE_SUFFIX}"
FULL_NAME="Nav User ${CASE_SUFFIX}"
TMP_DIR="$(mktemp -d)"
SIGNUP_BODY="$TMP_DIR/signup.json"
SIGNUP_STATUS="$TMP_DIR/signup.status"
RESPONSE_FILE="$TMP_DIR/response.json"
STATUS_FILE="$TMP_DIR/response.status"
cleanup_files() {
  rm -rf "$TMP_DIR"
}
trap cleanup_files EXIT

# Given — create a user eligible for successful signin
curl -sS -o "$SIGNUP_BODY" -w '%{http_code}' \
  -X POST "$BASE_URL/api/auth/signup" \
  -H 'Content-Type: application/json' \
  --data "{\"username\":\"${USERNAME}\",\"email\":\"${EMAIL}\",\"password\":\"${PASSWORD}\",\"fullName\":\"${FULL_NAME}\"}" \
  > "$SIGNUP_STATUS"
[ "$(cat "$SIGNUP_STATUS")" = "201" ]

# When — submit valid signin credentials
curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/auth/signin" \
  -H 'Content-Type: application/json' \
  --data "{\"email\":\"${EMAIL}\",\"password\":\"${PASSWORD}\"}" \
  > "$STATUS_FILE"

# Then — API returns successful authentication payload that the UI uses to navigate to the dashboard
STATUS="$(cat "$STATUS_FILE")"
[ "$STATUS" = "200" ]
grep -F "\"email\":\"${EMAIL}\"" "$RESPONSE_FILE" >/dev/null
grep -F '"token":"simulated-jwt-token-for-' "$RESPONSE_FILE" >/dev/null

echo "CODEVALID_TEST_ASSERTION_OK:signin_navigation_to_dashboard"

# Cleanup — no delete endpoint exists for users in this in-memory API; test data is isolated by unique suffix and resets with container lifecycle
