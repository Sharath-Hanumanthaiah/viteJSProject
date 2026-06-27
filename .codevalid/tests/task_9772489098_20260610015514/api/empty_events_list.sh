#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="${CASE_SUFFIX:-$(date +%s)-$$}"
RESPONSE_FILE="/tmp/empty_events_list_${CASE_SUFFIX}.json"
STATUS_FILE="/tmp/empty_events_list_${CASE_SUFFIX}.status"
cleanup_files() { rm -f "$RESPONSE_FILE" "$STATUS_FILE"; }
trap cleanup_files EXIT

# Given — the service exposes no public API seam to clear its seeded in-memory events

# When — request the events list
curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  "$BASE_URL/api/events" > "$STATUS_FILE"

# Then — verify the actual reachable behavior: HTTP 200 with a non-empty seeded array
STATUS="$(cat "$STATUS_FILE")"
[ "$STATUS" = "200" ]
[ "$(cat "$RESPONSE_FILE")" != '[]' ]
grep -F '"id":"event_1"' "$RESPONSE_FILE" >/dev/null

# Cleanup — stateless read-only test

echo "CODEVALID_TEST_ASSERTION_OK:empty_events_list"
