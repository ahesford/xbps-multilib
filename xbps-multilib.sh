#!/bin/sh

die() {
	echo ERROR: $@
	exit 1
}

# 
: ${XBPS_MULTILIB_ROOT:=/usr}

# XBPS_ARCH and command are derived from the base name
XBPS_CMD="${0##*/}"
# Strip command suffix to arrive at XBPS_ARCH
XBPS_ARCH="${XBPS_CMD%%-xbps-*}"
# Strip the XBPS_ARCH prefix to arrive at command
XBPS_CMD="${XBPS_CMD#${XBPS_ARCH}-}"

if [ "$XBPS_ARCH" = "$0" ] || [ -z "$XBPS_ARCH" ]; then
	die "unable to determine XBPS_ARCH"
fi

if [ "$XBPS_CMD" = "$0" ] || [ -z "$XBPS_CMD" ]; then
	die "unable to determine XBPS command"
fi

if [ ! command -v "$XBPS_CMD" >/dev/null 2>&1 ]; then
	die "unable to execute '$XBPS_CMD'"
fi

if ! xbps_root=$(readlink -f "${XBPS_MULTILIB_ROOT}/${XBPS_ARCH}"); then
	die "failed to canonicalize multilib path"
fi

if [ ! -d "$xbps_root" ]; then
	die "multilib root '$xbps_root' does not exist"
fi

if [ -d "${xbps_root}/etc/xbps.d" ]; then
	xbps_config="${xbps_root}/etc/xbps.d"
fi

export XBPS_ARCH
"$XBPS_CMD" -r "$xbps_root" ${xbps_config+-C "$xbps_config"} "$@"
