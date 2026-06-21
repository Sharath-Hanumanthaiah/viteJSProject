#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
RESPONSE_FILE="/tmp/form_validation_required_fields_${CASE_SUFFIX}.json"

cleanup() {
  rm -f "$RESPONSE_FILE"
}
trap cleanup EXIT

# Given — Registration endpoint is reachable.
HEALTH_STATUS="$(curl -sS -o /dev/null -w '%{http_code}' "$BASE_URL/health")"
[ "$HEALTH_STATUS" = "200" ]

# When — Submit a registration with a missing required name.
HTTP_STATUS="$(curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/registrations" \
  -H 'Content-Type: application/json' \
  --data '{"eventId":"evt-002","name":"","email":"user@test.com","phone":"+1-555-111-2222"}')"

# Then — API returns the required-fields validation error.
[ "$HTTP_STATUS" = "400" ]
jq -e '.message == "Event, name, email, and phone number are required."' "$RESPONSE_FILE" >/dev/null

# Cleanup — No side effects.

echo "CODEVALID_TEST_ASSERTION_OK:form_validation_required_fields"
