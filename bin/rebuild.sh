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

set -e

uname_s="$(uname -s)"
args="--show-trace switch --flake .#"

set -x
# Rebuild based on system type
if [[ "${uname_s}" = "Darwin" ]]; then
  darwin-rebuild ${args}
elif [[ "${uname_s}" = "Linux" ]]; then
  as_root nixos-rebuild ${args}
else
  printf "fatal: not yet configured for an os type of %s" "${uname_s}"
  exit 1
fi

exit $?
