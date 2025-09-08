#!/usr/bin/env sh
#-*-mode: Shell-script; coding: utf-8;-*-
# SPDX-License-Identifier: BlueOak-1.0.0
# Description: cargo run wrapper that can find the git clone base to work transparently
_base=$(basename "$0")
_dir=$(cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P || exit 126)
export _base _dir

RELEASE="${RELEASE+true}"
RUSTBUILD="${RUSTBUILD+true}"
CARGO="${CARGO:-cargo}"
GIT="${GIT:-git}"

log() {
  if [ "${VERBOSE:-false}" ]; then
    # log is a trampoline around printf
    #shellcheck disable=SC2059
    printf "$@" >&2
  fi
}

info() {
  log "info: "
  log "$@"
}

fatal() {
  prime=$1
  shift
  log "fatal: $prime" "$@"
  exit 2
}

# See if we're in a git clone, get the base workspace dir
if ${GIT} rev-parse --absolute-git-dir > /dev/null 2>&1; then
  base=$(${GIT} rev-parse --absolute-git-dir | sed -e 's|/[.]git.*||')
  info "running from %s\n" "${base}"
  # cd to that dir as that is the base we should be in
  cd "${base}" || exit 126
else
  fatal "not in a git clone\n"
fi

# See if we are in a rust cargo build dir
if [ -e "Cargo.toml" ]; then
  RUSTBUILD=true
fi

if ${RUSTBUILD:-false}; then
  args=""
  # TODO: keep this even tbh seems unnecessary maybe make a copy/symlink of
  # like crr and test that $0 is that instead or just stick with cr --release?
  # I might be overengineering this dum af script.

  if [ "${1}" = "--release" ]; then
    shift
    args="--release"
  fi
  args="${args} -- $*"

  cmd="${CARGO} run ${args}"
  info "${cmd}\n"
  ${cmd}
fi
