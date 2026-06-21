#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
EMAIL="startday.${CASE_SUFFIX}@example.com"
PHONE="+1-555-111-0000"
EVENT_ID="evt-400"
RESPONSE_FILE="/tmp/successful_registration_boundary_on_start_date_${CASE_SUFFIX}.json"
REGISTRATIONS_FILE="/tmp/successful_registration_boundary_on_start_date_regs_${CASE_SUFFIX}.json"

cleanup() {
  rm -f "$RESPONSE_FILE" "$REGISTRATIONS_FILE"
}
trap cleanup EXIT

# Given — use unique registration data for the boundary event.
:

# When — submit the registration request.
HTTP_STATUS="$(curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/registrations" \
  -H 'Content-Type: application/json' \
  --data "{\"eventId\":\"${EVENT_ID}\",\"name\":\"Start Day User\",\"email\":\"${EMAIL}\",\"phone\":\"${PHONE}\"}")"

# Then — it returns 201 and the registration is listed for the event.
[ "$HTTP_STATUS" = "201" ]
grep -F '"id":"reg-' "$RESPONSE_FILE" >/dev/null
grep -F "\"eventId\":\"${EVENT_ID}\"" "$RESPONSE_FILE" >/dev/null
grep -F '"name":"Start Day User"' "$RESPONSE_FILE" >/dev/null
grep -F "\"email\":\"${EMAIL}\"" "$RESPONSE_FILE" >/dev/null
grep -F "\"phone\":\"${PHONE}\"" "$RESPONSE_FILE" >/dev/null

REG_LIST_STATUS="$(curl -sS -o "$REGISTRATIONS_FILE" -w '%{http_code}' "$BASE_URL/api/registrations/${EVENT_ID}")"
[ "$REG_LIST_STATUS" = "200" ]
grep -F "\"email\":\"${EMAIL}\"" "$REGISTRATIONS_FILE" >/dev/null

echo "CODEVALID_TEST_ASSERTION_OK:successful_registration_boundary_on_start_date"

# Cleanup — no delete endpoint exists; temp files are removed by trap.
