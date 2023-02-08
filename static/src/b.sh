#!/usr/bin/env sh
#-*-mode: Shell-script; coding: utf-8;-*-
# SPDX-License-Identifier: BlueOak-1.0.0
# Description: Make the dumb af bw cli possible to use on macos at least, future
# me can replace/augment pbcopy with whatever else copies text off stdin to the
# "clipboard" of choice.
_base=$(basename "$0")
_dir=$(cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P || exit 126)
export _base _dir
set "${SETOPTS:--eu}"

bw_items() {
  bw list items --search "$*"
}

# Since the loging username/passwords in the same spot in the data.
get() {
  thing="${1}"
  shift
  echo "$@" | jq -r ".login.${thing}"
}

# Copy some "thing" to clipboard then clobber it with something different after
# we read anything.
copy() {
  thing="${1}"
  shift
  get "${thing}" "$@" | pbcopy
  wait_and_junk_to_clipboard "${thing}"
}

wait_and_junk_to_clipboard() {
  printf "type any key to clear clipboard of %s" "$@" >&2
  # n/a i'm just using read as an interactive nonsense thing piss off shellcheck
  # this isn't a problem i'm not even using the read data...
  #shellcheck disable=SC2162
  read
  echo "clearing" | pbcopy
}

matches=$(bw_items "$@")

# use fzf to select from a list if len > 1 or just that login item
get_one_login() {
  len=$(echo "$@" | jq ". | length")
  if [ 1 -eq "${len}" ]; then
    echo "$@" | jq '.[0]'
  else
    name=$(echo "$@" | jq -r '.[].name' | fzf --reverse)
    echo "$@" | jq ".[] | select(.name == \"${name}\")"
  fi
}

login=$(get_one_login "${matches}")

for thing in "username" "password"; do
  copy "${thing}" "${login}"
done
