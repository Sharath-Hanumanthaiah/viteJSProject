#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
EVENTS_FILE="/tmp/registration_count_accuracy_events_${CASE_SUFFIX}.json"
CONF_FILE="/tmp/registration_count_accuracy_conf_${CASE_SUFFIX}.json"
MEETUP_FILE="/tmp/registration_count_accuracy_meetup_${CASE_SUFFIX}.json"

cleanup_tmp() {
  rm -f "$EVENTS_FILE" "$CONF_FILE" "$MEETUP_FILE"
}
trap cleanup_tmp EXIT

# Given — The service is reachable and fixture registrations exist for evt-conf and evt-meetup.
curl -sS "$BASE_URL/health" >/dev/null

# When — Request the events collection and each event's registration list.
EVENTS_STATUS="$(curl -sS -o "$EVENTS_FILE" -w '%{http_code}' "$BASE_URL/api/events")"
CONF_STATUS="$(curl -sS -o "$CONF_FILE" -w '%{http_code}' "$BASE_URL/api/registrations/evt-conf")"
MEETUP_STATUS="$(curl -sS -o "$MEETUP_FILE" -w '%{http_code}' "$BASE_URL/api/registrations/evt-meetup")"

# Then — The API returns 200 and the counts match 5 for evt-conf and 2 for evt-meetup.
[ "$EVENTS_STATUS" = "200" ]
[ "$CONF_STATUS" = "200" ]
[ "$MEETUP_STATUS" = "200" ]
grep -F '"id":"evt-conf"' "$EVENTS_FILE" >/dev/null
grep -F '"id":"evt-meetup"' "$EVENTS_FILE" >/dev/null
CONF_COUNT="$(grep -o '"eventId":"evt-conf"' "$CONF_FILE" | wc -l | tr -d ' ')"
MEETUP_COUNT="$(grep -o '"eventId":"evt-meetup"' "$MEETUP_FILE" | wc -l | tr -d ' ')"
[ "$CONF_COUNT" = "5" ]
[ "$MEETUP_COUNT" = "2" ]
grep -F '"registrationCount":5' "$EVENTS_FILE" >/dev/null
grep -F '"registrationCount":2' "$EVENTS_FILE" >/dev/null

echo "CODEVALID_TEST_ASSERTION_OK:registration_count_accuracy"
