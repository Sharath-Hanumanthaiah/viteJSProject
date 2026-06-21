#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
EVENTS_FILE="/tmp/event_auto_selection_events_${CASE_SUFFIX}.json"
REGS_FILE="/tmp/event_auto_selection_regs_${CASE_SUFFIX}.json"
FIRST_EVENT_ID=""

cleanup() {
  rm -f "$EVENTS_FILE" "$REGS_FILE"
}
trap cleanup EXIT

# Given — Events endpoint is reachable.
HEALTH_STATUS="$(curl -sS -o /dev/null -w '%{http_code}' "$BASE_URL/health")"
[ "$HEALTH_STATUS" = "200" ]

# When — Fetch events and then fetch registrations for the first returned event.
EVENTS_STATUS="$(curl -sS -o "$EVENTS_FILE" -w '%{http_code}' "$BASE_URL/api/events")"
[ "$EVENTS_STATUS" = "200" ]
FIRST_EVENT_ID="$(jq -r '.[0].id // empty' "$EVENTS_FILE")"
[ -n "$FIRST_EVENT_ID" ]
REGS_STATUS="$(curl -sS -o "$REGS_FILE" -w '%{http_code}' "$BASE_URL/api/registrations/${FIRST_EVENT_ID}")"

# Then — The first event id is immediately usable for the registrations endpoint.
[ "$REGS_STATUS" = "200" ]
jq -e 'type == "array"' "$REGS_FILE" >/dev/null

# Cleanup — No side effects.

echo "CODEVALID_TEST_ASSERTION_OK:event_auto_selection"
