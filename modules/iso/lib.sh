#!/usr/bin/env sh
#-*-mode: Shell-script; coding: utf-8;-*-
# SPDX-License-Identifier: BlueOak-1.0.0
# Description: Lib functions for autoinstall
_base=$(basename "$0")
_dir=$(cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P || exit 126)
export _base _dir

set "${SETOPTS:--eu}"

# As much as I hate doing this much work for home nonsense it saves time in the end...

sfdisklabel() {
  label=$1
  shift
  index=$1
  shift
  dedicated=$1
  shift
  bootsize=$1
  shift
  swapsize=$1
  shift
  ossize=${1-256GiB}

  if [ "dos" = "${label}" ]; then
    cat << FIN
label: ${label}

1: size=${bootsize}, start=1M, type=83, bootable
2: size=${swapsize}, type=fd
3: size=${ossize}, type=83
4: type=83
FIN
  elif [ "gpt" = "${label}" ]; then
    if [ 0 -eq "${index}" ] && [ "" != "${dedicated}" ]; then
    cat << FIN
label: ${label}

1: type= uefi, bootable
FIN
    else

    cat << FIN
label: ${label}

1: size=${bootsize}, type= uefi, bootable
2: size=${swapsize}, type= 0657FD6D-A4AB-43C4-84E5-0933C84B4F4F
3: size=${ossize}, type= E6D6D379-F507-44C2-A23C-238F2A3DF928
4: type= 0FC63DAF-8483-4772-8E79-3D69D8477DE4
FIN
    fi

  else
    printf 'unknown label type %s\n' "${label}" >&2
  fi
}
