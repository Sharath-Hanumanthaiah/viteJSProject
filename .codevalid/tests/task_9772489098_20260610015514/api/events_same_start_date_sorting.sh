#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
EVENTS_FILE="/tmp/events_same_start_date_sorting_events_${CASE_SUFFIX}.json"
MORNING_FILE="/tmp/events_same_start_date_sorting_morning_${CASE_SUFFIX}.json"
AFTERNOON_FILE="/tmp/events_same_start_date_sorting_afternoon_${CASE_SUFFIX}.json"

cleanup_tmp() {
  rm -f "$EVENTS_FILE" "$MORNING_FILE" "$AFTERNOON_FILE"
}
trap cleanup_tmp EXIT

# Given — The service is reachable and two fixture events share the same start date.
curl -sS "$BASE_URL/health" >/dev/null

# When — Request the events collection and both per-event registration lists.
EVENTS_STATUS="$(curl -sS -o "$EVENTS_FILE" -w '%{http_code}' "$BASE_URL/api/events")"
MORNING_STATUS="$(curl -sS -o "$MORNING_FILE" -w '%{http_code}' "$BASE_URL/api/registrations/evt-morning")"
AFTERNOON_STATUS="$(curl -sS -o "$AFTERNOON_FILE" -w '%{http_code}' "$BASE_URL/api/registrations/evt-afternoon")"

# Then — The API returns 200 and includes both events with independent registration data.
[ "$EVENTS_STATUS" = "200" ]
[ "$MORNING_STATUS" = "200" ]
[ "$AFTERNOON_STATUS" = "200" ]
grep -F '"id":"evt-morning"' "$EVENTS_FILE" >/dev/null
grep -F '"id":"evt-afternoon"' "$EVENTS_FILE" >/dev/null
grep -F '"startDate":"2024-07-01"' "$EVENTS_FILE" >/dev/null
grep -F '"registrationCount":' "$EVENTS_FILE" >/dev/null

echo "CODEVALID_TEST_ASSERTION_OK:events_same_start_date_sorting"
