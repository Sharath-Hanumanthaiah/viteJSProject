#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(python3 - <<'PY'
import uuid
print(uuid.uuid4().hex[:8])
PY
)"
EVENT_BODY="/tmp/registration_duplicate_email_event_${CASE_SUFFIX}.json"
EVENT_HEADERS="/tmp/registration_duplicate_email_event_headers_${CASE_SUFFIX}.txt"
EVENT_RESPONSE="/tmp/registration_duplicate_email_event_response_${CASE_SUFFIX}.json"
GIVEN_REG_BODY="/tmp/registration_duplicate_email_given_reg_${CASE_SUFFIX}.json"
GIVEN_REG_HEADERS="/tmp/registration_duplicate_email_given_reg_headers_${CASE_SUFFIX}.txt"
GIVEN_REG_RESPONSE="/tmp/registration_duplicate_email_given_reg_response_${CASE_SUFFIX}.json"
WHEN_BODY="/tmp/registration_duplicate_email_when_${CASE_SUFFIX}.json"
WHEN_HEADERS="/tmp/registration_duplicate_email_when_headers_${CASE_SUFFIX}.txt"
WHEN_RESPONSE="/tmp/registration_duplicate_email_when_response_${CASE_SUFFIX}.json"
LIST_BODY="/tmp/registration_duplicate_email_list_${CASE_SUFFIX}.json"
LIST_HEADERS="/tmp/registration_duplicate_email_list_headers_${CASE_SUFFIX}.txt"
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

echo "STEP: Given — create an active event and an existing registration"
cat > "$EVENT_BODY" <<EOF
{"title":"Registration Duplicate Email ${CASE_SUFFIX}","description":"Duplicate email event","location":"West Hall","startDate":"$event_start_date","endDate":"$event_end_date"}
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
cat > "$GIVEN_REG_BODY" <<EOF
{"eventId":"$EVENT_ID","name":"Existing User","email":"$REG_EMAIL","phone":"+1111111111"}
EOF
echo "PREREQ: create existing registration prerequisite"
echo "REQUEST_HEADERS: Content-Type: application/json"
echo "REQUEST_BODY: $(cat "$GIVEN_REG_BODY")"
given_reg_status="$(curl -sS -D "$GIVEN_REG_HEADERS" -o "$GIVEN_REG_RESPONSE" -w '%{http_code}' -X POST "$BASE_URL/api/registrations" -H 'Content-Type: application/json' --data @"$GIVEN_REG_BODY")"
echo "RESPONSE_STATUS: $given_reg_status"
echo "RESPONSE_HEADERS:"
cat "$GIVEN_REG_HEADERS"
echo "RESPONSE_BODY: $(cat "$GIVEN_REG_RESPONSE")"
[ "$given_reg_status" = "201" ] || { echo "ASSERTION_FAILED: expected HTTP 201 got ${given_reg_status}"; exit 1; }

echo "STEP: When — attempt a second registration with the same email"
cat > "$WHEN_BODY" <<EOF
{"eventId":"$EVENT_ID","name":"Jane Doe","email":"$REG_EMAIL","phone":"+0987654321"}
EOF
echo "REQUEST_HEADERS: Content-Type: application/json"
echo "REQUEST_BODY: $(cat "$WHEN_BODY")"
when_status="$(curl -sS -D "$WHEN_HEADERS" -o "$WHEN_RESPONSE" -w '%{http_code}' -X POST "$BASE_URL/api/registrations" -H 'Content-Type: application/json' --data @"$WHEN_BODY")"
echo "RESPONSE_STATUS: $when_status"
echo "RESPONSE_HEADERS:"
cat "$WHEN_HEADERS"
echo "RESPONSE_BODY: $(cat "$WHEN_RESPONSE")"

echo "STEP: Then — assert duplicate email is rejected"
[ "$when_status" = "400" ] || { echo "ASSERTION_FAILED: expected HTTP 400 got ${when_status}"; exit 1; }
python3 - "$WHEN_RESPONSE" <<'PY'
import json, sys
body = json.load(open(sys.argv[1]))
assert body.get('message') == 'This email is already registered for this event.'
PY
[ $? -eq 0 ] || { echo "ASSERTION_FAILED: expected duplicate email message"; exit 1; }

echo "STEP: Cleanup — inspect registrations to confirm only one matching email remains"
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
matches = [item for item in items if item.get('email') == email]
assert len(matches) == 1
PY
[ $? -eq 0 ] || { echo "ASSERTION_FAILED: expected exactly one registration for duplicate email cleanup inspection"; exit 1; }
echo "CODEVALID_TEST_ASSERTION_OK:registration_duplicate_email"
