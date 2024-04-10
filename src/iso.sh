#!/usr/bin/env sh
#-*-mode: Shell-script; coding: utf-8;-*-
# SPDX-License-Identifier: BlueOak-1.0.0
# Description: Wrapper script to simplify running deploy-rs/etc...
_base=$(basename "$0")
_dir=$(cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P || exit 126)
export _base _dir

set "${SETOPTS:--eux}"

cd "${_dir}/.." || exit 126

runtime=$(date +%Y-%m-%d-%H:%M:%S)
for x in "$@"; do
  # This is useless here NIXOPTS when null shouldn't be in argv
  #shellcheck disable=SC2086
  nix build ${NIXOPTS-} ".#${x}"
  install -dm755 img
  iso=$(find -L result -type f -name '*.iso')
  baseiso=$(basename "${iso}")
  isoprefix="img/${runtime}"
  isodst="${isoprefix}/${baseiso}"
  # isoln="img/${baseiso}"

  install -dm755 "${isoprefix}"
  install -m400 "${iso}" "${isodst}"
  ln -sf "${isodst}" "img/${x}"

  # install -m444 "${iso}" "${isoln}"

  # lnsrc="img/${x}@${runtime}"
  # lndst="img/${x}"

  # for hl in ${lnsrc} ${lndst}; do
  #   #shellcheck disable=SC2086
  #   ln -f "${isoln}" "${hl}"
  # done
done

# Make sure we don't have duplicate iso files, or if we do make them hardlinks
[ -d img ] && nix-shell -p rdfind --run 'rdfind -deterministic true -makeresultsfile false -makehardlinks true img'
