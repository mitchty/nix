#!/usr/bin/env sh
#-*-mode: Shell-script; coding: utf-8;-*-
# SPDX-License-Identifier: BlueOak-1.0.0
# Description: Maccy will save anything we want to not do that for some stuff so
# basically this is an exec wrapper to turn that off for "thing" then turn it
# back on after.

revert() {
  defaults write org.p0deje.Maccy ignoreEvents false
}

trap revert EXIT TERM INT QUIT

# As that "thing" can fail we don't care if it errors so no set -e
defaults write org.p0deje.Maccy ignoreEvents true

eval "$*"
