#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
RESPONSE_FILE="/tmp/signin_case_insensitive_email_success_${CASE_SUFFIX}.json"
SIGNUP_RESPONSE_FILE="/tmp/signin_case_insensitive_email_success_signup_${CASE_SUFFIX}.json"
STORED_EMAIL="Admin.${CASE_SUFFIX}@Example.COM"
LOGIN_EMAIL="admin.${CASE_SUFFIX}@example.com"
USERNAME="admin_${CASE_SUFFIX}"
FULL_NAME="Admin User ${CASE_SUFFIX}"
PASSWORD="AdminPass999"

cleanup_files() {
  rm -f "$RESPONSE_FILE" "$SIGNUP_RESPONSE_FILE"
}
trap cleanup_files EXIT

# Given — create a user whose stored email uses mixed case.
SIGNUP_STATUS="$(curl -sS -o "$SIGNUP_RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/auth/signup" \
  -H 'Content-Type: application/json' \
  --data "{\"username\":\"${USERNAME}\",\"email\":\"${STORED_EMAIL}\",\"password\":\"${PASSWORD}\",\"fullName\":\"${FULL_NAME}\"}")"
[ "$SIGNUP_STATUS" = "201" ]

# When — sign in using the same email with different casing.
HTTP_STATUS="$(curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/auth/signin" \
  -H 'Content-Type: application/json' \
  --data "{\"email\":\"${LOGIN_EMAIL}\",\"password\":\"${PASSWORD}\"}")"

# Then — response is 200 and returns the stored user details with a token.
[ "$HTTP_STATUS" = "200" ]
grep -F '"user":' "$RESPONSE_FILE" >/dev/null
grep -F "\"email\":\"${STORED_EMAIL}\"" "$RESPONSE_FILE" >/dev/null
grep -F "\"fullName\":\"${FULL_NAME}\"" "$RESPONSE_FILE" >/dev/null
grep -F '"token":"simulated-jwt-token-for-' "$RESPONSE_FILE" >/dev/null
if grep -F '"password":' "$RESPONSE_FILE" >/dev/null; then
  echo 'password field should not be present in signin response'
  exit 1
fi

echo 'CODEVALID_TEST_ASSERTION_OK:signin_case_insensitive_email_success'

# Cleanup — no delete endpoint or database seam is exposed; temp files are removed by trap.
