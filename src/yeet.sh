#!/usr/bin/env sh
#-*-mode: Shell-script; coding: utf-8;-*-
# SPDX-License-Identifier: BlueOak-1.0.0
# Description: just wrap the yeet function so I can use yeet in things that
# don't work off of shell functions
_base=$(basename "$0")
_dir=$(cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P || exit 126)
export _base _dir
set "${SETOPTS:--eu}"

#shellcheck source=../static/src/ssh.sh
. ~/src/pub/github.com/mitchty/nix/static/src/ssh.sh

# Make sure this is exported for us to use first
: "${YEET?}"

yeet "$@"
