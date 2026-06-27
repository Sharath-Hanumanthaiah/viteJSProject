#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
RESPONSE_FILE="/tmp/view_registrations_empty_list_${CASE_SUFFIX}.json"
STATUS_FILE="/tmp/view_registrations_empty_list_${CASE_SUFFIX}.status"
cleanup_files() {
  rm -f "$RESPONSE_FILE" "$STATUS_FILE"
}
trap cleanup_files EXIT

# Given — use the seeded existing event that has no registrations
EVENT_ID="event_2"

# When — retrieve registrations for the event
curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' "$BASE_URL/api/registrations/${EVENT_ID}" > "$STATUS_FILE"

# Then — response is 200 and the body is an empty array
STATUS="$(cat "$STATUS_FILE")"
[ "$STATUS" = "200" ]
[ "$(jq 'length' "$RESPONSE_FILE")" = "0" ]
[ "$(jq -c '.' "$RESPONSE_FILE")" = "[]" ]

# Cleanup — stateless test using seeded in-memory data; nothing to undo

echo "CODEVALID_TEST_ASSERTION_OK:view_registrations_empty_list"
