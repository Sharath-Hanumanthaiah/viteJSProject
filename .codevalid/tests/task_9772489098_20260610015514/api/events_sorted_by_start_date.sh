#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="${CASE_SUFFIX:-$(date +%s)-$$}"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

WORKSHOP_TITLE="Spring Workshop ${CASE_SUFFIX}"
SUMMIT_TITLE="Annual Summit ${CASE_SUFFIX}"
GALA_TITLE="Gala Night ${CASE_SUFFIX}"

create_event() {
  title="$1"
  start_date="$2"
  end_date="$3"
  location="$4"
  payload=$(printf '{"title":"%s","description":"Sort verification %s","startDate":"%s","endDate":"%s","location":"%s"}' \
    "$title" "$CASE_SUFFIX" "$start_date" "$end_date" "$location")

  curl -sS -o /dev/null -w '%{http_code}' \
    -X POST "$BASE_URL/api/events" \
    -H 'Content-Type: application/json' \
    --data "$payload" > "$TMP_DIR/create.status"

  [ "$(cat "$TMP_DIR/create.status")" = "201" ]
}

# Given — create events in deliberately unsorted insertion order
create_event "$GALA_TITLE" "2024-06-15" "2024-06-16" "Grand Hall ${CASE_SUFFIX}"
create_event "$WORKSHOP_TITLE" "2024-02-28" "2024-02-29" "Workshop Room ${CASE_SUFFIX}"
create_event "$SUMMIT_TITLE" "2024-04-10" "2024-04-11" "Summit Center ${CASE_SUFFIX}"

# When — fetch the events list
curl -sS -o "$TMP_DIR/events.json" -w '%{http_code}' \
  "$BASE_URL/api/events" > "$TMP_DIR/events.status"

# Then — verify 200 and ascending order among this test's events
[ "$(cat "$TMP_DIR/events.status")" = "200" ]
WORKSHOP_POS=$(awk -v needle="$WORKSHOP_TITLE" 'BEGIN{print index($0, needle)} { if (index($0, needle)) { print index($0, needle); exit } }' "$TMP_DIR/events.json" | tail -n 1)
SUMMIT_POS=$(awk -v needle="$SUMMIT_TITLE" 'BEGIN{print index($0, needle)} { if (index($0, needle)) { print index($0, needle); exit } }' "$TMP_DIR/events.json" | tail -n 1)
GALA_POS=$(awk -v needle="$GALA_TITLE" 'BEGIN{print index($0, needle)} { if (index($0, needle)) { print index($0, needle); exit } }' "$TMP_DIR/events.json" | tail -n 1)
[ -n "$WORKSHOP_POS" ]
[ -n "$SUMMIT_POS" ]
[ -n "$GALA_POS" ]
WORKSHOP_OFFSET=$(python3 - <<'PY' "$TMP_DIR/events.json" "$WORKSHOP_TITLE"
import sys
text=open(sys.argv[1]).read()
needle=sys.argv[2]
print(text.find(needle))
PY
)
SUMMIT_OFFSET=$(python3 - <<'PY' "$TMP_DIR/events.json" "$SUMMIT_TITLE"
import sys
text=open(sys.argv[1]).read()
needle=sys.argv[2]
print(text.find(needle))
PY
)
GALA_OFFSET=$(python3 - <<'PY' "$TMP_DIR/events.json" "$GALA_TITLE"
import sys
text=open(sys.argv[1]).read()
needle=sys.argv[2]
print(text.find(needle))
PY
)
[ "$WORKSHOP_OFFSET" -ge 0 ]
[ "$SUMMIT_OFFSET" -ge 0 ]
[ "$GALA_OFFSET" -ge 0 ]
[ "$WORKSHOP_OFFSET" -lt "$SUMMIT_OFFSET" ]
[ "$SUMMIT_OFFSET" -lt "$GALA_OFFSET" ]

echo "CODEVALID_TEST_ASSERTION_OK:events_sorted_by_start_date"

# Cleanup — no cleanup API exists for events in this service; uniquely suffixed data avoids collisions
