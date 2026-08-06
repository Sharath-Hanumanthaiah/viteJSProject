#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(python3 - <<'PY'
import uuid
print(uuid.uuid4().hex[:8])
PY
)"
WHEN_BODY="/tmp/registration_missing_event_id_when_${CASE_SUFFIX}.json"
WHEN_HEADERS="/tmp/registration_missing_event_id_when_headers_${CASE_SUFFIX}.txt"
WHEN_RESPONSE="/tmp/registration_missing_event_id_when_response_${CASE_SUFFIX}.json"

echo "STEP: Given — no prerequisite data is required"

echo "STEP: When — submit registration without an eventId"
cat > "$WHEN_BODY" <<EOF
{"name":"John Doe","email":"user.${CASE_SUFFIX}@example.com","phone":"+1234567890"}
EOF
echo "REQUEST_HEADERS: Content-Type: application/json"
echo "REQUEST_BODY: $(cat "$WHEN_BODY")"
when_status="$(curl -sS -D "$WHEN_HEADERS" -o "$WHEN_RESPONSE" -w '%{http_code}' -X POST "$BASE_URL/api/registrations" -H 'Content-Type: application/json' --data @"$WHEN_BODY")"
echo "RESPONSE_STATUS: $when_status"
echo "RESPONSE_HEADERS:"
cat "$WHEN_HEADERS"
echo "RESPONSE_BODY: $(cat "$WHEN_RESPONSE")"

echo "STEP: Then — assert validation error for missing eventId"
[ "$when_status" = "400" ] || { echo "ASSERTION_FAILED: expected HTTP 400 got ${when_status}"; exit 1; }
python3 - "$WHEN_RESPONSE" <<'PY'
import json, sys
body = json.load(open(sys.argv[1]))
assert body.get('message') == 'Event, name, email, and phone number are required.'
PY
[ $? -eq 0 ] || { echo "ASSERTION_FAILED: expected missing field validation message"; exit 1; }

echo "STEP: Cleanup — no cleanup required for stateless validation"
echo "CODEVALID_TEST_ASSERTION_OK:registration_missing_event_id"
