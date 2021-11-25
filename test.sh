#!/usr/bin/env sh
#-*-mode: Shell-script; coding: utf-8;-*-
# File: rebuild.sh
_base=$(basename "$0")
_dir=$(cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P || exit 126)
export _base _dir

cd "${_dir}" || exit 126

set -e
nixos-rebuild build --flake .#
nix build --show-trace ".#homeManagerConfigurations.${USER}.activationPackage"
exit $?
