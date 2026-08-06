#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(python3 - <<'PY'
import uuid
print(uuid.uuid4().hex[:8])
PY
)"
EVENT_BODY="/tmp/registration_duplicate_email_case_insensitive_event_${CASE_SUFFIX}.json"
EVENT_HEADERS="/tmp/registration_duplicate_email_case_insensitive_event_headers_${CASE_SUFFIX}.txt"
EVENT_RESPONSE="/tmp/registration_duplicate_email_case_insensitive_event_response_${CASE_SUFFIX}.json"
GIVEN_REG_BODY="/tmp/registration_duplicate_email_case_insensitive_given_reg_${CASE_SUFFIX}.json"
GIVEN_REG_HEADERS="/tmp/registration_duplicate_email_case_insensitive_given_reg_headers_${CASE_SUFFIX}.txt"
GIVEN_REG_RESPONSE="/tmp/registration_duplicate_email_case_insensitive_given_reg_response_${CASE_SUFFIX}.json"
WHEN_BODY="/tmp/registration_duplicate_email_case_insensitive_when_${CASE_SUFFIX}.json"
WHEN_HEADERS="/tmp/registration_duplicate_email_case_insensitive_when_headers_${CASE_SUFFIX}.txt"
WHEN_RESPONSE="/tmp/registration_duplicate_email_case_insensitive_when_response_${CASE_SUFFIX}.json"
LIST_BODY="/tmp/registration_duplicate_email_case_insensitive_list_${CASE_SUFFIX}.json"
LIST_HEADERS="/tmp/registration_duplicate_email_case_insensitive_list_headers_${CASE_SUFFIX}.txt"
UPPER_EMAIL="User.${CASE_SUFFIX}@Example.com"
LOWER_EMAIL="user.${CASE_SUFFIX}@example.com"

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

echo "STEP: Given — create an active event and register mixed-case email"
cat > "$EVENT_BODY" <<EOF
{"title":"Registration Duplicate Email Case ${CASE_SUFFIX}","description":"Case insensitive duplicate event","location":"East Hall","startDate":"$event_start_date","endDate":"$event_end_date"}
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
{"eventId":"$EVENT_ID","name":"Existing User","email":"$UPPER_EMAIL","phone":"+1111111111"}
EOF
echo "PREREQ: create existing mixed-case registration prerequisite"
echo "REQUEST_HEADERS: Content-Type: application/json"
echo "REQUEST_BODY: $(cat "$GIVEN_REG_BODY")"
given_reg_status="$(curl -sS -D "$GIVEN_REG_HEADERS" -o "$GIVEN_REG_RESPONSE" -w '%{http_code}' -X POST "$BASE_URL/api/registrations" -H 'Content-Type: application/json' --data @"$GIVEN_REG_BODY")"
echo "RESPONSE_STATUS: $given_reg_status"
echo "RESPONSE_HEADERS:"
cat "$GIVEN_REG_HEADERS"
echo "RESPONSE_BODY: $(cat "$GIVEN_REG_RESPONSE")"
[ "$given_reg_status" = "201" ] || { echo "ASSERTION_FAILED: expected HTTP 201 got ${given_reg_status}"; exit 1; }

echo "STEP: When — attempt registration with same email in lower case"
cat > "$WHEN_BODY" <<EOF
{"eventId":"$EVENT_ID","name":"John Doe","email":"$LOWER_EMAIL","phone":"+1234567890"}
EOF
echo "REQUEST_HEADERS: Content-Type: application/json"
echo "REQUEST_BODY: $(cat "$WHEN_BODY")"
when_status="$(curl -sS -D "$WHEN_HEADERS" -o "$WHEN_RESPONSE" -w '%{http_code}' -X POST "$BASE_URL/api/registrations" -H 'Content-Type: application/json' --data @"$WHEN_BODY")"
echo "RESPONSE_STATUS: $when_status"
echo "RESPONSE_HEADERS:"
cat "$WHEN_HEADERS"
echo "RESPONSE_BODY: $(cat "$WHEN_RESPONSE")"

echo "STEP: Then — assert case-insensitive duplicate detection"
[ "$when_status" = "400" ] || { echo "ASSERTION_FAILED: expected HTTP 400 got ${when_status}"; exit 1; }
python3 - "$WHEN_RESPONSE" <<'PY'
import json, sys
body = json.load(open(sys.argv[1]))
assert body.get('message') == 'This email is already registered for this event.'
PY
[ $? -eq 0 ] || { echo "ASSERTION_FAILED: expected case-insensitive duplicate email message"; exit 1; }

echo "STEP: Cleanup — inspect registrations to confirm only original case variant exists"
list_status="$(curl -sS -D "$LIST_HEADERS" -o "$LIST_BODY" -w '%{http_code}' "$BASE_URL/api/registrations/$EVENT_ID")"
echo "REQUEST_HEADERS: Accept: application/json"
echo "REQUEST_BODY:"
echo "RESPONSE_STATUS: $list_status"
echo "RESPONSE_HEADERS:"
cat "$LIST_HEADERS"
echo "RESPONSE_BODY: $(cat "$LIST_BODY")"
[ "$list_status" = "200" ] || { echo "ASSERTION_FAILED: expected HTTP 200 got ${list_status}"; exit 1; }
python3 - "$LIST_BODY" "$UPPER_EMAIL" "$LOWER_EMAIL" <<'PY'
import json, sys
items = json.load(open(sys.argv[1]))
upper_email = sys.argv[2].lower()
lower_email = sys.argv[3].lower()
matches = [item for item in items if item.get('email', '').lower() in (upper_email, lower_email)]
assert len(matches) == 1
assert matches[0].get('email').lower() == lower_email
PY
[ $? -eq 0 ] || { echo "ASSERTION_FAILED: expected only one case-insensitive registration match in cleanup inspection"; exit 1; }
echo "CODEVALID_TEST_ASSERTION_OK:registration_duplicate_email_case_insensitive"
