#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
RESPONSE_FILE="/tmp/empty_events_list_${CASE_SUFFIX}.json"

cleanup_tmp() {
  rm -f "$RESPONSE_FILE"
}
trap cleanup_tmp EXIT

# Given — The service is reachable and this target scenario expects no seeded events.
curl -sS "$BASE_URL/health" >/dev/null

# When — Request the events collection.
HTTP_STATUS="$(curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' "$BASE_URL/api/events")"

# Then — The API returns 200 and the body is exactly an empty JSON array.
[ "$HTTP_STATUS" = "200" ]
BODY_COMPACT="$(tr -d '\n\r\t ' < "$RESPONSE_FILE")"
[ "$BODY_COMPACT" = "[]" ]

echo "CODEVALID_TEST_ASSERTION_OK:empty_events_list"
