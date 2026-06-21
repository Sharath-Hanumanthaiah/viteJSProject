#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
RESPONSE_FILE="/tmp/view_registrations_event_not_found_${CASE_SUFFIX}.json"

cleanup_files() {
  rm -f "$RESPONSE_FILE"
}
trap cleanup_files EXIT

# Given — choose an event id that does not exist.
EVENT_ID="evt-nonexistent"

# When — request registrations for a missing event.
HTTP_STATUS="$(curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' "$BASE_URL/api/registrations/$EVENT_ID")"

# Then — response is 404 with the expected error message.
[ "$HTTP_STATUS" = "404" ]
grep -F '"message":"Event not found."' "$RESPONSE_FILE" >/dev/null

echo "CODEVALID_TEST_ASSERTION_OK:view_registrations_event_not_found"

# Cleanup — no API side effects; only temporary files are removed by trap.
