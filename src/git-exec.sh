#!/usr/bin/env sh
#-*-mode: Shell-script; coding: utf-8;-*-
# Description: run/build wrapper script to find the git clone base or workspace
# base. And then exec stuff from there, this is so that if you're in say
# $CLONE/some/sub/dir blah I can just do git-base cargo build and that will then
# build at the base of the clone/workspace not pwd.
_base=$(basename "$0")
_dir=$(cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P || exit 126)
export _base _dir
set "${SETOPTS:--xe}"

# TODO: So this works in a workspace and clone
toplevel=$(git rev-parse --show-toplevel)

# This points to the clone .git dir if ^^^ fails
clone=$(git rev-parse --absolute-git-dir | sed -e 's|/[.]git.*||')

if [ -e "${toplevel}" ]; then
  printf "note: running in %s\n" "${toplevel}" >&2
  cd "${toplevel}" || exit 126
elif [ -e "${clone}" ]; then
  printf "note: running in %s\n" "${clone}" >&2
  cd "${clone}" || exit 126
else
  printf "note: not in a git clone\n" >&2
  exit 1
fi

exec "$@"
