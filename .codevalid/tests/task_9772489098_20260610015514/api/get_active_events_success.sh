#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
RESPONSE_FILE="/tmp/get_active_events_success_${CASE_SUFFIX}.json"

cleanup_tmp() {
  rm -f "$RESPONSE_FILE"
}
trap cleanup_tmp EXIT

# Given — The service is reachable and the seeded events dataset includes the expected fixtures.
curl -sS "$BASE_URL/health" >/dev/null

# When — Request the events collection.
HTTP_STATUS="$(curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' "$BASE_URL/api/events")"

# Then — The API returns 200 and includes the expected 3 events with registrationCount fields.
[ "$HTTP_STATUS" = "200" ]
grep -F '"id":"evt-001"' "$RESPONSE_FILE" >/dev/null
grep -F '"id":"evt-002"' "$RESPONSE_FILE" >/dev/null
grep -F '"id":"evt-003"' "$RESPONSE_FILE" >/dev/null
grep -F '"title":"Tech Conference 2024"' "$RESPONSE_FILE" >/dev/null
grep -F '"title":"Music Festival"' "$RESPONSE_FILE" >/dev/null
grep -F '"title":"Art Exhibition"' "$RESPONSE_FILE" >/dev/null
grep -F '"registrationCount":' "$RESPONSE_FILE" >/dev/null
COUNT_IDS="$(grep -o '"id":"evt-00[123]"' "$RESPONSE_FILE" | wc -l | tr -d ' ')"
[ "$COUNT_IDS" = "3" ]

echo "CODEVALID_TEST_ASSERTION_OK:get_active_events_success"
