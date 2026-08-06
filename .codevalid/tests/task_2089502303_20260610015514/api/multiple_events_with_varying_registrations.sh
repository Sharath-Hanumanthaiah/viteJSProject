#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(python3 - <<'PY'
import uuid
print(uuid.uuid4().hex[:8])
PY
)"
TODAY="$(python3 - <<'PY'
from datetime import date
print(date.today().isoformat())
PY
)"
EVENT_A_TITLE="Varying Count A ${CASE_SUFFIX}"
EVENT_B_TITLE="Varying Count B ${CASE_SUFFIX}"
EVENT_C_TITLE="Varying Count C ${CASE_SUFFIX}"
EVENT_A_ID=""
EVENT_B_ID=""
EVENT_C_ID=""
CREATE_HEADERS_A="/tmp/multiple_events_with_varying_registrations_create_headers_a_${CASE_SUFFIX}.txt"
CREATE_HEADERS_B="/tmp/multiple_events_with_varying_registrations_create_headers_b_${CASE_SUFFIX}.txt"
CREATE_HEADERS_C="/tmp/multiple_events_with_varying_registrations_create_headers_c_${CASE_SUFFIX}.txt"
CREATE_BODY_A="/tmp/multiple_events_with_varying_registrations_create_body_a_${CASE_SUFFIX}.json"
CREATE_BODY_B="/tmp/multiple_events_with_varying_registrations_create_body_b_${CASE_SUFFIX}.json"
CREATE_BODY_C="/tmp/multiple_events_with_varying_registrations_create_body_c_${CASE_SUFFIX}.json"
CREATE_REQ_A="/tmp/multiple_events_with_varying_registrations_create_req_a_${CASE_SUFFIX}.json"
CREATE_REQ_B="/tmp/multiple_events_with_varying_registrations_create_req_b_${CASE_SUFFIX}.json"
CREATE_REQ_C="/tmp/multiple_events_with_varying_registrations_create_req_c_${CASE_SUFFIX}.json"
LIST_HEADERS_FILE="/tmp/multiple_events_with_varying_registrations_list_headers_${CASE_SUFFIX}.txt"
LIST_BODY_FILE="/tmp/multiple_events_with_varying_registrations_list_body_${CASE_SUFFIX}.json"

cleanup_files() {
  rm -f "$CREATE_HEADERS_A" "$CREATE_HEADERS_B" "$CREATE_HEADERS_C" \
    "$CREATE_BODY_A" "$CREATE_BODY_B" "$CREATE_BODY_C" \
    "$CREATE_REQ_A" "$CREATE_REQ_B" "$CREATE_REQ_C" \
    "$LIST_HEADERS_FILE" "$LIST_BODY_FILE" \
    /tmp/multiple_events_with_varying_registrations_reg_*_headers_${CASE_SUFFIX}.txt \
    /tmp/multiple_events_with_varying_registrations_reg_*_body_${CASE_SUFFIX}.json \
    /tmp/multiple_events_with_varying_registrations_reg_*_req_${CASE_SUFFIX}.json
}
trap cleanup_files EXIT

printf '{"title":"%s","description":"count five","startDate":"%s","endDate":"%s","location":"Auditorium A"}' "$EVENT_A_TITLE" "$TODAY" "$TODAY" > "$CREATE_REQ_A"
printf '{"title":"%s","description":"count two","startDate":"%s","endDate":"%s","location":"Auditorium B"}' "$EVENT_B_TITLE" "$TODAY" "$TODAY" > "$CREATE_REQ_B"
printf '{"title":"%s","description":"count zero","startDate":"%s","endDate":"%s","location":"Auditorium C"}' "$EVENT_C_TITLE" "$TODAY" "$TODAY" > "$CREATE_REQ_C"

echo "STEP: Given — create three events and registrations with counts 5, 2, and 0"
for label in A B C; do
  req_file="$(eval "printf '%s' \"\$CREATE_REQ_${label}\"")"
  headers_file="$(eval "printf '%s' \"\$CREATE_HEADERS_${label}\"")"
  body_file="$(eval "printf '%s' \"\$CREATE_BODY_${label}\"")"
  echo "PREREQ: create event ${label} via POST /api/events"
  echo "REQUEST_HEADERS: Content-Type: application/json"
  echo "REQUEST_BODY: $(cat "$req_file")"
  create_status="$(curl -sS -D "$headers_file" -o "$body_file" -w '%{http_code}' \
    -X POST "$BASE_URL/api/events" \
    -H 'Content-Type: application/json' \
    --data @"$req_file")"
  echo "RESPONSE_STATUS: $create_status"
  echo "RESPONSE_HEADERS:"
  cat "$headers_file"
  echo "RESPONSE_BODY:"
  cat "$body_file"
  [ "$create_status" = "201" ] || { echo "ASSERTION_FAILED: expected HTTP 201 got ${create_status}"; exit 1; }
  event_id="$(python3 - "$body_file" <<'PY'
