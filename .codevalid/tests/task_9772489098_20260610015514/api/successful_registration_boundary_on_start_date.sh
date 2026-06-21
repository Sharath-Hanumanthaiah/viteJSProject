#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
EVENT_ID="evt-400"
EMAIL="startday+${CASE_SUFFIX}@example.com"
NAME="Start Day User"
PHONE="+1-555-111-0000"
EVENTS_FILE="/tmp/successful_registration_boundary_on_start_date_events_${CASE_SUFFIX}.json"
RESPONSE_FILE="/tmp/successful_registration_boundary_on_start_date_response_${CASE_SUFFIX}.json"
REGISTRATIONS_FILE="/tmp/successful_registration_boundary_on_start_date_registrations_${CASE_SUFFIX}.json"

cleanup_files() {
  rm -f "$EVENTS_FILE" "$RESPONSE_FILE" "$REGISTRATIONS_FILE"
}
trap cleanup_files EXIT

# Given — verify the seeded boundary-start event exists.
EVENTS_STATUS="$(curl -sS -o "$EVENTS_FILE" -w '%{http_code}' "$BASE_URL/api/events")"
[ "$EVENTS_STATUS" = "200" ]
grep -F '"id":"evt-400"' "$EVENTS_FILE" >/dev/null

# When — create a registration on the boundary-start event.
HTTP_STATUS="$(curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/registrations" \
  -H 'Content-Type: application/json' \
  --data "{\"eventId\":\"${EVENT_ID}\",\"name\":\"${NAME}\",\"email\":\"${EMAIL}\",\"phone\":\"${PHONE}\"}")"

# Then — assert 201 and persisted registration details.
[ "$HTTP_STATUS" = "201" ]
grep -F '"id":"reg-' "$RESPONSE_FILE" >/dev/null
grep -F "\"eventId\":\"${EVENT_ID}\"" "$RESPONSE_FILE" >/dev/null
grep -F "\"name\":\"${NAME}\"" "$RESPONSE_FILE" >/dev/null
grep -F "\"email\":\"${EMAIL}\"" "$RESPONSE_FILE" >/dev/null
grep -F "\"phone\":\"${PHONE}\"" "$RESPONSE_FILE" >/dev/null

REG_STATUS="$(curl -sS -o "$REGISTRATIONS_FILE" -w '%{http_code}' "$BASE_URL/api/registrations/${EVENT_ID}")"
[ "$REG_STATUS" = "200" ]
grep -F "\"email\":\"${EMAIL}\"" "$REGISTRATIONS_FILE" >/dev/null

echo "CODEVALID_TEST_ASSERTION_OK:successful_registration_boundary_on_start_date"

# Cleanup — no delete endpoint is exposed; temp files are removed by trap.
