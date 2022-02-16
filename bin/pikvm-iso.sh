#!/usr/bin/env sh
#-*-mode: Shell-script; coding: utf-8;-*-
# File: pikvm-iso.sh
# Copyright: 2022 Mitchell Tishmack
# Description: Simple wrapper around pikvm api to upload an iso image after
# removing whatever else might be there. Highly tuned to my specific use case.
_base=$(basename "$0")
_dir=$(cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P || exit 126)
export _base _dir

CURL=${CURL:-curl}
JQ=${JQ:-jq}

ok=0

# Validate we have the commands needed to run successfully, curl and jq
if ! command -v ${CURL} &> /dev/null; then
  printf "Did not find curl as '${CURL}' on PATH, this script cannot run without curl\n" >&2
  ok=1
fi

if ! command -v ${JQ} &> /dev/null; then
  printf "Did not find jq as '${JQ}' on PATH, this script cannot run without jq\n" >&2
  ok=1
fi

CURL=$(command -v ${CURL})
JQ=$(command -v ${JQ})

HOST=${HOST:-https://127.0.0.1}
USER=${USER:-admin}
PASS=${PASS:-admin}
ISO=${ISO:-example.iso}

# Helper functions to reduce the amount of args we pass in on each curl/jq call,
# note we are calling whatever command -v curl/jq/etc.. found directly to avoid
# recursion
curl() {
  printf "curl $@" >&2
  ${CURL} --insecure --user $USER:$PASS --silent "$@"
  printf "\n" >&2
}

post() {
  printf "post $@" >&2
  ${CURL} -X POST --insecure --user $USER:$PASS --silent "$@"
  printf "\n" >&2
}

jq() {
  ${JQ} -Mr "$@"
}

# If anything is amiss exit before work
[ $ok -ne 0 ] && exit $ok

set -e

# Disconnect msd if needed
if [[ $(curl ${HOST}/api/msd | jq '.result.drive.connected') = "true" ]]; then
  post ${HOST}/api/msd/set_connected?connected=0
fi

# First up, remove any/all iso files
for iso in $(curl ${HOST}/api/msd | jq -Mr '.result.storage.images[].name'); do
  post ${HOST}/api/msd/remove?image=${iso}
done

# Reset the msd while we're here
post ${HOST}/api/msd/reset

# Upload the iso
post ${HOST}/api/msd/write?image=$(basename ${ISO}) --data-binary @${ISO}

# Set the msd to use it (quoted due to the &)
post "${HOST}/api/msd/set_params?image=$(basename ${ISO})&cdrom=1"

# Then connect it
post ${HOST}/api/msd/set_connected?connected=1
