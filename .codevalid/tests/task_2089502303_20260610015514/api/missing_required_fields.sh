#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(python3 - <<'PY'
import uuid
print(uuid.uuid4().hex[:8])
PY
)"
TEST_ID="missing_required_fields"
REQUEST_BODY_FILE="/tmp/${TEST_ID}_request_${CASE_SUFFIX}.json"
RESPONSE_BODY_FILE="/tmp/${TEST_ID}_response_${CASE_SUFFIX}.json"
RESPONSE_HEADERS_FILE="/tmp/${TEST_ID}_headers_${CASE_SUFFIX}.txt"

# Given
echo "STEP: Given — prepare invalid event payload missing location and endDate"
echo "PREREQ: create request body with missing required fields"
cat > "$REQUEST_BODY_FILE" <<EOF
{
  "title": "Incomplete Event ${CASE_SUFFIX}",
  "startDate": "2024-10-01T09:00:00Z"
}
EOF

# When
echo "STEP: When — POST /api/events with missing required fields"
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
echo "STEP: Then — assert 400 validation error for missing required fields"
[ "$when_status" = "400" ] || { echo "ASSERTION_FAILED: expected HTTP 400 got ${when_status}"; exit 1; }
python3 - "$RESPONSE_BODY_FILE" <<'PY'
import json, sys
with open(sys.argv[1], 'r', encoding='utf-8') as fh:
    data = json.load(fh)
assert data.get('message') == 'Title, start date, end date, and location are required.', data
PY

echo "ASSERTION_OK: validation message matched expected missing-fields error"

# Cleanup
echo "STEP: Cleanup — stateless negative case; no cleanup required"

echo "CODEVALID_TEST_ASSERTION_OK:missing_required_fields"
