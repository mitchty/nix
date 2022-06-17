#!/usr/bin/env sh
#-*-mode: Shell-script; coding: utf-8;-*-
# SPDX-License-Identifier: BlueOak-1.0.0
# Description: Check for out of date stuff in my nix setup
_base=$(basename "$0")
_dir=$(cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P || exit 126)
export _base _dir
set "${SETOPTS:--eu}"

stats_cur="v2.7.21"
stats_found="$(curl --silent 'https://api.github.com/repos/exelban/stats/releases/latest' | jq -r '.tag_name')"

ok=0

if [ "${stats_cur}" != "${stats_found}" ]; then
  printf "stats out of date have %s latest is %s\n" "${stats_cur}" "${stats_found}" >&2
  ok=$(( ok + 1 ))
fi

exit $ok
