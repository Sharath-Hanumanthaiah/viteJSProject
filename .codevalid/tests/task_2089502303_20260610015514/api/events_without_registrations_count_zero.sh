#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(python3 - <<'PY'
import uuid
print(uuid.uuid4().hex[:8])
PY
)"
WHEN_HEADERS_FILE="/tmp/events_without_registrations_count_zero_when_headers_${CASE_SUFFIX}.txt"
WHEN_BODY_FILE="/tmp/events_without_registrations_count_zero_when_body_${CASE_SUFFIX}.json"

echo "STEP: Given — rely on seeded in-memory event data"
echo "PREREQ: backend seeds event_2 with no registrations per repo learnings"

echo "STEP: When — retrieve the events list"
echo "REQUEST_HEADERS: Accept: application/json"
echo "REQUEST_BODY: <empty>"
when_status="$(curl -sS -D "$WHEN_HEADERS_FILE" -o "$WHEN_BODY_FILE" -w '%{http_code}' \
  "$BASE_URL/api/events" \
  -H 'Accept: application/json')"
echo "RESPONSE_STATUS: $when_status"
echo "RESPONSE_HEADERS:"
cat "$WHEN_HEADERS_FILE"
echo "RESPONSE_BODY:"
cat "$WHEN_BODY_FILE"

echo "STEP: Then — assert event_2 has registrationCount equal to 0"
[ "$when_status" = "200" ] || { echo "ASSERTION_FAILED: expected HTTP 200 got ${when_status}"; exit 1; }
python3 - "$WHEN_BODY_FILE" <<'PY'
import json, sys
with open(sys.argv[1], 'r', encoding='utf-8') as fh:
    data = json.load(fh)
match = next((item for item in data if item.get('id') == 'event_2'), None)
assert match is not None, 'event_2 not found'
assert match.get('registrationCount') == 0, f"expected registrationCount 0 got {match.get('registrationCount')}"
PY
if [ $? -ne 0 ]; then
  echo "ASSERTION_FAILED: event_2 did not have registrationCount 0"
  exit 1
fi

echo "STEP: Cleanup — stateless read-only test using seeded data"
echo "CODEVALID_TEST_ASSERTION_OK:events_without_registrations_count_zero"
