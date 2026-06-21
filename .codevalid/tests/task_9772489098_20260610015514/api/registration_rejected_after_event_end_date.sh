#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
EMAIL="bob.wilson.${CASE_SUFFIX}@example.com"
PHONE="+1-555-456-7890"
EVENT_ID="evt-300"
RESPONSE_FILE="/tmp/registration_rejected_after_event_end_date_${CASE_SUFFIX}.json"
REGISTRATIONS_FILE="/tmp/registration_rejected_after_event_end_date_regs_${CASE_SUFFIX}.json"

cleanup() {
  rm -f "$RESPONSE_FILE" "$REGISTRATIONS_FILE"
}
trap cleanup EXIT

# Given — use a unique email so the request is not rejected as a duplicate.
:

# When — attempt to register after the event end date.
HTTP_STATUS="$(curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/registrations" \
  -H 'Content-Type: application/json' \
  --data "{\"eventId\":\"${EVENT_ID}\",\"name\":\"Bob Wilson\",\"email\":\"${EMAIL}\",\"phone\":\"${PHONE}\"}")"

# Then — response is 400 with the closed message and no registration is recorded.
[ "$HTTP_STATUS" = "400" ]
grep -F 'Registration is closed. The event ended on' "$RESPONSE_FILE" >/dev/null

REG_LIST_STATUS="$(curl -sS -o "$REGISTRATIONS_FILE" -w '%{http_code}' "$BASE_URL/api/registrations/${EVENT_ID}")"
if [ "$REG_LIST_STATUS" = "200" ]; then
  if grep -F "\"email\":\"${EMAIL}\"" "$REGISTRATIONS_FILE" >/dev/null; then
    exit 1
  fi
fi

echo "CODEVALID_TEST_ASSERTION_OK:registration_rejected_after_event_end_date"

# Cleanup — no delete endpoint exists; temp files are removed by trap.
