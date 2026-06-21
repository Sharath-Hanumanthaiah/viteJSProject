#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
RESPONSE_FILE="/tmp/view_registrations_for_existing_event_${CASE_SUFFIX}.json"

cleanup_files() {
  rm -f "$RESPONSE_FILE"
}
trap cleanup_files EXIT

# Given — use the existing seeded event and registrations described by the seed case.
EVENT_ID="evt-001"

# When — request registrations for the existing event.
HTTP_STATUS="$(curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' "$BASE_URL/api/registrations/$EVENT_ID")"

# Then — response is 200 and includes two registrations sorted by registeredAt descending.
[ "$HTTP_STATUS" = "200" ]
grep -F '"eventId":"evt-001"' "$RESPONSE_FILE" >/dev/null
COUNT="$(grep -o '"eventId":"evt-001"' "$RESPONSE_FILE" | wc -l | tr -d ' ')"
[ "$COUNT" = "2" ]
grep -F '"registeredAt":"2024-01-16T14:00:00Z"' "$RESPONSE_FILE" >/dev/null
grep -F '"registeredAt":"2024-01-15T10:30:00Z"' "$RESPONSE_FILE" >/dev/null
FIRST_POS="$(grep -b -o '"registeredAt":"2024-01-16T14:00:00Z"' "$RESPONSE_FILE" | head -n 1 | cut -d: -f1)"
SECOND_POS="$(grep -b -o '"registeredAt":"2024-01-15T10:30:00Z"' "$RESPONSE_FILE" | head -n 1 | cut -d: -f1)"
[ "$FIRST_POS" -lt "$SECOND_POS" ]

echo "CODEVALID_TEST_ASSERTION_OK:view_registrations_for_existing_event"

# Cleanup — no API side effects; only temporary files are removed by trap.
