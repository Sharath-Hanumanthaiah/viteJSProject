#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
TODAY="$(date -u +%Y-%m-%d)"
TMP_DIR="$(mktemp -d)"
EVENT_RESPONSE="$TMP_DIR/create_event.json"
RESPONSE_ONE="$TMP_DIR/missing_fields_one.json"
RESPONSE_TWO="$TMP_DIR/missing_fields_two.json"
STATUS_ONE="$TMP_DIR/missing_fields_one.status"
STATUS_TWO="$TMP_DIR/missing_fields_two.status"
REG_LIST_FILE="$TMP_DIR/registration_rejected_missing_required_fields_regs.json"
trap 'rm -rf "$TMP_DIR"' EXIT

EVENT_TITLE="Missing Fields Event ${CASE_SUFFIX}"
EVENT_LOCATION="Auditorium ${CASE_SUFFIX}"
EMAIL_UNUSED="test.user+${CASE_SUFFIX}@example.com"

plus_days() {
  python3 - "$1" "$2" <<'PY'
from datetime import date, timedelta
import sys
print((date.fromisoformat(sys.argv[1]) + timedelta(days=int(sys.argv[2]))).isoformat())
PY
}

START_DATE="$(plus_days "$TODAY" -1)"
END_DATE="$(plus_days "$TODAY" 1)"

# Given — create an event that is active today
CREATE_CODE="$(curl -sS -o "$EVENT_RESPONSE" -w '%{http_code}' -X POST "$BASE_URL/api/events" \
  -H 'Content-Type: application/json' \
  --data "{\"title\":\"${EVENT_TITLE}\",\"description\":\"Created by registration_rejected_missing_required_fields\",\"startDate\":\"${START_DATE}\",\"endDate\":\"${END_DATE}\",\"location\":\"${EVENT_LOCATION}\"}")"
[ "$CREATE_CODE" = "201" ]
EVENT_ID="$(python3 - "$EVENT_RESPONSE" <<'PY'
import json, sys
with open(sys.argv[1], 'r', encoding='utf-8') as fh:
    print(json.load(fh).get('id', ''))
PY
)"
[ -n "$EVENT_ID" ]

# When — submit two invalid registration payloads missing required fields
curl -sS -o "$RESPONSE_ONE" -w '%{http_code}' -X POST "$BASE_URL/api/registrations" \
  -H 'Content-Type: application/json' \
  --data "{\"eventId\":\"${EVENT_ID}\",\"name\":\"Test User ${CASE_SUFFIX}\"}" > "$STATUS_ONE"

curl -sS -o "$RESPONSE_TWO" -w '%{http_code}' -X POST "$BASE_URL/api/registrations" \
  -H 'Content-Type: application/json' \
  --data "{\"name\":\"Test User ${CASE_SUFFIX}\",\"email\":\"${EMAIL_UNUSED}\",\"phone\":\"+1-555-111-2222\"}" > "$STATUS_TWO"

# Then — both requests return the shared validation message and no registration exists for the event
[ "$(cat "$STATUS_ONE")" = "400" ]
[ "$(cat "$STATUS_TWO")" = "400" ]
python3 - "$RESPONSE_ONE" "$RESPONSE_TWO" <<'PY'
import json, sys
expected = 'Event, name, email, and phone number are required.'
for path in sys.argv[1:]:
    with open(path, 'r', encoding='utf-8') as fh:
        body = json.load(fh)
    assert body.get('message') == expected, body
PY

curl -sS "$BASE_URL/api/registrations/$EVENT_ID" > "$REG_LIST_FILE"
python3 - "$REG_LIST_FILE" <<'PY'
import json, sys
with open(sys.argv[1], 'r', encoding='utf-8') as fh:
    regs = json.load(fh)
assert regs == [], regs
PY

# Cleanup — no delete API exists for created event data in this in-memory service

echo "CODEVALID_TEST_ASSERTION_OK:registration_rejected_missing_required_fields"
