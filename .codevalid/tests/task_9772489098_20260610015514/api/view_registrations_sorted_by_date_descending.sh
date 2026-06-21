#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
RESPONSE_FILE="/tmp/view_registrations_sorted_by_date_descending_${CASE_SUFFIX}.json"

cleanup() {
  rm -f "$RESPONSE_FILE"
}
trap cleanup EXIT

# Given — The seeded application data contains event evt-003 with registrations reg-201, reg-202, and reg-203.
# No public API exists for setup mutation, so this test validates the seeded state returned by the API.

# When — Retrieve registrations for the event.
HTTP_STATUS="$(curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  "$BASE_URL/api/registrations/evt-003")"

# Then — Response is 200 and registrations are ordered reg-202, reg-203, reg-201.
[ "$HTTP_STATUS" = "200" ]
grep -F '"id":"reg-202"' "$RESPONSE_FILE" >/dev/null
grep -F '"id":"reg-203"' "$RESPONSE_FILE" >/dev/null
grep -F '"id":"reg-201"' "$RESPONSE_FILE" >/dev/null
POS_202="$(grep -ob '"id":"reg-202"' "$RESPONSE_FILE" | head -1 | cut -d: -f1)"
POS_203="$(grep -ob '"id":"reg-203"' "$RESPONSE_FILE" | head -1 | cut -d: -f1)"
POS_201="$(grep -ob '"id":"reg-201"' "$RESPONSE_FILE" | head -1 | cut -d: -f1)"
[ -n "$POS_202" ]
[ -n "$POS_203" ]
[ -n "$POS_201" ]
[ "$POS_202" -lt "$POS_203" ]
[ "$POS_203" -lt "$POS_201" ]

echo "CODEVALID_TEST_ASSERTION_OK:view_registrations_sorted_by_date_descending"

# Cleanup — No server-side side effects were created; temporary response file is removed by trap.
