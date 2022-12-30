#!/usr/bin/env sh
#-*-mode: Shell-script; coding: utf-8;-*-
# SPDX-License-Identifier: BlueOak-1.0.0
# Description: Until Git Diff Equal, cause syncthing is slow af at syncing single text files less than 4k... so we wait, and wait and wait
_base=$(basename "$0")
_dir=$(cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P || exit 126)
export _base _dir

set "${SETOPTS:--eu}"

#shellcheck source=../static/src/lib.sh
. ~/src/pub/github.com/mitchty/nix/static/src/lib.sh

_dots=0

_time=0

startit() {
  _time=$(date +%s)
  # printf "start: %s\n" "$*" >&2
}

# Used from lib.sh functions
#shellcheck disable=SC2034
LIMITERINITFN=startit

iterit() {
  rsleep 3
  _dots=$((_dots + 1))
  printf "." >&2
}

newline() {
  if [ "${_dots}" -gt 0 ]; then
    printf "\n" >&2
  fi
}

# Used from lib.sh functions
#shellcheck disable=SC2034
LIMITERFN=iterit

# Used from lib.sh functions
#shellcheck disable=SC2034
LIMITERFAILFN=newline

# Used from lib.sh functions
#shellcheck disable=SC2034
LIMITEROKFN=newline

cwd=$(pwd)
ok=0
cnt=1

# Basically just loop through each node making sure the remote git diff
# sha256sum = local checksum, loop until it is. Then let something else run
# after this to "do stuff" knowing its up to date.
until [ "${ok}" -eq "${cnt}" ]; do
  ok=0
  cnt=0

  # Yeah I know its for future, not a problem.
  #shellcheck disable=SC2043
  for host in srv.home.arpa; do
    cnt=$((cnt + 1))
    rem="$(ssh -q ${host} 'cd '"${cwd}"' && git diff 2> /dev/null | sha256sum')"
    if [ "${rem}" = "$(git diff 2> /dev/null | sha256sum)" ]; then
      ok=$((ok + 1))
    fi
  done

  if [ "${ok}" -ne "${cnt}" ]; then
    iterit
  fi
done

newline
