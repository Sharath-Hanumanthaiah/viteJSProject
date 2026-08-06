#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$$"
TEST_ID="get_registrations_event_id_parameter_validation"
ACTIVE_START_DATE="$(python3 - <<'PY'
from datetime import date, timedelta
print((date.today() - timedelta(days=1)).isoformat())
PY
)"
ACTIVE_END_DATE="$(python3 - <<'PY'
from datetime import date, timedelta
print((date.today() + timedelta(days=3)).isoformat())
PY
)"
FUTURE_START_DATE="$(python3 - <<'PY'
from datetime import date, timedelta
print((date.today() + timedelta(days=5)).isoformat())
PY
)"
FUTURE_END_DATE="$(python3 - <<'PY'
from datetime import date, timedelta
print((date.today() + timedelta(days=7)).isoformat())
PY
)"
EVENT1_HEADERS="/tmp/${TEST_ID}_event1_headers_${CASE_SUFFIX}.txt"
EVENT1_BODY="/tmp/${TEST_ID}_event1_body_${CASE_SUFFIX}.json"
EVENT2_HEADERS="/tmp/${TEST_ID}_event2_headers_${CASE_SUFFIX}.txt"
EVENT2_BODY="/tmp/${TEST_ID}_event2_body_${CASE_SUFFIX}.json"
REG_HEADERS="/tmp/${TEST_ID}_reg_headers_${CASE_SUFFIX}.txt"
REG_BODY="/tmp/${TEST_ID}_reg_body_${CASE_SUFFIX}.json"
WHEN_HEADERS="/tmp/${TEST_ID}_when_headers_${CASE_SUFFIX}.txt"
WHEN_BODY="/tmp/${TEST_ID}_when_body_${CASE_SUFFIX}.json"
TARGET_EVENT_ID=""
OTHER_EVENT_ID=""
TARGET_EMAIL="param_${CASE_SUFFIX}@example.com"

# Given
echo "STEP: Given — create multiple events and a registration only for one specific event"
EVENT1_REQUEST_BODY="$(cat <<JSON
{"title":"Specific Event ${CASE_SUFFIX}","description":"Target event for route parameter validation.","startDate":"${ACTIVE_START_DATE}","endDate":"${ACTIVE_END_DATE}","location":"North Hall ${CASE_SUFFIX}"}
JSON
)"
echo "PREREQ: create target event"
echo "REQUEST_HEADERS: Content-Type: application/json"
echo "REQUEST_BODY: ${EVENT1_REQUEST_BODY}"
event1_status="$(curl -sS -D "$EVENT1_HEADERS" -o "$EVENT1_BODY" -w '%{http_code}' \
  -X POST "$BASE_URL/api/events" \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json' \
  -d "$EVENT1_REQUEST_BODY")"
echo "RESPONSE_STATUS: ${event1_status}"
echo "RESPONSE_HEADERS:"
cat "$EVENT1_HEADERS"
echo "RESPONSE_BODY:"
cat "$EVENT1_BODY"
[ "$event1_status" = "201" ] || { echo "ASSERTION_FAILED: expected HTTP 201 creating target event got ${event1_status}"; exit 1; }
TARGET_EVENT_ID="$(python3 - "$EVENT1_BODY" <<'PY'
import json, sys
with open(sys.argv[1], 'r', encoding='utf-8') as f:
    print(json.load(f)['id'])
PY
)"
[ -n "$TARGET_EVENT_ID" ] || { echo "ASSERTION_FAILED: failed to extract target event id"; exit 1; }
EVENT2_REQUEST_BODY="$(cat <<JSON
{"title":"Other Event ${CASE_SUFFIX}","description":"Non-target event for route parameter validation.","startDate":"${FUTURE_START_DATE}","endDate":"${FUTURE_END_DATE}","location":"South Hall ${CASE_SUFFIX}"}
JSON
)"
echo "PREREQ: create non-target event"
echo "REQUEST_HEADERS: Content-Type: application/json"
echo "REQUEST_BODY: ${EVENT2_REQUEST_BODY}"
event2_status="$(curl -sS -D "$EVENT2_HEADERS" -o "$EVENT2_BODY" -w '%{http_code}' \
  -X POST "$BASE_URL/api/events" \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json' \
  -d "$EVENT2_REQUEST_BODY")"
