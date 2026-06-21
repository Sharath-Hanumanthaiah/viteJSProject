#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
EVENTS_FILE="/tmp/registration_count_with_mixed_events_events_${CASE_SUFFIX}.json"
EVENT_IDS_FILE="/tmp/registration_count_with_mixed_events_ids_${CASE_SUFFIX}.txt"

cleanup() {
  rm -f "$EVENTS_FILE" "$EVENT_IDS_FILE"
}
trap cleanup EXIT

# Given — The API is reachable and event registration counts should be isolated by event ID.
HEALTH_STATUS="$(curl -sS -o /dev/null -w '%{http_code}' "$BASE_URL/health")"
[ "$HEALTH_STATUS" = "200" ]

# When — Fetch /api/events and then query /api/registrations/:eventId for each event independently.
HTTP_STATUS="$(curl -sS -o "$EVENTS_FILE" -w '%{http_code}' \
  -X GET "$BASE_URL/api/events")"

# Then — HTTP 200 and each event's registrationCount matches only its own registration list length.
[ "$HTTP_STATUS" = "200" ]
jq -e 'type == "array"' "$EVENTS_FILE" >/dev/null
jq -r '.[].id' "$EVENTS_FILE" > "$EVENT_IDS_FILE"

while IFS= read -r EVENT_ID; do
  [ -n "$EVENT_ID" ] || continue
  EXPECTED_COUNT="$(jq -r --arg id "$EVENT_ID" '.[] | select(.id == $id) | .registrationCount' "$EVENTS_FILE")"
  REG_FILE="/tmp/registration_count_with_mixed_events_${CASE_SUFFIX}_${EVENT_ID}.json"
  REG_STATUS="$(curl -sS -o "$REG_FILE" -w '%{http_code}' \
    -X GET "$BASE_URL/api/registrations/$EVENT_ID")"
  [ "$REG_STATUS" = "200" ]
  ACTUAL_COUNT="$(jq 'length' "$REG_FILE")"
  [ "$EXPECTED_COUNT" = "$ACTUAL_COUNT" ]
  rm -f "$REG_FILE"
done < "$EVENT_IDS_FILE"

echo "CODEVALID_TEST_ASSERTION_OK:registration_count_with_mixed_events"

# Cleanup — No persistent side effects were created.
