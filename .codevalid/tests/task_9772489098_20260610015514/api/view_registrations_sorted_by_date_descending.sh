#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
RESPONSE_FILE="/tmp/view_registrations_sorted_by_date_descending_${CASE_SUFFIX}.json"
STATUS_FILE="/tmp/view_registrations_sorted_by_date_descending_${CASE_SUFFIX}.status"
cleanup_files() {
  rm -f "$RESPONSE_FILE" "$STATUS_FILE"
}
trap cleanup_files EXIT

# Given — use the seeded event with multiple registrations at distinct timestamps
EVENT_ID="event_1"

# When — retrieve registrations for the event
curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' "$BASE_URL/api/registrations/${EVENT_ID}" > "$STATUS_FILE"

# Then — response is 200 and registrations are sorted by registeredAt descending
STATUS="$(cat "$STATUS_FILE")"
[ "$STATUS" = "200" ]
[ "$(jq 'length' "$RESPONSE_FILE")" = "2" ]
FIRST_NAME="$(jq -r '.[0].name' "$RESPONSE_FILE")"
SECOND_NAME="$(jq -r '.[1].name' "$RESPONSE_FILE")"
[ "$FIRST_NAME" = "Bob Builder" ]
[ "$SECOND_NAME" = "Alice Vance" ]
FIRST_TIME="$(jq -r '.[0].registeredAt' "$RESPONSE_FILE")"
SECOND_TIME="$(jq -r '.[1].registeredAt' "$RESPONSE_FILE")"
[ "$FIRST_TIME" \> "$SECOND_TIME" ]

# Cleanup — stateless test using seeded in-memory data; nothing to undo

echo "CODEVALID_TEST_ASSERTION_OK:view_registrations_sorted_by_date_descending"
