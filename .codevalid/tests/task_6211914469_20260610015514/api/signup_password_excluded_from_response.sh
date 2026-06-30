#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="${CASE_SUFFIX:-$(date +%s)-$$}"
USERNAME="secureuser-${CASE_SUFFIX}"
EMAIL="secure-${CASE_SUFFIX}@test.com"
PASSWORD="MySecretPassword123"
FULL_NAME="Security Test ${CASE_SUFFIX}"
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
assert 'password' not in user, 'password must not be present'
for key, expected in [('username', username), ('email', email), ('fullName', full_name)]:
    assert user.get(key) == expected, f'{key} mismatch'
assert isinstance(user.get('id'), str) and user['id'], 'id missing'
PY

# Cleanup
# No cleanup available: signup persists only in in-memory process state and there is no public delete/reset API.

echo "CODEVALID_TEST_ASSERTION_OK:signup_password_excluded_from_response"
