#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="${CASE_SUFFIX:-$(date +%s)-$$}"
RESPONSE_FILE="/tmp/events_sorted_by_start_date_${CASE_SUFFIX}.json"
STATUS_FILE="/tmp/events_sorted_by_start_date_${CASE_SUFFIX}.status"
cleanup_files() { rm -f "$RESPONSE_FILE" "$STATUS_FILE"; }
trap cleanup_files EXIT

# Given — rely on seeded events whose start dates are unsorted in storage

# When — fetch the events list
curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  "$BASE_URL/api/events" > "$STATUS_FILE"

# Then — verify response is 200 and sorted ascending by startDate: event_3, event_1, event_2
STATUS="$(cat "$STATUS_FILE")"
[ "$STATUS" = "200" ]
line_event3="$(grep -n '"id":"event_3"' "$RESPONSE_FILE" | head -n 1 | cut -d: -f1)"
line_event1="$(grep -n '"id":"event_1"' "$RESPONSE_FILE" | head -n 1 | cut -d: -f1)"
line_event2="$(grep -n '"id":"event_2"' "$RESPONSE_FILE" | head -n 1 | cut -d: -f1)"
[ -n "$line_event3" ]
[ -n "$line_event1" ]
[ -n "$line_event2" ]
[ "$line_event3" -lt "$line_event1" ]
[ "$line_event1" -lt "$line_event2" ]

# Cleanup — stateless read-only test

echo "CODEVALID_TEST_ASSERTION_OK:events_sorted_by_start_date"
