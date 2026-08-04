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
USERNAME="signin-invalid-password-${CASE_SUFFIX}"
EMAIL="signin.invalid.password.${CASE_SUFFIX}@example.com"
CORRECT_PASSWORD="correctPassword"
WRONG_PASSWORD="wrongPassword"
FULL_NAME="Invalid Password ${CASE_SUFFIX}"
cleanup_files() {
  rm -rf "$TMP_DIR"
}
trap cleanup_files EXIT

cat > "$SIGNUP_REQUEST_BODY_FILE" <<EOF
{"username":"${USERNAME}","email":"${EMAIL}","password":"${CORRECT_PASSWORD}","fullName":"${FULL_NAME}"}
EOF

cat > "$WHEN_REQUEST_BODY_FILE" <<EOF
{"email":"${EMAIL}","password":"${WRONG_PASSWORD}"}
EOF

echo "STEP: Given — create a user with a known correct password"
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

echo "STEP: When — attempt signin with the wrong password"
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

echo "STEP: Then — assert generic invalid-credentials response"
[ "$when_status" = "401" ] || { echo "ASSERTION_FAILED: expected HTTP 401 got ${when_status}"; exit 1; }
grep -F '"message":"Invalid email or password."' "$WHEN_BODY" >/dev/null || { echo "ASSERTION_FAILED: expected generic invalid credentials message"; exit 1; }

echo "STEP: Cleanup — no cleanup required for in-memory service state"
:

echo "CODEVALID_TEST_ASSERTION_OK:signin_invalid_password"
