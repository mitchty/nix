#!/usr/bin/env sh
#-*-mode: Shell-script; coding: utf-8;-*-
# Description: For quick printing out the size of cargo binaries via like hwatch
# or whatever cause... god knows its more so I can see the impact of adding deps
# on binary size.
_base=$(basename "$0")
_dir=$(cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P || exit 126)
export _base _dir

# Dump out from cargo all the binary targets in the workspace (or not as it may
# be) then just pipe that crap to sed to strip out everything in front of
# release/debug and the binary name itself so we don't have gihugic lines and
# get like size {debug,release}/bin
(for bin in $(cargo metadata --format-version 1 --no-deps | jq -r '.packages[].targets[] | select(.kind[] == "bin") | .name'); do
  find "${CARGO_TARGET_DIR}" -type f -name "${bin}" -exec du -hs {} \+
done) | sed -e "s,/.*\/\(release\|debug\)/\(.*\)$,\1/\2," | sort -k2
