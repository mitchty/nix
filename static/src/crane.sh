#!/usr/bin/env nix-shell
#!nix-shell -i bash -p bash git patch
#-*-mode: Shell-script; coding: utf-8;-*-
# SPDX-License-Identifier: BlueOak-1.0.0
# Description: Tool to do nix flake init... cargo init... git init.. all at once
_base=$(basename "$0")
_dir=$(cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P || exit 126)
export _base _dir
set "${SETOPTS:--eu}"

# Arg is the directory to do stuff to, required
dir=${1?}

if [ -e "${dir}" ]; then
  printf "fatal: %S exists, refusing to add stuff to it\n" "${dir}" >&2
  exit 1
fi

install -dm755 "${dir}"

cd "${dir}" || exit 126

nix flake init -t github:ipetkov/crane
git init

printf "result\ntarget\n" > .gitignore
printf 'use flake\n' > .envrc

git add -A
git commit -m "nix flake init -t github:ipetkov/crane"
