#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$$"
TEST_ID="get_registrations_multiple_sorted_by_date"
WHEN_HEADERS="/tmp/${TEST_ID}_when_headers_${CASE_SUFFIX}.txt"
WHEN_BODY="/tmp/${TEST_ID}_when_body_${CASE_SUFFIX}.json"

# Given
echo "STEP: Given — use seeded event_1 with multiple seeded registrations"
echo "PREREQ: event_1 exists in seeded store and has reg_1 and reg_2 with different registeredAt timestamps"

# When
echo "STEP: When — retrieve registrations for seeded event_1"
echo "REQUEST_HEADERS: Accept: application/json"
echo "REQUEST_BODY: <empty>"
when_status="$(curl -sS -D "$WHEN_HEADERS" -o "$WHEN_BODY" -w '%{http_code}' \
  -H 'Accept: application/json' \
  "$BASE_URL/api/registrations/event_1")"
echo "RESPONSE_STATUS: ${when_status}"
echo "RESPONSE_HEADERS:"
cat "$WHEN_HEADERS"
echo "RESPONSE_BODY:"
cat "$WHEN_BODY"

# Then
echo "STEP: Then — assert registrations are sorted by registeredAt descending"
[ "$when_status" = "200" ] || { echo "ASSERTION_FAILED: expected HTTP 200 got ${when_status}"; exit 1; }
python3 - "$WHEN_BODY" <<'PY'
import json, sys
from datetime import datetime
with open(sys.argv[1], 'r', encoding='utf-8') as f:
    data = json.load(f)
assert isinstance(data, list), f'expected list got {type(data).__name__}'
assert len(data) >= 2, f'expected at least 2 registrations got {len(data)}'
for item in data:
    assert item['eventId'] == 'event_1', f"unexpected eventId {item['eventId']!r}"
registered = [datetime.fromisoformat(item['registeredAt'].replace('Z', '+00:00')) for item in data]
assert all(a >= b for a, b in zip(registered, registered[1:])), 'registrations are not sorted newest-first'
assert data[0]['id'] == 'reg_2', f"expected newest registration reg_2 first got {data[0]['id']!r}"
assert data[1]['id'] == 'reg_1', f"expected second registration reg_1 got {data[1]['id']!r}"
PY

# Cleanup
echo "STEP: Cleanup — no cleanup required for read-only seeded data"

echo "CODEVALID_TEST_ASSERTION_OK:get_registrations_multiple_sorted_by_date"
