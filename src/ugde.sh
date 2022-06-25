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
    sleep 1
    _dots=$((_dots + 1))
    printf "." >&2
}

# Used from lib.sh functions
#shellcheck disable=SC2034
LIMITERFN=iterit

failit() {
    if [ "${_dots}" -gt 0 ]; then
        printf "\n" >&2
    fi
    # printf "fatal: %s\n" "$*" >&2
}

# Used from lib.sh functions
#shellcheck disable=SC2034
LIMITERFAILFN=failit
okit() {
    if [ "${_dots}" -gt 0 ]; then
        printf "\n" >&2
    fi
    # printf "ok: %s\n" "$*" >&2
}

# Used from lib.sh functions
#shellcheck disable=SC2034
LIMITEROKFN=okit

# Until Git Diff Equal
# Because syncthing is SLOW (seconds....) to sync, compare local changes to a remote and only return when they're the same git diff (by sha256sum of the diff itself)
until [ "$(ssh nexus.home.arpa 'cd ~/src/pub/github.com/mitchty/nix && git diff 2> /dev/null | sha256sum')" = "$(gi mitchty/nix 2> /dev/null && git diff 2> /dev/null| sha256sum)" ]; do
  printf "." >&2
  rsleep 3
done
printf "\n" >&2
