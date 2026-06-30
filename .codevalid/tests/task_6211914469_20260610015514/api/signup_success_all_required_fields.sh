#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="${CASE_SUFFIX:-$(date +%s)-$$}"
USERNAME="newuser123-${CASE_SUFFIX}"
EMAIL="newuser-${CASE_SUFFIX}@example.com"
PASSWORD="SecurePass123!"
FULL_NAME="New User ${CASE_SUFFIX}"
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
python3 - "$RESPONSE_FILE" "$USERNAME" "$EMAIL" "$FULL_NAME" <<'PY'
import json, sys
path, username, email, full_name = sys.argv[1:]
with open(path, 'r', encoding='utf-8') as fh:
    data = json.load(fh)
user = data.get('user')
assert isinstance(user, dict), 'user object missing'
assert isinstance(user.get('id'), str) and user['id'].startswith('user_'), 'user.id missing or invalid'
assert user.get('username') == username, 'username mismatch'
assert user.get('email') == email, 'email mismatch'
assert user.get('fullName') == full_name, 'fullName mismatch'
assert user.get('phone') == '', 'phone should default to empty string'
assert user.get('organization') == '', 'organization should default to empty string'
assert 'password' not in user, 'password must not be returned'
token = data.get('token')
assert isinstance(token, str) and token == f"simulated-jwt-token-for-{user['id']}", 'token missing or invalid'
PY

# Cleanup
# No cleanup available: signup persists only in in-memory process state and there is no public delete/reset API.

echo "CODEVALID_TEST_ASSERTION_OK:signup_success_all_required_fields"
