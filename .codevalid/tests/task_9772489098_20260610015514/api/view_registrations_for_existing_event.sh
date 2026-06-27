#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="${CASE_SUFFIX:-$(date +%s)-$$}"
EVENT_TITLE="Tech Conference ${CASE_SUFFIX}"
RESPONSE_CREATE_EVENT="/tmp/view_registrations_for_existing_event_event_${CASE_SUFFIX}.json"
STATUS_CREATE_EVENT="/tmp/view_registrations_for_existing_event_event_${CASE_SUFFIX}.status"
RESPONSE_REG1="/tmp/view_registrations_for_existing_event_reg1_${CASE_SUFFIX}.json"
STATUS_REG1="/tmp/view_registrations_for_existing_event_reg1_${CASE_SUFFIX}.status"
RESPONSE_REG2="/tmp/view_registrations_for_existing_event_reg2_${CASE_SUFFIX}.json"
STATUS_REG2="/tmp/view_registrations_for_existing_event_reg2_${CASE_SUFFIX}.status"
RESPONSE_FILE="/tmp/view_registrations_for_existing_event_${CASE_SUFFIX}.json"
STATUS_FILE="/tmp/view_registrations_for_existing_event_${CASE_SUFFIX}.status"
cleanup_files() {
  rm -f "$RESPONSE_CREATE_EVENT" "$STATUS_CREATE_EVENT" "$RESPONSE_REG1" "$STATUS_REG1" "$RESPONSE_REG2" "$STATUS_REG2" "$RESPONSE_FILE" "$STATUS_FILE"
}
trap cleanup_files EXIT
TODAY="$(date -u +%F)"

# Given
curl -sS -o "$RESPONSE_CREATE_EVENT" -w '%{http_code}' -X POST "$BASE_URL/api/events" \
  -H 'Content-Type: application/json' \
  --data "{\"title\":\"${EVENT_TITLE}\",\"description\":\"Event for registration listing\",\"startDate\":\"${TODAY}\",\"endDate\":\"${TODAY}\",\"location\":\"Hall A\"}" > "$STATUS_CREATE_EVENT"
[ "$(cat "$STATUS_CREATE_EVENT")" = "201" ]
EVENT_ID="$(sed -n 's/.*\"id\":\"\([^\"]*\)\".*/\1/p' "$RESPONSE_CREATE_EVENT")"
[ -n "$EVENT_ID" ]

curl -sS -o "$RESPONSE_REG1" -w '%{http_code}' -X POST "$BASE_URL/api/registrations" \
  -H 'Content-Type: application/json' \
  --data "{\"eventId\":\"${EVENT_ID}\",\"name\":\"Alice Johnson\",\"email\":\"alice-${CASE_SUFFIX}@example.com\",\"phone\":\"1111111111\"}" > "$STATUS_REG1"
[ "$(cat "$STATUS_REG1")" = "201" ]
grep -F '"name":"Alice Johnson"' "$RESPONSE_REG1" >/dev/null
sleep 1
curl -sS -o "$RESPONSE_REG2" -w '%{http_code}' -X POST "$BASE_URL/api/registrations" \
  -H 'Content-Type: application/json' \
  --data "{\"eventId\":\"${EVENT_ID}\",\"name\":\"Bob Smith\",\"email\":\"bob-${CASE_SUFFIX}@example.com\",\"phone\":\"2222222222\"}" > "$STATUS_REG2"
[ "$(cat "$STATUS_REG2")" = "201" ]
grep -F '"name":"Bob Smith"' "$RESPONSE_REG2" >/dev/null

# When
curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' "$BASE_URL/api/registrations/${EVENT_ID}" > "$STATUS_FILE"

# Then
[ "$(cat "$STATUS_FILE")" = "200" ]
grep -F '"eventId":"'"${EVENT_ID}"'"' "$RESPONSE_FILE" >/dev/null
grep -F '"name":"Alice Johnson"' "$RESPONSE_FILE" >/dev/null
grep -F '"name":"Bob Smith"' "$RESPONSE_FILE" >/dev/null
FIRST_NAME="$(grep -o '"name":"[^"]*"' "$RESPONSE_FILE" | sed -n '1p')"
SECOND_NAME="$(grep -o '"name":"[^"]*"' "$RESPONSE_FILE" | sed -n '2p')"
[ "$FIRST_NAME" = '"name":"Bob Smith"' ]
[ "$SECOND_NAME" = '"name":"Alice Johnson"' ]

echo "CODEVALID_TEST_ASSERTION_OK:view_registrations_for_existing_event"

# Cleanup
# No cleanup endpoint exists for this in-memory service; data is test-unique and process-local.
