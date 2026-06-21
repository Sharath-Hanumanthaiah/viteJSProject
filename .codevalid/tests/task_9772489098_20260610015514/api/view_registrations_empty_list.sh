#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
RESPONSE_FILE="/tmp/view_registrations_empty_list_${CASE_SUFFIX}.json"

cleanup_files() {
  rm -f "$RESPONSE_FILE"
}
trap cleanup_files EXIT

# Given — use an existing event that has no registrations.
EVENT_ID="evt-002"

# When — request registrations for that event.
HTTP_STATUS="$(curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' "$BASE_URL/api/registrations/$EVENT_ID")"

# Then — response is 200 with an empty JSON array.
[ "$HTTP_STATUS" = "200" ]
BODY_COMPACT="$(tr -d '\n[:space:]' < "$RESPONSE_FILE")"
[ "$BODY_COMPACT" = "[]" ]

echo "CODEVALID_TEST_ASSERTION_OK:view_registrations_empty_list"

# Cleanup — no API side effects; only temporary files are removed by trap.
