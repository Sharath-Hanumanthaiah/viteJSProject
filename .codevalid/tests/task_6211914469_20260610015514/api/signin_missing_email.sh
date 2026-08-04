#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="${CASE_SUFFIX:-$(date +%s)-$$}"
TMP_DIR="$(mktemp -d)"
WHEN_HEADERS="$TMP_DIR/when_headers.txt"
WHEN_BODY="$TMP_DIR/when_body.json"
WHEN_REQUEST_BODY_FILE="$TMP_DIR/when_request.json"
cleanup_files() {
  rm -rf "$TMP_DIR"
}
trap cleanup_files EXIT

cat > "$WHEN_REQUEST_BODY_FILE" <<EOF
{"password":"somePassword-${CASE_SUFFIX}"}
EOF

echo "STEP: Given — prepare a signin request without an email field"
:

echo "STEP: When — submit signin request missing email"
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

echo "STEP: Then — assert validation rejects missing email"
[ "$when_status" = "400" ] || { echo "ASSERTION_FAILED: expected HTTP 400 got ${when_status}"; exit 1; }
grep -F '"message":"Email and password are required."' "$WHEN_BODY" >/dev/null || { echo "ASSERTION_FAILED: expected validation message for missing email and password"; exit 1; }

echo "STEP: Cleanup — no cleanup required for stateless negative request"
:

echo "CODEVALID_TEST_ASSERTION_OK:signin_missing_email"
