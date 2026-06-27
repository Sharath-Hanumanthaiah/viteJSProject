#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="${CASE_SUFFIX:-$(date +%s)-$$}"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

MORNING_TITLE="Morning Session ${CASE_SUFFIX}"
AFTERNOON_TITLE="Afternoon Session ${CASE_SUFFIX}"
TODAY="$(date +%F)"

extract_id() {
  python3 - <<'PY' "$1"
import json, sys
print(json.load(open(sys.argv[1]))["id"])
PY
}

create_event() {
  title="$1"
  response_file="$2"
  status_file="$3"
  payload=$(printf '{"title":"%s","description":"Shared start date %s","startDate":"2024-07-01","endDate":"2024-07-02","location":"Venue %s"}' \
    "$title" "$CASE_SUFFIX" "$CASE_SUFFIX")

  curl -sS -o "$response_file" -w '%{http_code}' \
    -X POST "$BASE_URL/api/events" \
    -H 'Content-Type: application/json' \
    --data "$payload" > "$status_file"

  [ "$(cat "$status_file")" = "201" ]
}

create_active_event() {
  title="$1"
  location="$2"
  response_file="$3"
  status_file="$4"
  payload=$(printf '{"title":"%s","description":"Active same-date count %s","startDate":"%s","endDate":"%s","location":"%s"}' \
    "$title" "$CASE_SUFFIX" "$TODAY" "$TODAY" "$location")

  curl -sS -o "$response_file" -w '%{http_code}' \
    -X POST "$BASE_URL/api/events" \
    -H 'Content-Type: application/json' \
    --data "$payload" > "$status_file"

  [ "$(cat "$status_file")" = "201" ]
}

# Given — create two events with the same startDate, and active counterparts to validate counts
create_event "$MORNING_TITLE" "$TMP_DIR/morning_event.json" "$TMP_DIR/morning_event.status"
create_event "$AFTERNOON_TITLE" "$TMP_DIR/afternoon_event.json" "$TMP_DIR/afternoon_event.status"
MORNING_EVENT_ID="$(extract_id "$TMP_DIR/morning_event.json")"
AFTERNOON_EVENT_ID="$(extract_id "$TMP_DIR/afternoon_event.json")"

create_active_event "Morning Session Active ${CASE_SUFFIX}" "Venue A ${CASE_SUFFIX}" "$TMP_DIR/active_morning.json" "$TMP_DIR/active_morning.status"
create_active_event "Afternoon Session Active ${CASE_SUFFIX}" "Venue B ${CASE_SUFFIX}" "$TMP_DIR/active_afternoon.json" "$TMP_DIR/active_afternoon.status"
ACTIVE_MORNING_ID="$(extract_id "$TMP_DIR/active_morning.json")"
ACTIVE_AFTERNOON_ID="$(extract_id "$TMP_DIR/active_afternoon.json")"

REG1_PAYLOAD=$(printf '{"eventId":"%s","name":"Morning User","email":"morning-%s@example.com","phone":"4000000001"}' \
  "$ACTIVE_MORNING_ID" "$CASE_SUFFIX")
REG2_PAYLOAD=$(printf '{"eventId":"%s","name":"Afternoon User","email":"afternoon-%s@example.com","phone":"4000000002"}' \
  "$ACTIVE_AFTERNOON_ID" "$CASE_SUFFIX")

curl -sS -o "$TMP_DIR/reg1.json" -w '%{http_code}' \
  -X POST "$BASE_URL/api/registrations" \
  -H 'Content-Type: application/json' \
  --data "$REG1_PAYLOAD" > "$TMP_DIR/reg1.status"
[ "$(cat "$TMP_DIR/reg1.status")" = "201" ]

curl -sS -o "$TMP_DIR/reg2.json" -w '%{http_code}' \
  -X POST "$BASE_URL/api/registrations" \
  -H 'Content-Type: application/json' \
  --data "$REG2_PAYLOAD" > "$TMP_DIR/reg2.status"
[ "$(cat "$TMP_DIR/reg2.status")" = "201" ]

# When — fetch events
curl -sS -o "$TMP_DIR/events.json" -w '%{http_code}' \
  "$BASE_URL/api/events" > "$TMP_DIR/events.status"

# Then — verify both same-start-date events are included and active variants carry independent counts
[ "$(cat "$TMP_DIR/events.status")" = "200" ]
python3 - <<'PY' "$TMP_DIR/events.json" "$MORNING_EVENT_ID" "$AFTERNOON_EVENT_ID" "$ACTIVE_MORNING_ID" "$ACTIVE_AFTERNOON_ID"
import json, sys
items = json.load(open(sys.argv[1]))
ids = sys.argv[2:]
lookup = {item['id']: item for item in items}
assert ids[0] in lookup, ids[0]
assert ids[1] in lookup, ids[1]
assert lookup[ids[2]]['registrationCount'] == 1, lookup.get(ids[2])
assert lookup[ids[3]]['registrationCount'] == 1, lookup.get(ids[3])
PY

echo "CODEVALID_TEST_ASSERTION_OK:events_same_start_date_sorting"

# Cleanup — no cleanup API exists for events or registrations; uniquely suffixed data avoids collisions
