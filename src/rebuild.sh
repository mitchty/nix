#!/usr/bin/env sh
#-*-mode: Shell-script; coding: utf-8;-*-
# SPDX-License-Identifier: BlueOak-1.0.0
# Description: Wrapper script to simplify running deploy-rs or whatever locally
# to rebuild the local node only from a flake checkout.
_base=$(basename "$0")
_dir=$(cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P || exit 126)
export _base _dir

set "${SETOPTS:--eu}"

# Note args are just what we would pass directly into nix build or
# darwin-rebuild... this is just an easier way to use whichever is right for
# each platform.

# Only check flake if CHECK is set
[ -z "${CHECK:-}" ] && nix flake check --show-trace "$@"

if [ "Linux" = "$(uname -s)" ]; then
  nix run github:serokell/deploy-rs -- -s .
else
  darwin-rebuild switch --flake .# "$@"
fi
