#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="${CASE_SUFFIX:-$(date +%s)-$$}"
USERNAME="tokenuser-${CASE_SUFFIX}"
EMAIL="token-${CASE_SUFFIX}@test.com"
PASSWORD="tokenpass"
FULL_NAME="Token Test ${CASE_SUFFIX}"
TMP_DIR="$(mktemp -d)"
RESPONSE_FILE="$TMP_DIR/response.json"
STATUS_FILE="$TMP_DIR/status.txt"
trap 'rm -rf "$TMP_DIR"' EXIT

# Given
cat >"$TMP_DIR/request.json" <<EOF
{
  "username": "$USERNAME",
  "email": "$EMAIL",
  "password": "$PASSWORD",
  "fullName": "$FULL_NAME"
}
EOF

# When
curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/auth/signup" \
  -H 'Content-Type: application/json' \
  --data @"$TMP_DIR/request.json" > "$STATUS_FILE"

# Then
STATUS="$(cat "$STATUS_FILE")"
[ "$STATUS" = "201" ]
python3 - "$RESPONSE_FILE" <<'PY'
import json, sys
with open(sys.argv[1], 'r', encoding='utf-8') as fh:
    data = json.load(fh)
user = data.get('user')
assert isinstance(user, dict), 'user object missing'
user_id = user.get('id')
assert isinstance(user_id, str) and user_id.startswith('user_'), 'invalid user id'
token = data.get('token')
assert isinstance(token, str), 'token missing'
assert token == f'simulated-jwt-token-for-{user_id}', 'token format mismatch'
PY

# Cleanup
# No cleanup available: signup persists only in in-memory process state and there is no public delete/reset API.

echo "CODEVALID_TEST_ASSERTION_OK:signup_token_generation_format"
