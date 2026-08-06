#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(python3 - <<'PY'
import uuid
print(uuid.uuid4().hex[:8])
PY
)"
EVENT1_BODY="/tmp/registration_same_email_different_events_event1_${CASE_SUFFIX}.json"
EVENT1_HEADERS="/tmp/registration_same_email_different_events_event1_headers_${CASE_SUFFIX}.txt"
EVENT1_RESPONSE="/tmp/registration_same_email_different_events_event1_response_${CASE_SUFFIX}.json"
EVENT2_BODY="/tmp/registration_same_email_different_events_event2_${CASE_SUFFIX}.json"
EVENT2_HEADERS="/tmp/registration_same_email_different_events_event2_headers_${CASE_SUFFIX}.txt"
EVENT2_RESPONSE="/tmp/registration_same_email_different_events_event2_response_${CASE_SUFFIX}.json"
GIVEN_REG_BODY="/tmp/registration_same_email_different_events_given_reg_${CASE_SUFFIX}.json"
GIVEN_REG_HEADERS="/tmp/registration_same_email_different_events_given_reg_headers_${CASE_SUFFIX}.txt"
GIVEN_REG_RESPONSE="/tmp/registration_same_email_different_events_given_reg_response_${CASE_SUFFIX}.json"
WHEN_BODY="/tmp/registration_same_email_different_events_when_${CASE_SUFFIX}.json"
WHEN_HEADERS="/tmp/registration_same_email_different_events_when_headers_${CASE_SUFFIX}.txt"
WHEN_RESPONSE="/tmp/registration_same_email_different_events_when_response_${CASE_SUFFIX}.json"
LIST_BODY="/tmp/registration_same_email_different_events_list_${CASE_SUFFIX}.json"
LIST_HEADERS="/tmp/registration_same_email_different_events_list_headers_${CASE_SUFFIX}.txt"
REG_EMAIL="user.${CASE_SUFFIX}@example.com"

event_start_date="$(python3 - <<'PY'
from datetime import date, timedelta
print((date.today() - timedelta(days=1)).isoformat())
PY
)"
event_end_date="$(python3 - <<'PY'
from datetime import date, timedelta
print((date.today() + timedelta(days=2)).isoformat())
PY
)"

