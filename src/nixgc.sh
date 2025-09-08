#!/usr/bin/env sh
#-*-mode: Shell-script; coding: utf-8;-*-
# SPDX-License-Identifier: BlueOak-1.0.0
# Description:
_base=$(basename "$0")
_dir=$(cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P || exit 126)
export _base _dir
set "${SETOPTS:--eu}"

# Don't gc a broken store
nix-store --verify --check-contents --repair

# Month should be good enough...
nix-collect-garbage --delete-older-than 31d

nix-store --gc
nix-store --optimise

# And make sure nothing broke in gc/optimization
nix-store --verify --check-contents --repair
