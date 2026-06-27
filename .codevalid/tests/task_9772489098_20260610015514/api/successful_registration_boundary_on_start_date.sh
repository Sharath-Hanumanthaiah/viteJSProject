#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
TODAY="$(date -u +%Y-%m-%d)"
TMP_DIR="$(mktemp -d)"
EVENT_RESPONSE="$TMP_DIR/create_event.json"
RESPONSE_FILE="$TMP_DIR/successful_registration_boundary_on_start_date.json"
STATUS_FILE="$TMP_DIR/successful_registration_boundary_on_start_date.status"
REG_LIST_FILE="$TMP_DIR/successful_registration_boundary_on_start_date_regs.json"
trap 'rm -rf "$TMP_DIR"' EXIT

NAME="Start Day User ${CASE_SUFFIX}"
EMAIL="startday+${CASE_SUFFIX}@example.com"
PHONE="+1-555-111-0000"
EVENT_TITLE="Start Boundary Event ${CASE_SUFFIX}"
EVENT_LOCATION="Lobby ${CASE_SUFFIX}"

plus_days() {
  python3 - "$1" "$2" <<'PY'
from datetime import date, timedelta
import sys
print((date.fromisoformat(sys.argv[1]) + timedelta(days=int(sys.argv[2]))).isoformat())
PY
}

START_DATE="$TODAY"
END_DATE="$(plus_days "$TODAY" 30)"

# Given — create an event whose start date is exactly today
CREATE_CODE="$(curl -sS -o "$EVENT_RESPONSE" -w '%{http_code}' -X POST "$BASE_URL/api/events" \
  -H 'Content-Type: application/json' \
  --data "{\"title\":\"${EVENT_TITLE}\",\"description\":\"Created by successful_registration_boundary_on_start_date\",\"startDate\":\"${START_DATE}\",\"endDate\":\"${END_DATE}\",\"location\":\"${EVENT_LOCATION}\"}")"
[ "$CREATE_CODE" = "201" ]
EVENT_ID="$(python3 - "$EVENT_RESPONSE" <<'PY'
import json, sys
with open(sys.argv[1], 'r', encoding='utf-8') as fh:
    print(json.load(fh).get('id', ''))
PY
)"
[ -n "$EVENT_ID" ]

# When — register on the exact start-date boundary
curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' -X POST "$BASE_URL/api/registrations" \
  -H 'Content-Type: application/json' \
  --data "{\"eventId\":\"${EVENT_ID}\",\"name\":\"${NAME}\",\"email\":\"${EMAIL}\",\"phone\":\"${PHONE}\"}" > "$STATUS_FILE"

# Then — assert registration succeeds and is retrievable
[ "$(cat "$STATUS_FILE")" = "201" ]
python3 - "$RESPONSE_FILE" "$EVENT_ID" "$NAME" "$EMAIL" "$PHONE" <<'PY'
import json, sys
with open(sys.argv[1], 'r', encoding='utf-8') as fh:
    body = json.load(fh)
assert body.get('eventId') == sys.argv[2], body
assert body.get('name') == sys.argv[3], body
assert body.get('email') == sys.argv[4], body
assert body.get('phone') == sys.argv[5], body
assert body.get('registeredAt'), body
PY

curl -sS "$BASE_URL/api/registrations/$EVENT_ID" > "$REG_LIST_FILE"
python3 - "$REG_LIST_FILE" "$EMAIL" <<'PY'
import json, sys
with open(sys.argv[1], 'r', encoding='utf-8') as fh:
    regs = json.load(fh)
assert any(r.get('email') == sys.argv[2] for r in regs), regs
PY

# Cleanup — no delete API exists for created event or registration data in this in-memory service

echo "CODEVALID_TEST_ASSERTION_OK:successful_registration_boundary_on_start_date"
