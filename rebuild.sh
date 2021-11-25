#!/usr/bin/env sh
#-*-mode: Shell-script; coding: utf-8;-*-
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
as_root nixos-rebuild switch --flake .#

# Not sure this makes sense to run the same way as both $USER/root...
nix build ".#homeManagerConfigurations.${USER}.activationPackage"
"${_dir}/result/activate"
rm -fr result
exit $?
