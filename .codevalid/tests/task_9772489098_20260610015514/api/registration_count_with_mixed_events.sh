#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
EVENTS_FILE="/tmp/registration_count_with_mixed_events_events_${CASE_SUFFIX}.json"
A_FILE="/tmp/registration_count_with_mixed_events_a_${CASE_SUFFIX}.json"
B_FILE="/tmp/registration_count_with_mixed_events_b_${CASE_SUFFIX}.json"
C_FILE="/tmp/registration_count_with_mixed_events_c_${CASE_SUFFIX}.json"

cleanup_tmp() {
  rm -f "$EVENTS_FILE" "$A_FILE" "$B_FILE" "$C_FILE"
}
trap cleanup_tmp EXIT

# Given — The service is reachable and fixture events evt-a, evt-b, and evt-c exist.
curl -sS "$BASE_URL/health" >/dev/null

# When — Request the events collection and each event's registration list.
EVENTS_STATUS="$(curl -sS -o "$EVENTS_FILE" -w '%{http_code}' "$BASE_URL/api/events")"
A_STATUS="$(curl -sS -o "$A_FILE" -w '%{http_code}' "$BASE_URL/api/registrations/evt-a")"
B_STATUS="$(curl -sS -o "$B_FILE" -w '%{http_code}' "$BASE_URL/api/registrations/evt-b")"
C_STATUS="$(curl -sS -o "$C_FILE" -w '%{http_code}' "$BASE_URL/api/registrations/evt-c")"

# Then — The API returns 200 and registration totals remain isolated per event.
[ "$EVENTS_STATUS" = "200" ]
[ "$A_STATUS" = "200" ]
[ "$B_STATUS" = "200" ]
[ "$C_STATUS" = "200" ]
grep -F '"id":"evt-a"' "$EVENTS_FILE" >/dev/null
grep -F '"id":"evt-b"' "$EVENTS_FILE" >/dev/null
grep -F '"id":"evt-c"' "$EVENTS_FILE" >/dev/null
grep -F '"registrationCount":3' "$EVENTS_FILE" >/dev/null
grep -F '"registrationCount":7' "$EVENTS_FILE" >/dev/null
grep -F '"registrationCount":0' "$EVENTS_FILE" >/dev/null
A_COUNT="$(grep -o '"eventId":"evt-a"' "$A_FILE" | wc -l | tr -d ' ')"
B_COUNT="$(grep -o '"eventId":"evt-b"' "$B_FILE" | wc -l | tr -d ' ')"
C_COUNT="$(grep -o '"eventId":"evt-c"' "$C_FILE" | wc -l | tr -d ' ')"
[ "$A_COUNT" = "3" ]
[ "$B_COUNT" = "7" ]
[ "$C_COUNT" = "0" ]

echo "CODEVALID_TEST_ASSERTION_OK:registration_count_with_mixed_events"
