#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="${CASE_SUFFIX:-$(date +%s)-$$}"
EMAIL="nonexistent.${CASE_SUFFIX}@unknown.com"
TMP_DIR="$(mktemp -d)"
RESPONSE_FILE="$TMP_DIR/response.json"
STATUS_FILE="$TMP_DIR/status.txt"
trap 'rm -rf "$TMP_DIR"' EXIT

# Given — use a unique email that cannot already exist in this process
REQUEST_BODY="{\"email\":\"${EMAIL}\",\"password\":\"anypassword\"}"

# When — attempt signin with non-existent email
curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' -X POST "$BASE_URL/api/auth/signin" \
  -H 'Content-Type: application/json' \
  --data "$REQUEST_BODY" > "$STATUS_FILE"

# Then — verify invalid credentials response
STATUS="$(cat "$STATUS_FILE")"
[ "$STATUS" = "401" ]
python3 - "$RESPONSE_FILE" <<'PY'
import json, sys
with open(sys.argv[1], 'r', encoding='utf-8') as fh:
    data = json.load(fh)
assert data == {"message": "Invalid email or password."}, data
PY

# Cleanup — no side effects to undo

echo "CODEVALID_TEST_ASSERTION_OK:signin_invalid_email_returns_401"
