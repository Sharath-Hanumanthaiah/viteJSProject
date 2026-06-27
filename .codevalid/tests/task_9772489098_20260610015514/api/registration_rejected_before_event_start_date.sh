#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
TODAY="$(date -u +%Y-%m-%d)"
TMP_DIR="$(mktemp -d)"
EVENT_RESPONSE="$TMP_DIR/create_event.json"
RESPONSE_FILE="$TMP_DIR/registration_rejected_before_event_start_date.json"
STATUS_FILE="$TMP_DIR/registration_rejected_before_event_start_date.status"
REG_LIST_FILE="$TMP_DIR/registration_rejected_before_event_start_date_regs.json"
trap 'rm -rf "$TMP_DIR"' EXIT

EMAIL="jane.smith+${CASE_SUFFIX}@example.com"
PHONE="+1-555-987-6543"
NAME="Jane Smith ${CASE_SUFFIX}"
EVENT_TITLE="Future Event ${CASE_SUFFIX}"
EVENT_LOCATION="Hall ${CASE_SUFFIX}"

plus_days() {
  python3 - "$1" "$2" <<'PY'
from datetime import date, timedelta
import sys
print((date.fromisoformat(sys.argv[1]) + timedelta(days=int(sys.argv[2]))).isoformat())
PY
}

START_DATE="$(plus_days "$TODAY" 7)"
END_DATE="$(plus_days "$TODAY" 14)"

# Given — create an event whose start date is in the future
CREATE_CODE="$(curl -sS -o "$EVENT_RESPONSE" -w '%{http_code}' -X POST "$BASE_URL/api/events" \
  -H 'Content-Type: application/json' \
  --data "{\"title\":\"${EVENT_TITLE}\",\"description\":\"Created by registration_rejected_before_event_start_date\",\"startDate\":\"${START_DATE}\",\"endDate\":\"${END_DATE}\",\"location\":\"${EVENT_LOCATION}\"}")"
[ "$CREATE_CODE" = "201" ]
EVENT_ID="$(python3 - "$EVENT_RESPONSE" <<'PY'
import json, sys
with open(sys.argv[1], 'r', encoding='utf-8') as fh:
    print(json.load(fh).get('id', ''))
PY
)"
[ -n "$EVENT_ID" ]

# When — attempt registration before the event start date
curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' -X POST "$BASE_URL/api/registrations" \
  -H 'Content-Type: application/json' \
  --data "{\"eventId\":\"${EVENT_ID}\",\"name\":\"${NAME}\",\"email\":\"${EMAIL}\",\"phone\":\"${PHONE}\"}" > "$STATUS_FILE"

# Then — assert rejection message and no persisted registration
STATUS="$(cat "$STATUS_FILE")"
[ "$STATUS" = "400" ]
python3 - "$RESPONSE_FILE" "$START_DATE" <<'PY'
import json, sys
with open(sys.argv[1], 'r', encoding='utf-8') as fh:
    body = json.load(fh)
expected = f"Registration has not opened yet. Registration opens on {sys.argv[2]}."
assert body.get('message') == expected, body
PY

curl -sS "$BASE_URL/api/registrations/$EVENT_ID" > "$REG_LIST_FILE"
python3 - "$REG_LIST_FILE" "$EMAIL" <<'PY'
import json, sys
with open(sys.argv[1], 'r', encoding='utf-8') as fh:
    regs = json.load(fh)
assert all(r.get('email') != sys.argv[2] for r in regs), regs
PY

# Cleanup — no delete API exists for created event data in this in-memory service

echo "CODEVALID_TEST_ASSERTION_OK:registration_rejected_before_event_start_date"
