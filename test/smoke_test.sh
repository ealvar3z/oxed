#!/bin/sh

set -u

if [ "$#" -eq 0 ]; then
	echo "usage: $0 executable [args...]" >&2
	exit 2
fi

before=$(stty -g) || exit 1

dune exec "$@"
status=$?

after=$(stty -g) || exit 1

if [ "$before" = "$after" ] && [ "$status" -eq 0 ]; then
	echo PASS
else
	printf 'FAIL (exit=%s)\n' "$status" >&2
	exit 1
fi

