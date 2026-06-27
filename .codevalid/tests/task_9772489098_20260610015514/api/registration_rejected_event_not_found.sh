#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
MISSING_EVENT_ID="evt-nonexistent-${CASE_SUFFIX}"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

REG_RESPONSE="$TMP_DIR/registration.json"
REG_STATUS="$TMP_DIR/registration.status"

# Given — choose an event id that does not exist in the in-memory store
: "${MISSING_EVENT_ID}"

# When — attempt registration for a non-existent event
curl -sS -o "$REG_RESPONSE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/registrations" \
  -H 'Content-Type: application/json' \
  --data "{\"eventId\":\"${MISSING_EVENT_ID}\",\"name\":\"Alice Brown\",\"email\":\"alice.brown-${CASE_SUFFIX}@example.com\",\"phone\":\"+1-555-333-4444\"}" \
  > "$REG_STATUS"

# Then — HTTP/body assertions
[ "$(cat "$REG_STATUS")" = "404" ]
grep -F 'Event not found.' "$REG_RESPONSE" >/dev/null

echo "CODEVALID_TEST_ASSERTION_OK:registration_rejected_event_not_found"

# Cleanup — stateless negative test; nothing to undo
