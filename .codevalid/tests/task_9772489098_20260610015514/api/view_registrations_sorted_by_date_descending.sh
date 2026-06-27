#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="${CASE_SUFFIX:-$(date +%s)-$$}"
EVENT_TITLE="Sorting Event ${CASE_SUFFIX}"
RESPONSE_CREATE_EVENT="/tmp/view_registrations_sorted_by_date_descending_event_${CASE_SUFFIX}.json"
STATUS_CREATE_EVENT="/tmp/view_registrations_sorted_by_date_descending_event_${CASE_SUFFIX}.status"
RESPONSE_REG1="/tmp/view_registrations_sorted_by_date_descending_reg1_${CASE_SUFFIX}.json"
STATUS_REG1="/tmp/view_registrations_sorted_by_date_descending_reg1_${CASE_SUFFIX}.status"
RESPONSE_REG2="/tmp/view_registrations_sorted_by_date_descending_reg2_${CASE_SUFFIX}.json"
STATUS_REG2="/tmp/view_registrations_sorted_by_date_descending_reg2_${CASE_SUFFIX}.status"
RESPONSE_REG3="/tmp/view_registrations_sorted_by_date_descending_reg3_${CASE_SUFFIX}.json"
STATUS_REG3="/tmp/view_registrations_sorted_by_date_descending_reg3_${CASE_SUFFIX}.status"
RESPONSE_FILE="/tmp/view_registrations_sorted_by_date_descending_${CASE_SUFFIX}.json"
STATUS_FILE="/tmp/view_registrations_sorted_by_date_descending_${CASE_SUFFIX}.status"
cleanup_files() {
  rm -f "$RESPONSE_CREATE_EVENT" "$STATUS_CREATE_EVENT" "$RESPONSE_REG1" "$STATUS_REG1" "$RESPONSE_REG2" "$STATUS_REG2" "$RESPONSE_REG3" "$STATUS_REG3" "$RESPONSE_FILE" "$STATUS_FILE"
}
trap cleanup_files EXIT
TODAY="$(date -u +%F)"

# Given
curl -sS -o "$RESPONSE_CREATE_EVENT" -w '%{http_code}' -X POST "$BASE_URL/api/events" \
  -H 'Content-Type: application/json' \
  --data "{\"title\":\"${EVENT_TITLE}\",\"description\":\"Event for sort verification\",\"startDate\":\"${TODAY}\",\"endDate\":\"${TODAY}\",\"location\":\"Room C\"}" > "$STATUS_CREATE_EVENT"
[ "$(cat "$STATUS_CREATE_EVENT")" = "201" ]
EVENT_ID="$(sed -n 's/.*\"id\":\"\([^\"]*\)\".*/\1/p' "$RESPONSE_CREATE_EVENT")"
[ -n "$EVENT_ID" ]

curl -sS -o "$RESPONSE_REG1" -w '%{http_code}' -X POST "$BASE_URL/api/registrations" \
  -H 'Content-Type: application/json' \
  --data "{\"eventId\":\"${EVENT_ID}\",\"name\":\"First Registrant\",\"email\":\"first-${CASE_SUFFIX}@example.com\",\"phone\":\"1000000001\"}" > "$STATUS_REG1"
[ "$(cat "$STATUS_REG1")" = "201" ]
sleep 1
curl -sS -o "$RESPONSE_REG2" -w '%{http_code}' -X POST "$BASE_URL/api/registrations" \
  -H 'Content-Type: application/json' \
  --data "{\"eventId\":\"${EVENT_ID}\",\"name\":\"Second Registrant\",\"email\":\"second-${CASE_SUFFIX}@example.com\",\"phone\":\"1000000002\"}" > "$STATUS_REG2"
[ "$(cat "$STATUS_REG2")" = "201" ]
sleep 1
curl -sS -o "$RESPONSE_REG3" -w '%{http_code}' -X POST "$BASE_URL/api/registrations" \
  -H 'Content-Type: application/json' \
  --data "{\"eventId\":\"${EVENT_ID}\",\"name\":\"Third Registrant\",\"email\":\"third-${CASE_SUFFIX}@example.com\",\"phone\":\"1000000003\"}" > "$STATUS_REG3"
[ "$(cat "$STATUS_REG3")" = "201" ]

# When
curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' "$BASE_URL/api/registrations/${EVENT_ID}" > "$STATUS_FILE"

# Then
[ "$(cat "$STATUS_FILE")" = "200" ]
grep -F '"name":"First Registrant"' "$RESPONSE_FILE" >/dev/null
grep -F '"name":"Second Registrant"' "$RESPONSE_FILE" >/dev/null
grep -F '"name":"Third Registrant"' "$RESPONSE_FILE" >/dev/null
FIRST_NAME="$(grep -o '"name":"[^"]*"' "$RESPONSE_FILE" | sed -n '1p')"
SECOND_NAME="$(grep -o '"name":"[^"]*"' "$RESPONSE_FILE" | sed -n '2p')"
THIRD_NAME="$(grep -o '"name":"[^"]*"' "$RESPONSE_FILE" | sed -n '3p')"
[ "$FIRST_NAME" = '"name":"Third Registrant"' ]
[ "$SECOND_NAME" = '"name":"Second Registrant"' ]
[ "$THIRD_NAME" = '"name":"First Registrant"' ]

echo "CODEVALID_TEST_ASSERTION_OK:view_registrations_sorted_by_date_descending"

# Cleanup
# No cleanup endpoint exists for this in-memory service; data is test-unique and process-local.
