#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
RESPONSE_FILE="/tmp/view_registrations_sorted_by_date_descending_${CASE_SUFFIX}.json"

cleanup_files() {
  rm -f "$RESPONSE_FILE"
}
trap cleanup_files EXIT

# Given — use the existing seeded event with three registrations.
EVENT_ID="evt-003"

# When — request registrations for the event.
HTTP_STATUS="$(curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' "$BASE_URL/api/registrations/$EVENT_ID")"

# Then — response is 200 and registrations are ordered newest to oldest.
[ "$HTTP_STATUS" = "200" ]
grep -F '"eventId":"evt-003"' "$RESPONSE_FILE" >/dev/null
COUNT="$(grep -o '"eventId":"evt-003"' "$RESPONSE_FILE" | wc -l | tr -d ' ')"
[ "$COUNT" = "3" ]
grep -F '"registeredAt":"2024-02-03T16:30:00Z"' "$RESPONSE_FILE" >/dev/null
grep -F '"registeredAt":"2024-02-02T12:00:00Z"' "$RESPONSE_FILE" >/dev/null
grep -F '"registeredAt":"2024-02-01T08:00:00Z"' "$RESPONSE_FILE" >/dev/null
POS1="$(grep -b -o '"registeredAt":"2024-02-03T16:30:00Z"' "$RESPONSE_FILE" | head -n 1 | cut -d: -f1)"
POS2="$(grep -b -o '"registeredAt":"2024-02-02T12:00:00Z"' "$RESPONSE_FILE" | head -n 1 | cut -d: -f1)"
POS3="$(grep -b -o '"registeredAt":"2024-02-01T08:00:00Z"' "$RESPONSE_FILE" | head -n 1 | cut -d: -f1)"
[ "$POS1" -lt "$POS2" ]
[ "$POS2" -lt "$POS3" ]

echo "CODEVALID_TEST_ASSERTION_OK:view_registrations_sorted_by_date_descending"

# Cleanup — no API side effects; only temporary files are removed by trap.
