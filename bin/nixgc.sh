#!/usr/bin/env sh
#-*-mode: Shell-script; coding: utf-8;-*-
# SPDX-License-Identifier: BlueOak-1.0.0
# Description:
_base=$(basename "$0")
_dir=$(cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P || exit 126)
export _base _dir
set "${SETOPTS:--eu}"

# We run this twice to catch if/when say result dir gets updated/removed so we
# can recover that gc root and delete any garbage from it
nix-collect-garbage --delete-older-than 31d
nix-store --gc
nix-store --optimise
