#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
RESPONSE_FILE="/tmp/signin_wrong_password_returns_401_${CASE_SUFFIX}.json"
SIGNUP_RESPONSE_FILE="/tmp/signin_wrong_password_returns_401_signup_${CASE_SUFFIX}.json"
EMAIL="jane.smith.${CASE_SUFFIX}@example.com"
USERNAME="jane_${CASE_SUFFIX}"
FULL_NAME="Jane Smith ${CASE_SUFFIX}"
CORRECT_PASSWORD="CorrectPass456"
WRONG_PASSWORD="WrongPassword789"

cleanup_files() {
  rm -f "$RESPONSE_FILE" "$SIGNUP_RESPONSE_FILE"
}
trap cleanup_files EXIT

# Given — create a user with a known correct password.
SIGNUP_STATUS="$(curl -sS -o "$SIGNUP_RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/auth/signup" \
  -H 'Content-Type: application/json' \
  --data "{\"username\":\"${USERNAME}\",\"email\":\"${EMAIL}\",\"password\":\"${CORRECT_PASSWORD}\",\"fullName\":\"${FULL_NAME}\"}")"
[ "$SIGNUP_STATUS" = "201" ]

# When — submit signin with the wrong password.
HTTP_STATUS="$(curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/auth/signin" \
  -H 'Content-Type: application/json' \
  --data "{\"email\":\"${EMAIL}\",\"password\":\"${WRONG_PASSWORD}\"}")"

# Then — response is 401 with the expected invalid-credentials message.
[ "$HTTP_STATUS" = "401" ]
grep -F '"message":"Invalid email or password."' "$RESPONSE_FILE" >/dev/null

echo 'CODEVALID_TEST_ASSERTION_OK:signin_wrong_password_returns_401'

# Cleanup — no delete endpoint or database seam is exposed; temp files are removed by trap.
