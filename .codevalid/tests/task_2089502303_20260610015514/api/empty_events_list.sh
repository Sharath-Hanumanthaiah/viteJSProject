#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(python3 - <<'PY'
import uuid
print(uuid.uuid4().hex[:8])
PY
)"
WHEN_HEADERS_FILE="/tmp/empty_events_list_when_headers_${CASE_SUFFIX}.txt"
WHEN_BODY_FILE="/tmp/empty_events_list_when_body_${CASE_SUFFIX}.json"

echo "STEP: Given — no events are created in this test"
echo "PREREQ: assert current repository behavior may include seeded events on startup"

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

echo "STEP: Then — assert the endpoint returns an empty array"
[ "$when_status" = "200" ] || { echo "ASSERTION_FAILED: expected HTTP 200 got ${when_status}"; exit 1; }
python3 - "$WHEN_BODY_FILE" <<'PY'
import json, sys
with open(sys.argv[1], 'r', encoding='utf-8') as fh:
    data = json.load(fh)
assert data == [], f'expected empty array got {data!r}'
PY
if [ $? -ne 0 ]; then
  echo "ASSERTION_FAILED: expected GET /api/events to return [] when no events exist"
  exit 1
fi

echo "STEP: Cleanup — stateless read-only request"
echo "CODEVALID_TEST_ASSERTION_OK:empty_events_list"
