#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
TODAY="$(date -u +%F)"
EVENTS_FILE="/tmp/loading_states_during_api_calls_events_${CASE_SUFFIX}.json"
REGS_FILE="/tmp/loading_states_during_api_calls_regs_${CASE_SUFFIX}.json"
POST_FILE="/tmp/loading_states_during_api_calls_post_${CASE_SUFFIX}.json"
EVENT_ID=""

cleanup() {
  rm -f "$EVENTS_FILE" "$REGS_FILE" "$POST_FILE"
}
trap cleanup EXIT

# Given — Find an event open for registration today.
EVENTS_STATUS="$(curl -sS -o "$EVENTS_FILE" -w '%{http_code}' "$BASE_URL/api/events")"
[ "$EVENTS_STATUS" = "200" ]
EVENT_ID="$(jq -r --arg today "$TODAY" 'map(select(.startDate <= $today and .endDate >= $today)) | .[0].id // empty' "$EVENTS_FILE")"
[ -n "$EVENT_ID" ]

# When — Exercise events fetch, registrations fetch, and registration submit APIs.
REGS_STATUS="$(curl -sS -o "$REGS_FILE" -w '%{http_code}' "$BASE_URL/api/registrations/${EVENT_ID}")"
POST_STATUS="$(curl -sS -o "$POST_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/registrations" \
  -H 'Content-Type: application/json' \
  --data "{\"eventId\":\"${EVENT_ID}\",\"name\":\"Loading User\",\"email\":\"loading.${CASE_SUFFIX}@example.com\",\"phone\":\"+1-555-000-9999\"}")"

# Then — All API calls succeed.
[ "$REGS_STATUS" = "200" ]
[ "$POST_STATUS" = "201" ]
jq -e '.name == "Loading User"' "$POST_FILE" >/dev/null

# Cleanup — No delete endpoint is exposed; unique email isolates side effects.

echo "CODEVALID_TEST_ASSERTION_OK:loading_states_during_api_calls"