echo "RESPONSE_STATUS: ${event2_status}"
echo "RESPONSE_HEADERS:"
cat "$EVENT2_HEADERS"
echo "RESPONSE_BODY:"
cat "$EVENT2_BODY"
[ "$event2_status" = "201" ] || { echo "ASSERTION_FAILED: expected HTTP 201 creating non-target event got ${event2_status}"; exit 1; }
OTHER_EVENT_ID="$(python3 - "$EVENT2_BODY" <<'PY'
import json, sys
with open(sys.argv[1], 'r', encoding='utf-8') as f:
    print(json.load(f)['id'])
PY
)"
[ -n "$OTHER_EVENT_ID" ] || { echo "ASSERTION_FAILED: failed to extract other event id"; exit 1; }
REG_REQUEST_BODY="$(cat <<JSON
{"eventId":"${TARGET_EVENT_ID}","name":"Param Validation User ${CASE_SUFFIX}","email":"${TARGET_EMAIL}","phone":"+1-555-${CASE_SUFFIX}"}
JSON
)"
echo "PREREQ: create registration only for target event"
echo "REQUEST_HEADERS: Content-Type: application/json"
echo "REQUEST_BODY: ${REG_REQUEST_BODY}"
reg_status="$(curl -sS -D "$REG_HEADERS" -o "$REG_BODY" -w '%{http_code}' \
  -X POST "$BASE_URL/api/registrations" \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json' \
  -d "$REG_REQUEST_BODY")"
echo "RESPONSE_STATUS: ${reg_status}"
echo "RESPONSE_HEADERS:"
cat "$REG_HEADERS"
echo "RESPONSE_BODY:"
cat "$REG_BODY"
[ "$reg_status" = "201" ] || { echo "ASSERTION_FAILED: expected HTTP 201 creating registration got ${reg_status}"; exit 1; }

# When
echo "STEP: When — request registrations using the specific target event id parameter"
echo "REQUEST_HEADERS: Accept: application/json"
echo "REQUEST_BODY: <empty>"
when_status="$(curl -sS -D "$WHEN_HEADERS" -o "$WHEN_BODY" -w '%{http_code}' \
  -H 'Accept: application/json' \
  "$BASE_URL/api/registrations/${TARGET_EVENT_ID}")"
echo "RESPONSE_STATUS: ${when_status}"
echo "RESPONSE_HEADERS:"
cat "$WHEN_HEADERS"
echo "RESPONSE_BODY:"
cat "$WHEN_BODY"

# Then
echo "STEP: Then — assert only registrations for the requested event id are returned"
[ "$when_status" = "200" ] || { echo "ASSERTION_FAILED: expected HTTP 200 got ${when_status}"; exit 1; }
python3 - "$WHEN_BODY" "$TARGET_EVENT_ID" "$OTHER_EVENT_ID" "$TARGET_EMAIL" <<'PY'
import json, sys
path, target_event_id, other_event_id, target_email = sys.argv[1:5]
with open(path, 'r', encoding='utf-8') as f:
    data = json.load(f)
assert isinstance(data, list), f'expected list got {type(data).__name__}'
assert len(data) == 1, f'expected 1 registration got {len(data)}'
item = data[0]
assert item['eventId'] == target_event_id, f"expected eventId {target_event_id!r} got {item['eventId']!r}"
assert item['eventId'] != other_event_id, 'response incorrectly used a different event id parameter'
assert item['email'] == target_email, f"expected email {target_email!r} got {item['email']!r}"
PY

# Cleanup
echo "STEP: Cleanup — no API delete exists; created in-memory events/registration will reset on container restart"

echo "CODEVALID_TEST_ASSERTION_OK:get_registrations_event_id_parameter_validation"
