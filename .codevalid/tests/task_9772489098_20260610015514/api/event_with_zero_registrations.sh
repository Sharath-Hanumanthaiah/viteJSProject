#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="${CASE_SUFFIX:-$(date +%s)-$$}"
RESPONSE_FILE="/tmp/event_with_zero_registrations_${CASE_SUFFIX}.json"
STATUS_FILE="/tmp/event_with_zero_registrations_${CASE_SUFFIX}.status"
cleanup_files() { rm -f "$RESPONSE_FILE" "$STATUS_FILE"; }
trap cleanup_files EXIT

# Given — use seeded data where event_2 and event_3 have no registrations

# When — request the events list
curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  "$BASE_URL/api/events" > "$STATUS_FILE"

# Then — verify an event with zero registrations is returned
STATUS="$(cat "$STATUS_FILE")"
[ "$STATUS" = "200" ]
grep -F '"id":"event_2"' "$RESPONSE_FILE" >/dev/null
grep -F '"registrationCount":0' "$RESPONSE_FILE" >/dev/null

# Cleanup — stateless read-only test

echo "CODEVALID_TEST_ASSERTION_OK:event_with_zero_registrations"
