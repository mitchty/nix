#!/usr/bin/env sh
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

if [ "true" = "${CHECK:-true}" ]; then
  if ! nix flake check --show-trace; then
    exit $?
  fi
fi

if [ "Linux" = "$(uname -s)" ]; then
  nix run github:serokell/deploy-rs -- -s ".${1+#}${1}" &
else
  darwin-rebuild switch --flake .# "$@" &
fi

ok=0
hungtest=0

# Has to be the foreground due to sudo
until [ 0 -lt ${ok} ]; do
  # If darwin-rebuild is done on macos, deploy-rs on linux is done nothing
  # more to do the test didn't hang for some reason
    case "$(uname -s)" in
    Darwin)
      if ! pgrep -lif darwin-rebuild > /dev/null 2>&1; then
        ((ok=ok+1))
      fi
      ;;
    Linux)
      if ! pgrep -lif deploy > /dev/null 2>&1; then
        ((ok=ok+1))
      fi
    ;;

    *)
	printf "fatal: how did you get here?\n" >&2
        exit 1
    ;;
    esac

  if pgrep -U $(id -u) -lifa emacs | awk '/seq-tests.el/ && !/true/ {print $1; exit 1}' > /dev/null 2>&1; then
    ((hungtest=hungtest+1))
    sleep 60
  fi

  if [ ${hungtest} -ge 3 ]; then
    victim="$(grep -vxF -f =(pgrep -U $(id -u)) =(pgrep -lifa emacs) | grep 'seq-tests.el' | grep -Ev '(true)')"
    pid="$(echo ${victim} | awk '{print $1}')"

    # I let this run for a long time and it eventually exited, but that was
    # like hours, ain't nobody got time for that and killing the test seems
    # fine.
    if [ "${pid}" = "" ]; then
      hungtest=0
    else
      printf "\n\nnote: will kill likely hung test pid %s\n" "${victim}" >&2
      sudo kill -TERM ${pid} || : # We don't want to accidentally exit from this
    fi
  fi
  sleep 3
done

wait $!
rc=$?

printf "\nfin\n"

exit $rc
