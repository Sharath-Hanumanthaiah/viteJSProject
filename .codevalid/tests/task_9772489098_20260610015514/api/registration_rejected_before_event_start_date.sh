#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
EMAIL="jane.smith.${CASE_SUFFIX}@example.com"
PHONE="+1-555-987-6543"
EVENT_ID="evt-200"
RESPONSE_FILE="/tmp/registration_rejected_before_event_start_date_${CASE_SUFFIX}.json"
REGISTRATIONS_FILE="/tmp/registration_rejected_before_event_start_date_regs_${CASE_SUFFIX}.json"

cleanup() {
  rm -f "$RESPONSE_FILE" "$REGISTRATIONS_FILE"
}
trap cleanup EXIT

# Given — use a unique email so the request is not rejected as a duplicate.
:

# When — attempt to register before the event start date.
HTTP_STATUS="$(curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/registrations" \
  -H 'Content-Type: application/json' \
  --data "{\"eventId\":\"${EVENT_ID}\",\"name\":\"Jane Smith\",\"email\":\"${EMAIL}\",\"phone\":\"${PHONE}\"}")"

# Then — response is 400 with the not-open-yet message and no registration is recorded.
[ "$HTTP_STATUS" = "400" ]
grep -F 'Registration has not opened yet. Registration opens on' "$RESPONSE_FILE" >/dev/null

REG_LIST_STATUS="$(curl -sS -o "$REGISTRATIONS_FILE" -w '%{http_code}' "$BASE_URL/api/registrations/${EVENT_ID}")"
if [ "$REG_LIST_STATUS" = "200" ]; then
  if grep -F "\"email\":\"${EMAIL}\"" "$REGISTRATIONS_FILE" >/dev/null; then
    exit 1
  fi
fi

echo "CODEVALID_TEST_ASSERTION_OK:registration_rejected_before_event_start_date"

# Cleanup — no delete endpoint exists; temp files are removed by trap.
