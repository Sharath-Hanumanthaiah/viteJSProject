#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="${CASE_SUFFIX:-$(date +%s)-$$}"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

EVENT1_TITLE="Tech Conference 2024 ${CASE_SUFFIX}"
EVENT2_TITLE="Music Festival ${CASE_SUFFIX}"
EVENT3_TITLE="Art Exhibition ${CASE_SUFFIX}"

create_event() {
  title="$1"
  start_date="$2"
  end_date="$3"
  location="$4"
  response_file="$5"
  status_file="$6"

  payload=$(printf '{"title":"%s","description":"Seed event %s","startDate":"%s","endDate":"%s","location":"%s"}' \
    "$title" "$CASE_SUFFIX" "$start_date" "$end_date" "$location")

  curl -sS -o "$response_file" -w '%{http_code}' \
    -X POST "$BASE_URL/api/events" \
    -H 'Content-Type: application/json' \
    --data "$payload" > "$status_file"

  [ "$(cat "$status_file")" = "201" ]
}

# Given — create at least 3 events for this test case
create_event "$EVENT1_TITLE" "2024-03-15" "2024-03-16" "Hall A ${CASE_SUFFIX}" "$TMP_DIR/event1.json" "$TMP_DIR/event1.status"
create_event "$EVENT2_TITLE" "2024-04-20" "2024-04-21" "Hall B ${CASE_SUFFIX}" "$TMP_DIR/event2.json" "$TMP_DIR/event2.status"
create_event "$EVENT3_TITLE" "2024-05-01" "2024-05-02" "Hall C ${CASE_SUFFIX}" "$TMP_DIR/event3.json" "$TMP_DIR/event3.status"

# When — request the events list
curl -sS -o "$TMP_DIR/events.json" -w '%{http_code}' \
  "$BASE_URL/api/events" > "$TMP_DIR/events.status"

# Then — verify 200 and that all created events are present with registrationCount
[ "$(cat "$TMP_DIR/events.status")" = "200" ]
grep -F '"title":"'"$EVENT1_TITLE"'"' "$TMP_DIR/events.json" >/dev/null
grep -F '"title":"'"$EVENT2_TITLE"'"' "$TMP_DIR/events.json" >/dev/null
grep -F '"title":"'"$EVENT3_TITLE"'"' "$TMP_DIR/events.json" >/dev/null
grep -F '"registrationCount":0' "$TMP_DIR/events.json" >/dev/null

echo "CODEVALID_TEST_ASSERTION_OK:get_active_events_success"

# Cleanup — no cleanup API exists for events in this service; uniquely suffixed data avoids collisions
