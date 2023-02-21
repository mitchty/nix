#!/usr/bin/env sh
#-*-mode: Shell-script; coding: utf-8;-*-
# SPDX-License-Identifier: BlueOak-1.0.0
# Description: Cause sometimes I'm at a coffee shoppe with conflicting ip ranges
# to stuff in/on vpn and need to route internal traffic to it.
#
# e.g. one coffee shoppe has a 10.0.0.0/24 range (yeah... its derp)
_base=$(basename "$0")
_dir=$(cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P || exit 126)
export _base _dir
set "${SETOPTS:--eu}"

vpniface="${vpniface:-utun2}"
route="${route:=/sbin/route}"

add_one_thing() {
  sudo "${route}" add "${1?}" -interface "${vpniface}"
}

# don't do a dns lookup if something is an ip address
ipv4() {
  echo "${1?}" | grep '^[.0-9]*$' > /dev/null 2>&1
}

add_thing() {
  thing="${1}"

  if ! ipv4 "${thing}"; then
    thing=$(dig +noall +answer +short "${thing}" | grep '^[.0-9]*$')
  fi
  add_one_thing "${thing}"
}

# Args as inputs first
for thing in "$@"; do
  add_thing "${thing}"
done

# iff stdin loop off it for inputs
if [ ! -t 0 ]; then
  # eff off shellcheck i'm not using read for this
  #shellcheck disable=SC2013
  for thing in $(cat /dev/stdin); do
    add_thing "${thing}"
  done
fi
