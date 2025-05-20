#!/usr/bin/env sh
#-*-mode: Shell-script; coding: utf-8;-*-
# Description: For quick printing out the size of binaries
_base=$(basename "$0")
_dir=$(cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P || exit 126)
export _base _dir

(for x in debug release; do
  files=$(find "${CARGO_TARGET_DIR:-target}/${x}" -maxdepth 1 -type f \( ! -name "*.d" -a ! -name "*.rlib" -a ! -name ".cargo-lock" \))
  du -hs "${files}"
done) | sed -e "s|/.*\(release\)/|\1/|" -e "s|/.*\(debug\)/|\1/|" | sort -k2
