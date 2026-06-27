#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
RESPONSE_FILE="/tmp/view_registrations_for_existing_event_${CASE_SUFFIX}.json"
STATUS_FILE="/tmp/view_registrations_for_existing_event_${CASE_SUFFIX}.status"
cleanup_files() {
  rm -f "$RESPONSE_FILE" "$STATUS_FILE"
}
trap cleanup_files EXIT

# Given — use the seeded existing event that already has registrations
EVENT_ID="event_1"

# When — retrieve registrations for the existing event
curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' "$BASE_URL/api/registrations/${EVENT_ID}" > "$STATUS_FILE"

# Then — response is 200 with two registrations sorted by registeredAt descending
STATUS="$(cat "$STATUS_FILE")"
[ "$STATUS" = "200" ]
[ "$(jq 'length' "$RESPONSE_FILE")" = "2" ]
[ "$(jq -r '.[0].eventId' "$RESPONSE_FILE")" = "$EVENT_ID" ]
[ "$(jq -r '.[1].eventId' "$RESPONSE_FILE")" = "$EVENT_ID" ]
[ "$(jq -r '.[0].name' "$RESPONSE_FILE")" = "Bob Builder" ]
[ "$(jq -r '.[1].name' "$RESPONSE_FILE")" = "Alice Vance" ]
FIRST_TIME="$(jq -r '.[0].registeredAt' "$RESPONSE_FILE")"
SECOND_TIME="$(jq -r '.[1].registeredAt' "$RESPONSE_FILE")"
[ "$FIRST_TIME" \> "$SECOND_TIME" ]

# Cleanup — stateless test using seeded in-memory data; nothing to undo

echo "CODEVALID_TEST_ASSERTION_OK:view_registrations_for_existing_event"
