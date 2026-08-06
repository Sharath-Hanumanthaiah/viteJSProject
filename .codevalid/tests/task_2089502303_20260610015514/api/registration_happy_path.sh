#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(python3 - <<'PY'
import uuid
print(uuid.uuid4().hex[:8])
PY
)"
EVENT_TITLE="Registration Happy Path ${CASE_SUFFIX}"
REG_EMAIL="user.${CASE_SUFFIX}@example.com"
EVENT_BODY="/tmp/registration_happy_path_event_${CASE_SUFFIX}.json"
EVENT_HEADERS="/tmp/registration_happy_path_event_headers_${CASE_SUFFIX}.txt"
EVENT_RESPONSE="/tmp/registration_happy_path_event_response_${CASE_SUFFIX}.json"
WHEN_BODY="/tmp/registration_happy_path_when_${CASE_SUFFIX}.json"
WHEN_HEADERS="/tmp/registration_happy_path_when_headers_${CASE_SUFFIX}.txt"
WHEN_RESPONSE="/tmp/registration_happy_path_when_response_${CASE_SUFFIX}.json"
LIST_BODY="/tmp/registration_happy_path_list_${CASE_SUFFIX}.json"
LIST_HEADERS="/tmp/registration_happy_path_list_headers_${CASE_SUFFIX}.txt"

event_start_date="$(python3 - <<'PY'
from datetime import date, timedelta
print((date.today() - timedelta(days=1)).isoformat())
PY
)"
event_end_date="$(python3 - <<'PY'
from datetime import date, timedelta
print((date.today() + timedelta(days=1)).isoformat())
PY
)"

echo "STEP: Given — create an event open for registration"
cat > "$EVENT_BODY" <<EOF
{"title":"$EVENT_TITLE","description":"Happy path registration event","location":"Main Hall","startDate":"$event_start_date","endDate":"$event_end_date"}
EOF
echo "PREREQ: create event prerequisite"
echo "REQUEST_HEADERS: Content-Type: application/json"
echo "REQUEST_BODY: $(cat "$EVENT_BODY")"
event_status="$(curl -sS -D "$EVENT_HEADERS" -o "$EVENT_RESPONSE" -w '%{http_code}' -X POST "$BASE_URL/api/events" -H 'Content-Type: application/json' --data @"$EVENT_BODY")"
echo "RESPONSE_STATUS: $event_status"
echo "RESPONSE_HEADERS:"
cat "$EVENT_HEADERS"
echo "RESPONSE_BODY: $(cat "$EVENT_RESPONSE")"
[ "$event_status" = "201" ] || { echo "ASSERTION_FAILED: expected HTTP 201 got ${event_status}"; exit 1; }
EVENT_ID="$(python3 - "$EVENT_RESPONSE" <<'PY'
import json, sys
print(json.load(open(sys.argv[1]))['id'])
PY
)"
[ -n "$EVENT_ID" ] || { echo "ASSERTION_FAILED: expected created event id"; exit 1; }

echo "STEP: When — submit registration with all required fields"
cat > "$WHEN_BODY" <<EOF
{"eventId":"$EVENT_ID","name":"John Doe","email":"$REG_EMAIL","phone":"+1234567890"}
EOF
echo "REQUEST_HEADERS: Content-Type: application/json"
echo "REQUEST_BODY: $(cat "$WHEN_BODY")"
when_status="$(curl -sS -D "$WHEN_HEADERS" -o "$WHEN_RESPONSE" -w '%{http_code}' -X POST "$BASE_URL/api/registrations" -H 'Content-Type: application/json' --data @"$WHEN_BODY")"
echo "RESPONSE_STATUS: $when_status"
echo "RESPONSE_HEADERS:"
cat "$WHEN_HEADERS"
echo "RESPONSE_BODY: $(cat "$WHEN_RESPONSE")"

echo "STEP: Then — assert the registration was created"
[ "$when_status" = "201" ] || { echo "ASSERTION_FAILED: expected HTTP 201 got ${when_status}"; exit 1; }
python3 - "$WHEN_RESPONSE" "$EVENT_ID" "$REG_EMAIL" <<'PY'
import json, re, sys
body = json.load(open(sys.argv[1]))
event_id = sys.argv[2]
email = sys.argv[3]
assert re.match(r'^reg[_-]', body.get('id', '')), 'id prefix mismatch'
assert body.get('eventId') == event_id, 'eventId mismatch'
assert body.get('name') == 'John Doe', 'name mismatch'
assert body.get('email') == email, 'email mismatch'
assert body.get('phone') == '+1234567890', 'phone mismatch'
assert body.get('registeredAt'), 'registeredAt missing'
PY
[ $? -eq 0 ] || { echo "ASSERTION_FAILED: response body missing expected registration fields"; exit 1; }

echo "STEP: Cleanup — inspect created registrations for traceability"
list_status="$(curl -sS -D "$LIST_HEADERS" -o "$LIST_BODY" -w '%{http_code}' "$BASE_URL/api/registrations/$EVENT_ID")"
echo "REQUEST_HEADERS: Accept: application/json"
echo "REQUEST_BODY:"
echo "RESPONSE_STATUS: $list_status"
echo "RESPONSE_HEADERS:"
cat "$LIST_HEADERS"
echo "RESPONSE_BODY: $(cat "$LIST_BODY")"
[ "$list_status" = "200" ] || { echo "ASSERTION_FAILED: expected HTTP 200 got ${list_status}"; exit 1; }
python3 - "$LIST_BODY" "$REG_EMAIL" <<'PY'
import json, sys
items = json.load(open(sys.argv[1]))
email = sys.argv[2]
assert any(item.get('email') == email for item in items), 'created registration not found during cleanup inspection'
PY
[ $? -eq 0 ] || { echo "ASSERTION_FAILED: expected cleanup inspection to find created registration"; exit 1; }
echo "CODEVALID_TEST_ASSERTION_OK:registration_happy_path"
