#!/usr/bin/env sh
#-*-mode: Shell-script; coding: utf-8;-*-
# File: fmt.sh
_base=$(basename "$0")
_dir=$(cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P || exit 126)
export _base _dir

nix-shell -p nixpkgs-fmt --run "find ${_dir} -type f -name *.nix | xargs nixpkgs-fmt"
