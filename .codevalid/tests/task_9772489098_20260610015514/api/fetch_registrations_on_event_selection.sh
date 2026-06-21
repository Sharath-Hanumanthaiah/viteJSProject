#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
EVENTS_FILE="/tmp/fetch_registrations_on_event_selection_events_${CASE_SUFFIX}.json"
RESPONSE_FILE="/tmp/fetch_registrations_on_event_selection_${CASE_SUFFIX}.json"
EVENT_ID=""

cleanup() {
  rm -f "$EVENTS_FILE" "$RESPONSE_FILE"
}
trap cleanup EXIT

# Given — Load available events and select the first event id.
EVENTS_STATUS="$(curl -sS -o "$EVENTS_FILE" -w '%{http_code}' "$BASE_URL/api/events")"
[ "$EVENTS_STATUS" = "200" ]
EVENT_ID="$(jq -r '.[0].id // empty' "$EVENTS_FILE")"
[ -n "$EVENT_ID" ]

# When — Fetch registrations for that selected event.
HTTP_STATUS="$(curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' "$BASE_URL/api/registrations/${EVENT_ID}")"

# Then — API returns HTTP 200 and a JSON array.
[ "$HTTP_STATUS" = "200" ]
jq -e 'type == "array"' "$RESPONSE_FILE" >/dev/null

# Cleanup — No side effects.

echo "CODEVALID_TEST_ASSERTION_OK:fetch_registrations_on_event_selection"
