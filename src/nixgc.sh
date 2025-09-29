#!/usr/bin/env sh
#-*-mode: Shell-script; coding: utf-8;-*-
# SPDX-License-Identifier: BlueOak-1.0.0
# Description:
_base=$(basename "$0")
_dir=$(cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P || exit 126)
export _base _dir
set "${SETOPTS:--eu}"

run() {
  echo "$*"
  "$@"
}

verify() {
  # Don't gc a broken store
  run nix-store --verify --check-contents --repair
}

# Only gc a store that isn't broken
verify

# Month should be good enough...
run nix-collect-garbage --delete-older-than 31d

run nix-store --gc
run nix-store --optimise

# And make sure nothing broke in gc/optimization along the way
verify
