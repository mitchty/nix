#!/usr/bin/env sh
#-*-mode: Shell-script; coding: utf-8;-*-
# SPDX-License-Identifier: BlueOak-1.0.0
# Description: Wat The Frell is going on? And maybe try to fix it.
_base=$(basename "$0")
_dir=$(cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P || exit 126)
export _base _dir
set "${SETOPTS:--eu}"

# No idea how we get to this state but can get to a metric, not imperial butt
# load of diskimages-helper processes. So kill em all.
#
# Using gt 10 for the "too many" rubicon.
if [ "$(pgrep -lif diskimages-helper | wc -l)" -gt 10 ]; then
  printf "Too many diskimages-helper process, something probably horked killing them all cause reasons\n" >&2
  pkill -lif diskimages-helper
fi
