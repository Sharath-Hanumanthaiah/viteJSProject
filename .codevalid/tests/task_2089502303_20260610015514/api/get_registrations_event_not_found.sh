#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$$"
TEST_ID="get_registrations_event_not_found"
EVENT_ID="event_missing_${CASE_SUFFIX}"
WHEN_HEADERS="/tmp/${TEST_ID}_when_headers_${CASE_SUFFIX}.txt"
WHEN_BODY="/tmp/${TEST_ID}_when_body_${CASE_SUFFIX}.json"

# Given
echo "STEP: Given — prepare a non-existent event id"
echo "PREREQ: using event id ${EVENT_ID} that is not present in seeded in-memory data"

# When
echo "STEP: When — request registrations for a non-existent event"
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
echo "STEP: Then — assert 404 and event not found message"
[ "$when_status" = "404" ] || { echo "ASSERTION_FAILED: expected HTTP 404 got ${when_status}"; exit 1; }
python3 - "$WHEN_BODY" <<'PY'
import json, sys
path = sys.argv[1]
with open(path, 'r', encoding='utf-8') as f:
    data = json.load(f)
assert data.get('message') == 'Event not found.', f"expected message 'Event not found.' got {data.get('message')!r}"
PY

# Cleanup
echo "STEP: Cleanup — no cleanup required for stateless lookup"

echo "CODEVALID_TEST_ASSERTION_OK:get_registrations_event_not_found"
