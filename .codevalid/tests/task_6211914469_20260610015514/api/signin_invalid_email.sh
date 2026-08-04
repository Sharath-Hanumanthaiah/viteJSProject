#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="${CASE_SUFFIX:-$(date +%s)-$$}"
TMP_DIR="$(mktemp -d)"
WHEN_HEADERS="$TMP_DIR/when_headers.txt"
WHEN_BODY="$TMP_DIR/when_body.json"
WHEN_REQUEST_BODY_FILE="$TMP_DIR/when_request.json"
EMAIL="nonexistent.${CASE_SUFFIX}@example.com"
PASSWORD="anyPassword-${CASE_SUFFIX}"
cleanup_files() {
  rm -rf "$TMP_DIR"
}
trap cleanup_files EXIT

cat > "$WHEN_REQUEST_BODY_FILE" <<EOF
{"email":"${EMAIL}","password":"${PASSWORD}"}
EOF

echo "STEP: Given — use a unique email that has not been registered"
:

echo "STEP: When — attempt signin with an email that does not exist"
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

echo "STEP: Cleanup — no cleanup required because no user was created"
:

echo "CODEVALID_TEST_ASSERTION_OK:signin_invalid_email"
