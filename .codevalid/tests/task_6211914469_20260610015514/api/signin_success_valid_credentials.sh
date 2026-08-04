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
USERNAME="signin-success-${CASE_SUFFIX}"
EMAIL="signin.success.${CASE_SUFFIX}@example.com"
PASSWORD="validPassword123"
FULL_NAME="Signin Success ${CASE_SUFFIX}"
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

echo "STEP: Given — create a unique user account for signin"
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
grep -F '"email":"'"${EMAIL}"'"' "$SIGNUP_BODY_FILE" >/dev/null || { echo "ASSERTION_FAILED: expected signup response to contain created email ${EMAIL}"; exit 1; }

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

echo "STEP: Then — assert successful signin returns user data and token"
[ "$when_status" = "200" ] || { echo "ASSERTION_FAILED: expected HTTP 200 got ${when_status}"; exit 1; }
python3 - "$WHEN_BODY" "$EMAIL" "$FULL_NAME" <<'PY'
import json, sys
path, email, full_name = sys.argv[1:4]
with open(path, 'r', encoding='utf-8') as fh:
    data = json.load(fh)
assert isinstance(data, dict), 'response is not a JSON object'
assert 'user' in data and isinstance(data['user'], dict), 'missing user object'
assert 'token' in data and isinstance(data['token'], str), 'missing token'
user = data['user']
assert user.get('email') == email, f"expected email {email} got {user.get('email')}"
assert user.get('fullName') == full_name, f"expected fullName {full_name} got {user.get('fullName')}"
assert isinstance(user.get('id'), str) and user['id'].startswith('user_'), f"unexpected user id {user.get('id')}"
assert 'password' not in user, 'password field should not be present in user object'
assert data['token'] == f"simulated-jwt-token-for-{user['id']}", f"unexpected token {data['token']}"
PY
python_status="$?"
[ "$python_status" = "0" ] || { echo "ASSERTION_FAILED: expected signin response JSON to contain user without password and a matching simulated token"; exit 1; }

echo "STEP: Cleanup — no cleanup required for in-memory service state"
:

echo "CODEVALID_TEST_ASSERTION_OK:signin_success_valid_credentials"
