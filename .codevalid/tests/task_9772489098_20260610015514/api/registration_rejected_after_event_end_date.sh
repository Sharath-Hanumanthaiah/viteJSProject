#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
EVENT_ID="evt-300"
EMAIL="bob.wilson+${CASE_SUFFIX}@example.com"
NAME="Bob Wilson"
PHONE="+1-555-456-7890"
EVENTS_FILE="/tmp/registration_rejected_after_event_end_date_events_${CASE_SUFFIX}.json"
RESPONSE_FILE="/tmp/registration_rejected_after_event_end_date_response_${CASE_SUFFIX}.json"
REGISTRATIONS_FILE="/tmp/registration_rejected_after_event_end_date_registrations_${CASE_SUFFIX}.json"

cleanup_files() {
  rm -f "$EVENTS_FILE" "$RESPONSE_FILE" "$REGISTRATIONS_FILE"
}
trap cleanup_files EXIT

# Given — verify the expected seeded past event exists.
EVENTS_STATUS="$(curl -sS -o "$EVENTS_FILE" -w '%{http_code}' "$BASE_URL/api/events")"
[ "$EVENTS_STATUS" = "200" ]
grep -F '"id":"evt-300"' "$EVENTS_FILE" >/dev/null

# When — attempt registration after the event has closed.
HTTP_STATUS="$(curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/registrations" \
  -H 'Content-Type: application/json' \
  --data "{\"eventId\":\"${EVENT_ID}\",\"name\":\"${NAME}\",\"email\":\"${EMAIL}\",\"phone\":\"${PHONE}\"}")"

# Then — assert 400, expected message, and no persisted registration for this email.
[ "$HTTP_STATUS" = "400" ]
grep -F 'Registration is closed. The event ended on ' "$RESPONSE_FILE" >/dev/null

REG_STATUS="$(curl -sS -o "$REGISTRATIONS_FILE" -w '%{http_code}' "$BASE_URL/api/registrations/${EVENT_ID}")"
[ "$REG_STATUS" = "200" ]
if grep -F "\"email\":\"${EMAIL}\"" "$REGISTRATIONS_FILE" >/dev/null; then
  echo "unexpected persisted registration for ${EMAIL}" >&2
  exit 1
fi

echo "CODEVALID_TEST_ASSERTION_OK:registration_rejected_after_event_end_date"

# Cleanup — rejection should be side-effect free; temp files are removed by trap.
