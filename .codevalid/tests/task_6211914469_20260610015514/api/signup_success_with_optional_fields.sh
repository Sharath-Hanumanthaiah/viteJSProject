#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="${CASE_SUFFIX:-$(date +%s)-$$}"
USERNAME="acmeuser-${CASE_SUFFIX}"
EMAIL="employee-${CASE_SUFFIX}@acme.com"
PASSWORD="Password456"
FULL_NAME="Acme Employee ${CASE_SUFFIX}"
PHONE="+1-555-123-4567"
ORGANIZATION="Acme Corp"
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
  "fullName": "$FULL_NAME",
  "phone": "$PHONE",
  "organization": "$ORGANIZATION"
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
python3 - "$RESPONSE_FILE" "$USERNAME" "$EMAIL" "$FULL_NAME" "$PHONE" "$ORGANIZATION" <<'PY'
import json, sys
path, username, email, full_name, phone, organization = sys.argv[1:]
with open(path, 'r', encoding='utf-8') as fh:
    data = json.load(fh)
user = data.get('user')
assert isinstance(user, dict), 'user object missing'
assert user.get('username') == username, 'username mismatch'
assert user.get('email') == email, 'email mismatch'
assert user.get('fullName') == full_name, 'fullName mismatch'
assert user.get('phone') == phone, 'phone mismatch'
assert user.get('organization') == organization, 'organization mismatch'
assert 'password' not in user, 'password must not be returned'
assert data.get('token') == f"simulated-jwt-token-for-{user['id']}", 'token mismatch'
PY

# Cleanup
# No cleanup available: signup persists only in in-memory process state and there is no public delete/reset API.

echo "CODEVALID_TEST_ASSERTION_OK:signup_success_with_optional_fields"
