#!/usr/bin/env sh
#-*-mode: Shell-script; coding: utf-8;-*-
# SPDX-License-Identifier: BlueOak-1.0.0

SSH="${SSH:-$(command -v ssh)}"
SCP="${SCP:-$(command -v scp)}"
SSHOPTS="${SSHOPTS--o LogLevel=quiet}"

_yolo() {
  printf "%s" "${SSHOPTS-}${SSHOPTS:+ }-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"
}

yolo() {
  # Non issue in this instance, we've unit tests to prove the behavior is ok
  #shellcheck disable=SC2155 disable=SC2030
  (
    export SSHOPTS="$(_yolo)"
    "$@"
  )
}

# Internal wrapper used for testing SSHOPTS usage in ssh()
_ssh() {
  # Also a non issue as the subshell is not in this function
  #shellcheck disable=SC2031
  printf "%s" "${SSHOPTS:+ }${SSHOPTS-}${SSHOPTS:+ }"
}

# Internal wrapper used for testing SSHOPTS usage in scp()
_scp() {
  # Also a non issue as the subshell is not in this function
  #shellcheck disable=SC2031
  printf "%s" "${SSHOPTS:+ }${SSHOPTS-}${SSHOPTS:+ }"
}

# ssh echo, for use if you just want what ssh() would call, e.g. for sshpass
_sshe() {
  printf "%s%s %s" "${SSH}" "$(_ssh)" "$@"
}

# ssh option echo, for use if you just want what ssh() would call, e.g. for sshpass
_sshoe() {
  printf "%s %s" "$(_ssh)" "$@"
}

# scp echo, for use if you just want what scp() would call, e.g. for sshpass
_scpe() {
  printf "%s%s %s" "${SSH}" "$(_ssh)" "$@"
}

# Mostly for sshpass usage
_yolo_sshe() {
  printf "%s %s" "${SSH}" "$(_yolo)"
}

# Mostly for sshpass usage
_yolo_scpe() {
  printf "%s %s" "${SCP}" "$(_yolo)"
}

ssh() {
  # We don't want to quote _ssh() calls in this instance, it would change the
  # args passed to exec(ssh ...)
  #shellcheck disable=SC2046
  ${SSH} $(_ssh) "$@"
}

scp() {
  # Same as ^^
  #shellcheck disable=SC2046
  ${SCP} $(_scp) "$@"
}

SSHPASS="${SSHPASS:-$(command -v sshpass)}"
SSHPASSOPTS="${SSHPASSOPTS-}"

_sshpass() {
  printf "%s" "${SSHPASSOPTS:+ }${SSHPASSOPTS-}${SSHPASSOPTS:+ }"
}

sshpass() {
  # Same rationale as ssh() really as here
  #shellcheck disable=SC2046
  ${SSHPASS} $(_sshpass) "$@"
}

# TODO: tdd this
#
# yolo around ssh/scp via sshpass ^^^
#
# Just reduces the amount of invocations of stuff like host=foo SSHPASSOPTS=....
#
# Note only useful for stuff that "requires" an interactive password, looks up passwords via YEET
# which should be a var like so:
# YEET="host=pass;hostN=passN"
#
# arg 1 is ssh/scp to note
yeet() {
  (
    # We parse out the hostname differently if we're sshing or scp'ing
    action="${1:-help}"
    shift

    # $1 should now include the hostname for a lookup this ones easy
    # just strip off anything before @ if it exists
    if [ "ssh" = "${action}" ]; then
      # quoting ${1} in this echo $() exec is silly/unneeded
      #shellcheck disable=SC2086
      host="$(echo ${1} | sed -e 's/.*\@//g')"
    elif [ "scp" = "${action}" ]; then
      # Bit harder, but scp could be
      # THING USER@HOST:/DEST
      # THING THING1 ... THING USER@HOST:/DEST
      # USER@HOST:/SRC/THING THING
      #
      # So the only thing that makes sense to me is to find whatever has a : in it
      # and hope thats the hostname.
      for s in "$@"; do
        # If this is something like user@host:/blah strip off :->eol and bol->@
        if echo "${s}" | grep '[:]' > /dev/null 2>&1; then
          host=$(echo "${s}" | sed -e 's/.*\@//g' -e 's/\:.*//g')
          break
        fi
      done
    else
      printf "yeet should only start with ssh or scp as first arg\n" >&2
      return
    fi

    # Be sure this is set by now...
    host="${host?}"

    for s in $(echo "${YEET}" | tr ':' ' '); do
      lhs=$(echo "${s}" | sed -e "s/\=.*//g")
      rhs=$(echo "${s}" | sed -e "s/.*\=//g")
      if [ "${lhs}" = "${host}" ]; then
        password="${rhs}"
        break
      fi
    done

    password="${password?}"

    export SSHPASSOPTS="-p ${password}"

    # For this function neither of these matter
    #shellcheck disable=SC2294 disable=SC2046
    eval sshpass $(_yolo_"${action}e") "$@"
  )
}
