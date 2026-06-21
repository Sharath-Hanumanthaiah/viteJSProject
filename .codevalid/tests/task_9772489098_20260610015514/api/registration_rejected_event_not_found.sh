#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
EVENT_ID="evt-nonexistent-${CASE_SUFFIX}"
EVENTS_FILE="/tmp/registration_rejected_event_not_found_events_${CASE_SUFFIX}.json"
RESPONSE_FILE="/tmp/registration_rejected_event_not_found_response_${CASE_SUFFIX}.json"

cleanup_files() {
  rm -f "$EVENTS_FILE" "$RESPONSE_FILE"
}
trap cleanup_files EXIT

# Given — ensure this synthetic event id does not appear in the events list.
EVENTS_STATUS="$(curl -sS -o "$EVENTS_FILE" -w '%{http_code}' "$BASE_URL/api/events")"
[ "$EVENTS_STATUS" = "200" ]
if grep -F "\"id\":\"${EVENT_ID}\"" "$EVENTS_FILE" >/dev/null; then
  echo "unexpected pre-existing event ${EVENT_ID}" >&2
  exit 1
fi

# When — attempt to register for the non-existent event.
HTTP_STATUS="$(curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/registrations" \
  -H 'Content-Type: application/json' \
  --data "{\"eventId\":\"${EVENT_ID}\",\"name\":\"Alice Brown\",\"email\":\"alice.brown+${CASE_SUFFIX}@example.com\",\"phone\":\"+1-555-333-4444\"}")"

# Then — assert 404 and event-not-found message.
[ "$HTTP_STATUS" = "404" ]
grep -F '"message":"Event not found."' "$RESPONSE_FILE" >/dev/null

echo "CODEVALID_TEST_ASSERTION_OK:registration_rejected_event_not_found"

# Cleanup — 404 should be side-effect free; temp files are removed by trap.