echo "STEP: Given — create two active events and register the email on the first event"
cat > "$EVENT1_BODY" <<EOF
{"title":"Registration Same Email Event One ${CASE_SUFFIX}","description":"First active event","location":"Room One","startDate":"$event_start_date","endDate":"$event_end_date"}
EOF
echo "PREREQ: create first event prerequisite"
echo "REQUEST_HEADERS: Content-Type: application/json"
echo "REQUEST_BODY: $(cat "$EVENT1_BODY")"
event1_status="$(curl -sS -D "$EVENT1_HEADERS" -o "$EVENT1_RESPONSE" -w '%{http_code}' -X POST "$BASE_URL/api/events" -H 'Content-Type: application/json' --data @"$EVENT1_BODY")"
echo "RESPONSE_STATUS: $event1_status"
echo "RESPONSE_HEADERS:"
cat "$EVENT1_HEADERS"
echo "RESPONSE_BODY: $(cat "$EVENT1_RESPONSE")"
[ "$event1_status" = "201" ] || { echo "ASSERTION_FAILED: expected HTTP 201 got ${event1_status}"; exit 1; }
EVENT1_ID="$(python3 - "$EVENT1_RESPONSE" <<'PY'
import json, sys
print(json.load(open(sys.argv[1]))['id'])
PY
)"
cat > "$EVENT2_BODY" <<EOF
{"title":"Registration Same Email Event Two ${CASE_SUFFIX}","description":"Second active event","location":"Room Two","startDate":"$event_start_date","endDate":"$event_end_date"}
EOF
echo "PREREQ: create second event prerequisite"
echo "REQUEST_HEADERS: Content-Type: application/json"
echo "REQUEST_BODY: $(cat "$EVENT2_BODY")"
event2_status="$(curl -sS -D "$EVENT2_HEADERS" -o "$EVENT2_RESPONSE" -w '%{http_code}' -X POST "$BASE_URL/api/events" -H 'Content-Type: application/json' --data @"$EVENT2_BODY")"
echo "RESPONSE_STATUS: $event2_status"
echo "RESPONSE_HEADERS:"
cat "$EVENT2_HEADERS"
echo "RESPONSE_BODY: $(cat "$EVENT2_RESPONSE")"
[ "$event2_status" = "201" ] || { echo "ASSERTION_FAILED: expected HTTP 201 got ${event2_status}"; exit 1; }
EVENT2_ID="$(python3 - "$EVENT2_RESPONSE" <<'PY'
import json, sys
print(json.load(open(sys.argv[1]))['id'])
PY
)"
cat > "$GIVEN_REG_BODY" <<EOF
{"eventId":"$EVENT1_ID","name":"Existing User","email":"$REG_EMAIL","phone":"+1111111111"}
EOF
echo "PREREQ: create first-event registration prerequisite"
echo "REQUEST_HEADERS: Content-Type: application/json"
echo "REQUEST_BODY: $(cat "$GIVEN_REG_BODY")"
given_reg_status="$(curl -sS -D "$GIVEN_REG_HEADERS" -o "$GIVEN_REG_RESPONSE" -w '%{http_code}' -X POST "$BASE_URL/api/registrations" -H 'Content-Type: application/json' --data @"$GIVEN_REG_BODY")"
echo "RESPONSE_STATUS: $given_reg_status"
echo "RESPONSE_HEADERS:"
cat "$GIVEN_REG_HEADERS"
echo "RESPONSE_BODY: $(cat "$GIVEN_REG_RESPONSE")"
[ "$given_reg_status" = "201" ] || { echo "ASSERTION_FAILED: expected HTTP 201 got ${given_reg_status}"; exit 1; }

echo "STEP: When — register the same email on the second event"
cat > "$WHEN_BODY" <<EOF
{"eventId":"$EVENT2_ID","name":"John Doe","email":"$REG_EMAIL","phone":"+1234567890"}
EOF
echo "REQUEST_HEADERS: Content-Type: application/json"
echo "REQUEST_BODY: $(cat "$WHEN_BODY")"
when_status="$(curl -sS -D "$WHEN_HEADERS" -o "$WHEN_RESPONSE" -w '%{http_code}' -X POST "$BASE_URL/api/registrations" -H 'Content-Type: application/json' --data @"$WHEN_BODY")"
echo "RESPONSE_STATUS: $when_status"
echo "RESPONSE_HEADERS:"
cat "$WHEN_HEADERS"
echo "RESPONSE_BODY: $(cat "$WHEN_RESPONSE")"

echo "STEP: Then — assert same email is allowed for a different event"
[ "$when_status" = "201" ] || { echo "ASSERTION_FAILED: expected HTTP 201 got ${when_status}"; exit 1; }
python3 - "$WHEN_RESPONSE" "$EVENT2_ID" "$REG_EMAIL" <<'PY'
import json, re, sys
body = json.load(open(sys.argv[1]))
event_id = sys.argv[2]
email = sys.argv[3]
assert re.match(r'^reg[_-]', body.get('id', '')), 'id prefix mismatch'
assert body.get('eventId') == event_id, 'eventId mismatch'
assert body.get('email') == email, 'email mismatch'
PY
[ $? -eq 0 ] || { echo "ASSERTION_FAILED: expected successful registration for second event"; exit 1; }

echo "STEP: Cleanup — inspect second event registrations to confirm created registration exists"
list_status="$(curl -sS -D "$LIST_HEADERS" -o "$LIST_BODY" -w '%{http_code}' "$BASE_URL/api/registrations/$EVENT2_ID")"
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
assert any(item.get('email') == email for item in items)
PY
[ $? -eq 0 ] || { echo "ASSERTION_FAILED: expected registration on second event during cleanup inspection"; exit 1; }
echo "CODEVALID_TEST_ASSERTION_OK:registration_same_email_different_events"
