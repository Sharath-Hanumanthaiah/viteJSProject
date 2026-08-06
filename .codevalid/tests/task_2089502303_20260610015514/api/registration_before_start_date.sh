#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(python3 - <<'PY'
import uuid
print(uuid.uuid4().hex[:8])
PY
)"
EVENT_BODY="/tmp/registration_before_start_date_event_${CASE_SUFFIX}.json"
EVENT_HEADERS="/tmp/registration_before_start_date_event_headers_${CASE_SUFFIX}.txt"
EVENT_RESPONSE="/tmp/registration_before_start_date_event_response_${CASE_SUFFIX}.json"
WHEN_BODY="/tmp/registration_before_start_date_when_${CASE_SUFFIX}.json"
WHEN_HEADERS="/tmp/registration_before_start_date_when_headers_${CASE_SUFFIX}.txt"
WHEN_RESPONSE="/tmp/registration_before_start_date_when_response_${CASE_SUFFIX}.json"

future_start_date="$(python3 - <<'PY'
from datetime import date, timedelta
print((date.today() + timedelta(days=30)).isoformat())
PY
)"
future_end_date="$(python3 - <<'PY'
from datetime import date, timedelta
print((date.today() + timedelta(days=35)).isoformat())
PY
)"

echo "STEP: Given — create an event whose registration opens in the future"
cat > "$EVENT_BODY" <<EOF
{"title":"Registration Future Event ${CASE_SUFFIX}","description":"Future registration window","location":"North Wing","startDate":"$future_start_date","endDate":"$future_end_date"}
EOF
echo "PREREQ: create future event prerequisite"
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

echo "STEP: When — attempt registration before the start date"
cat > "$WHEN_BODY" <<EOF
{"eventId":"$EVENT_ID","name":"John Doe","email":"user.${CASE_SUFFIX}@example.com","phone":"+1234567890"}
EOF
echo "REQUEST_HEADERS: Content-Type: application/json"
echo "REQUEST_BODY: $(cat "$WHEN_BODY")"
when_status="$(curl -sS -D "$WHEN_HEADERS" -o "$WHEN_RESPONSE" -w '%{http_code}' -X POST "$BASE_URL/api/registrations" -H 'Content-Type: application/json' --data @"$WHEN_BODY")"
echo "RESPONSE_STATUS: $when_status"
echo "RESPONSE_HEADERS:"
cat "$WHEN_HEADERS"
echo "RESPONSE_BODY: $(cat "$WHEN_RESPONSE")"

echo "STEP: Then — assert registration has not opened yet"
[ "$when_status" = "400" ] || { echo "ASSERTION_FAILED: expected HTTP 400 got ${when_status}"; exit 1; }
python3 - "$WHEN_RESPONSE" "$future_start_date" <<'PY'
import json, sys
body = json.load(open(sys.argv[1]))
start_date = sys.argv[2]
message = body.get('message', '')
assert 'Registration has not opened yet.' in message
assert start_date in message
PY
[ $? -eq 0 ] || { echo "ASSERTION_FAILED: expected future registration window message"; exit 1; }

echo "STEP: Cleanup — no registration was created and no delete endpoint exists"
echo "CODEVALID_TEST_ASSERTION_OK:registration_before_start_date"
