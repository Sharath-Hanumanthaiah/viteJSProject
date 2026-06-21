#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
EVENTS_FILE="/tmp/event_with_zero_registrations_events_${CASE_SUFFIX}.json"
ZEROS_FILE="/tmp/event_with_zero_registrations_zero_ids_${CASE_SUFFIX}.txt"

cleanup() {
  rm -f "$EVENTS_FILE" "$ZEROS_FILE"
}
trap cleanup EXIT

# Given — The API is reachable and events expose registrationCount.
HEALTH_STATUS="$(curl -sS -o /dev/null -w '%{http_code}' "$BASE_URL/health")"
[ "$HEALTH_STATUS" = "200" ]

# When — Fetch /api/events and identify events whose registrationCount is zero.
HTTP_STATUS="$(curl -sS -o "$EVENTS_FILE" -w '%{http_code}' \
  -X GET "$BASE_URL/api/events")"

# Then — HTTP 200 and for every zero-count event, /api/registrations/:eventId returns an empty array.
[ "$HTTP_STATUS" = "200" ]
jq -e 'type == "array"' "$EVENTS_FILE" >/dev/null
jq -r '.[] | select(.registrationCount == 0) | .id' "$EVENTS_FILE" > "$ZEROS_FILE"

while IFS= read -r EVENT_ID; do
  [ -n "$EVENT_ID" ] || continue
  REG_FILE="/tmp/event_with_zero_registrations_${CASE_SUFFIX}_${EVENT_ID}.json"
  REG_STATUS="$(curl -sS -o "$REG_FILE" -w '%{http_code}' \
    -X GET "$BASE_URL/api/registrations/$EVENT_ID")"
  [ "$REG_STATUS" = "200" ]
  [ "$(jq 'length' "$REG_FILE")" = "0" ]
  rm -f "$REG_FILE"
done < "$ZEROS_FILE"

echo "CODEVALID_TEST_ASSERTION_OK:event_with_zero_registrations"

# Cleanup — No persistent side effects were created.
