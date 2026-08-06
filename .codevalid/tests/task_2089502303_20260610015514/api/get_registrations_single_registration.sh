#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$$"
TEST_ID="get_registrations_single_registration"
EVENT_ID=""
REG_EMAIL="single_${CASE_SUFFIX}@example.com"
START_DATE="$(python3 - <<'PY'
from datetime import date, timedelta
print((date.today() - timedelta(days=1)).isoformat())
PY
)"
END_DATE="$(python3 - <<'PY'
from datetime import date, timedelta
print((date.today() + timedelta(days=2)).isoformat())
PY
)"
GIVEN_EVENT_HEADERS="/tmp/${TEST_ID}_given_event_headers_${CASE_SUFFIX}.txt"
GIVEN_EVENT_BODY="/tmp/${TEST_ID}_given_event_body_${CASE_SUFFIX}.json"
GIVEN_REG_HEADERS="/tmp/${TEST_ID}_given_reg_headers_${CASE_SUFFIX}.txt"
GIVEN_REG_BODY="/tmp/${TEST_ID}_given_reg_body_${CASE_SUFFIX}.json"
WHEN_HEADERS="/tmp/${TEST_ID}_when_headers_${CASE_SUFFIX}.txt"
WHEN_BODY="/tmp/${TEST_ID}_when_body_${CASE_SUFFIX}.json"

# Given
echo "STEP: Given — create an active event and one registration"
EVENT_REQUEST_BODY="$(cat <<JSON
{"title":"Single Registration Event ${CASE_SUFFIX}","description":"Created for one registration retrieval.","startDate":"${START_DATE}","endDate":"${END_DATE}","location":"Room ${CASE_SUFFIX}"}
JSON
)"
echo "PREREQ: create active event"
echo "REQUEST_HEADERS: Content-Type: application/json"
echo "REQUEST_BODY: ${EVENT_REQUEST_BODY}"
given_event_status="$(curl -sS -D "$GIVEN_EVENT_HEADERS" -o "$GIVEN_EVENT_BODY" -w '%{http_code}' \
  -X POST "$BASE_URL/api/events" \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json' \
  -d "$EVENT_REQUEST_BODY")"
echo "RESPONSE_STATUS: ${given_event_status}"
echo "RESPONSE_HEADERS:"
cat "$GIVEN_EVENT_HEADERS"
echo "RESPONSE_BODY:"
cat "$GIVEN_EVENT_BODY"
[ "$given_event_status" = "201" ] || { echo "ASSERTION_FAILED: expected HTTP 201 creating event got ${given_event_status}"; exit 1; }
EVENT_ID="$(python3 - "$GIVEN_EVENT_BODY" <<'PY'
import json, sys
with open(sys.argv[1], 'r', encoding='utf-8') as f:
    print(json.load(f)['id'])
PY
)"
[ -n "$EVENT_ID" ] || { echo "ASSERTION_FAILED: failed to extract event id"; exit 1; }
REG_REQUEST_BODY="$(cat <<JSON
{"eventId":"${EVENT_ID}","name":"Single Registrant ${CASE_SUFFIX}","email":"${REG_EMAIL}","phone":"+1-555-${CASE_SUFFIX}"}
JSON
)"
echo "PREREQ: create one registration for the event"
echo "REQUEST_HEADERS: Content-Type: application/json"
echo "REQUEST_BODY: ${REG_REQUEST_BODY}"
given_reg_status="$(curl -sS -D "$GIVEN_REG_HEADERS" -o "$GIVEN_REG_BODY" -w '%{http_code}' \
  -X POST "$BASE_URL/api/registrations" \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json' \
  -d "$REG_REQUEST_BODY")"
echo "RESPONSE_STATUS: ${given_reg_status}"
echo "RESPONSE_HEADERS:"
cat "$GIVEN_REG_HEADERS"
echo "RESPONSE_BODY:"
cat "$GIVEN_REG_BODY"
[ "$given_reg_status" = "201" ] || { echo "ASSERTION_FAILED: expected HTTP 201 creating registration got ${given_reg_status}"; exit 1; }

# When
echo "STEP: When — retrieve registrations for the event"
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
echo "STEP: Then — assert the single registration is returned with expected fields"
[ "$when_status" = "200" ] || { echo "ASSERTION_FAILED: expected HTTP 200 got ${when_status}"; exit 1; }
python3 - "$WHEN_BODY" "$EVENT_ID" "$REG_EMAIL" "$CASE_SUFFIX" <<'PY'
import json, re, sys
path, event_id, email, suffix = sys.argv[1:5]
with open(path, 'r', encoding='utf-8') as f:
    data = json.load(f)
assert isinstance(data, list), f'expected list got {type(data).__name__}'
assert len(data) == 1, f'expected 1 registration got {len(data)}'
item = data[0]
assert item['eventId'] == event_id, f"expected eventId {event_id!r} got {item['eventId']!r}"
assert item['email'] == email, f"expected email {email!r} got {item['email']!r}"
assert item['name'] == f'Single Registrant {suffix}', f"unexpected name {item['name']!r}"
assert 'registeredAt' in item and item['registeredAt'], 'registeredAt missing or empty'
assert re.match(r'^reg[_-]', item['id']), f"unexpected registration id {item['id']!r}"
PY

# Cleanup
echo "STEP: Cleanup — no API delete exists; created in-memory event/registration will reset on container restart"

echo "CODEVALID_TEST_ASSERTION_OK:get_registrations_single_registration"
