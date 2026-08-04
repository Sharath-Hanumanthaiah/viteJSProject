#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="${CASE_SUFFIX:-$(date +%s)-$$}"
TMP_DIR="$(mktemp -d)"
SIGNUP_HEADERS="$TMP_DIR/signup_headers.txt"
SIGNUP_BODY_FILE="$TMP_DIR/signup_body.json"
WHEN_HEADERS="$TMP_DIR/when_headers.txt"
WHEN_BODY="$TMP_DIR/when_body.json"
SIGNUP_REQUEST_BODY_FILE="$TMP_DIR/signup_request.json"
WHEN_REQUEST_BODY_FILE="$TMP_DIR/when_request.json"
USERNAME="signin-password-hidden-${CASE_SUFFIX}"
EMAIL="signin.password.hidden.${CASE_SUFFIX}@example.com"
PASSWORD="secretPassword"
FULL_NAME="Response Security ${CASE_SUFFIX}"
cleanup_files() {
  rm -rf "$TMP_DIR"
}
trap cleanup_files EXIT

cat > "$SIGNUP_REQUEST_BODY_FILE" <<EOF
{"username":"${USERNAME}","email":"${EMAIL}","password":"${PASSWORD}","fullName":"${FULL_NAME}"}
EOF

cat > "$WHEN_REQUEST_BODY_FILE" <<EOF
{"email":"${EMAIL}","password":"${PASSWORD}"}
EOF

echo "STEP: Given — create a user whose credentials will be used for signin"
echo "PREREQ: registering user ${EMAIL} via signup API"
echo "REQUEST_HEADERS: Content-Type: application/json"
echo "REQUEST_BODY: $(cat "$SIGNUP_REQUEST_BODY_FILE")"
signup_status="$(curl -sS -D "$SIGNUP_HEADERS" -o "$SIGNUP_BODY_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/auth/signup" \
  -H 'Content-Type: application/json' \
  --data @"$SIGNUP_REQUEST_BODY_FILE")"
echo "RESPONSE_STATUS: ${signup_status}"
echo "RESPONSE_HEADERS:"
cat "$SIGNUP_HEADERS"
echo "RESPONSE_BODY:"
cat "$SIGNUP_BODY_FILE"
[ "$signup_status" = "201" ] || { echo "ASSERTION_FAILED: expected HTTP 201 from signup got ${signup_status}"; exit 1; }

echo "STEP: When — sign in with valid credentials"
echo "REQUEST_HEADERS: Content-Type: application/json"
echo "REQUEST_BODY: $(cat "$WHEN_REQUEST_BODY_FILE")"
when_status="$(curl -sS -D "$WHEN_HEADERS" -o "$WHEN_BODY" -w '%{http_code}' \
  -X POST "$BASE_URL/api/auth/signin" \
  -H 'Content-Type: application/json' \
  --data @"$WHEN_REQUEST_BODY_FILE")"
echo "RESPONSE_STATUS: ${when_status}"
echo "RESPONSE_HEADERS:"
cat "$WHEN_HEADERS"
echo "RESPONSE_BODY:"
cat "$WHEN_BODY"

echo "STEP: Then — assert password is excluded from the returned user object"
[ "$when_status" = "200" ] || { echo "ASSERTION_FAILED: expected HTTP 200 got ${when_status}"; exit 1; }
python3 - "$WHEN_BODY" "$EMAIL" "$PASSWORD" <<'PY'
import json, sys
path, email, password = sys.argv[1:4]
raw = open(path, 'r', encoding='utf-8').read()
assert password not in raw, 'plaintext password leaked into response body'
data = json.loads(raw)
assert 'user' in data and isinstance(data['user'], dict), 'missing user object'
user = data['user']
assert user.get('email') == email, f"expected email {email} got {user.get('email')}"
assert 'password' not in user, 'password field should not be present in user object'
assert isinstance(user.get('id'), str) and user['id'].startswith('user_'), f"unexpected user id {user.get('id')}"
assert isinstance(data.get('token'), str) and data['token'] == f"simulated-jwt-token-for-{user['id']}", f"unexpected token {data.get('token')}"
PY
python_status="$?"
[ "$python_status" = "0" ] || { echo "ASSERTION_FAILED: expected successful signin response to exclude password and include matching token"; exit 1; }

echo "STEP: Cleanup — no cleanup required for in-memory service state"
:

echo "CODEVALID_TEST_ASSERTION_OK:signin_password_excluded_from_response"
