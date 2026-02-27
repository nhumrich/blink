#!/bin/sh
# Run a single test file using pact test
f="$1"
pact="$2"
name=$(basename "$f" .pact)
if output=$("$pact" test "$f" 2>&1); then
  if echo "$output" | grep -q "FAIL"; then
    echo "FAIL (assert) ${name}"
    exit 1
  else
    echo "PASS ${name}"
  fi
else
  echo "FAIL (test) ${name}"
  exit 1
fi
