#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(python3 - <<'PY'
import uuid
print(uuid.uuid4().hex[:8])
PY
)"
TEST_ID="event_available_for_registration"
TODAY_DATE="$(python3 - <<'PY'
from datetime import datetime, timezone
print(datetime.now(timezone.utc).strftime('%Y-%m-%d'))
PY
)"
EVENT_TITLE="Registrable Event ${CASE_SUFFIX}"
CREATE_REQUEST_BODY_FILE="/tmp/${TEST_ID}_create_request_${CASE_SUFFIX}.json"
CREATE_RESPONSE_BODY_FILE="/tmp/${TEST_ID}_create_response_${CASE_SUFFIX}.json"
CREATE_RESPONSE_HEADERS_FILE="/tmp/${TEST_ID}_create_headers_${CASE_SUFFIX}.txt"
REGISTER_REQUEST_BODY_FILE="/tmp/${TEST_ID}_register_request_${CASE_SUFFIX}.json"
REGISTER_RESPONSE_BODY_FILE="/tmp/${TEST_ID}_register_response_${CASE_SUFFIX}.json"
REGISTER_RESPONSE_HEADERS_FILE="/tmp/${TEST_ID}_register_headers_${CASE_SUFFIX}.txt"
LIST_RESPONSE_BODY_FILE="/tmp/${TEST_ID}_list_response_${CASE_SUFFIX}.json"
LIST_RESPONSE_HEADERS_FILE="/tmp/${TEST_ID}_list_headers_${CASE_SUFFIX}.txt"

# Given
echo "STEP: Given — create an event whose startDate and endDate allow registration today"
echo "PREREQ: create request body for event creation"
cat > "$CREATE_REQUEST_BODY_FILE" <<EOF
{
  "title": "$EVENT_TITLE",
  "description": "Registration availability check",
  "location": "Hall ${CASE_SUFFIX}",
  "startDate": "$TODAY_DATE",
  "endDate": "$TODAY_DATE"
}
EOF
echo 'REQUEST_HEADERS: Content-Type: application/json'
echo "REQUEST_BODY:"
cat "$CREATE_REQUEST_BODY_FILE"
given_status="$(curl -sS -D "$CREATE_RESPONSE_HEADERS_FILE" -o "$CREATE_RESPONSE_BODY_FILE" -w '%{http_code}' -X POST "$BASE_URL/api/events" -H 'Content-Type: application/json' --data @"$CREATE_REQUEST_BODY_FILE")"
echo "RESPONSE_STATUS: $given_status"
echo "RESPONSE_HEADERS:"
cat "$CREATE_RESPONSE_HEADERS_FILE"
echo "RESPONSE_BODY:"
cat "$CREATE_RESPONSE_BODY_FILE"
[ "$given_status" = "201" ] || { echo "ASSERTION_FAILED: expected Given event creation HTTP 201 got ${given_status}"; exit 1; }
CREATED_EVENT_ID="$(python3 - "$CREATE_RESPONSE_BODY_FILE" <<'PY'
import json, sys
with open(sys.argv[1], 'r', encoding='utf-8') as fh:
    data = json.load(fh)
print(data['id'])
PY
)"
[ -n "$CREATED_EVENT_ID" ] || { echo "ASSERTION_FAILED: expected created event id to be present"; exit 1; }
echo "PREREQ: create registration request body for the new event"
cat > "$REGISTER_REQUEST_BODY_FILE" <<EOF
{
  "eventId": "$CREATED_EVENT_ID",
  "name": "Registration User ${CASE_SUFFIX}",
  "email": "registration-${CASE_SUFFIX}@example.com",
  "phone": "+1555000${CASE_SUFFIX}"
}
EOF

# When
echo "STEP: When — POST /api/registrations for the created event and then GET /api/events to verify registrationCount"
echo 'REQUEST_HEADERS: Content-Type: application/json'
echo "REQUEST_BODY:"
cat "$REGISTER_REQUEST_BODY_FILE"
when_status="$(curl -sS -D "$REGISTER_RESPONSE_HEADERS_FILE" -o "$REGISTER_RESPONSE_BODY_FILE" -w '%{http_code}' -X POST "$BASE_URL/api/registrations" -H 'Content-Type: application/json' --data @"$REGISTER_REQUEST_BODY_FILE")"
echo "RESPONSE_STATUS: $when_status"
echo "RESPONSE_HEADERS:"
cat "$REGISTER_RESPONSE_HEADERS_FILE"
echo "RESPONSE_BODY:"
cat "$REGISTER_RESPONSE_BODY_FILE"
list_status="$(curl -sS -D "$LIST_RESPONSE_HEADERS_FILE" -o "$LIST_RESPONSE_BODY_FILE" -w '%{http_code}' "$BASE_URL/api/events")"
echo "FOLLOWUP_RESPONSE_STATUS: $list_status"
echo "FOLLOWUP_RESPONSE_HEADERS:"
cat "$LIST_RESPONSE_HEADERS_FILE"
echo "FOLLOWUP_RESPONSE_BODY:"
cat "$LIST_RESPONSE_BODY_FILE"

# Then
echo "STEP: Then — assert registration succeeds and event registrationCount becomes 1"
[ "$when_status" = "201" ] || { echo "ASSERTION_FAILED: expected HTTP 201 from registration got ${when_status}"; exit 1; }
[ "$list_status" = "200" ] || { echo "ASSERTION_FAILED: expected HTTP 200 from GET /api/events got ${list_status}"; exit 1; }
python3 - "$REGISTER_RESPONSE_BODY_FILE" "$CREATED_EVENT_ID" "$CASE_SUFFIX" <<'PY'
import json, sys, re
path, event_id, suffix = sys.argv[1:4]
with open(path, 'r', encoding='utf-8') as fh:
    data = json.load(fh)
assert isinstance(data.get('id'), str) and re.match(r'^reg_', data['id']), 'registration id must start with reg_'
assert data.get('eventId') == event_id, data
assert data.get('name') == f'Registration User {suffix}', data
assert data.get('email') == f'registration-{suffix}@example.com', data
assert data.get('phone') == f'+1555000{suffix}', data
assert isinstance(data.get('registeredAt'), str) and data['registeredAt'], data
PY
python3 - "$LIST_RESPONSE_BODY_FILE" "$CREATED_EVENT_ID" <<'PY'
import json, sys
path, event_id = sys.argv[1:3]
with open(path, 'r', encoding='utf-8') as fh:
    events = json.load(fh)
match = None
for item in events:
    if item.get('id') == event_id:
        match = item
        break
assert match is not None, f'event {event_id} not found in events list'
assert match.get('registrationCount') == 1, match
PY

echo "ASSERTION_OK: registration succeeded and event registrationCount became 1"

# Cleanup
echo "STEP: Cleanup — no API delete endpoints exist; no cleanup performed"

echo "CODEVALID_TEST_ASSERTION_OK:event_available_for_registration"
