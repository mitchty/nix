#!/usr/bin/env sh
#-*-mode: Shell-script; coding: utf-8;-*-
# SPDX-License-Identifier: BlueOak-1.0.0
# Description: Create an sd image from the flake
_base=$(basename "$0")
_dir=$(cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P || exit 126)
export _base _dir

SETOPTS="${SETOPTS:--eu}"

cd "${_dir}/.." || exit 126

runtime=$(date +%Y-%m-%d-%H:%M:%S)
for x in "$@"; do
  nix build ".#sd${x}"
  install -dm755 img
  lnsrc="img/${x}@${runtime}.img.zst"
  lndst="img/${x}.img.zst"
  install -m444 "$(find result -type f -name '"*.img.zst')" "${lnsrc}"
  ln -f "${lnsrc}" "${lndst}"
done

# Make sure we don't have duplicate files, or if we do make them hardlinks
[ -d img ] && nix-shell -p rdfind --run 'rdfind -deterministic true -makeresultsfile false -makehardlinks true img'
