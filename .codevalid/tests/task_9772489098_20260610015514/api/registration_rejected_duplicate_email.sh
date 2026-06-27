#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
TODAY="$(date -u +%Y-%m-%d)"
TMP_DIR="$(mktemp -d)"
EVENT_RESPONSE="$TMP_DIR/create_event.json"
FIRST_RESPONSE="$TMP_DIR/first_registration.json"
DUP_RESPONSE_ONE="$TMP_DIR/duplicate_one.json"
DUP_RESPONSE_TWO="$TMP_DIR/duplicate_two.json"
FIRST_STATUS="$TMP_DIR/first_registration.status"
DUP_STATUS_ONE="$TMP_DIR/duplicate_one.status"
DUP_STATUS_TWO="$TMP_DIR/duplicate_two.status"
REG_LIST_FILE="$TMP_DIR/registration_rejected_duplicate_email_regs.json"
trap 'rm -rf "$TMP_DIR"' EXIT

EMAIL="existing+${CASE_SUFFIX}@example.com"
EMAIL_UPPER="$(printf '%s' "$EMAIL" | tr '[:lower:]' '[:upper:]')"
PHONE_ONE="+1-555-777-8888"
PHONE_TWO="+1-555-999-0000"
EVENT_TITLE="Duplicate Email Event ${CASE_SUFFIX}"
EVENT_LOCATION="Conference Room ${CASE_SUFFIX}"

plus_days() {
  python3 - "$1" "$2" <<'PY'
from datetime import date, timedelta
import sys
print((date.fromisoformat(sys.argv[1]) + timedelta(days=int(sys.argv[2]))).isoformat())
PY
}

START_DATE="$(plus_days "$TODAY" -1)"
END_DATE="$(plus_days "$TODAY" 1)"

# Given — create an active event and seed an initial registration via the public API
CREATE_CODE="$(curl -sS -o "$EVENT_RESPONSE" -w '%{http_code}' -X POST "$BASE_URL/api/events" \
  -H 'Content-Type: application/json' \
  --data "{\"title\":\"${EVENT_TITLE}\",\"description\":\"Created by registration_rejected_duplicate_email\",\"startDate\":\"${START_DATE}\",\"endDate\":\"${END_DATE}\",\"location\":\"${EVENT_LOCATION}\"}")"
[ "$CREATE_CODE" = "201" ]
EVENT_ID="$(python3 - "$EVENT_RESPONSE" <<'PY'
import json, sys
with open(sys.argv[1], 'r', encoding='utf-8') as fh:
    print(json.load(fh).get('id', ''))
PY
)"
[ -n "$EVENT_ID" ]

curl -sS -o "$FIRST_RESPONSE" -w '%{http_code}' -X POST "$BASE_URL/api/registrations" \
  -H 'Content-Type: application/json' \
  --data "{\"eventId\":\"${EVENT_ID}\",\"name\":\"Existing User ${CASE_SUFFIX}\",\"email\":\"${EMAIL}\",\"phone\":\"${PHONE_ONE}\"}" > "$FIRST_STATUS"
[ "$(cat "$FIRST_STATUS")" = "201" ]

# When — try to register the same email twice, including different case
curl -sS -o "$DUP_RESPONSE_ONE" -w '%{http_code}' -X POST "$BASE_URL/api/registrations" \
  -H 'Content-Type: application/json' \
  --data "{\"eventId\":\"${EVENT_ID}\",\"name\":\"Existing User ${CASE_SUFFIX}\",\"email\":\"${EMAIL}\",\"phone\":\"${PHONE_ONE}\"}" > "$DUP_STATUS_ONE"

curl -sS -o "$DUP_RESPONSE_TWO" -w '%{http_code}' -X POST "$BASE_URL/api/registrations" \
  -H 'Content-Type: application/json' \
  --data "{\"eventId\":\"${EVENT_ID}\",\"name\":\"Another User ${CASE_SUFFIX}\",\"email\":\"${EMAIL_UPPER}\",\"phone\":\"${PHONE_TWO}\"}" > "$DUP_STATUS_TWO"

# Then — both duplicates are rejected and only the seeded registration remains
[ "$(cat "$DUP_STATUS_ONE")" = "400" ]
[ "$(cat "$DUP_STATUS_TWO")" = "400" ]
python3 - "$DUP_RESPONSE_ONE" "$DUP_RESPONSE_TWO" <<'PY'
import json, sys
expected = 'This email is already registered for this event.'
for path in sys.argv[1:]:
    with open(path, 'r', encoding='utf-8') as fh:
        body = json.load(fh)
    assert body.get('message') == expected, body
PY

curl -sS "$BASE_URL/api/registrations/$EVENT_ID" > "$REG_LIST_FILE"
python3 - "$REG_LIST_FILE" "$EMAIL" <<'PY'
import json, sys
with open(sys.argv[1], 'r', encoding='utf-8') as fh:
    regs = json.load(fh)
matching = [r for r in regs if r.get('email', '').lower() == sys.argv[2].lower()]
assert len(matching) == 1, regs
PY

# Cleanup — no delete API exists for created event or registration data in this in-memory service

echo "CODEVALID_TEST_ASSERTION_OK:registration_rejected_duplicate_email"
