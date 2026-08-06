#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(python3 - <<'PY'
import uuid
print(uuid.uuid4().hex[:8])
PY
)"
TEST_ID="create_event_happy_path"
EVENT_TITLE="Tech Conference ${CASE_SUFFIX}"
START_DATE="2024-10-01T09:00:00Z"
END_DATE="2024-10-01T17:00:00Z"
REQUEST_BODY_FILE="/tmp/${TEST_ID}_request_${CASE_SUFFIX}.json"
RESPONSE_BODY_FILE="/tmp/${TEST_ID}_response_${CASE_SUFFIX}.json"
RESPONSE_HEADERS_FILE="/tmp/${TEST_ID}_headers_${CASE_SUFFIX}.txt"

# Given
echo "STEP: Given — prepare unique event payload"
echo "PREREQ: create request body for event creation"
cat > "$REQUEST_BODY_FILE" <<EOF
{
  "title": "$EVENT_TITLE",
  "description": "Annual tech meet-up",
  "location": "Convention Center",
  "startDate": "$START_DATE",
  "endDate": "$END_DATE"
}
EOF

# When
echo "STEP: When — POST /api/events with all required fields"
echo 'REQUEST_HEADERS: Content-Type: application/json'
echo "REQUEST_BODY:"
cat "$REQUEST_BODY_FILE"
when_status="$(curl -sS -D "$RESPONSE_HEADERS_FILE" -o "$RESPONSE_BODY_FILE" -w '%{http_code}' -X POST "$BASE_URL/api/events" -H 'Content-Type: application/json' --data @"$REQUEST_BODY_FILE")"
echo "RESPONSE_STATUS: $when_status"
echo "RESPONSE_HEADERS:"
cat "$RESPONSE_HEADERS_FILE"
echo "RESPONSE_BODY:"
cat "$RESPONSE_BODY_FILE"

# Then
echo "STEP: Then — assert 201 response and returned event fields"
[ "$when_status" = "201" ] || { echo "ASSERTION_FAILED: expected HTTP 201 got ${when_status}"; exit 1; }
python3 - "$RESPONSE_BODY_FILE" "$EVENT_TITLE" "$START_DATE" "$END_DATE" <<'PY'
import json, sys, re
path, expected_title, expected_start, expected_end = sys.argv[1:5]
with open(path, 'r', encoding='utf-8') as fh:
    data = json.load(fh)
assert isinstance(data.get('id'), str) and re.match(r'^event_', data['id']), 'id must start with event_'
assert data.get('title') == expected_title, f"expected title {expected_title!r} got {data.get('title')!r}"
assert data.get('description') == 'Annual tech meet-up', f"unexpected description {data.get('description')!r}"
assert data.get('location') == 'Convention Center', f"unexpected location {data.get('location')!r}"
assert data.get('startDate') == expected_start, f"unexpected startDate {data.get('startDate')!r}"
assert data.get('endDate') == expected_end, f"unexpected endDate {data.get('endDate')!r}"
assert data.get('registrationCount') == 0, f"unexpected registrationCount {data.get('registrationCount')!r}"
PY

echo "ASSERTION_OK: response JSON contains expected created event fields"

# Cleanup
echo "STEP: Cleanup — no API delete endpoint exists; no cleanup performed"

echo "CODEVALID_TEST_ASSERTION_OK:create_event_happy_path"
