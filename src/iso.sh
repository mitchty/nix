#!/usr/bin/env sh
#-*-mode: Shell-script; coding: utf-8;-*-
# SPDX-License-Identifier: BlueOak-1.0.0
# Description: Wrapper script to simplify running deploy-rs/etc...
_base=$(basename "$0")
_dir=$(cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P || exit 126)
export _base _dir

set "${SETOPTS:--eu}"

cd "${_dir}/.." || exit 126

runtime=$(date +%Y-%m-%d-%H:%M:%S)
for x in "$@"; do
  # This is useless here NIXOPTS when null shouldn't be in argv
  #shellcheck disable=SC2086
  nix build ${NIXOPTS-} ".#${_base}${x}"
  install -dm755 img
  lnsrc="img/${x}@${runtime}.${_base}"
  lndst="img/${x}.${_base}"
  #shellcheck disable=SC2086
  install -m444 "$(find -L result -type f -name '*.'${_base})" "${lnsrc}"
  ln -f "${lnsrc}" "${lndst}"
done

# Make sure we don't have duplicate iso files, or if we do make them hardlinks
[ -d img ] && nix-shell -p rdfind --run 'rdfind -deterministic true -makeresultsfile false -makehardlinks true img'
