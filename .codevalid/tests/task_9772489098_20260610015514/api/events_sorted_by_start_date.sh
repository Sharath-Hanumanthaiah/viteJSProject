#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
RESPONSE_FILE="/tmp/events_sorted_by_start_date_${CASE_SUFFIX}.json"

cleanup_tmp() {
  rm -f "$RESPONSE_FILE"
}
trap cleanup_tmp EXIT

# Given — The service is reachable and fixture events exist for the ordering scenario.
curl -sS "$BASE_URL/health" >/dev/null

# When — Request the events collection.
HTTP_STATUS="$(curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' "$BASE_URL/api/events")"

# Then — The API returns 200 and the fixture events appear in ascending start-date order.
[ "$HTTP_STATUS" = "200" ]
grep -F '"id":"evt-workshop"' "$RESPONSE_FILE" >/dev/null
grep -F '"id":"evt-summit"' "$RESPONSE_FILE" >/dev/null
grep -F '"id":"evt-gala"' "$RESPONSE_FILE" >/dev/null
WORKSHOP_POS="$(grep -bo '"id":"evt-workshop"' "$RESPONSE_FILE" | head -1 | cut -d: -f1)"
SUMMIT_POS="$(grep -bo '"id":"evt-summit"' "$RESPONSE_FILE" | head -1 | cut -d: -f1)"
GALA_POS="$(grep -bo '"id":"evt-gala"' "$RESPONSE_FILE" | head -1 | cut -d: -f1)"
[ -n "$WORKSHOP_POS" ]
[ -n "$SUMMIT_POS" ]
[ -n "$GALA_POS" ]
[ "$WORKSHOP_POS" -lt "$SUMMIT_POS" ]
[ "$SUMMIT_POS" -lt "$GALA_POS" ]

echo "CODEVALID_TEST_ASSERTION_OK:events_sorted_by_start_date"
