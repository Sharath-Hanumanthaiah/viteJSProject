#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
TMP_DIR="$(mktemp -d)"
RESPONSE_FILE="$TMP_DIR/registration_rejected_event_not_found.json"
STATUS_FILE="$TMP_DIR/registration_rejected_event_not_found.status"
trap 'rm -rf "$TMP_DIR"' EXIT

EVENT_ID="evt-nonexistent-${CASE_SUFFIX}"
NAME="Alice Brown ${CASE_SUFFIX}"
EMAIL="alice.brown+${CASE_SUFFIX}@example.com"
PHONE="+1-555-333-4444"

# Given — use a guaranteed-unique event id that does not exist
: "${EVENT_ID}"

# When — attempt registration against a non-existent event
curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' -X POST "$BASE_URL/api/registrations" \
  -H 'Content-Type: application/json' \
  --data "{\"eventId\":\"${EVENT_ID}\",\"name\":\"${NAME}\",\"email\":\"${EMAIL}\",\"phone\":\"${PHONE}\"}" > "$STATUS_FILE"

# Then — assert 404 and event-not-found message
STATUS="$(cat "$STATUS_FILE")"
[ "$STATUS" = "404" ]
python3 - "$RESPONSE_FILE" <<'PY'
import json, sys
with open(sys.argv[1], 'r', encoding='utf-8') as fh:
    body = json.load(fh)
assert body.get('message') == 'Event not found.', body
PY

# Cleanup — stateless test, no cleanup required

echo "CODEVALID_TEST_ASSERTION_OK:registration_rejected_event_not_found"
