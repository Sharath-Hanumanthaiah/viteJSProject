#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
PAST_START_DATE="$(python3 - <<'PY'
from datetime import datetime, timedelta, timezone
now = datetime.now(timezone.utc).date()
print((now - timedelta(days=20)).isoformat())
PY
)"
PAST_END_DATE="$(python3 - <<'PY'
from datetime import datetime, timedelta, timezone
now = datetime.now(timezone.utc).date()
print((now - timedelta(days=10)).isoformat())
PY
)"
ATTENDEE_EMAIL="bob.wilson-${CASE_SUFFIX}@example.com"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

EVENT_RESPONSE="$TMP_DIR/event.json"
EVENT_STATUS="$TMP_DIR/event.status"
REG_RESPONSE="$TMP_DIR/registration.json"
REG_STATUS="$TMP_DIR/registration.status"
LIST_RESPONSE="$TMP_DIR/registrations.json"
LIST_STATUS="$TMP_DIR/registrations.status"

# Given — create an event that already ended before today
curl -sS -o "$EVENT_RESPONSE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/events" \
  -H 'Content-Type: application/json' \
  --data "{\"title\":\"Past Event ${CASE_SUFFIX}\",\"description\":\"Past registration scenario\",\"startDate\":\"${PAST_START_DATE}\",\"endDate\":\"${PAST_END_DATE}\",\"location\":\"South Hall\"}" \
  > "$EVENT_STATUS"
[ "$(cat "$EVENT_STATUS")" = "201" ]
EVENT_ID_CREATED="$(python3 - <<'PY' "$EVENT_RESPONSE"
import json,sys
with open(sys.argv[1], 'r', encoding='utf-8') as fh:
    print(json.load(fh)['id'])
PY
)"

# When — attempt registration after the event end date
curl -sS -o "$REG_RESPONSE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/registrations" \
  -H 'Content-Type: application/json' \
  --data "{\"eventId\":\"${EVENT_ID_CREATED}\",\"name\":\"Bob Wilson\",\"email\":\"${ATTENDEE_EMAIL}\",\"phone\":\"+1-555-456-7890\"}" \
  > "$REG_STATUS"

# Then — HTTP/body assertions and non-persistence verification
[ "$(cat "$REG_STATUS")" = "400" ]
grep -F "Registration is closed. The event ended on ${PAST_END_DATE}." "$REG_RESPONSE" >/dev/null

curl -sS -o "$LIST_RESPONSE" -w '%{http_code}' \
  "$BASE_URL/api/registrations/${EVENT_ID_CREATED}" \
  > "$LIST_STATUS"
[ "$(cat "$LIST_STATUS")" = "200" ]
if grep -F "${ATTENDEE_EMAIL}" "$LIST_RESPONSE" >/dev/null; then
  echo "registration should not have been recorded" >&2
  exit 1
fi

echo "CODEVALID_TEST_ASSERTION_OK:registration_rejected_after_event_end_date"

# Cleanup — no delete endpoint or database exists; test data is isolated by unique suffix
