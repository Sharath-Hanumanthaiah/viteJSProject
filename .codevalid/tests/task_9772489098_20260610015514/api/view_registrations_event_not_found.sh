#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
MISSING_EVENT_ID="evt-nonexistent-${CASE_SUFFIX}"
RESPONSE_FILE="/tmp/view_registrations_event_not_found_${CASE_SUFFIX}.json"
STATUS_FILE="/tmp/view_registrations_event_not_found_${CASE_SUFFIX}.status"
cleanup_files() {
  rm -f "$RESPONSE_FILE" "$STATUS_FILE"
}
trap cleanup_files EXIT

# Given — choose a unique event id that does not exist in the in-memory store
: "$MISSING_EVENT_ID"

# When — request registrations for the non-existent event
curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' "$BASE_URL/api/registrations/${MISSING_EVENT_ID}" > "$STATUS_FILE"

# Then — response is 404 with the expected message
STATUS="$(cat "$STATUS_FILE")"
[ "$STATUS" = "404" ]
[ "$(jq -r '.message' "$RESPONSE_FILE")" = "Event not found." ]

# Cleanup — stateless test, nothing to undo

echo "CODEVALID_TEST_ASSERTION_OK:view_registrations_event_not_found"
