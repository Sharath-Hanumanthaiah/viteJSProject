#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(python3 - <<'PY'
import uuid
print(uuid.uuid4().hex[:8])
PY
)"
EVENT_TITLE="Team Meeting ${CASE_SUFFIX}"
EVENT_DESCRIPTION="Weekly sync"
EVENT_LOCATION="Room 101"
EVENT_START_DATE="2024-05-01"
EVENT_END_DATE="2024-05-01"
GIVEN_HEADERS_FILE="/tmp/event_includes_all_fields_given_headers_${CASE_SUFFIX}.txt"
GIVEN_BODY_FILE="/tmp/event_includes_all_fields_given_body_${CASE_SUFFIX}.json"
WHEN_HEADERS_FILE="/tmp/event_includes_all_fields_when_headers_${CASE_SUFFIX}.txt"
WHEN_BODY_FILE="/tmp/event_includes_all_fields_when_body_${CASE_SUFFIX}.json"
REQUEST_BODY_FILE="/tmp/event_includes_all_fields_request_${CASE_SUFFIX}.json"

cleanup_files() {
  rm -f "$GIVEN_HEADERS_FILE" "$GIVEN_BODY_FILE" "$WHEN_HEADERS_FILE" "$WHEN_BODY_FILE" "$REQUEST_BODY_FILE"
}
trap cleanup_files EXIT

printf '{"title":"%s","description":"%s","startDate":"%s","endDate":"%s","location":"%s"}' \
  "$EVENT_TITLE" "$EVENT_DESCRIPTION" "$EVENT_START_DATE" "$EVENT_END_DATE" "$EVENT_LOCATION" > "$REQUEST_BODY_FILE"

echo "STEP: Given — create an event with all required storage fields"
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

echo "STEP: Then — assert the event contains title, description, location, startDate, endDate, id, and registrationCount"
[ "$when_status" = "200" ] || { echo "ASSERTION_FAILED: expected HTTP 200 got ${when_status}"; exit 1; }
python3 - "$WHEN_BODY_FILE" "$EVENT_TITLE" "$EVENT_DESCRIPTION" "$EVENT_LOCATION" "$EVENT_START_DATE" "$EVENT_END_DATE" <<'PY'
import json, sys
body_path, title, description, location, start_date, end_date = sys.argv[1:]
with open(body_path, 'r', encoding='utf-8') as fh:
    data = json.load(fh)
match = next((item for item in data if item.get('title') == title), None)
assert match is not None, 'matching event not found'
assert match.get('description') == description, 'description mismatch'
assert match.get('location') == location, 'location mismatch'
assert match.get('startDate') == start_date, 'startDate mismatch'
assert match.get('endDate') == end_date, 'endDate mismatch'
assert isinstance(match.get('id'), str) and match['id'].startswith('event_'), 'id missing or invalid'
assert match.get('registrationCount') == 0, 'registrationCount mismatch'
PY
if [ $? -ne 0 ]; then
  echo "ASSERTION_FAILED: event object did not contain all required stored fields"
  exit 1
fi

echo "STEP: Cleanup — no cleanup possible because the app uses in-memory state without delete endpoints"
echo "CODEVALID_TEST_ASSERTION_OK:event_includes_all_fields"
