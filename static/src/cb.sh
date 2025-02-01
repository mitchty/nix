#!/usr/bin/env sh
#-*-mode: Shell-script; coding: utf-8;-*-
# SPDX-License-Identifier: BlueOak-1.0.0
# Description: run/build.sh wrapper script
_base=$(basename "$0")
_dir=$(cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P || exit 126)
export _base _dir
set "${SETOPTS:--xeu}"

RELEASE="${RELEASE+true}"
RUSTBUILD="${RUSTBUILD+true}"
NIXBUILD="${NIXTBUILD+true}"

# See if we're in a git clone, get the base workspace dir
if git rev-parse --absolute-git-dir > /dev/null 2>&1; then
  base=$(git rev-parse --absolute-git-dir | sed -e 's|/[.]git.*||')
  printf "info: git worktree is %s\n" "${base}" >&2
  # cd to that dir as that is the base we should be in
  cd "${base}" || exit 126
else
  printf "note: not in a git clone\n" >&2
fi

# See if we are in a rust cargo build dir
if [ -e "Cargo.toml" ]; then
  RUSTBUILD=true
fi

if ${RUSTBUILD:-false}; then
  cargo build --workspace
  if ${RELEASE:-false}; then
    cargo build --workspace --release
  fi
fi

# Or if this is a nix flake use nix build
if [ -e "flake.nix" ]; then
  NIXBUILD=true
fi

if ${NIXBUILD:-false}; then
  nix flake check
  nix build -L
  if ${RELEASE:-false}; then
    nix build -L .#release
  fi
fi
