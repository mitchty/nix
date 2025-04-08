#!/usr/bin/env nix-shell
#!nix-shell -i bash -p coreutils gdb
#-*-mode: Shell-script; coding: utf-8;-*-
# SPDX-License-Identifier: BlueOak-1.0.0
# Description: Abuse gdb for evil to try to kill a process and force
# it to exit 0 via evil.
_base=$(basename "$0")
_dir=$(cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P || exit 126)
export _base _dir
set "${SETOPTS:--eu}"

case "$(uname -s)" in
  Linux)
    case "$(uname -m)" in
      x86_64)
        # Note, we set rdi to 0 so $? won't be useful after using this >.<
        gdb -p "$1" -batch -ex 'set {short}$rip = 0x050f' -ex 'set $rax=231' -ex 'set $rdi=0' -ex 'cont'
        ;;
      aarch64)
        # ditto here but for arm64 set x0 to 0 as well
        gdb -p "$1" -batch -ex 'set {int}$pc = 0xd4000001' -ex 'set $w8=94' -ex 'set $x0=0' -ex 'cont'
        ;;
      *)
        printf "fatal: evil for arch %s not yet implemented\n" "$(uname -m)" >&2
        ;;
    esac
    ;;
  *)
    printf "fatal: evil only implemented for linux\n" >&2
    ;;
esac
