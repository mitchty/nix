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
  out=$(echo "$@" | jq -r ".login.${thing}")
  if [ "null" = "${out}" ]; then
    printf "fatal: got a null value for %s probably not what was wanted but you do you\n" "${thing}" >&2
  fi
  printf "%s" "${out}"
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
  printf "clear macos clipboard of %s data" "$@" >&2
  # Not applicable I'm just using read as an interactive nonsense thing piss
  # off, this isn't a problem I'm not even using the read data...
  #shellcheck disable=SC2162
  read
  echo "the sound of silence" | pbcopy
}

matches=$(bw_items "$@")

# use fzf to select from a list if len > 1 or just that login item
get_one_login() {
  len=$(echo "$@" | jq ". | length")
  if [ 1 -eq "${len}" ]; then
    single=$(echo "$@" | jq '.[0].name')
    printf "one match found using: %s\n" "${single}" >&2
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

wait_and_junk_to_clipboard "remainders"
