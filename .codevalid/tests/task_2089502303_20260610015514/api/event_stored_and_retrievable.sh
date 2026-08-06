#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(python3 - <<'PY'
import uuid
print(uuid.uuid4().hex[:8])
PY
)"
TEST_ID="event_stored_and_retrievable"
EVENT_TITLE="Stored Event ${CASE_SUFFIX}"
START_DATE="2024-09-20T09:00:00Z"
END_DATE="2024-09-20T17:00:00Z"
CREATE_REQUEST_BODY_FILE="/tmp/${TEST_ID}_create_request_${CASE_SUFFIX}.json"
CREATE_RESPONSE_BODY_FILE="/tmp/${TEST_ID}_create_response_${CASE_SUFFIX}.json"
CREATE_RESPONSE_HEADERS_FILE="/tmp/${TEST_ID}_create_headers_${CASE_SUFFIX}.txt"
LIST_RESPONSE_BODY_FILE="/tmp/${TEST_ID}_list_response_${CASE_SUFFIX}.json"
LIST_RESPONSE_HEADERS_FILE="/tmp/${TEST_ID}_list_headers_${CASE_SUFFIX}.txt"

# Given
echo "STEP: Given — create a unique event to later retrieve from the events list"
echo "PREREQ: create request body for new event"
cat > "$CREATE_REQUEST_BODY_FILE" <<EOF
{
  "title": "$EVENT_TITLE",
  "description": "Stored event retrieval verification",
  "location": "Auditorium ${CASE_SUFFIX}",
  "startDate": "$START_DATE",
  "endDate": "$END_DATE"
}
EOF
echo 'REQUEST_HEADERS: Content-Type: application/json'
echo "REQUEST_BODY:"
cat "$CREATE_REQUEST_BODY_FILE"
given_status="$(curl -sS -D "$CREATE_RESPONSE_HEADERS_FILE" -o "$CREATE_RESPONSE_BODY_FILE" -w '%{http_code}' -X POST "$BASE_URL/api/events" -H 'Content-Type: application/json' --data @"$CREATE_REQUEST_BODY_FILE")"
echo "RESPONSE_STATUS: $given_status"
echo "RESPONSE_HEADERS:"
cat "$CREATE_RESPONSE_HEADERS_FILE"
echo "RESPONSE_BODY:"
cat "$CREATE_RESPONSE_BODY_FILE"
[ "$given_status" = "201" ] || { echo "ASSERTION_FAILED: expected Given event creation HTTP 201 got ${given_status}"; exit 1; }
CREATED_EVENT_ID="$(python3 - "$CREATE_RESPONSE_BODY_FILE" <<'PY'
import json, sys
with open(sys.argv[1], 'r', encoding='utf-8') as fh:
    data = json.load(fh)
print(data['id'])
PY
)"
[ -n "$CREATED_EVENT_ID" ] || { echo "ASSERTION_FAILED: expected created event id to be present"; exit 1; }

# When
echo "STEP: When — GET /api/events to retrieve stored events"
echo 'REQUEST_HEADERS: Accept: application/json'
echo 'REQUEST_BODY: <empty>'
when_status="$(curl -sS -D "$LIST_RESPONSE_HEADERS_FILE" -o "$LIST_RESPONSE_BODY_FILE" -w '%{http_code}' "$BASE_URL/api/events")"
echo "RESPONSE_STATUS: $when_status"
echo "RESPONSE_HEADERS:"
cat "$LIST_RESPONSE_HEADERS_FILE"
echo "RESPONSE_BODY:"
cat "$LIST_RESPONSE_BODY_FILE"

# Then
echo "STEP: Then — assert the created event appears in the retrieved list with matching fields"
[ "$when_status" = "200" ] || { echo "ASSERTION_FAILED: expected HTTP 200 got ${when_status}"; exit 1; }
python3 - "$LIST_RESPONSE_BODY_FILE" "$CREATED_EVENT_ID" "$EVENT_TITLE" "$START_DATE" "$END_DATE" "$CASE_SUFFIX" <<'PY'
import json, sys
path, event_id, expected_title, expected_start, expected_end, suffix = sys.argv[1:7]
with open(path, 'r', encoding='utf-8') as fh:
    data = json.load(fh)
assert isinstance(data, list), 'events response must be a list'
match = None
for item in data:
    if item.get('id') == event_id:
        match = item
        break
assert match is not None, f'event {event_id} not found in events list'
assert match.get('title') == expected_title, match
assert match.get('description') == 'Stored event retrieval verification', match
assert match.get('location') == f'Auditorium {suffix}', match
assert match.get('startDate') == expected_start, match
assert match.get('endDate') == expected_end, match
assert match.get('registrationCount') == 0, match
PY

echo "ASSERTION_OK: created event was retrievable from GET /api/events with matching fields"

# Cleanup
echo "STEP: Cleanup — no API delete endpoint exists; no cleanup performed"

echo "CODEVALID_TEST_ASSERTION_OK:event_stored_and_retrievable"
