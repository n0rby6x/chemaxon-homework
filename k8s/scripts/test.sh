#!/usr/bin/env bash

set -euo pipefail

URL="${URL:-http://localhost:8080/hello-world}"

echo "Testing: $URL"

response="$(curl --fail --silent "$URL")"

echo "Response:"
echo "$response"

expected='{"message":"Hello World"}'

if [[ "$response" != "$expected" ]]; then
  echo
  echo "ERROR: Unexpected response."
  echo "Expected: $expected"
  echo "Actual:   $response"
  exit 1
fi

echo
echo "SUCCESS: REST endpoint returned the expected response."