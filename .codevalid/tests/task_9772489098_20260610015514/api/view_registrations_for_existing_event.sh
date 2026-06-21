#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
RESPONSE_FILE="/tmp/view_registrations_for_existing_event_${CASE_SUFFIX}.json"

cleanup() {
  rm -f "$RESPONSE_FILE"
}
trap cleanup EXIT

# Given — The seeded application data contains event evt-001 and registrations reg-101 and reg-102.
# No public API exists to create events or registrations for setup, so this test validates seeded state.

# When — Retrieve registrations for the existing event.
HTTP_STATUS="$(curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  "$BASE_URL/api/registrations/evt-001")"

# Then — Response is 200 and includes the expected registrations sorted by registeredAt descending.
[ "$HTTP_STATUS" = "200" ]
grep -F '"id":"reg-102"' "$RESPONSE_FILE" >/dev/null
grep -F '"id":"reg-101"' "$RESPONSE_FILE" >/dev/null
grep -F '"eventId":"evt-001"' "$RESPONSE_FILE" >/dev/null
POS_102="$(grep -ob '"id":"reg-102"' "$RESPONSE_FILE" | head -1 | cut -d: -f1)"
POS_101="$(grep -ob '"id":"reg-101"' "$RESPONSE_FILE" | head -1 | cut -d: -f1)"
[ -n "$POS_102" ]
[ -n "$POS_101" ]
[ "$POS_102" -lt "$POS_101" ]

echo "CODEVALID_TEST_ASSERTION_OK:view_registrations_for_existing_event"

# Cleanup — No server-side side effects were created; temporary response file is removed by trap.
