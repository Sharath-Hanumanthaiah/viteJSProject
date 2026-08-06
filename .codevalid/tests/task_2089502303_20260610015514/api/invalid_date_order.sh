#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(python3 - <<'PY'
import uuid
print(uuid.uuid4().hex[:8])
PY
)"
TEST_ID="invalid_date_order"
REQUEST_BODY_FILE="/tmp/${TEST_ID}_request_${CASE_SUFFIX}.json"
RESPONSE_BODY_FILE="/tmp/${TEST_ID}_response_${CASE_SUFFIX}.json"
RESPONSE_HEADERS_FILE="/tmp/${TEST_ID}_headers_${CASE_SUFFIX}.txt"

# Given
echo "STEP: Given — prepare invalid event payload with start date after end date"
echo "PREREQ: create request body with reversed date order"
cat > "$REQUEST_BODY_FILE" <<EOF
{
  "title": "Invalid Dates ${CASE_SUFFIX}",
  "description": "Test",
  "location": "Room A",
  "startDate": "2024-10-02T09:00:00Z",
  "endDate": "2024-10-01T17:00:00Z"
}
EOF

# When
echo "STEP: When — POST /api/events with invalid date order"
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
echo "STEP: Then — assert 400 validation error for invalid date order"
[ "$when_status" = "400" ] || { echo "ASSERTION_FAILED: expected HTTP 400 got ${when_status}"; exit 1; }
python3 - "$RESPONSE_BODY_FILE" <<'PY'
import json, sys
with open(sys.argv[1], 'r', encoding='utf-8') as fh:
    data = json.load(fh)
assert data.get('message') == 'Start date must be before or equal to the end date.', data
PY

echo "ASSERTION_OK: invalid date-order message matched expected response"

# Cleanup
echo "STEP: Cleanup — stateless negative case; no cleanup required"

echo "CODEVALID_TEST_ASSERTION_OK:invalid_date_order"
