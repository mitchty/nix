#!/usr/bin/env nix-shell
#-*-mode: Shell-script; coding: utf-8;-*-
#!nix-shell -i bash -p bash jq coreutils curl htmlq
# File: versions.sh
# Copyright: 2022 Mitchell Tishmack
# Description: Script for ci to run to see if any specific package(s) have newer versions
_base=$(basename "$0")
_dir=$(cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P || exit 126)
export _base _dir

${SETOPTS:+set ${SETOPTS}}

# TODO: for now just look for certain things, future me figure out how to nix
# eval what packages are present in the flake.

ok=0

${DIR:+cd $DIR}

uname_s=$(uname -s)
uname_m=$(uname -m)

if [ "${uname_s}" = "Linux" ]; then
  arch="${uname_m}-linux"
elif [ "${uname_s}" = "Darwin" ]; then
  # nix platform arch is named aarch64 not arm64 like uname returns on macos
  if [ "${uname_m}" = "arm64" ]; then
    arch="aarch64-darwin"
  else
    arch="${uname_m}-darwin"
  fi
fi

# 2> /dev/null to nuke the stderr warning: messages
for pkg in $(nix flake show --json 2> /dev/null | jq -r '.packages."'${arch}'" | keys[]'); do
  evalstring=$(nix eval --raw ".#${pkg}.latest" 2> /dev/null)
  if [ "$?" -eq 0 ]; then
    latest=$(eval "${evalstring}")
    ours=$(nix eval --raw ".#${pkg}.version" 2> /dev/null)

    if [ "$?" -eq 0 ]; then
      if [ "${latest}" != "${ours}" ]; then
        printf "%s latest version out of date: ours=%s latest=%s\n" "${pkg}" "${ours}" "${latest}" >&2
        printf "nix-update --flake %s --version %s\n" "${pkg}" "${latest}"
        ok=$((ok + 1))
      else
        if [ -n "${VERBOSE}" ]; then
          printf "%s have=%s latest=%s\n" "${pkg}" "${ours}" "${latest}" >&2
        fi
      fi
    fi
  fi
done

exit $ok
