#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
RESPONSE_FILE="/tmp/view_registrations_event_not_found_${CASE_SUFFIX}.json"

cleanup() {
  rm -f "$RESPONSE_FILE"
}
trap cleanup EXIT

# Given — No event exists with id evt-nonexistent.

# When — Retrieve registrations for a non-existent event.
HTTP_STATUS="$(curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  "$BASE_URL/api/registrations/evt-nonexistent")"

# Then — Response is 404 with the expected error body.
[ "$HTTP_STATUS" = "404" ]
grep -F '"message":"Event not found."' "$RESPONSE_FILE" >/dev/null

echo "CODEVALID_TEST_ASSERTION_OK:view_registrations_event_not_found"

# Cleanup — No server-side side effects were created; temporary response file is removed by trap.
