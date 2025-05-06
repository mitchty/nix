#!/usr/bin/env sh
#-*-mode: Shell-script; coding: utf-8;-*-
# SPDX-License-Identifier: BlueOak-1.0.0
# Description: run/build.sh wrapper script
_base=$(basename "$0")
_dir=$(cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P || exit 126)
export _base _dir
set "${SETOPTS:--xe}"

#shellcheck disable=SC1090
. ~/.config/direnv/direnvrc

dir=$(uniq_cache rust)

install -dm755 "${dir}"

release=debug

if echo "$*" | grep -q release; then
  release=release
fi

# Lockfile is unique per directory we run from.
lockfile="${dir}-${_base}-${release}.lock"

# I want this to expand now dammit
#shellcheck disable=SC2064
trap "rm -f ${lockfile}" EXIT TERM INT QUIT

# Only lock one instance of this cmd
singleton() {
  halockrun -c "${lockfile}" "$@"
}

# See if we're in a git clone, get the base workspace dir
if git rev-parse --absolute-git-dir > /dev/null 2>&1; then
  # TODO being lazy and just rerunning rather than dealing with variables
  base=$(git rev-parse --absolute-git-dir | sed -e 's|/[.]git.*||')
  printf "info: git worktree is %s\n" "${base}" >&2
  # cd to that dir as that is the base we should be in
  cd "${base}" || exit 126
else
  printf "note: not in a git clone\n" >&2
fi

# See if we are in a rust cargo build dir
if [ -e "Cargo.toml" ] && [ -z "${NORUST}" ]; then
  # Make sure we don't use RUST_BACKTRACE for cargo test, don't want a full
  # backtrace for that.
  #
  # Note, we skip doc tests cause they take forever to link/build.
  env -u RUST_BACKTRACE cargo test --lib --bins --tests
  singleton cargo build --workspace --all-targets

  # build release version
  if [ $release = "release" ]; then
    singleton cargo build --workspace --release --all-targets
  fi
fi

# # Or if this is a nix flake use nix build
if [ -e "flake.nix" ] && [ -z "${NONIX}" ]; then
  nix flake check
  nix build -L

  # see if there is a release arg in the arguments
  if [ $release = "release" ]; then
    nix build -L .#release
  fi
fi
