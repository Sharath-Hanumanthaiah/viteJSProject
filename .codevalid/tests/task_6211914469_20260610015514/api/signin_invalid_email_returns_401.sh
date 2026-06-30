#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="${CASE_SUFFIX:-$(date +%s)-$$}"
TMP_DIR="$(mktemp -d)"
RESPONSE_FILE="$TMP_DIR/response.json"
STATUS_FILE="$TMP_DIR/response.status"
cleanup_files() { rm -rf "$TMP_DIR"; }
trap cleanup_files EXIT

# Given — choose an email that is unique to this test and therefore not registered
EMAIL="nonexistent.${CASE_SUFFIX}@unknown.com"
cat >"$TMP_DIR/request.json" <<EOF
{"email":"${EMAIL}","password":"anypassword-${CASE_SUFFIX}"}
EOF

# When — submit signin request with a non-existent email
curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/auth/signin" \
  -H 'Content-Type: application/json' \
  --data @"$TMP_DIR/request.json" > "$STATUS_FILE"

# Then — verify invalid credentials response
STATUS="$(cat "$STATUS_FILE")"
[ "$STATUS" = "401" ]
python3 - "$RESPONSE_FILE" <<'PY'
import json, sys
with open(sys.argv[1], 'r', encoding='utf-8') as fh:
    data = json.load(fh)
assert data.get('message') == 'Invalid email or password.'
PY

echo "CODEVALID_TEST_ASSERTION_OK:signin_invalid_email_returns_401"

# Cleanup — stateless request; no cleanup required
