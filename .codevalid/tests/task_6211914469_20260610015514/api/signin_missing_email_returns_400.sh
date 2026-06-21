#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
RESPONSE_FILE="/tmp/signin_missing_email_returns_400_${CASE_SUFFIX}.json"

cleanup_files() {
  rm -f "$RESPONSE_FILE"
}
trap cleanup_files EXIT

# Given — no user setup is required.
:

# When — submit signin without email.
HTTP_STATUS="$(curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/auth/signin" \
  -H 'Content-Type: application/json' \
  --data '{"password":"somepassword123"}')"

# Then — response is 400 with the expected validation message.
[ "$HTTP_STATUS" = "400" ]
grep -F '"message":"Email and password are required."' "$RESPONSE_FILE" >/dev/null

echo 'CODEVALID_TEST_ASSERTION_OK:signin_missing_email_returns_400'

# Cleanup — stateless test; temp files are removed by trap.
