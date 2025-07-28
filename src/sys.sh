#!/usr/bin/env nix-shell
#-*-mode: Shell-script; coding: utf-8;-*-
#!nix-shell -i bash -p bash
# SPDX-License-Identifier: BlueOak-1.0.0
# Description: Want to test out autoinstall iso setup.
_base=$(basename "$0")
_dir=$(cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P || exit 126)
export _base _dir

set -eu

# Note: nix-shell for now whilst I work out kinks manually.

# Note this is just a custom wrapper script that auto uses the OVMF firmware. I
# need to validate/test using efi vars to do more automation but for now this is
# fine.
QEMU=${QEMU:-qemu-system-x86_64-uefi}
PREFIX="${PREFIX:-${HOME}/.cache/mitchty}"

install -dm755 "${PREFIX}"

base=$(TMPDIR=${PREFIX} mktemp -d XXXXXXXX -t)
SYS=${1:-vm-mirror-iso}
shift

trap "rm -fr ${base}" EXIT TERM INT QUIT

port() {
  echo $((($(echo ${SYS} | sha1sum | awk '{print $1}' | tr -d '[a-z]' | head -c 19)) % 100 * 100 + 10022))
}

default() {
  networkqemuargs="-net user,hostfwd=tcp::$(port)-:22 -net nic"

  qemuargs="${qemuargs:--enable-kvm -smp 4 -nographic -m 8096 -boot d ${networkqemuargs}}"

  disk0="${base}/vdisk0"
  qemu-img create -f qcow2 ${disk0} 40G
  disk1="${base}/vdisk1"
  qemu-img create -f qcow2 ${disk1} 40G
  disk2="${base}/vdisk2"
  qemu-img create -f qcow2 ${disk2} 40G

  ${QEMU} ${qemuargs} -cdrom $(iso) -hda ${disk0} -hdb ${disk1} -hdd ${disk2}
}

iso() {
  # The rescue iso is special, its just the nixos installer iso with whatever the
  # hell I want on it so we don't use nixos-generate to build it.
  if [ "${SYS}" = "rescue" ]; then
    nix build .#nixosConfigurations.rescue.config.system.build.isoImage
    # result is just a bunch o symlinks
    iso=$(readlink -f $(find -L result -name "*.iso" -type f))
  else
    iso=$(nixos-generate --flake ".#${SYS}" -f install-iso)
  fi
  echo ${iso}
}

# gist is script system action so that I can still go:
# iso system
# vs iso default system or some other dum scheme
action="${1:-default}"
case "${action}" in
  default)
    default
    ;;
  port)
    port
    ;;
  iso)
    iso
    ;;
esac
