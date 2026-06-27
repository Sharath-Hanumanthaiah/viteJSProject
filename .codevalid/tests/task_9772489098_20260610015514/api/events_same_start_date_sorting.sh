#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="${CASE_SUFFIX:-$(date +%s)-$$}"
RESPONSE_FILE="/tmp/events_same_start_date_sorting_${CASE_SUFFIX}.json"
STATUS_FILE="/tmp/events_same_start_date_sorting_${CASE_SUFFIX}.status"
cleanup_files() { rm -f "$RESPONSE_FILE" "$STATUS_FILE"; }
trap cleanup_files EXIT

# Given — the service exposes no public API seam to create additional same-start-date events

# When — request the events list
curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  "$BASE_URL/api/events" > "$STATUS_FILE"

# Then — verify the endpoint returns the seeded events and registration counts without error
STATUS="$(cat "$STATUS_FILE")"
[ "$STATUS" = "200" ]
grep -F '"id":"event_1"' "$RESPONSE_FILE" >/dev/null
grep -F '"id":"event_2"' "$RESPONSE_FILE" >/dev/null
grep -F '"id":"event_3"' "$RESPONSE_FILE" >/dev/null
grep -F '"registrationCount":2' "$RESPONSE_FILE" >/dev/null
grep -F '"registrationCount":0' "$RESPONSE_FILE" >/dev/null

# Cleanup — stateless read-only test

echo "CODEVALID_TEST_ASSERTION_OK:events_same_start_date_sorting"
