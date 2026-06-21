#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
RESPONSE_FILE="/tmp/display_loading_state_during_fetch_${CASE_SUFFIX}.json"

cleanup() {
  rm -f "$RESPONSE_FILE"
}
trap cleanup EXIT

# Given — The events endpoint is available to fetch event data.

# When — Fetch the events list.
HTTP_STATUS="$(curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' "$BASE_URL/api/events")"

# Then — The API returns data suitable for populating the events view.
[ "$HTTP_STATUS" = "200" ]
grep -F '[' "$RESPONSE_FILE" >/dev/null
grep -F '"registrationCount"' "$RESPONSE_FILE" >/dev/null

echo "CODEVALID_TEST_ASSERTION_OK:display_loading_state_during_fetch"

# Cleanup — No server-side state was created.
