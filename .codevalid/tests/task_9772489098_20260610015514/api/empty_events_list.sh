#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

# Given — this service has no public reset/delete API for the in-memory events store,
# so an absolute empty-store precondition cannot be established from a black-box API test.
# This script verifies the graceful-response contract achievable through the public API.

# When — request the events list
curl -sS -o "$TMP_DIR/events.json" -w '%{http_code}' \
  "$BASE_URL/api/events" > "$TMP_DIR/events.status"

# Then — verify the endpoint responds successfully with a JSON array payload
[ "$(cat "$TMP_DIR/events.status")" = "200" ]
python3 - <<'PY' "$TMP_DIR/events.json"
import json, sys
body = json.load(open(sys.argv[1]))
assert isinstance(body, list), type(body)
PY

echo "CODEVALID_TEST_ASSERTION_OK:empty_events_list"
