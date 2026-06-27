#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="${CASE_SUFFIX:-$(date +%s)-$$}"
EVENT_TITLE="New Workshop ${CASE_SUFFIX}"
RESPONSE_CREATE_EVENT="/tmp/view_registrations_empty_list_event_${CASE_SUFFIX}.json"
STATUS_CREATE_EVENT="/tmp/view_registrations_empty_list_event_${CASE_SUFFIX}.status"
RESPONSE_FILE="/tmp/view_registrations_empty_list_${CASE_SUFFIX}.json"
STATUS_FILE="/tmp/view_registrations_empty_list_${CASE_SUFFIX}.status"
cleanup_files() {
  rm -f "$RESPONSE_CREATE_EVENT" "$STATUS_CREATE_EVENT" "$RESPONSE_FILE" "$STATUS_FILE"
}
trap cleanup_files EXIT
TODAY="$(date -u +%F)"

# Given
curl -sS -o "$RESPONSE_CREATE_EVENT" -w '%{http_code}' -X POST "$BASE_URL/api/events" \
  -H 'Content-Type: application/json' \
  --data "{\"title\":\"${EVENT_TITLE}\",\"description\":\"Event with no registrations\",\"startDate\":\"${TODAY}\",\"endDate\":\"${TODAY}\",\"location\":\"Room B\"}" > "$STATUS_CREATE_EVENT"
[ "$(cat "$STATUS_CREATE_EVENT")" = "201" ]
EVENT_ID="$(sed -n 's/.*\"id\":\"\([^\"]*\)\".*/\1/p' "$RESPONSE_CREATE_EVENT")"
[ -n "$EVENT_ID" ]

# When
curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' "$BASE_URL/api/registrations/${EVENT_ID}" > "$STATUS_FILE"

# Then
[ "$(cat "$STATUS_FILE")" = "200" ]
[ "$(tr -d '\n\r[:space:]' < "$RESPONSE_FILE")" = "[]" ]

echo "CODEVALID_TEST_ASSERTION_OK:view_registrations_empty_list"

# Cleanup
# No cleanup endpoint exists for this in-memory service; data is test-unique and process-local.
