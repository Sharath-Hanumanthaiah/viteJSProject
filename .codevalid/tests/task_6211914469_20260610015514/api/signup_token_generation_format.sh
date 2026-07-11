#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
USERNAME="tokenuser-${CASE_SUFFIX}"
EMAIL="token-${CASE_SUFFIX}@test.com"
PASSWORD="tokenpass"
FULL_NAME="Token Test ${CASE_SUFFIX}"
RESPONSE_FILE="/tmp/signup_token_generation_format_${CASE_SUFFIX}.json"
STATUS_FILE="/tmp/signup_token_generation_format_${CASE_SUFFIX}.status"
cleanup_files() {
  rm -f "$RESPONSE_FILE" "$STATUS_FILE"
}
trap cleanup_files EXIT

# Given — prepare unique signup payload for token validation
:

# When — submit successful signup request
curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/auth/signup" \
  -H 'Content-Type: application/json' \
  --data "{\"username\":\"${USERNAME}\",\"email\":\"${EMAIL}\",\"password\":\"${PASSWORD}\",\"fullName\":\"${FULL_NAME}\"}" \
  > "$STATUS_FILE"

# Then — expect token format to include the returned user id
STATUS="$(cat "$STATUS_FILE")"
[ "$STATUS" = "201" ]
USER_ID="$(python3 - <<'PY' "$RESPONSE_FILE"
import json, sys
with open(sys.argv[1], 'r', encoding='utf-8') as fh:
    data = json.load(fh)
print(data['user']['id'])
PY
)"
TOKEN="$(python3 - <<'PY' "$RESPONSE_FILE"
import json, sys
with open(sys.argv[1], 'r', encoding='utf-8') as fh:
    data = json.load(fh)
print(data['token'])
PY
)"
[ -n "$USER_ID" ]
[ "$TOKEN" = "simulated-jwt-token-for-${USER_ID}" ]
grep -F "\"username\":\"${USERNAME}\"" "$RESPONSE_FILE" >/dev/null
grep -F "\"email\":\"${EMAIL}\"" "$RESPONSE_FILE" >/dev/null
if grep -F '"password":' "$RESPONSE_FILE" >/dev/null; then
  echo "password should not be returned in signup response"
  exit 1
fi

echo "CODEVALID_TEST_ASSERTION_OK:signup_token_generation_format"

# Cleanup — no delete endpoint exists for users in this in-memory API; unique data prevents collisions and state resets with container lifecycle
