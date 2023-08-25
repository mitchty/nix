#!/usr/bin/env sh
#-*-mode: Shell-script; coding: utf-8;-*-
# SPDX-License-Identifier: BlueOak-1.0.0
# Description: close a macos app by name
if [ $# -lt 1 ]; then
  printf "usage: close app_name\n" >&2
  exit 1
fi

osascript << END
tell application "${@}"
    quit
end tell
END
