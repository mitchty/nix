#!/usr/bin/env sh
#-*-mode: Shell-script; coding: utf-8;-*-
# Description: For now wrapper to just toggle the jiggler on/off
#
# Future me can port over the other iso upload stuff.
_base=$(basename "$0")
_dir=$(cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P || exit 126)
export _base _dir

CURL=${CURL:-curl}
JQ=${JQ:-jq}

ok=0

CURL=$(command -v ${CURL})
JQ=$(command -v ${JQ})

KVMHOST=${KVMHOST:-https://127.0.0.1}
KVMUSER=${KVMUSER:-admin}
KVMPASS=${KVMPASS:-admin}

# Helper functions to reduce the amount of args we pass in on each curl/jq call,
# note we are calling whatever command -v curl/jq/etc.. found directly to avoid
# recursion
curl() {
  printf "curl %s\n" "$*" >&2
  ${CURL} --silent --insecure --user $KVMUSER:$KVMPASS "$@"
  printf "\n" >&2
}

post() {
  printf "post %s\n" "$*" >&2
  ${CURL} -X POST --insecure --user $KVMUSER:$KVMPASS --progress-bar "$@" | cat
  printf "\n" >&2
}

jq() {
  ${JQ} -Mr "$@"
}

jiggler_off() {
  post ${KVMHOST}/api/hid/set_params?jiggler=false
}

jiggler_on() {
  post ${KVMHOST}/api/hid/set_params?jiggler=true
}

disconnect_drive() {
  post ${KVMHOST}/api/msd/set_connected?connected=0
}

remove_image() {
  post ${KVMHOST}/api/msd/remove?image="$*"
}

reset_msd() {
  post ${KVMHOST}/api/msd/reset
}

write_image() {
  # not applicable shellcheck
  #shellcheck disable=SC2046
  post ${KVMHOST}/api/msd/write?image=$(basename "$@") -T "$@"
}

set_params_image() {
  # not applicable shellcheck
  #shellcheck disable=SC2046
  post ${KVMHOST}/api/msd/set_params?image=$(basename "$@")"&cdrom=1"
}

set_connected() {
  post ${KVMHOST}/api/msd/set_connected?connected=1
}

task="${1:-jiggler}"
shift

# For now just jiggler and imported old iso image setting stuff
if [ "${task}" = "jiggler" ]; then
  # If not specified turn the jiggler on I guess.
  val="${1:-on}"

  if [ "${val}" = "on" ]; then
    jiggler_on
  else
    jiggler_off
  fi
elif [ "${task}" = "img" ]; then
  # Disconnect msd if needed
  if [ "true" = "$(curl ${KVMHOST}/api/msd | jq '.result.drive.connected')" ]; then
    disconnect_drive
  fi

  # iff clean or clear was passed as first arg clean up all existing images, both
  # cause I forget what the option is...
  if [ "clean" = "$1" ] || [ "clear" = "$1" ]; then
    shift
    for iso in $(curl ${KVMHOST}/api/msd | jq '.result.storage.images | keys[]'); do
      remove_image ${iso}
    done
  fi

  # Reset the msd while we're here
  reset_msd

  # Upload the images
  for img in "$@"; do
    write_image "${img}"
  done

  # Set the msd to use it (quoted due to the &), note only the last img is set
  # obviously but you can use this to upload other images/isos.
  for img in "$@"; do
    set_params_image "${img}"
  done

  # Then connect it
  if [ "" != "$*" ]; then
    set_connected
  fi
else
  printf "fatal: task %s is not known\n" >&2
fi
