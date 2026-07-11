#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
USERNAME="dashboarduser_${CASE_SUFFIX}"
EMAIL="dashboardtest_${CASE_SUFFIX}@test.com"
PASSWORD="DashboardPass1!"
FULL_NAME="Dashboard User ${CASE_SUFFIX}"
RESPONSE_FILE="/tmp/signup_redirect_to_dashboard_${CASE_SUFFIX}.json"
STATUS_FILE="/tmp/signup_redirect_to_dashboard_${CASE_SUFFIX}.status"
cleanup_files() {
  rm -f "$RESPONSE_FILE" "$STATUS_FILE"
}
trap cleanup_files EXIT

# Given — prepare unique signup data for a successful authentication flow
:

# When — submit signup request that should authenticate the user
curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/auth/signup" \
  -H 'Content-Type: application/json' \
  --data "{\"username\":\"${USERNAME}\",\"email\":\"${EMAIL}\",\"password\":\"${PASSWORD}\",\"fullName\":\"${FULL_NAME}\"}" \
  > "$STATUS_FILE"

# Then — API grants access by returning the authenticated user and token used for dashboard redirect by the UI
STATUS="$(cat "$STATUS_FILE")"
[ "$STATUS" = "201" ]
grep -F "\"username\":\"${USERNAME}\"" "$RESPONSE_FILE" >/dev/null
grep -F "\"email\":\"${EMAIL}\"" "$RESPONSE_FILE" >/dev/null
grep -F '"token":"simulated-jwt-token-for-' "$RESPONSE_FILE" >/dev/null
if grep -F '"password":' "$RESPONSE_FILE" >/dev/null; then
  echo "password should not be returned in signup response"
  exit 1
fi

echo "CODEVALID_TEST_ASSERTION_OK:signup_redirect_to_dashboard"

# Cleanup — no delete endpoint exists for users in this in-memory API; redirect behavior is handled by UI after this successful API response
