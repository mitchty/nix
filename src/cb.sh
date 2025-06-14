#!/usr/bin/env sh
#-*-mode: Shell-script; coding: utf-8;-*-
# SPDX-License-Identifier: BlueOak-1.0.0
# Description: run/build.sh wrapper script
_base=$(basename "$0")
_dir=$(cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P || exit 126)
export _base _dir
set "${SETOPTS:--e}"

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
  # For each target, run the test targets BUT ignore doctests
  # TODO: have a FULL env var to control if I run full test suite or not?

  # Since there isn't a --no-doctest, parse through all the other types of tests
  # in cargo metadata, then construct our cargo test command to run what is
  # there sans that stuff cause it takes forever and ass ages to run doctests
  # for some stuff.

  for k in $(cargo metadata --format-version 1 --no-deps | jq -r '
    .packages[].targets[]
    | select(.kind[] | IN("lib", "bin", "test", "example"))
    | "\(.kind[])"'); do

    if [ "${k}" = "bin" ]; then
      bins=true
    elif [ "${k}" = "lib" ]; then
      libs=true
    elif [ "${k}" = "test" ]; then
      tests=true
    elif [ "${k}" = "example" ]; then
      examples=true
    else
      printf "fatal: unknown cargo test kind %s refusing to continue fixme\n" "${k}" >&2
      exit 1
    fi
  done

  env -u RUST_BACKTRACE cargo test ${bins+--bins }${libs+--lib }${tests+--tests }${examples+--examples}

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
