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
  (export SSHOPTS="$(_yolo)"; "$@")
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
