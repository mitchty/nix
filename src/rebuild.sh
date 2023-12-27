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
    exit 1 # $? is 0 here somehow? whatever
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
        ok=$((ok = ok + 1))
        break
      fi
      ;;
    Linux)
      if ! pgrep -lif deploy > /dev/null 2>&1; then
        ok=$((ok = ok + 1))
        break
      fi
      ;;

    *)
      printf "fatal: how did you get here?\n" >&2
      exit 1
      ;;
  esac

  # Whatever I'm not quoting id -u you can't have spaces in userids...
  #shellcheck disable=SC2046
  hungtest=$(pgrep -lifa emacs | awk '/seq-tests[.]el$/ {print $1; exit}')
  if [ "" != "${hungtest}" ]; then
    # I let this run for a long time and it eventually exited, but that was
    # like hours, ain't nobody got time for that and killing the test seems
    # fine.
    printf "\n\nnote: will kill likely hung test pid %s\nsudo kill -TERM %s\n" "${hungtest}" "${hungtest}" >&2
    sudo kill -TERM "${hungtest}" || : # We don't want to accidentally exit from this
  fi
  sleep 2
done

wait $!
rc=$?

printf "fin\n" >&2

exit $rc
