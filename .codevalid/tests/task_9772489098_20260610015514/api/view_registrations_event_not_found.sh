#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="${CASE_SUFFIX:-$(date +%s)-$$}"
EVENT_ID="evt-nonexistent-${CASE_SUFFIX}"
RESPONSE_FILE="/tmp/view_registrations_event_not_found_${CASE_SUFFIX}.json"
STATUS_FILE="/tmp/view_registrations_event_not_found_${CASE_SUFFIX}.status"
cleanup_files() {
  rm -f "$RESPONSE_FILE" "$STATUS_FILE"
}
trap cleanup_files EXIT

# Given
# Stateless setup only: use a unique event id that does not exist.

# When
curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' "$BASE_URL/api/registrations/${EVENT_ID}" > "$STATUS_FILE"

# Then
[ "$(cat "$STATUS_FILE")" = "404" ]
grep -F '"message":"Event not found."' "$RESPONSE_FILE" >/dev/null

echo "CODEVALID_TEST_ASSERTION_OK:view_registrations_event_not_found"
