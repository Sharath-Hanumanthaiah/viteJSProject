#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="${CASE_SUFFIX:-$(date +%s)-$$}"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

TODAY="$(date +%F)"

extract_id() {
  python3 - <<'PY' "$1"
import json, sys
print(json.load(open(sys.argv[1]))["id"])
PY
}

create_event() {
  title="$1"
  location="$2"
  response_file="$3"
  status_file="$4"
  payload=$(printf '{"title":"%s","description":"Mixed registration count %s","startDate":"%s","endDate":"%s","location":"%s"}' \
    "$title" "$CASE_SUFFIX" "$TODAY" "$TODAY" "$location")

  curl -sS -o "$response_file" -w '%{http_code}' \
    -X POST "$BASE_URL/api/events" \
    -H 'Content-Type: application/json' \
    --data "$payload" > "$status_file"

  [ "$(cat "$status_file")" = "201" ]
}

register_many() {
  event_id="$1"
  prefix="$2"
  count="$3"
  i=1
  while [ "$i" -le "$count" ]; do
    email="${prefix}${i}-${CASE_SUFFIX}@example.com"
    phone=$(printf '5%09d' "$i")
    payload=$(printf '{"eventId":"%s","name":"%s User %s","email":"%s","phone":"%s"}' \
      "$event_id" "$prefix" "$i" "$email" "$phone")

    curl -sS -o /dev/null -w '%{http_code}' \
      -X POST "$BASE_URL/api/registrations" \
      -H 'Content-Type: application/json' \
      --data "$payload" > "$TMP_DIR/register.status"

    [ "$(cat "$TMP_DIR/register.status")" = "201" ]
    i=$((i + 1))
  done
}

# Given — create three active events with 3, 7, and 0 registrations
create_event "Event A ${CASE_SUFFIX}" "Hall A ${CASE_SUFFIX}" "$TMP_DIR/event_a.json" "$TMP_DIR/event_a.status"
create_event "Event B ${CASE_SUFFIX}" "Hall B ${CASE_SUFFIX}" "$TMP_DIR/event_b.json" "$TMP_DIR/event_b.status"
create_event "Event C ${CASE_SUFFIX}" "Hall C ${CASE_SUFFIX}" "$TMP_DIR/event_c.json" "$TMP_DIR/event_c.status"
EVENT_A_ID="$(extract_id "$TMP_DIR/event_a.json")"
EVENT_B_ID="$(extract_id "$TMP_DIR/event_b.json")"
EVENT_C_ID="$(extract_id "$TMP_DIR/event_c.json")"

register_many "$EVENT_A_ID" "a" 3
register_many "$EVENT_B_ID" "b" 7

# When — fetch events
curl -sS -o "$TMP_DIR/events.json" -w '%{http_code}' \
  "$BASE_URL/api/events" > "$TMP_DIR/events.status"

# Then — verify counts are isolated by event ID
[ "$(cat "$TMP_DIR/events.status")" = "200" ]
python3 - <<'PY' "$TMP_DIR/events.json" "$EVENT_A_ID" "$EVENT_B_ID" "$EVENT_C_ID"
import json, sys
items = json.load(open(sys.argv[1]))
a, b, c = sys.argv[2:5]
lookup = {item['id']: item for item in items}
assert lookup[a]['registrationCount'] == 3, lookup.get(a)
assert lookup[b]['registrationCount'] == 7, lookup.get(b)
assert lookup[c]['registrationCount'] == 0, lookup.get(c)
PY

echo "CODEVALID_TEST_ASSERTION_OK:registration_count_with_mixed_events"

# Cleanup — no cleanup API exists for events or registrations; uniquely suffixed data avoids collisions
