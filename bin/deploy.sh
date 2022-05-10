#!/usr/bin/env sh
#-*-mode: Shell-script; coding: utf-8;-*-
# SPDX-License-Identifier: BlueOak-1.0.0
# Description: Wrapper script to simplify running deploy-rs/etc...
_base=$(basename "$0")
_dir=$(cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P || exit 126)
export _base _dir

set "${SETOPTS:--eu}"

[ "check" = "${1:-deploy}" ] && nix flake check --show-trace

if [ "Linux" = "$(uname -s)" ]; then
  nix run github:serokell/deploy-rs -- -s .
else
  darwin-rebuild switch --flake .#
fi
