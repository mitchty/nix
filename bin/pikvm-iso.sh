#!/usr/bin/env nix-shell
#-*-mode: Shell-script; coding: utf-8;-*-
#!nix-shell -i bash -p bash jq curl
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
if ! command -v "${CURL}" > /dev/null 2>&1; then
  printf "Did not find curl as '${CURL}' on PATH, this script cannot run without curl\n" >&2
  ok=1
fi

if ! command -v ${JQ} > /dev/null 2>&1; then
  printf "Did not find jq as '${JQ}' on PATH, this script cannot run without jq\n" >&2
  ok=1
fi

CURL=$(command -v ${CURL})
JQ=$(command -v ${JQ})

KVMHOST=${KVMHOST:-https://127.0.0.1}
KVMUSER=${KVMUSER:-admin}
KVMPASS=${KVMPASS:-admin}
ISO=${ISO:-example.iso}

# Helper functions to reduce the amount of args we pass in on each curl/jq call,
# note we are calling whatever command -v curl/jq/etc.. found directly to avoid
# recursion
curl() {
  printf "curl $@\n" >&2
  ${CURL} --insecure --user $KVMUSER:$KVMPASS --silent "$@"
  printf "\n" >&2
}

post() {
  printf "post $@\n" >&2
  ${CURL} -X POST --insecure --user $KVMUSER:$KVMPASS --silent "$@"
  printf "\n" >&2
}

jq() {
  ${JQ} -Mr "$@"
}

disconnect_drive() {
  post ${KVMHOST}/api/msd/set_connected?connected=0
}

remove_image() {
  post ${KVMHOST}/api/msd/remove?image="$@"
}

reset_msd() {
  post ${KVMHOST}/api/msd/reset
}

write_image() {
  post ${KVMHOST}/api/msd/write?image=$(basename "$@") --data-binary @"$@"
}

set_params_image() {
  post "${KVMHOST}/api/msd/set_params?image=$(basename $@)&cdrom=1"
}

set_connected() {
  post ${KVMHOST}/api/msd/set_connected?connected=1
}

# If anything is amiss exit before work
[ $ok -ne 0 ] && exit $ok

set -e

# Disconnect msd if needed
if [ "true" = "$(curl ${KVMHOST}/api/msd | jq '.result.drive.connected')" ]; then
  disconnect_drive
fi

# iff clean was passed clean up all existing images.
if [ "clean" = "$*" ]; then
  for iso in $(curl ${KVMHOST}/api/msd | jq '.result.storage.images[].name'); do
    remove_image ${iso}
  done
fi

# Reset the msd while we're here
reset_msd

# Upload the iso
write_image "${ISO}"

# Set the msd to use it (quoted due to the &)
set_params_image "${ISO}"

# Then connect it
set_connected
