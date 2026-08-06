#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$$"
TEST_ID="get_registrations_validates_event_fields_accessible"
EVENT_HEADERS="/tmp/${TEST_ID}_event_headers_${CASE_SUFFIX}.txt"
EVENT_BODY="/tmp/${TEST_ID}_event_body_${CASE_SUFFIX}.json"
WHEN_HEADERS="/tmp/${TEST_ID}_when_headers_${CASE_SUFFIX}.txt"
WHEN_BODY="/tmp/${TEST_ID}_when_body_${CASE_SUFFIX}.json"
EVENT_ID=""
START_DATE="$(python3 - <<'PY'
from datetime import date, timedelta
print((date.today() + timedelta(days=2)).isoformat())
PY
)"
END_DATE="$(python3 - <<'PY'
from datetime import date, timedelta
print((date.today() + timedelta(days=4)).isoformat())
PY
)"

# Given
echo "STEP: Given — create an event with all required business fields"
EVENT_REQUEST_BODY="$(cat <<JSON
{"title":"Accessible Event ${CASE_SUFFIX}","description":"Stored event for registration availability verification ${CASE_SUFFIX}","startDate":"${START_DATE}","endDate":"${END_DATE}","location":"Venue ${CASE_SUFFIX}"}
JSON
)"
echo "PREREQ: create event and capture all stored fields"
echo "REQUEST_HEADERS: Content-Type: application/json"
echo "REQUEST_BODY: ${EVENT_REQUEST_BODY}"
event_status="$(curl -sS -D "$EVENT_HEADERS" -o "$EVENT_BODY" -w '%{http_code}' \
  -X POST "$BASE_URL/api/events" \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json' \
  -d "$EVENT_REQUEST_BODY")"
echo "RESPONSE_STATUS: ${event_status}"
echo "RESPONSE_HEADERS:"
cat "$EVENT_HEADERS"
echo "RESPONSE_BODY:"
cat "$EVENT_BODY"
[ "$event_status" = "201" ] || { echo "ASSERTION_FAILED: expected HTTP 201 creating event got ${event_status}"; exit 1; }
python3 - "$EVENT_BODY" "$CASE_SUFFIX" "$START_DATE" "$END_DATE" <<'PY'
import json, sys
path, suffix, start_date, end_date = sys.argv[1:5]
with open(path, 'r', encoding='utf-8') as f:
    data = json.load(f)
assert data['title'] == f'Accessible Event {suffix}', f"unexpected title {data['title']!r}"
assert data['description'] == f'Stored event for registration availability verification {suffix}', f"unexpected description {data['description']!r}"
assert data['location'] == f'Venue {suffix}', f"unexpected location {data['location']!r}"
assert data['startDate'] == start_date, f"unexpected startDate {data['startDate']!r}"
assert data['endDate'] == end_date, f"unexpected endDate {data['endDate']!r}"
assert data['registrationCount'] == 0, f"expected registrationCount 0 got {data['registrationCount']!r}"
PY
EVENT_ID="$(python3 - "$EVENT_BODY" <<'PY'
import json, sys
with open(sys.argv[1], 'r', encoding='utf-8') as f:
    print(json.load(f)['id'])
PY
)"
[ -n "$EVENT_ID" ] || { echo "ASSERTION_FAILED: failed to extract event id"; exit 1; }

# When
echo "STEP: When — retrieve registrations for the stored event"
echo "REQUEST_HEADERS: Accept: application/json"
echo "REQUEST_BODY: <empty>"
when_status="$(curl -sS -D "$WHEN_HEADERS" -o "$WHEN_BODY" -w '%{http_code}' \
  -H 'Accept: application/json' \
  "$BASE_URL/api/registrations/${EVENT_ID}")"
echo "RESPONSE_STATUS: ${when_status}"
echo "RESPONSE_HEADERS:"
cat "$WHEN_HEADERS"
echo "RESPONSE_BODY:"
cat "$WHEN_BODY"

# Then
echo "STEP: Then — assert the stored event is available for registration retrieval"
[ "$when_status" = "200" ] || { echo "ASSERTION_FAILED: expected HTTP 200 got ${when_status}"; exit 1; }
python3 - "$WHEN_BODY" <<'PY'
import json, sys
with open(sys.argv[1], 'r', encoding='utf-8') as f:
    data = json.load(f)
assert isinstance(data, list), f'expected list got {type(data).__name__}'
assert data == [], f'expected no registrations yet got {data!r}'
PY

# Cleanup
echo "STEP: Cleanup — no API delete exists; created in-memory event will reset on container restart"

echo "CODEVALID_TEST_ASSERTION_OK:get_registrations_validates_event_fields_accessible"
