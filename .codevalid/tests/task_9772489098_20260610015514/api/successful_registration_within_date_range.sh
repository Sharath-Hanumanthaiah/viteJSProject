#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
TODAY="$(date -u +%Y-%m-%d)"
TMP_DIR="$(mktemp -d)"
EVENTS_FILE="$TMP_DIR/events.json"
CREATE_RESPONSE="$TMP_DIR/create_event.json"
RESPONSE_FILE="$TMP_DIR/successful_registration_within_date_range.json"
STATUS_FILE="$TMP_DIR/successful_registration_within_date_range.status"
REG_LIST_FILE="$TMP_DIR/successful_registration_within_date_range_regs.json"
trap 'rm -rf "$TMP_DIR"' EXIT

EMAIL="john.doe+${CASE_SUFFIX}@example.com"
PHONE="+1-555-123-4567"
NAME="John Doe ${CASE_SUFFIX}"
EVENT_TITLE="Within Range Event ${CASE_SUFFIX}"
EVENT_LOCATION="Room ${CASE_SUFFIX}"

next_day() {
  python3 - "$1" <<'PY'
from datetime import date, timedelta
import sys
print((date.fromisoformat(sys.argv[1]) + timedelta(days=1)).isoformat())
PY
}

previous_day() {
  python3 - "$1" <<'PY'
from datetime import date, timedelta
import sys
print((date.fromisoformat(sys.argv[1]) - timedelta(days=1)).isoformat())
PY
}

# Given — locate an event currently open for registration, or create one via public API
curl -sS "$BASE_URL/api/events" > "$EVENTS_FILE"
EVENT_ID="$(python3 - "$TODAY" "$EVENTS_FILE" <<'PY'
import json, sys

today = sys.argv[1]
with open(sys.argv[2], 'r', encoding='utf-8') as fh:
    events = json.load(fh)
for event in events:
    start = event.get('startDate')
    end = event.get('endDate')
    if start and end and start <= today <= end:
        print(event.get('id', ''))
        break
PY
)"

if [ -z "$EVENT_ID" ]; then
  START_DATE="$(previous_day "$TODAY")"
  END_DATE="$(next_day "$TODAY")"
  CREATE_CODE="$(curl -sS -o "$CREATE_RESPONSE" -w '%{http_code}' -X POST "$BASE_URL/api/events" \
    -H 'Content-Type: application/json' \
    --data "{\"title\":\"${EVENT_TITLE}\",\"description\":\"Created by successful_registration_within_date_range\",\"startDate\":\"${START_DATE}\",\"endDate\":\"${END_DATE}\",\"location\":\"${EVENT_LOCATION}\"}")"
  [ "$CREATE_CODE" = "201" ]
  EVENT_ID="$(python3 - "$CREATE_RESPONSE" <<'PY'
import json, sys
with open(sys.argv[1], 'r', encoding='utf-8') as fh:
    body = json.load(fh)
print(body.get('id', ''))
PY
)"
fi

[ -n "$EVENT_ID" ]

# When — submit a registration for the open event
curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' -X POST "$BASE_URL/api/registrations" \
  -H 'Content-Type: application/json' \
  --data "{\"eventId\":\"${EVENT_ID}\",\"name\":\"${NAME}\",\"email\":\"${EMAIL}\",\"phone\":\"${PHONE}\"}" > "$STATUS_FILE"

# Then — assert 201 response and persisted registration
STATUS="$(cat "$STATUS_FILE")"
[ "$STATUS" = "201" ]
python3 - "$RESPONSE_FILE" "$EVENT_ID" "$NAME" "$EMAIL" "$PHONE" <<'PY'
import json, re, sys
with open(sys.argv[1], 'r', encoding='utf-8') as fh:
    body = json.load(fh)
assert re.match(r'^reg[_-]', body.get('id', '')), body
assert body.get('eventId') == sys.argv[2], body
assert body.get('name') == sys.argv[3], body
assert body.get('email') == sys.argv[4], body
assert body.get('phone') == sys.argv[5], body
assert 'T' in body.get('registeredAt', ''), body
PY

curl -sS "$BASE_URL/api/registrations/$EVENT_ID" > "$REG_LIST_FILE"
python3 - "$REG_LIST_FILE" "$EMAIL" <<'PY'
import json, sys
with open(sys.argv[1], 'r', encoding='utf-8') as fh:
    regs = json.load(fh)
assert any(r.get('email') == sys.argv[2] for r in regs), regs
PY

# Cleanup — no delete API exists for registrations or events in this in-memory service

echo "CODEVALID_TEST_ASSERTION_OK:successful_registration_within_date_range"
