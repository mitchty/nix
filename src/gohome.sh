#!/usr/bin/env sh
#-*-mode: Shell-script; coding: utf-8;-*-
# SPDX-License-Identifier: BlueOak-1.0.0
# Description: Make an application on macos Go Home if its lost in the aether
# after a monitor switch.
thing="${1}"
shift
id="${1:-0}"

osascript <<FIN
tell application "System Events" to tell window ${id} of process "${thing}"
    set position to {100, 100}
end tell
FIN
