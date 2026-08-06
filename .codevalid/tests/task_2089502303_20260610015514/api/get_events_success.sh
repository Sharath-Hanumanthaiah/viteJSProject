#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(python3 - <<'PY'
import uuid
print(uuid.uuid4().hex[:8])
PY
)"
EVENT_TITLE="CV Get Events ${CASE_SUFFIX}"
EVENT_DESCRIPTION="Created for get_events_success"
EVENT_LOCATION="Room ${CASE_SUFFIX}"
EVENT_START_DATE="2099-12-31"
EVENT_END_DATE="2099-12-31"
GIVEN_BODY_FILE="/tmp/get_events_success_given_body_${CASE_SUFFIX}.json"
GIVEN_HEADERS_FILE="/tmp/get_events_success_given_headers_${CASE_SUFFIX}.txt"
WHEN_BODY_FILE="/tmp/get_events_success_when_body_${CASE_SUFFIX}.json"
WHEN_HEADERS_FILE="/tmp/get_events_success_when_headers_${CASE_SUFFIX}.txt"
REQUEST_BODY_FILE="/tmp/get_events_success_request_${CASE_SUFFIX}.json"

cleanup_files() {
  rm -f "$GIVEN_BODY_FILE" "$GIVEN_HEADERS_FILE" "$WHEN_BODY_FILE" "$WHEN_HEADERS_FILE" "$REQUEST_BODY_FILE"
}
trap cleanup_files EXIT

printf '{"title":"%s","description":"%s","startDate":"%s","endDate":"%s","location":"%s"}' \
  "$EVENT_TITLE" "$EVENT_DESCRIPTION" "$EVENT_START_DATE" "$EVENT_END_DATE" "$EVENT_LOCATION" > "$REQUEST_BODY_FILE"

echo "STEP: Given — create an event so the events list is non-empty"
echo "PREREQ: create event via POST /api/events"
echo "REQUEST_HEADERS: Content-Type: application/json"
echo "REQUEST_BODY: $(cat "$REQUEST_BODY_FILE")"
given_status="$(curl -sS -D "$GIVEN_HEADERS_FILE" -o "$GIVEN_BODY_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/events" \
  -H 'Content-Type: application/json' \
  --data @"$REQUEST_BODY_FILE")"
echo "RESPONSE_STATUS: $given_status"
echo "RESPONSE_HEADERS:"
cat "$GIVEN_HEADERS_FILE"
echo "RESPONSE_BODY:"
cat "$GIVEN_BODY_FILE"
[ "$given_status" = "201" ] || { echo "ASSERTION_FAILED: expected HTTP 201 got ${given_status}"; exit 1; }
python3 - "$GIVEN_BODY_FILE" "$EVENT_TITLE" "$EVENT_DESCRIPTION" "$EVENT_LOCATION" "$EVENT_START_DATE" "$EVENT_END_DATE" <<'PY'
import json, sys
body_path, title, description, location, start_date, end_date = sys.argv[1:]
with open(body_path, 'r', encoding='utf-8') as fh:
    data = json.load(fh)
assert data['title'] == title, 'title mismatch'
assert data['description'] == description, 'description mismatch'
assert data['location'] == location, 'location mismatch'
assert data['startDate'] == start_date, 'startDate mismatch'
assert data['endDate'] == end_date, 'endDate mismatch'
assert data['registrationCount'] == 0, 'registrationCount mismatch'
assert data['id'].startswith('event_'), 'id format mismatch'
PY
if [ $? -ne 0 ]; then
  echo "ASSERTION_FAILED: created event payload did not match expected fields"
  exit 1
fi

echo "STEP: When — retrieve the events list"
echo "REQUEST_HEADERS: Accept: application/json"
echo "REQUEST_BODY: <empty>"
when_status="$(curl -sS -D "$WHEN_HEADERS_FILE" -o "$WHEN_BODY_FILE" -w '%{http_code}' \
  "$BASE_URL/api/events" \
  -H 'Accept: application/json')"
echo "RESPONSE_STATUS: $when_status"
echo "RESPONSE_HEADERS:"
cat "$WHEN_HEADERS_FILE"
echo "RESPONSE_BODY:"
cat "$WHEN_BODY_FILE"

echo "STEP: Then — assert response is 200 and includes event objects with stored fields"
[ "$when_status" = "200" ] || { echo "ASSERTION_FAILED: expected HTTP 200 got ${when_status}"; exit 1; }
python3 - "$WHEN_BODY_FILE" "$EVENT_TITLE" "$EVENT_DESCRIPTION" "$EVENT_LOCATION" "$EVENT_START_DATE" "$EVENT_END_DATE" <<'PY'
import json, sys
body_path, title, description, location, start_date, end_date = sys.argv[1:]
with open(body_path, 'r', encoding='utf-8') as fh:
    data = json.load(fh)
assert isinstance(data, list), 'response is not a JSON array'
assert len(data) >= 1, 'response array is empty'
match = None
for item in data:
    if item.get('title') == title and item.get('location') == location:
        match = item
        break
assert match is not None, 'created event not found in response'
for key in ['id', 'title', 'description', 'location', 'startDate', 'endDate', 'registrationCount']:
    assert key in match, f'missing key {key}'
assert match['description'] == description, 'description mismatch in list response'
assert match['startDate'] == start_date, 'startDate mismatch in list response'
assert match['endDate'] == end_date, 'endDate mismatch in list response'
assert match['registrationCount'] == 0, 'registrationCount mismatch in list response'
PY
if [ $? -ne 0 ]; then
  echo "ASSERTION_FAILED: GET /api/events response did not include expected event fields"
  exit 1
fi

echo "STEP: Cleanup — no cleanup possible because the app uses in-memory state without delete endpoints"
echo "CODEVALID_TEST_ASSERTION_OK:get_events_success"
