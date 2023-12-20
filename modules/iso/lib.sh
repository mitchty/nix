#!/usr/bin/env sh
#-*-mode: Shell-script; coding: utf-8;-*-
# SPDX-License-Identifier: BlueOak-1.0.0
# Description: Lib functions for autoinstall
# abusing the systemd env for a lot of inputs
#shellcheck disable=SC2154 disable=SC2317
_base=$(basename "$0")
_dir=$(cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P || exit 126)
export _base _dir

set "${SETOPTS:--eu}"

# As much as I hate doing this much work for home nonsense it saves time in the end...

# Wipe out all md/lv/vg/partition info/data
wipe_lvm() {
  # Have lvm activate anything that might be around
  vgchange -ay

  # TODO: hack for now, udevadm settle somehow? WHATEVER future me problem...
  sleep 10

  printf "Wiping all lvm+md setup\n" >&2
  # Nuke lv's first
  for lv in /dev/mapper/*-*; do
    printf "removing lv %s\n" "%{lv}" >&2
    wipefs --all --force "${lv}" || :
    lvremove -f "${lv}" || :
  done

  # Then vg's
  for vg in $(vgs --noheadings | awk '{print $1}'); do
    printf "removing vg %s\n" "${vg}" >&2
    vgremove "${vg}" || :
  done

  # Then pv's
  for pv in $(pvs --noheadings | awk '{print $1}'); do
    printf "removing pv %s\n" "${pv}" >&2
    pvremove "${pv}" || :
  done

  # Finally stop any md devices and zero the md superblocks if any
  if [ -e /proc/mdstat ]; then
    for md in $(awk '/md/ {print $1}' /proc/mdstat); do
      wipefs --all --force "/dev/${md}" || :
      mdadm --stop "/dev/${md}" || :
    done

    # Could be better done... but fits for the specific use case of
    # rebuilding for home.
    #
    # Only tested/valdiated against this specific setup/raid layout. If a
    # dev is sdc1 not sure what would happen.
    for dev in $(awk '/active/{print $0}' /proc/mdstat | sed -e 's/.*raid1 //' | tr -d "01"); do
      mdadm --zero-superblock --force "/dev/${dev}" || :
      mdadm --zero-superblock --metadata 1.0 --force "/dev/${dev}" || :
    done
  fi
}

# dd the entire disk device, slow af but can be handy at times
zero_disks() {
  #shellcheck disable=SC2048
  for disk in $*; do
    dd if=/dev/zero of="${disk}" &
  done

  # Iff zero is set wait for dd's to finish before returning to caller
  printf "\nwaiting for dd's to finish\n" >&2
  wait
}

# If partprobe fails, probably due to in use stuff, just reboot,
# should clear it up on next install run, easier than trying to be
# cute with in use devices.
clear_partition_table_reboot() {
  #shellcheck disable=SC2048
  for disk in $*; do
    wipefs --all --force "${disk}"
  done

  wack=0
  #shellcheck disable=SC2048
  for disk in $*; do
    if ! partprobe --summary "${disk}"; then
      wack=$((wack + 1))
    fi
  done

  if [ "${wack}" -gt 0 ]; then
    printf "couldn't wipe a disk will need to reboot to clear in use partitions\n" >&2
    until [ -e /tmp/okgo ]; do
      sleep 1
    done
    echo b > /proc/sysrq-trigger
  fi
}

# wait for each device to complete initialization/settle
device_settle() {
  #shellcheck disable=SC2048
  for disk in $*; do
    dev=$(readlink -f ${disk})
    udevadm settle "${dev}"
    for part in $(echo ${dev}*); do
      udevadm settle "${part}"
    done
  done
}

# If we can reboot into firmware-setup via efi do that, otherwise poweroff so
# the usb stick/iso can be yeeted out.
reboot_into_firmware_or_shutdown() {
  if ! systemctl reboot --firmware-setup; then
    printf "reboot into efi firmware setup failed will shutdown in 30 seconds\n" >&2
    sleep 30
    shutdown now
  fi
}

seed_shell_history() {
  # Don't just keep appending to .bash_history...
  if ! grep sysrq-trigger /root/.bash_history > /dev/null 2>&1; then
    cat >> /root/.bash_history << FIN
systemctl reboot --firmware-setup
echo b > /proc/sysrq-trigger
systemctl restart autoinstall
systemctl status autoinstall
touch /tmp/okgo
touch /tmp/wait
shutdown now
journalctl -u autoinstall | cat
journalctl -fu autoinstall
FIN
  fi
}
