#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
EMAIL="alice.brown.${CASE_SUFFIX}@example.com"
PHONE="+1-555-333-4444"
RESPONSE_FILE="/tmp/registration_rejected_event_not_found_${CASE_SUFFIX}.json"

cleanup() {
  rm -f "$RESPONSE_FILE"
}
trap cleanup EXIT

# Given — use a non-existent event id with otherwise valid registration data.
:

# When — submit the registration request.
HTTP_STATUS="$(curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/registrations" \
  -H 'Content-Type: application/json' \
  --data "{\"eventId\":\"evt-nonexistent\",\"name\":\"Alice Brown\",\"email\":\"${EMAIL}\",\"phone\":\"${PHONE}\"}")"

# Then — it returns 404 with the event-not-found message.
[ "$HTTP_STATUS" = "404" ]
grep -F 'Event not found.' "$RESPONSE_FILE" >/dev/null

echo "CODEVALID_TEST_ASSERTION_OK:registration_rejected_event_not_found"

# Cleanup — temp files are removed by trap.
