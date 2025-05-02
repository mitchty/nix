#!/usr/bin/env nix-shell
#-*-mode: Shell-script; coding: utf-8;-*-
#!nix-shell -i bash -p bash jq coreutils curl htmlq
# File: update-versions.sh
# Description: copy/pasta to update package versions automatically and commit them.
_base=$(basename "$0")
_dir=$(cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P || exit 126)
export _base _dir

set -eu

${SETOPTS:+set ${SETOPTS}}

# TODO: for now just look for certain things, future me figure out how to nix
# eval what packages are present in the flake.

${DIR:+cd $DIR}

# Check that there are no uncommitted changes exit if any uncommitted
# changes present. Note rando files not applicable, only changes to
# tracked stuff.
#
# Abusing git commit -u to be sure any changes/updates only apply to
# the specific package nix-update updated.
if ! git diff-index --quiet HEAD; then
  printf "local git changes, refusing to continue.\n" >&2
  exit 2
fi

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
  if nix eval --raw ".#${pkg}.latest" 2> /dev/null; then
    evalstring=$(nix eval --raw ".#${pkg}.latest" 2> /dev/null)
    latest=$(eval "${evalstring}")
    ours=$(nix eval --raw ".#${pkg}.version" 2> /dev/null)

    if [ "$?" -eq 0 ]; then
      if [ "${latest}" != "${ours}" ]; then
        printf "%s latest version out of date: ours=%s latest=%s\n" "${pkg}" "${ours}" "${latest}" >&2
        printf "nix run github:MiC92/nix-update -- --flake %s --version %s\n" "${pkg}" "${latest}"
        nix-update --flake "${pkg}" --version "${latest}"
        nix build .#${pkg}
        git add -u
        git commit -m "${pkg} ${latest}"
      fi
    fi
  fi
done
