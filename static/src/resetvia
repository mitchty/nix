#!/usr/bin/env sh
#-*-mode: Shell-script; coding: utf-8;-*-
# SPDX-License-Identifier: BlueOak-1.0.0
# Description: Cause every time (almost) you go off external display the damn
# window stays off screen unless you have a display size gihugic enough to show
# it. So force system events to set the position to 0,0 so you can you know
# interact with it in case its prompting you for some data.
_base=$(basename "$0")
_dir=$(cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P || exit 126)
export _base _dir
set "${SETOPTS:--eu}"

osascript << FIN
tell application "System Events" to tell window 1 of process "Virtual Intranet Access"
    set position to {0, 0}
end tell
FIN
