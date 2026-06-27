#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
TODAY="$(date -u +%F)"
DUPLICATE_EMAIL="existing-${CASE_SUFFIX}@example.com"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

EVENT_RESPONSE="$TMP_DIR/event.json"
EVENT_STATUS="$TMP_DIR/event.status"
FIRST_REG_RESPONSE="$TMP_DIR/first_registration.json"
FIRST_REG_STATUS="$TMP_DIR/first_registration.status"
DUP_RESPONSE_ONE="$TMP_DIR/duplicate_one.json"
DUP_STATUS_ONE="$TMP_DIR/duplicate_one.status"
DUP_RESPONSE_TWO="$TMP_DIR/duplicate_two.json"
DUP_STATUS_TWO="$TMP_DIR/duplicate_two.status"
LIST_RESPONSE="$TMP_DIR/registrations.json"
LIST_STATUS="$TMP_DIR/registrations.status"

# Given — create an event active today and seed one successful registration through the public API
curl -sS -o "$EVENT_RESPONSE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/events" \
  -H 'Content-Type: application/json' \
  --data "{\"title\":\"Duplicate Event ${CASE_SUFFIX}\",\"description\":\"Duplicate email scenario\",\"startDate\":\"${TODAY}\",\"endDate\":\"${TODAY}\",\"location\":\"Conference Room\"}" \
  > "$EVENT_STATUS"
[ "$(cat "$EVENT_STATUS")" = "201" ]
EVENT_ID_CREATED="$(python3 - <<'PY' "$EVENT_RESPONSE"
import json,sys
with open(sys.argv[1], 'r', encoding='utf-8') as fh:
    print(json.load(fh)['id'])
PY
)"

curl -sS -o "$FIRST_REG_RESPONSE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/registrations" \
  -H 'Content-Type: application/json' \
  --data "{\"eventId\":\"${EVENT_ID_CREATED}\",\"name\":\"Existing User\",\"email\":\"${DUPLICATE_EMAIL}\",\"phone\":\"+1-555-777-8888\"}" \
  > "$FIRST_REG_STATUS"
[ "$(cat "$FIRST_REG_STATUS")" = "201" ]

# When — attempt duplicate registrations with exact-case and different-case emails
curl -sS -o "$DUP_RESPONSE_ONE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/registrations" \
  -H 'Content-Type: application/json' \
  --data "{\"eventId\":\"${EVENT_ID_CREATED}\",\"name\":\"Existing User Again\",\"email\":\"${DUPLICATE_EMAIL}\",\"phone\":\"+1-555-999-0000\"}" \
  > "$DUP_STATUS_ONE"

UPPER_EMAIL="$(printf '%s' "$DUPLICATE_EMAIL" | tr '[:lower:]' '[:upper:]')"
curl -sS -o "$DUP_RESPONSE_TWO" -w '%{http_code}' \
  -X POST "$BASE_URL/api/registrations" \
  -H 'Content-Type: application/json' \
  --data "{\"eventId\":\"${EVENT_ID_CREATED}\",\"name\":\"Another User\",\"email\":\"${UPPER_EMAIL}\",\"phone\":\"+1-555-999-0000\"}" \
  > "$DUP_STATUS_TWO"

# Then — HTTP/body assertions and single-record verification
[ "$(cat "$DUP_STATUS_ONE")" = "400" ]
[ "$(cat "$DUP_STATUS_TWO")" = "400" ]
grep -F 'This email is already registered for this event.' "$DUP_RESPONSE_ONE" >/dev/null
grep -F 'This email is already registered for this event.' "$DUP_RESPONSE_TWO" >/dev/null

curl -sS -o "$LIST_RESPONSE" -w '%{http_code}' \
  "$BASE_URL/api/registrations/${EVENT_ID_CREATED}" \
  > "$LIST_STATUS"
[ "$(cat "$LIST_STATUS")" = "200" ]
REG_COUNT="$(python3 - <<'PY' "$LIST_RESPONSE" "$DUPLICATE_EMAIL"
import json,sys
with open(sys.argv[1], 'r', encoding='utf-8') as fh:
    rows = json.load(fh)
target = sys.argv[2].lower()
print(sum(1 for row in rows if row.get('email', '').lower() == target))
PY
)"
[ "$REG_COUNT" = "1" ]

echo "CODEVALID_TEST_ASSERTION_OK:registration_rejected_duplicate_email"

# Cleanup — no delete endpoint or database exists; test data is isolated by unique suffix
