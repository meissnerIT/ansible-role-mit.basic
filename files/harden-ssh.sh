#!/usr/bin/env bash
# vim: ts=4 sw=4 noet ft=sh
#
# Harden SSH for Debian 11
# Based on https://www.ssh-audit.com/hardening_guides.html#debian_11

set -euo pipefail
preserve_keys=0
# shellcheck disable=2155
declare -r BN=$(basename "$0")

function die {
	echo >&2 "$@"
	exit 1
}

function usage {
	die "Usage: $BN [--preserve-keys] debian11 {/path/to/new.conf}"
}

function ifdiff_replace {
	local src=$1 dst=$2
	diff -q "$src" "$dst" || cat "$src" >"$dst"
}

function keygen {
	local ktype=$1
	shift
	ssh-keygen -t "$ktype" "$@" -f "/etc/ssh/ssh_host_${ktype}_key" -N "" -q
}

function harden_debian11 {
	local conf_out=$1 tmp

	if [[ $preserve_keys -eq 0 ]]; then
		echo "Replace existing SSH keys"
		rm -f /etc/ssh/ssh_host_*
		keygen ed25519
		keygen rsa -b 4096
	fi

	echo "Enable the RSA and ED25519 keys"
	tmp=$(mktemp)
	# shellcheck disable=2064
	trap "rm $tmp" EXIT
	sed -E -e 's:^#+[[:space:]]*(HostKey[[:space:]]+/etc/ssh/ssh_host_)(rsa|ed25519)(_key).*:\1\2\3:g' \
		/etc/ssh/sshd_config >"$tmp"
	ifdiff_replace "$tmp" /etc/ssh/sshd_config

	# Remove small Diffie-Hellman moduli
	awk '$5 >= 3071' /etc/ssh/moduli >"$tmp"
	ifdiff_replace "$tmp" /etc/ssh/moduli

	# Restrict supported key exchange, cipher, and MAC algorithms
	cat >"$conf_out" <<EOC
# Ansible-managed; manual changes will be overwritten!
#
# Restrict key exchange, cipher, and MAC algorithms, as per sshaudit.com hardening guide.
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr
HostKeyAlgorithms ssh-ed25519,ssh-ed25519-cert-v01@openssh.com,sk-ssh-ed25519@openssh.com,sk-ssh-ed25519-cert-v01@openssh.com,rsa-sha2-256,rsa-sha2-512,rsa-sha2-256-cert-v01@openssh.com,rsa-sha2-512-cert-v01@openssh.com
KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512,diffie-hellman-group-exchange-sha256
MACs hmac-sha2-256-etm@openssh.com,hmac-sha2-512-etm@openssh.com,umac-128-etm@openssh.com

EOC
}

function main {
	[[ $# -ge 2 ]] || usage
	if [[ $1 =~ ^--pres ]]; then
		preserve_keys=1
		shift
	elif [[ $1 =~ ^- ]]; then
		usage
	fi
	case $1 in
	debian11)
		[[ $# -eq 2 ]] || usage
		harden_"$1" "$2"
		sshd -t || die "Config test failed"
		;;
	*)
		usage
		;;
	esac
}

main "$@"
builtin unset preserve_keys
