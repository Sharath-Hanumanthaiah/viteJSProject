#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
RESPONSE_FILE="/tmp/signin_invalid_email_returns_401_${CASE_SUFFIX}.json"
EMAIL="nonexistent.${CASE_SUFFIX}@unknown.com"
PASSWORD="anypassword"

cleanup_files() {
  rm -f "$RESPONSE_FILE"
}
trap cleanup_files EXIT

# Given — use a unique email that has not been registered during this test.
:

# When — submit signin with a non-existent email.
HTTP_STATUS="$(curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/auth/signin" \
  -H 'Content-Type: application/json' \
  --data "{\"email\":\"${EMAIL}\",\"password\":\"${PASSWORD}\"}")"

# Then — response is 401 with the expected invalid-credentials message.
[ "$HTTP_STATUS" = "401" ]
grep -F '"message":"Invalid email or password."' "$RESPONSE_FILE" >/dev/null

echo 'CODEVALID_TEST_ASSERTION_OK:signin_invalid_email_returns_401'

# Cleanup — stateless test; temp files are removed by trap.
