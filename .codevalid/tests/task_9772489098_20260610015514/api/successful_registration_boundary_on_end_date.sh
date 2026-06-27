#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
TODAY="$(date -u +%F)"
PAST_START_DATE="$(python3 - <<'PY'
from datetime import datetime, timedelta, timezone
now = datetime.now(timezone.utc).date()
print((now - timedelta(days=7)).isoformat())
PY
)"
ATTENDEE_EMAIL="endday-${CASE_SUFFIX}@example.com"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

EVENT_RESPONSE="$TMP_DIR/event.json"
EVENT_STATUS="$TMP_DIR/event.status"
REG_RESPONSE="$TMP_DIR/registration.json"
REG_STATUS="$TMP_DIR/registration.status"
LIST_RESPONSE="$TMP_DIR/registrations.json"
LIST_STATUS="$TMP_DIR/registrations.status"

# Given — create an event whose end date is exactly today
curl -sS -o "$EVENT_RESPONSE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/events" \
  -H 'Content-Type: application/json' \
  --data "{\"title\":\"End Boundary Event ${CASE_SUFFIX}\",\"description\":\"Boundary end scenario\",\"startDate\":\"${PAST_START_DATE}\",\"endDate\":\"${TODAY}\",\"location\":\"West Wing\"}" \
  > "$EVENT_STATUS"
[ "$(cat "$EVENT_STATUS")" = "201" ]
EVENT_ID_CREATED="$(python3 - <<'PY' "$EVENT_RESPONSE"
import json,sys
with open(sys.argv[1], 'r', encoding='utf-8') as fh:
    print(json.load(fh)['id'])
PY
)"

# When — register on the exact end-date boundary
curl -sS -o "$REG_RESPONSE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/registrations" \
  -H 'Content-Type: application/json' \
  --data "{\"eventId\":\"${EVENT_ID_CREATED}\",\"name\":\"End Day User\",\"email\":\"${ATTENDEE_EMAIL}\",\"phone\":\"+1-555-222-0000\"}" \
  > "$REG_STATUS"

# Then — HTTP/body assertions and persistence verification
[ "$(cat "$REG_STATUS")" = "201" ]
grep -F "\"eventId\":\"${EVENT_ID_CREATED}\"" "$REG_RESPONSE" >/dev/null
grep -F '"name":"End Day User"' "$REG_RESPONSE" >/dev/null
grep -F "\"email\":\"${ATTENDEE_EMAIL}\"" "$REG_RESPONSE" >/dev/null
grep -F '"phone":"+1-555-222-0000"' "$REG_RESPONSE" >/dev/null

curl -sS -o "$LIST_RESPONSE" -w '%{http_code}' \
  "$BASE_URL/api/registrations/${EVENT_ID_CREATED}" \
  > "$LIST_STATUS"
[ "$(cat "$LIST_STATUS")" = "200" ]
grep -F "\"email\":\"${ATTENDEE_EMAIL}\"" "$LIST_RESPONSE" >/dev/null

echo "CODEVALID_TEST_ASSERTION_OK:successful_registration_boundary_on_end_date"

# Cleanup — no delete endpoint or database exists; test data is isolated by unique suffix
