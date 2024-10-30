#!/usr/bin/env sh
#-*-mode: Shell-script; coding: utf-8;-*-
# SPDX-License-Identifier: BlueOak-1.0.0
# Description: Dumb wrapper around making notifications on macos via
# osascript and kdialog for linux (for now at least)
_base=$(basename "$0")
_dir=$(cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P || exit 126)
export _base _dir
set "${SETOPTS:--e}"

iam=$(uname -s)
title=${1?need at least one arg for a title}
shift

case "${iam}" in
  Linux)
    # No sense in trying to use an X app without X
    if [ -n "$DISPLAY" ]; then
      kdialog --title "${title}" --passivepopup "$@" 2> /dev/null
    fi
    ;;
  Darwin)
    osascript << END
display notification "$@" ${title}
END
    ;;
  *)
    printf "fatal: unknown os type %s\n" "${iam}"
    exit 1
    ;;
esac
