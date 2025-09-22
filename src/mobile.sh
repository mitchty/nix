#!/usr/bin/env sh
#-*-mode: Shell-script; coding: utf-8;-*-
# SPDX-License-Identifier: BlueOak-1.0.0
# Description: Script to "do crap" to my nix config at runtime.
#
# Mostly just here to (un)comment out lines as needed when my laptops not at
# home so some stuff makes less sense like abusing my proxy nix caching setup.
_base=$(basename "$0")
_dir=$(cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P || exit 126)
export _base _dir
set "${SETOPTS:--eu}"

cd "${_dir}/.." || exit 126

# Script should have on/off as args, on is assumed by default, extra args ignored
action="${1:-on}"

ok=0

help() {
  printf "fatal: run me with either no args or (on|off)" >&2
  ok=42
}

AWK="${AWK:-awk}"

files=nix/crossplatformModules/nix.nix

case "${action}" in
  on)
    for file in $files; do
      ${AWK} -i inplace '/MOBILE_START/{flag=1; print; next} /MOBILE_END/{flag=0; print; next} {print (flag?"#":"") $0}' "${file}"
      ok=$((ok + $?))
    done
    ;;
  off)
    for file in $files; do
      ${AWK} -i inplace '/MOBILE_START/{flag=1; print; next} /MOBILE_END/{flag=0; print; next} {if (flag == 1) {gsub(/#/, "")} else {}; print;}' "${file}"
      ok=$((ok + $?))
    done
    ;;
  help)
    help
    ;;
  *)
    help
    ;;
esac

exit $ok
