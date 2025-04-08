#!/usr/bin/env sh
#-*-mode: Shell-script; coding: utf-8;-*-
# SPDX-License-Identifier: BlueOak-1.0.0
# Description: Clean up ~/.cache (on linux, macos work tbd by future me... sucker)
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

# go build cache, no sense keeping stuff around for too long here either.
for goturd in ~/.cache/go ~/.cache/go-build; do
  if [ -e "${goturd}" ]; then
    # Kill all the files older than a week, then nuke empty dirs
    find "${goturd}" -maxdepth 1 -type d -ctime +7 -print -exec rm -fr {} \+
  fi
done

# Nix build turds leftover in /tmp: ref https://github.com/NixOS/nix/issues/5207
# for upstream issue this is a workaround.
find /tmp -maxdepth 1 -name "nix-build-*" -type d -ctime +1 -print -exec rm -fr {} \+

xorgturd=~/.local/share/Trash
#find "${xorgturd}" -type f -ctime +31 -print -exec rm {} \+
if [ -e "${xorgturd}" ]; then
  find "${xorgturd}" -type d -ctime +31 -print -exec rm -fr {} \+
fi

# Find all result symlinks and nuke em
for d in ~/src/prv ~/src/pub; do
  find ${d} -type l -name result -lname "/nix/store/*" -print -exec rm {} \+
done
