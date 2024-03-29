#!/usr/bin/env sh
#-*-mode: Shell-script; coding: utf-8;-*-
# SPDX-License-Identifier: BlueOak-1.0.0
# Description: Update everything I got... sanely, for use with entr really.
_base=$(basename "$0")
_dir=$(cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P || exit 126)
export _base _dir

set "${SETOPTS:--eu}"

DEPLOYOPTS="${DEPLOYOPTS:-}"
LOCALCHECK="${LOCALCHECK:-}"
LOCAL="${LOCAL:-false}"

#shellcheck source=../static/src/lib.sh
. ~/src/pub/github.com/mitchty/nix/static/src/lib.sh

nixossys=srv.home.arpa

check() {
  checkit='gi mitchty/nix && nix flake check --show-trace'
  if [ -z "${LOCALCHECK}" ]; then
    eval "${checkit}"
  else
    ugde && ssh -t "${nixossys}" "zsh --login -i -c '${checkit}'"
  fi
}

_deployrs() {
  if ${LOCAL}; then
    #shellcheck disable=SC2086
    gi mitchty/nix && nix run github:serokell/deploy-rs -- -s ${1} -- ${DEPLOYOPTS}
  else
    ugde && ssh -t "${nixossys}" "zsh --login -i -c 'gi mitchty/nix && nix run github:serokell/deploy-rs -- -s ${1} -- ${DEPLOYOPTS}'"
  fi
}

deployrs() {
  if [ $# -gt 0 ]; then
    until [ $# -eq 0 ]; do
      host="${1-}"
      shift || :
      _deployrs ".${host+#}${host}"
    done
  else
    _deployrs "."
  fi
}

[ -z "${CHECK:-}" ] && check

if [ $# -gt 0 ]; then
  deployrs "$@"
else
  deployrs
fi
