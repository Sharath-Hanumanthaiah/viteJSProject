#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
RESPONSE_FILE="/tmp/signin_valid_credentials_success_${CASE_SUFFIX}.json"
SIGNUP_RESPONSE_FILE="/tmp/signin_valid_credentials_success_signup_${CASE_SUFFIX}.json"
EMAIL="john.doe.${CASE_SUFFIX}@example.com"
USERNAME="john_${CASE_SUFFIX}"
FULL_NAME="John Doe ${CASE_SUFFIX}"
PASSWORD="SecurePass123!"

cleanup_files() {
  rm -f "$RESPONSE_FILE" "$SIGNUP_RESPONSE_FILE"
}
trap cleanup_files EXIT

# Given — create a user that can successfully sign in.
SIGNUP_STATUS="$(curl -sS -o "$SIGNUP_RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/auth/signup" \
  -H 'Content-Type: application/json' \
  --data "{\"username\":\"${USERNAME}\",\"email\":\"${EMAIL}\",\"password\":\"${PASSWORD}\",\"fullName\":\"${FULL_NAME}\"}")"
[ "$SIGNUP_STATUS" = "201" ]

# When — sign in with the created credentials.
HTTP_STATUS="$(curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/auth/signin" \
  -H 'Content-Type: application/json' \
  --data "{\"email\":\"${EMAIL}\",\"password\":\"${PASSWORD}\"}")"

# Then — response is 200, includes user and token, and excludes password.
[ "$HTTP_STATUS" = "200" ]
grep -F '"user":' "$RESPONSE_FILE" >/dev/null
grep -F "\"email\":\"${EMAIL}\"" "$RESPONSE_FILE" >/dev/null
grep -F '"id":"user-' "$RESPONSE_FILE" >/dev/null
grep -F "\"fullName\":\"${FULL_NAME}\"" "$RESPONSE_FILE" >/dev/null
grep -F '"token":"simulated-jwt-token-for-' "$RESPONSE_FILE" >/dev/null
if grep -F '"password":' "$RESPONSE_FILE" >/dev/null; then
  echo 'password field should not be present in signin response'
  exit 1
fi
if grep -F "$PASSWORD" "$RESPONSE_FILE" >/dev/null; then
  echo 'plaintext password should not appear in signin response'
  exit 1
fi

echo 'CODEVALID_TEST_ASSERTION_OK:signin_valid_credentials_success'

# Cleanup — no delete endpoint or database seam is exposed; temp files are removed by trap.
