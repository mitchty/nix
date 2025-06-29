#!/usr/bin/env sh
#-*-mode: Shell-script; coding: utf-8;-*-
# Description: Setup an ssh host/user ca (user not yet working)
_base=$(basename "$0")
_dir=$(cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P || exit 126)
export _base _dir

set -xeu

d="${_dir}/../crypt/ssh/ca"

install -dm755 "${d}"

cd "${d}" || exit 126

ssh-keygen -t ed25519 -f host_ca -N '' -C "flake host ca"
ssh-keygen -t ed25519 -f user_ca -N '' -C "flake user ca"
