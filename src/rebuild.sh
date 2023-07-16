#!/usr/bin/env zsh
#-*-mode: Shell-script; coding: utf-8;-*-
# SPDX-License-Identifier: BlueOak-1.0.0
# Description: Wrapper script to simplify running deploy-rs or whatever locally
# to rebuild the local node only from a flake checkout.
_base=$(basename "$0")
_dir=$(cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P || exit 126)
export _base _dir

set "${SETOPTS:--eu}"

# Note args are just what we would pass directly into nix build or
# darwin-rebuild... this is just an easier way to use whichever is right for
# each platform.

[ "true" = "${CHECK:-true}" ] && nix flake check --show-trace "$@"

if [ "Linux" = "$(uname -s)" ]; then
  nix run github:serokell/deploy-rs -- -s .
else
  darwin-rebuild switch --flake .# "$@" &

  ok=0
  hungtest=0

  # Has to be the foreground due to sudo
  until [ 0 -lt ${ok} ]; do
    # If the rebuild is done, nothing to do.
    if ! pgrep -lif darwin-rebuild > /dev/null 2>&1; then
      ((ok=ok+1))
    fi

    if grep -vxF -f =(pgrep -U $(id -u)) =(pgrep -lif emacs) | grep 'seq-tests.el' | grep -Ev '(true)' > /dev/null 2>&1; then
      ((hungtest=hungtest+1))
      sleep 60
    fi

    if [ ${hungtest} -ge 3 ]; then
      victim="$(grep -vxF -f =(pgrep -U $(id -u)) =(pgrep -lif emacs) | grep 'seq-tests.el' | grep -Ev '(true)')"
      pid="$(echo ${victim} | awk '{print $1}')"

      # I let this run for a long time and it eventually exited, but that was
      # like hours, ain't nobody got time for that and killing the test seems
      # fine.
      if [ "${pid}" = "" ]; then
        hungtest=0
      else
        printf "\nnote: will kill hung test pid %s\n" "${victim}" >&2
        sudo kill -TERM ${pid} || : # We don't want to accidentally exit from this
      fi
    fi
    sleep 3
  done

  wait $!

  exit $?
fi
