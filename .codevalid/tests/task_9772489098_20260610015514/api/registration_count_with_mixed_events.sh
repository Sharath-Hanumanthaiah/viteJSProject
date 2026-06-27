#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="${CASE_SUFFIX:-$(date +%s)-$$}"
RESPONSE_FILE="/tmp/registration_count_with_mixed_events_${CASE_SUFFIX}.json"
STATUS_FILE="/tmp/registration_count_with_mixed_events_${CASE_SUFFIX}.status"
cleanup_files() { rm -f "$RESPONSE_FILE" "$STATUS_FILE"; }
trap cleanup_files EXIT

# Given — rely on seeded mixed counts: one event with registrations and multiple events without

# When — request the events list
curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  "$BASE_URL/api/events" > "$STATUS_FILE"

# Then — verify counts stay isolated by event ID in the returned array
STATUS="$(cat "$STATUS_FILE")"
[ "$STATUS" = "200" ]
grep -F '"id":"event_1"' "$RESPONSE_FILE" >/dev/null
grep -F '"registrationCount":2' "$RESPONSE_FILE" >/dev/null
grep -F '"id":"event_2"' "$RESPONSE_FILE" >/dev/null
grep -F '"id":"event_3"' "$RESPONSE_FILE" >/dev/null
zero_count_occurrences="$(grep -o '"registrationCount":0' "$RESPONSE_FILE" | wc -l | tr -d ' ')"
[ "$zero_count_occurrences" -ge 2 ]

# Cleanup — stateless read-only test

echo "CODEVALID_TEST_ASSERTION_OK:registration_count_with_mixed_events"
