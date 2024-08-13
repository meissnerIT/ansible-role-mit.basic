#!/usr/bin/env bash
# vim: ts=4 sw=4 noet ft=sh
#
# Remove all existing (potentially weak) SSH host keys,
# then generate new, strong ones.

set -euo pipefail
declare -r HOSTKEY_PREFIX=/etc/ssh/ssh_host_

function usage {
	echo >&2 "Usage: $(basename "$0") {completion-flag-file}"
	exit 1
}

function keygen {
	# keygen {key-type} [argument ...]
	local key_type=$1
	shift
	ssh-keygen -t "$key_type" "$@" -f "${HOSTKEY_PREFIX}${key_type}_key" -N "" -q
}

function main {
	local flag=$1
	[[ $flag != help ]] || usage
	rm -f ${HOSTKEY_PREFIX}*
	keygen ed25519
	keygen rsa -b 4096
	touch "$flag"
}

[[ $# -eq 1 ]] || usage
main "$@"