import json, sys
with open(sys.argv[1], 'r', encoding='utf-8') as fh:
    print(json.load(fh)['id'])
PY
)"
  eval "EVENT_${label}_ID=\"$event_id\""
done

create_registration() {
  reg_name="$1"
  event_id="$2"
  email="$3"
  phone="$4"
  req_file="/tmp/multiple_events_with_varying_registrations_reg_${reg_name}_req_${CASE_SUFFIX}.json"
  headers_file="/tmp/multiple_events_with_varying_registrations_reg_${reg_name}_headers_${CASE_SUFFIX}.txt"
  body_file="/tmp/multiple_events_with_varying_registrations_reg_${reg_name}_body_${CASE_SUFFIX}.json"
  printf '{"eventId":"%s","name":"%s","email":"%s","phone":"%s"}' "$event_id" "$reg_name" "$email" "$phone" > "$req_file"
  echo "PREREQ: create registration ${reg_name} via POST /api/registrations"
  echo "REQUEST_HEADERS: Content-Type: application/json"
  echo "REQUEST_BODY: $(cat "$req_file")"
  reg_status="$(curl -sS -D "$headers_file" -o "$body_file" -w '%{http_code}' \
    -X POST "$BASE_URL/api/registrations" \
    -H 'Content-Type: application/json' \
    --data @"$req_file")"
  echo "RESPONSE_STATUS: $reg_status"
  echo "RESPONSE_HEADERS:"
  cat "$headers_file"
  echo "RESPONSE_BODY:"
  cat "$body_file"
  [ "$reg_status" = "201" ] || { echo "ASSERTION_FAILED: expected HTTP 201 got ${reg_status}"; exit 1; }
}

create_registration "regA1_${CASE_SUFFIX}" "$EVENT_A_ID" "rega1_${CASE_SUFFIX}@example.com" "555-0001"
create_registration "regA2_${CASE_SUFFIX}" "$EVENT_A_ID" "rega2_${CASE_SUFFIX}@example.com" "555-0002"
create_registration "regA3_${CASE_SUFFIX}" "$EVENT_A_ID" "rega3_${CASE_SUFFIX}@example.com" "555-0003"
create_registration "regA4_${CASE_SUFFIX}" "$EVENT_A_ID" "rega4_${CASE_SUFFIX}@example.com" "555-0004"
create_registration "regA5_${CASE_SUFFIX}" "$EVENT_A_ID" "rega5_${CASE_SUFFIX}@example.com" "555-0005"
create_registration "regB1_${CASE_SUFFIX}" "$EVENT_B_ID" "regb1_${CASE_SUFFIX}@example.com" "555-0011"
create_registration "regB2_${CASE_SUFFIX}" "$EVENT_B_ID" "regb2_${CASE_SUFFIX}@example.com" "555-0012"

echo "STEP: When — retrieve the events list"
echo "REQUEST_HEADERS: Accept: application/json"
echo "REQUEST_BODY: <empty>"
when_status="$(curl -sS -D "$LIST_HEADERS_FILE" -o "$LIST_BODY_FILE" -w '%{http_code}' \
  "$BASE_URL/api/events" \
  -H 'Accept: application/json')"
echo "RESPONSE_STATUS: $when_status"
echo "RESPONSE_HEADERS:"
cat "$LIST_HEADERS_FILE"
echo "RESPONSE_BODY:"
cat "$LIST_BODY_FILE"

echo "STEP: Then — assert each event shows the correct individual registrationCount"
[ "$when_status" = "200" ] || { echo "ASSERTION_FAILED: expected HTTP 200 got ${when_status}"; exit 1; }
python3 - "$LIST_BODY_FILE" "$EVENT_A_ID" "$EVENT_B_ID" "$EVENT_C_ID" <<'PY'
import json, sys
body_path, event_a_id, event_b_id, event_c_id = sys.argv[1:]
with open(body_path, 'r', encoding='utf-8') as fh:
    data = json.load(fh)
lookup = {item['id']: item for item in data}
assert lookup[event_a_id]['registrationCount'] == 5, f"event A expected 5 got {lookup[event_a_id]['registrationCount']}"
assert lookup[event_b_id]['registrationCount'] == 2, f"event B expected 2 got {lookup[event_b_id]['registrationCount']}"
assert lookup[event_c_id]['registrationCount'] == 0, f"event C expected 0 got {lookup[event_c_id]['registrationCount']}"
PY
if [ $? -ne 0 ]; then
  echo "ASSERTION_FAILED: one or more events had an incorrect registrationCount"
  exit 1
fi

echo "STEP: Cleanup — no cleanup possible because the app uses in-memory state without delete endpoints"
echo "CODEVALID_TEST_ASSERTION_OK:multiple_events_with_varying_registrations"
