#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
EVENTS_FILE="/tmp/create_event_with_minimal_required_data_events_${CASE_SUFFIX}.json"
RESPONSE_FILE="/tmp/create_event_with_minimal_required_data_response_${CASE_SUFFIX}.json"
VERIFY_FILE="/tmp/create_event_with_minimal_required_data_verify_${CASE_SUFFIX}.json"
EVENT_ID=""
ATTENDEE_NAME="minimal-registrant-${CASE_SUFFIX}"
ATTENDEE_EMAIL="minimal-registrant-${CASE_SUFFIX}@example.com"
ATTENDEE_PHONE="555-${CASE_SUFFIX}"
REGISTRATION_ID=""

cleanup() {
  rm -f "$EVENTS_FILE" "$RESPONSE_FILE" "$VERIFY_FILE"
}
trap cleanup EXIT

# Given — Find an event currently open for registration.
EVENTS_STATUS="$(curl -sS -o "$EVENTS_FILE" -w '%{http_code}' "$BASE_URL/api/events")"
[ "$EVENTS_STATUS" = "200" ]
TODAY="$(date -u +%Y-%m-%d)"
EVENT_ID="$(python3 - "$EVENTS_FILE" "$TODAY" <<'PY'
import json, sys
with open(sys.argv[1], 'r', encoding='utf-8') as fh:
    events = json.load(fh)
today = sys.argv[2]
for event in events:
    start = event.get('startDate')
    end = event.get('endDate')
    if start and end and start <= today <= end:
        print(event.get('id', ''))
        break
PY
)"
[ -n "$EVENT_ID" ]

# When — Register using only the required registration fields.
HTTP_STATUS="$(curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/registrations" \
  -H 'Content-Type: application/json' \
  --data "{\"eventId\":\"${EVENT_ID}\",\"name\":\"${ATTENDEE_NAME}\",\"email\":\"${ATTENDEE_EMAIL}\",\"phone\":\"${ATTENDEE_PHONE}\"}")"

# Then — The registration succeeds and is retrievable from the registrations list.
[ "$HTTP_STATUS" = "201" ]
grep -F '"eventId":"'"${EVENT_ID}"'"' "$RESPONSE_FILE" >/dev/null
grep -F '"name":"'"${ATTENDEE_NAME}"'"' "$RESPONSE_FILE" >/dev/null
grep -F '"email":"'"${ATTENDEE_EMAIL}"'"' "$RESPONSE_FILE" >/dev/null
REGISTRATION_ID="$(python3 - "$RESPONSE_FILE" <<'PY'
import json, sys
with open(sys.argv[1], 'r', encoding='utf-8') as fh:
    data = json.load(fh)
print(data.get('id', ''))
PY
)"
[ -n "$REGISTRATION_ID" ]
VERIFY_STATUS="$(curl -sS -o "$VERIFY_FILE" -w '%{http_code}' "$BASE_URL/api/registrations/${EVENT_ID}")"
[ "$VERIFY_STATUS" = "200" ]
grep -F '"id":"'"${REGISTRATION_ID}"'"' "$VERIFY_FILE" >/dev/null

echo "CODEVALID_TEST_ASSERTION_OK:create_event_with_minimal_required_data"

# Cleanup — No delete endpoint exists for registrations; temp files are removed only.
