#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
EVENTS_FILE="/tmp/reject_event_with_end_date_before_start_date_events_${CASE_SUFFIX}.json"
RESPONSE_FILE="/tmp/reject_event_with_end_date_before_start_date_response_${CASE_SUFFIX}.json"
VERIFY_FILE="/tmp/reject_event_with_end_date_before_start_date_verify_${CASE_SUFFIX}.json"
EVENT_ID=""
ATTENDEE_EMAIL="closed-event-${CASE_SUFFIX}@example.com"

cleanup() {
  rm -f "$EVENTS_FILE" "$RESPONSE_FILE" "$VERIFY_FILE"
}
trap cleanup EXIT

# Given — Find an event whose end date is before today.
EVENTS_STATUS="$(curl -sS -o "$EVENTS_FILE" -w '%{http_code}' "$BASE_URL/api/events")"
[ "$EVENTS_STATUS" = "200" ]
TODAY="$(date -u +%Y-%m-%d)"
EVENT_ID="$(python3 - "$EVENTS_FILE" "$TODAY" <<'PY'
import json, sys
with open(sys.argv[1], 'r', encoding='utf-8') as fh:
    events = json.load(fh)
today = sys.argv[2]
for event in events:
    end = event.get('endDate')
    if end and today > end:
        print(event.get('id', ''))
        break
PY
)"
[ -n "$EVENT_ID" ]

# When — Attempt to register after the event date range has closed.
HTTP_STATUS="$(curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/registrations" \
  -H 'Content-Type: application/json' \
  --data "{\"eventId\":\"${EVENT_ID}\",\"name\":\"closed-registrant-${CASE_SUFFIX}\",\"email\":\"${ATTENDEE_EMAIL}\",\"phone\":\"555-${CASE_SUFFIX}\"}")"

# Then — The API rejects the request and no registration is recorded for that email.
[ "$HTTP_STATUS" = "400" ]
grep -F 'Registration is closed.' "$RESPONSE_FILE" >/dev/null
VERIFY_STATUS="$(curl -sS -o "$VERIFY_FILE" -w '%{http_code}' "$BASE_URL/api/registrations/${EVENT_ID}")"
[ "$VERIFY_STATUS" = "200" ]
if grep -F '"email":"'"${ATTENDEE_EMAIL}"'"' "$VERIFY_FILE" >/dev/null; then
  echo "registration should not have been recorded" >&2
  exit 1
fi

echo "CODEVALID_TEST_ASSERTION_OK:reject_event_with_end_date_before_start_date"

# Cleanup — No server-side state is created on rejection.
