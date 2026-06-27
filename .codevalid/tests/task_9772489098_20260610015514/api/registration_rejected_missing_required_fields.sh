#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
TODAY="$(date -u +%F)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

EVENT_RESPONSE="$TMP_DIR/event.json"
EVENT_STATUS="$TMP_DIR/event.status"
RESP_ONE="$TMP_DIR/response_one.json"
STATUS_ONE="$TMP_DIR/status_one"
RESP_TWO="$TMP_DIR/response_two.json"
STATUS_TWO="$TMP_DIR/status_two"
LIST_RESPONSE="$TMP_DIR/registrations.json"
LIST_STATUS="$TMP_DIR/registrations.status"

# Given — create an event active today
curl -sS -o "$EVENT_RESPONSE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/events" \
  -H 'Content-Type: application/json' \
  --data "{\"title\":\"Required Fields Event ${CASE_SUFFIX}\",\"description\":\"Required fields scenario\",\"startDate\":\"${TODAY}\",\"endDate\":\"${TODAY}\",\"location\":\"Validation Room\"}" \
  > "$EVENT_STATUS"
[ "$(cat "$EVENT_STATUS")" = "201" ]
EVENT_ID_CREATED="$(python3 - <<'PY' "$EVENT_RESPONSE"
import json,sys
with open(sys.argv[1], 'r', encoding='utf-8') as fh:
    print(json.load(fh)['id'])
PY
)"

# When — send requests missing required fields
curl -sS -o "$RESP_ONE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/registrations" \
  -H 'Content-Type: application/json' \
  --data "{\"eventId\":\"${EVENT_ID_CREATED}\",\"name\":\"Test User\"}" \
  > "$STATUS_ONE"

curl -sS -o "$RESP_TWO" -w '%{http_code}' \
  -X POST "$BASE_URL/api/registrations" \
  -H 'Content-Type: application/json' \
  --data '{"name":"Test User","email":"test@example.com","phone":"+1-555-111-2222"}' \
  > "$STATUS_TWO"

# Then — HTTP/body assertions and non-persistence verification
[ "$(cat "$STATUS_ONE")" = "400" ]
[ "$(cat "$STATUS_TWO")" = "400" ]
grep -F 'Event, name, email, and phone number are required.' "$RESP_ONE" >/dev/null
grep -F 'Event, name, email, and phone number are required.' "$RESP_TWO" >/dev/null

curl -sS -o "$LIST_RESPONSE" -w '%{http_code}' \
  "$BASE_URL/api/registrations/${EVENT_ID_CREATED}" \
  > "$LIST_STATUS"
[ "$(cat "$LIST_STATUS")" = "200" ]
if grep -F 'test@example.com' "$LIST_RESPONSE" >/dev/null; then
  echo "missing-fields request should not create registration" >&2
  exit 1
fi

echo "CODEVALID_TEST_ASSERTION_OK:registration_rejected_missing_required_fields"

# Cleanup — no delete endpoint or database exists; test data is isolated by unique suffix
