#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="${CASE_SUFFIX:-$(date +%s)-$$}"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

TODAY="$(date +%F)"
EVENT_CONF_TITLE="Developer Conference ${CASE_SUFFIX}"
EVENT_MEETUP_TITLE="Community Meetup ${CASE_SUFFIX}"

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
  payload=$(printf '{"title":"%s","description":"Registration count test %s","startDate":"%s","endDate":"%s","location":"%s"}' \
    "$title" "$CASE_SUFFIX" "$TODAY" "$TODAY" "$location")

  curl -sS -o "$response_file" -w '%{http_code}' \
    -X POST "$BASE_URL/api/events" \
    -H 'Content-Type: application/json' \
    --data "$payload" > "$status_file"

  [ "$(cat "$status_file")" = "201" ]
}

register_user() {
  event_id="$1"
  name="$2"
  email="$3"
  phone="$4"
  response_file="$5"
  status_file="$6"
  payload=$(printf '{"eventId":"%s","name":"%s","email":"%s","phone":"%s"}' \
    "$event_id" "$name" "$email" "$phone")

  curl -sS -o "$response_file" -w '%{http_code}' \
    -X POST "$BASE_URL/api/registrations" \
    -H 'Content-Type: application/json' \
    --data "$payload" > "$status_file"

  [ "$(cat "$status_file")" = "201" ]
}

# Given — create two active events and seed 5 + 2 registrations via public APIs
create_event "$EVENT_CONF_TITLE" "Conf Hall ${CASE_SUFFIX}" "$TMP_DIR/conf_event.json" "$TMP_DIR/conf_event.status"
create_event "$EVENT_MEETUP_TITLE" "Meetup Hall ${CASE_SUFFIX}" "$TMP_DIR/meetup_event.json" "$TMP_DIR/meetup_event.status"
CONF_EVENT_ID="$(extract_id "$TMP_DIR/conf_event.json")"
MEETUP_EVENT_ID="$(extract_id "$TMP_DIR/meetup_event.json")"

register_user "$CONF_EVENT_ID" "Conf User 1" "conf1-${CASE_SUFFIX}@example.com" "1000000001" "$TMP_DIR/reg1.json" "$TMP_DIR/reg1.status"
register_user "$CONF_EVENT_ID" "Conf User 2" "conf2-${CASE_SUFFIX}@example.com" "1000000002" "$TMP_DIR/reg2.json" "$TMP_DIR/reg2.status"
register_user "$CONF_EVENT_ID" "Conf User 3" "conf3-${CASE_SUFFIX}@example.com" "1000000003" "$TMP_DIR/reg3.json" "$TMP_DIR/reg3.status"
register_user "$CONF_EVENT_ID" "Conf User 4" "conf4-${CASE_SUFFIX}@example.com" "1000000004" "$TMP_DIR/reg4.json" "$TMP_DIR/reg4.status"
register_user "$CONF_EVENT_ID" "Conf User 5" "conf5-${CASE_SUFFIX}@example.com" "1000000005" "$TMP_DIR/reg5.json" "$TMP_DIR/reg5.status"
register_user "$MEETUP_EVENT_ID" "Meetup User 1" "meetup1-${CASE_SUFFIX}@example.com" "2000000001" "$TMP_DIR/reg6.json" "$TMP_DIR/reg6.status"
register_user "$MEETUP_EVENT_ID" "Meetup User 2" "meetup2-${CASE_SUFFIX}@example.com" "2000000002" "$TMP_DIR/reg7.json" "$TMP_DIR/reg7.status"

# When — fetch events
curl -sS -o "$TMP_DIR/events.json" -w '%{http_code}' \
  "$BASE_URL/api/events" > "$TMP_DIR/events.status"

# Then — verify registrationCount values for the two created events
[ "$(cat "$TMP_DIR/events.status")" = "200" ]
python3 - <<'PY' "$TMP_DIR/events.json" "$CONF_EVENT_ID" "$MEETUP_EVENT_ID"
import json, sys
items = json.load(open(sys.argv[1]))
conf_id = sys.argv[2]
meetup_id = sys.argv[3]
lookup = {item['id']: item for item in items}
assert lookup[conf_id]['registrationCount'] == 5, lookup.get(conf_id)
assert lookup[meetup_id]['registrationCount'] == 2, lookup.get(meetup_id)
PY

echo "CODEVALID_TEST_ASSERTION_OK:registration_count_accuracy"

# Cleanup — no cleanup API exists for seeded events or registrations; uniquely suffixed data isolates this case
