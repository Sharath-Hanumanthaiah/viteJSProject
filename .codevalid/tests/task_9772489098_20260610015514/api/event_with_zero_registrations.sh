#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
EVENTS_FILE="/tmp/event_with_zero_registrations_events_${CASE_SUFFIX}.json"
REGS_FILE="/tmp/event_with_zero_registrations_regs_${CASE_SUFFIX}.json"

cleanup_tmp() {
  rm -f "$EVENTS_FILE" "$REGS_FILE"
}
trap cleanup_tmp EXIT

# Given — The service is reachable and fixture event evt-new exists without registrations.
curl -sS "$BASE_URL/health" >/dev/null

# When — Request the events collection and registrations for evt-new.
EVENTS_STATUS="$(curl -sS -o "$EVENTS_FILE" -w '%{http_code}' "$BASE_URL/api/events")"
REGS_STATUS="$(curl -sS -o "$REGS_FILE" -w '%{http_code}' "$BASE_URL/api/registrations/evt-new")"

# Then — The API returns 200, evt-new is present, and it has zero registrations.
[ "$EVENTS_STATUS" = "200" ]
[ "$REGS_STATUS" = "200" ]
grep -F '"id":"evt-new"' "$EVENTS_FILE" >/dev/null
grep -F '"registrationCount":0' "$EVENTS_FILE" >/dev/null
REGS_BODY="$(tr -d '\n\r\t ' < "$REGS_FILE")"
[ "$REGS_BODY" = "[]" ]

echo "CODEVALID_TEST_ASSERTION_OK:event_with_zero_registrations"
