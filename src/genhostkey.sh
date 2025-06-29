#!/usr/bin/env sh
#-*-mode: Shell-script; coding: utf-8;-*-
# Description: Until I get ssh ca stuff working will just use ssh host keys I
# build here for now.
_base=$(basename "$0")
_dir=$(cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P || exit 126)
export _base _dir

set -xeu

host="${1?need a hostname}"

d="${_dir}/../crypt/ssh/${host}"

install -dm755 "${d}"

cd "${d}" || exit 126

for typ in ed25519 rsa; do
  ssh-keygen -t "${typ}" -f ssh_host_${typ}_key -N '' -C 'private genhostkey.sh'
done
