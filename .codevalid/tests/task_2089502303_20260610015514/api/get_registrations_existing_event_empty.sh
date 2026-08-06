#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$$"
TEST_ID="get_registrations_existing_event_empty"
EVENT_ID=""
START_DATE="$(python3 - <<'PY'
from datetime import date, timedelta
print((date.today() + timedelta(days=1)).isoformat())
PY
)"
END_DATE="$(python3 - <<'PY'
from datetime import date, timedelta
print((date.today() + timedelta(days=3)).isoformat())
PY
)"
GIVEN_HEADERS="/tmp/${TEST_ID}_given_headers_${CASE_SUFFIX}.txt"
GIVEN_BODY="/tmp/${TEST_ID}_given_body_${CASE_SUFFIX}.json"
WHEN_HEADERS="/tmp/${TEST_ID}_when_headers_${CASE_SUFFIX}.txt"
WHEN_BODY="/tmp/${TEST_ID}_when_body_${CASE_SUFFIX}.json"

# Given
echo "STEP: Given — create an event with no registrations"
GIVEN_REQUEST_BODY="$(cat <<JSON
{"title":"Empty Registration Event ${CASE_SUFFIX}","description":"Created to verify empty registrations list.","startDate":"${START_DATE}","endDate":"${END_DATE}","location":"Test Hall ${CASE_SUFFIX}"}
JSON
)"
echo "PREREQ: create event via POST /api/events"
echo "REQUEST_HEADERS: Content-Type: application/json"
echo "REQUEST_BODY: ${GIVEN_REQUEST_BODY}"
given_status="$(curl -sS -D "$GIVEN_HEADERS" -o "$GIVEN_BODY" -w '%{http_code}' \
  -X POST "$BASE_URL/api/events" \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json' \
  -d "$GIVEN_REQUEST_BODY")"
echo "RESPONSE_STATUS: ${given_status}"
echo "RESPONSE_HEADERS:"
cat "$GIVEN_HEADERS"
echo "RESPONSE_BODY:"
cat "$GIVEN_BODY"
[ "$given_status" = "201" ] || { echo "ASSERTION_FAILED: expected HTTP 201 creating event got ${given_status}"; exit 1; }
EVENT_ID="$(python3 - "$GIVEN_BODY" <<'PY'
import json, sys
with open(sys.argv[1], 'r', encoding='utf-8') as f:
    print(json.load(f)['id'])
PY
)"
[ -n "$EVENT_ID" ] || { echo "ASSERTION_FAILED: failed to extract created event id"; exit 1; }

# When
echo "STEP: When — request registrations for the created event"
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
echo "STEP: Then — assert 200 and empty registration array"
[ "$when_status" = "200" ] || { echo "ASSERTION_FAILED: expected HTTP 200 got ${when_status}"; exit 1; }
python3 - "$WHEN_BODY" <<'PY'
import json, sys
with open(sys.argv[1], 'r', encoding='utf-8') as f:
    data = json.load(f)
assert isinstance(data, list), f'expected list got {type(data).__name__}'
assert data == [], f'expected empty list got {data!r}'
PY

# Cleanup
echo "STEP: Cleanup — no API delete exists; created in-memory event will reset on container restart"

echo "CODEVALID_TEST_ASSERTION_OK:get_registrations_existing_event_empty"
