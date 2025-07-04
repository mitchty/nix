#!/usr/bin/env sh
#-*-mode: Shell-script; coding: utf-8;-*-
# SPDX-License-Identifier: BlueOak-1.0.0
# Description: Just a dum wrapper for me to use in hwatch to monitor mutagen
_base=$(basename "$0")
_dir=$(cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P || exit 126)
export _base _dir
set "${SETOPTS:--eu}"

for x in rtx wm2 srv mb ark; do
  echo $x
  mutagen sync list src-${x} -l | grep -Ev '^[-]+$' | grep -Ev '.*symbolic.*' | tail -n 3
done
