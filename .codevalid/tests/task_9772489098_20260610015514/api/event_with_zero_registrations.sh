#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="${CASE_SUFFIX:-$(date +%s)-$$}"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

ZERO_EVENT_TITLE="Newly Announced Event ${CASE_SUFFIX}"
OTHER_EVENT_TITLE="Busy Event ${CASE_SUFFIX}"
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
  payload=$(printf '{"title":"%s","description":"Zero count test %s","startDate":"%s","endDate":"%s","location":"%s"}' \
    "$title" "$CASE_SUFFIX" "$TODAY" "$TODAY" "$location")

  curl -sS -o "$response_file" -w '%{http_code}' \
    -X POST "$BASE_URL/api/events" \
    -H 'Content-Type: application/json' \
    --data "$payload" > "$status_file"

  [ "$(cat "$status_file")" = "201" ]
}

# Given — create a zero-registration event and another event with one registration
create_event "$ZERO_EVENT_TITLE" "Announcement Hall ${CASE_SUFFIX}" "$TMP_DIR/zero_event.json" "$TMP_DIR/zero_event.status"
create_event "$OTHER_EVENT_TITLE" "Popular Hall ${CASE_SUFFIX}" "$TMP_DIR/other_event.json" "$TMP_DIR/other_event.status"
ZERO_EVENT_ID="$(extract_id "$TMP_DIR/zero_event.json")"
OTHER_EVENT_ID="$(extract_id "$TMP_DIR/other_event.json")"

REG_PAYLOAD=$(printf '{"eventId":"%s","name":"Busy User","email":"busy-%s@example.com","phone":"3000000001"}' \
  "$OTHER_EVENT_ID" "$CASE_SUFFIX")
curl -sS -o "$TMP_DIR/reg.json" -w '%{http_code}' \
  -X POST "$BASE_URL/api/registrations" \
  -H 'Content-Type: application/json' \
  --data "$REG_PAYLOAD" > "$TMP_DIR/reg.status"
[ "$(cat "$TMP_DIR/reg.status")" = "201" ]

# When — fetch events
curl -sS -o "$TMP_DIR/events.json" -w '%{http_code}' \
  "$BASE_URL/api/events" > "$TMP_DIR/events.status"

# Then — verify the zero-registration event reports registrationCount 0
[ "$(cat "$TMP_DIR/events.status")" = "200" ]
python3 - <<'PY' "$TMP_DIR/events.json" "$ZERO_EVENT_ID"
import json, sys
items = json.load(open(sys.argv[1]))
event_id = sys.argv[2]
lookup = {item['id']: item for item in items}
assert lookup[event_id]['registrationCount'] == 0, lookup.get(event_id)
PY

echo "CODEVALID_TEST_ASSERTION_OK:event_with_zero_registrations"

# Cleanup — no cleanup API exists for events or registrations; uniquely suffixed data avoids collisions
