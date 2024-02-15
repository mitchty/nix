#!/usr/bin/env sh
#-*-mode: Shell-script; coding: utf-8;-*-
# SPDX-License-Identifier: BlueOak-1.0.0
# Description: Just a dum af wrapper around vpn-hack.sh
_base=$(basename "$0")
_dir=$(cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P || exit 126)
export _base _dir
set "${SETOPTS:--eu}"

# Just a quick hack to let me specify multiple files to the hack script.
for f in "$@"; do
  if [ -e "${f}" ]; then
    "${_dir}/../src/vpn-hack.sh" < "${f}"
  fi
done
