#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
RESPONSE_FILE="/tmp/view_registrations_empty_list_${CASE_SUFFIX}.json"

cleanup() {
  rm -f "$RESPONSE_FILE"
}
trap cleanup EXIT

# Given — The seeded application data contains event evt-002 and no registrations for it.
# No public setup API is available, so this test validates the expected seeded state.

# When — Retrieve registrations for the event with no registrations.
HTTP_STATUS="$(curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  "$BASE_URL/api/registrations/evt-002")"

# Then — Response is 200 with an empty JSON array.
[ "$HTTP_STATUS" = "200" ]
BODY_COMPACT="$(tr -d '[:space:]' < "$RESPONSE_FILE")"
[ "$BODY_COMPACT" = "[]" ]

echo "CODEVALID_TEST_ASSERTION_OK:view_registrations_empty_list"

# Cleanup — No server-side side effects were created; temporary response file is removed by trap.
