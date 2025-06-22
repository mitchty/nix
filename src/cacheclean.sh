#!/usr/bin/env sh
#-*-mode: Shell-script; coding: utf-8;-*-
# SPDX-License-Identifier: BlueOak-1.0.0
# Description: Clean up ~/.cache (on linux, macos work tbd by future me...
# sucker)
#
# This will eventually become something ran periodically.
_base=$(basename "$0")
_dir=$(cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P || exit 126)
export _base _dir
set "${SETOPTS:--eu}"

# Find .direnv layouts older than a month and nuke em, note I yeet em all into
# ~/.cache/direnv/layouts not .direnv, makes management easier.
direnvturds=~/.cache/direnv/layouts
if [ -e "${direnvturds}" ]; then
  find "${direnvturds}" -maxdepth 1 -type d -ctime +31 -print -exec rm -fr {} \+
fi

# All my rust target dir stuff, only bother keeping stuff within the week.
rustturds=~/.cache/uniq
if [ -e "${rustturds}" ]; then
  find "${rustturds}" -maxdepth 1 -type d -ctime +7 -print -exec rm -fr {} \+
fi

# And any target dirs in ~/src that might have slipped by.
pipe=$(mktemp cleanfile.XXXXX)
trap 'rm -f ${pipe}' EXIT TERM INT QUIT

# find can fail on stuff like .Trashes in macos, for now just assume it output
# something useful, read will catch things right or not.
find ~/src -type d -name target 2> /dev/null > "${pipe}" || :

while IFS='
' read -r adir; do
  b=$(dirname "${adir}")
  c="${b}/Cargo.toml"
  j="${adir}/.rustc_info.json"

  # Be careful about what we nuke, be sure as sure as we can reasonably be about
  # this being a rust target build dir by checking all the above, if not leave it be.
  if [ -e "${c}" ] && [ -e "${j}" ]; then
    echo rm france rust build dir "${adir}"
    rm -fr "${adir}"
  fi
done < "${pipe}"

# go build cache, no sense keeping stuff around for too long here either.
for goturd in ~/.cache/go ~/.cache/go-build; do
  if [ -e "${goturd}" ]; then
    # Kill all the files older than a week, then nuke empty dirs
    find "${goturd}" -maxdepth 1 -type d -ctime +7 -print -exec rm -fr {} \+
  fi
done

# Nix build turds leftover in /tmp: ref https://github.com/NixOS/nix/issues/5207
# for upstream issue this is a workaround.
find /tmp -maxdepth 1 -name "nix-build-*" -type d -ctime +1 -print -exec sudo rm -fr {} \+

# Find all result symlinks and nuke em
for d in ~/src/prv ~/src/pub; do
  find ${d} -type l -name result -lname "/nix/store/*" -print -exec rm {} \+
done

# Prep for specific type of system
uname_m=$(uname -m)

if [ "${uname_m}" = "linux" ]; then
  xorgturd=~/.local/share/Trash
  if [ -e "${xorgturd}" ]; then
    find "${xorgturd}" -type d -ctime +31 -print -exec rm -fr {} \+
  fi
fi
