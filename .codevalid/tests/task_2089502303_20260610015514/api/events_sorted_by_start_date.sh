#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(python3 - <<'PY'
import uuid
print(uuid.uuid4().hex[:8])
PY
)"
GIVEN_HEADERS_1="/tmp/events_sorted_by_start_date_given_headers_1_${CASE_SUFFIX}.txt"
GIVEN_HEADERS_2="/tmp/events_sorted_by_start_date_given_headers_2_${CASE_SUFFIX}.txt"
GIVEN_HEADERS_3="/tmp/events_sorted_by_start_date_given_headers_3_${CASE_SUFFIX}.txt"
GIVEN_BODY_1="/tmp/events_sorted_by_start_date_given_body_1_${CASE_SUFFIX}.json"
GIVEN_BODY_2="/tmp/events_sorted_by_start_date_given_body_2_${CASE_SUFFIX}.json"
GIVEN_BODY_3="/tmp/events_sorted_by_start_date_given_body_3_${CASE_SUFFIX}.json"
REQ_1="/tmp/events_sorted_by_start_date_req_1_${CASE_SUFFIX}.json"
REQ_2="/tmp/events_sorted_by_start_date_req_2_${CASE_SUFFIX}.json"
REQ_3="/tmp/events_sorted_by_start_date_req_3_${CASE_SUFFIX}.json"
WHEN_HEADERS_FILE="/tmp/events_sorted_by_start_date_when_headers_${CASE_SUFFIX}.txt"
WHEN_BODY_FILE="/tmp/events_sorted_by_start_date_when_body_${CASE_SUFFIX}.json"
TITLE_1="Sort Event March ${CASE_SUFFIX}"
TITLE_2="Sort Event January ${CASE_SUFFIX}"
TITLE_3="Sort Event February ${CASE_SUFFIX}"

cleanup_files() {
  rm -f "$GIVEN_HEADERS_1" "$GIVEN_HEADERS_2" "$GIVEN_HEADERS_3" \
    "$GIVEN_BODY_1" "$GIVEN_BODY_2" "$GIVEN_BODY_3" \
    "$REQ_1" "$REQ_2" "$REQ_3" "$WHEN_HEADERS_FILE" "$WHEN_BODY_FILE"
}
trap cleanup_files EXIT

printf '{"title":"%s","description":"Created for sorting test","startDate":"2024-03-15","endDate":"2024-03-15","location":"Hall A"}' "$TITLE_1" > "$REQ_1"
printf '{"title":"%s","description":"Created for sorting test","startDate":"2024-01-10","endDate":"2024-01-10","location":"Hall B"}' "$TITLE_2" > "$REQ_2"
printf '{"title":"%s","description":"Created for sorting test","startDate":"2024-02-20","endDate":"2024-02-20","location":"Hall C"}' "$TITLE_3" > "$REQ_3"

echo "STEP: Given — create multiple events with different start dates"
for idx in 1 2 3; do
  req_var="REQ_${idx}"
  headers_var="GIVEN_HEADERS_${idx}"
  body_var="GIVEN_BODY_${idx}"
  req_file="$(eval "printf '%s' \"\${$req_var}\"")"
  headers_file="$(eval "printf '%s' \"\${$headers_var}\"")"
  body_file="$(eval "printf '%s' \"\${$body_var}\"")"
  echo "PREREQ: create event ${idx} via POST /api/events"
  echo "REQUEST_HEADERS: Content-Type: application/json"
  echo "REQUEST_BODY: $(cat "$req_file")"
  given_status="$(curl -sS -D "$headers_file" -o "$body_file" -w '%{http_code}' \
    -X POST "$BASE_URL/api/events" \
    -H 'Content-Type: application/json' \
    --data @"$req_file")"
  echo "RESPONSE_STATUS: $given_status"
  echo "RESPONSE_HEADERS:"
  cat "$headers_file"
  echo "RESPONSE_BODY:"
  cat "$body_file"
  [ "$given_status" = "201" ] || { echo "ASSERTION_FAILED: expected HTTP 201 got ${given_status}"; exit 1; }
done

echo "STEP: When — retrieve the events list"
echo "REQUEST_HEADERS: Accept: application/json"
echo "REQUEST_BODY: <empty>"
when_status="$(curl -sS -D "$WHEN_HEADERS_FILE" -o "$WHEN_BODY_FILE" -w '%{http_code}' \
  "$BASE_URL/api/events" \
  -H 'Accept: application/json')"
echo "RESPONSE_STATUS: $when_status"
echo "RESPONSE_HEADERS:"
cat "$WHEN_HEADERS_FILE"
echo "RESPONSE_BODY:"
cat "$WHEN_BODY_FILE"

echo "STEP: Then — assert events are sorted by startDate ascending"
[ "$when_status" = "200" ] || { echo "ASSERTION_FAILED: expected HTTP 200 got ${when_status}"; exit 1; }
python3 - "$WHEN_BODY_FILE" "$TITLE_1" "$TITLE_2" "$TITLE_3" <<'PY'
import json, sys
body_path, title_1, title_2, title_3 = sys.argv[1:]
with open(body_path, 'r', encoding='utf-8') as fh:
    data = json.load(fh)
assert isinstance(data, list), 'response is not a JSON array'
assert all(a['startDate'] <= b['startDate'] for a, b in zip(data, data[1:])), 'array is not globally sorted by startDate ascending'
positions = {}
for index, item in enumerate(data):
    title = item.get('title')
    if title in {title_1, title_2, title_3}:
        positions[title] = index
assert len(positions) == 3, 'not all created events were found in response'
assert positions[title_2] < positions[title_3] < positions[title_1], 'created events are not ordered Jan, Feb, Mar'
PY
if [ $? -ne 0 ]; then
  echo "ASSERTION_FAILED: events were not returned in ascending startDate order"
  exit 1
fi

echo "STEP: Cleanup — no cleanup possible because the app uses in-memory state without delete endpoints"
echo "CODEVALID_TEST_ASSERTION_OK:events_sorted_by_start_date"
