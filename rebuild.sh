#!/usr/bin/env nix-shell
#-*-mode: Shell-script; coding: utf-8;-*-
#!nix-shell -i bash -p bash git
# NOTE: home-manager missing from ^^ -p(ackage) list in lieu of system's until
# the base nixpkgs includes flake support by default.
# File: rebuild.sh
_base=$(basename "$0")
_dir=$(cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P || exit 126)
export _base _dir

cd "${_dir}" || exit 126

# Don't sudo when we don't need it sudo as root is... rather sad
as_root() {
  if [ "root" = "$(id -un)" ]; then
    "$@"
  else
    sudo "$@"
  fi
}

cleanup() {
  rm -fr "${_dir}/result"
}

trap cleanup EXIT

set -e
as_root nixos-rebuild switch --flake .#
home-manager switch --flake .

exit $?
