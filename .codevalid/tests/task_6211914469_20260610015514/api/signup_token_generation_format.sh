#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
USERNAME="tokenuser-${CASE_SUFFIX}"
EMAIL="token-${CASE_SUFFIX}@test.com"
PASSWORD="tokenpass"
FULL_NAME="Token Test ${CASE_SUFFIX}"
RESPONSE_FILE="/tmp/signup_token_generation_format_${CASE_SUFFIX}.json"
STATUS_FILE="/tmp/signup_token_generation_format_${CASE_SUFFIX}.status"
cleanup_files() {
  rm -f "$RESPONSE_FILE" "$STATUS_FILE"
}
trap cleanup_files EXIT

# Given — prepare unique signup payload for token verification
:

# When — submit successful signup request
curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/auth/signup" \
  -H 'Content-Type: application/json' \
  --data "{\"username\":\"${USERNAME}\",\"email\":\"${EMAIL}\",\"password\":\"${PASSWORD}\",\"fullName\":\"${FULL_NAME}\"}" \
  > "$STATUS_FILE"

# Then — expect 201 and token format simulated-jwt-token-for-{userId}
STATUS="$(cat "$STATUS_FILE")"
[ "$STATUS" = "201" ]
python3 - "$RESPONSE_FILE" <<'PY'
import json
import sys
from pathlib import Path
payload = json.loads(Path(sys.argv[1]).read_text())
user = payload.get("user", {})
token = payload.get("token", "")
user_id = user.get("id", "")
assert user_id.startswith("user_"), f"unexpected user id: {user_id}"
expected = f"simulated-jwt-token-for-{user_id}"
assert token == expected, f"unexpected token: {token} != {expected}"
PY

# Cleanup — no delete endpoint exists for users in this in-memory API; unique data prevents collisions and state resets with container lifecycle

echo "CODEVALID_TEST_ASSERTION_OK:signup_token_generation_format"
