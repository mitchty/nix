#!/usr/bin/env sh
#-*-mode: Shell-script; coding: utf-8;-*-
# SPDX-License-Identifier: BlueOak-1.0.0
# Description: Sick of having long ass build commands in my history.
#
# This is a quick wrapper around nix build ... with notify to let me know status of builds.
_base=$(basename "$0")
_dir=$(cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P || exit 126)
export _base _dir
set "${SETOPTS:--eu}"

# Snag the directory name, compress $HOME to ~
#shellcheck disable=SC2046,SC2034,SC2155,SC3043
d=$(pwd | sed -e "s|$HOME|~|g")

#shellcheck disable=SC3043
rc=1

if nix build --print-build-logs --show-trace --no-warn-dirty "$@"; then
  rc=$?
  # Piss off its fine
  #shellcheck disable=SC2145
  notify "${d} $@" "ok bra"
else
  rc=$?
  # Piss off its fine
  #shellcheck disable=SC2145
  notify "${d} $@" "GAME OVER MAN GAME OVER\nrc: ${rc}"
fi
exit ${rc}

#nix build --print-build-logs --show-trace --no-warn-dirty "$@"
