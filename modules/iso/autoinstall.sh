#!/usr/bin/env sh
#-*-mode: Shell-script; coding: utf-8;-*-
# SPDX-License-Identifier: BlueOak-1.0.0
# Description:
_base=$(basename "$0")
_dir=$(cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P || exit 126)
_script="${_dir}/${_base}"
export _base _dir

set "${SETOPTS:--eux}"

# Make sure everything is defined as an env var
disks="${disks?}"
wipe="${wipe?}"
zero="${zero?}"
flavor="${flavor?}"
debug="${debug?}"
dedicatedboot="${dedicatedboot?}"
bootsize="${bootsize?}"
swapsize="${swapsize?}"
ossize="${ossize?}"
host="${host?}"
configuration="${configuration?}"

# This is filled in at runtime, if not exit
#shellcheck disable=SC1090
for x in $(echo "${LIBSH}" | tr ':' ' '); do
  . "${x}"
done

seed_shell_history

# Pause until /tmp/okgo is found otherwise just keep looping waiting for the
# file.
pause() {
  go=/tmp/okgo
  while ! [ -e "${go}" ]; do
    printf "pause()\n" >&2
    if [ 1 = "${debug}" ]; then
      blimit=10
      breaker=10
      printf "backoff(%d %s)\n" "${blimit}" "${breaker}" >&2
      backoff ${blimit} ${breaker} :
    else
      rs=$(randint 30)
      printf "sleep(%d)\n" "${rs}" >&2
      sleep "${rs}"
    fi
  done
  printf "rm -f %s\n" "${go}" >&2
  rm -f "${go}"
}

# trap pause EXIT

if [ 1 = "${debug}" ]; then
  cat >&2 << FIN
    disks=${disks}
    wipe=${wipe}
    zero=${zero}
    flavor=${flavor}
    debug=${debug}
    dedicatedboot=${dedicatedboot}
    bootsize=${bootsize}
    swapsize=${swapsize}
    host=${host}
    configuration=${configuration}
FIN

  if [ ! -f /tmp/okgo ]; then
    cat >&2 << FIN
      Not installing automatically as debug is set and /tmp/okgo not present
      script is: ${_dir}/${_base}
FIN
  fi
fi

# # Only do this if we're not in a test vm, test vm's use /dev/blah devices
# # directly.
# if ! dmidecode | grep -i qemu ; then

wack=0
disksbyid=""
for disk in $disks; do
  # See if we got passed in something like /dev/sda /dev/nvme... If
  # so use a /dev/disk/by-uuid link if we see the string /dev/disk/by- presume
  # its ok/right, we just need the links to get at the -part entries
  # so the logic in the script is simple and can presume -part
  # instead of care about the silliness difference between partition
  # suffixes of sd and nvme etc...
  if echo $disk | grep '/dev/disk/by-'; then
    disksbyid="${disksbyid-}${disksbyid:+ }$disk"
  else
    byuuid=$(find -L /dev/disk -samefile $disk | grep uuid)
    if [ "$byuuid" = "" ]; then
      printf "fatal: Could not find a /dev/disk/by-uuid symlink for %s\n" "$disk" >&2
      wack=1
    else
      disksbyid="${disksbyid-}${disksbyid:+ }$byuuid"
    fi
  fi
done

if [ 1 = "${debug}" ]; then
  cat >&2 << FIN
    disksbyid=${disksbyid}
FIN
fi

# The for loop has the actual output
if [ "${wack}" -gt 0 ]; then
  exit 2
fi

# fi
# pause

# Iff wipe is set, and we find *any* lvm *or* md devices, nuke em all from
# orbit before we do anything.
#
# Logic here is if anythings important, it shouldn't be plugged in. For
# home thats perfectly fine uncomplicated logic.
if [ 1 = "$wipe" ]; then
  printf "Wiping disks\n" >&2
  wipe_disks

  if [ 1 = "${zero}" ]; then
    printf "Zeroing disks\n" >&2
    zero_disks "${disks}"
  fi
fi

clear_partition_table_reboot "${disks}"

device_settle "${disks}"

idx=0
for disk in $disks; do
  if [ 1 -eq "${wipe}" ]; then
     wipeit="yep"
  fi
  sfdisklabel gpt ${idx} "${dedicatedboot}" "${bootsize}" "${swapsize}" "${ossize}" | sfdisk --force ${wipeit+--wipe always --wipe-partitions always} "${disk}"
  idx=$((idx+1))
done

device_settle "${disks}"

# This is a hack for now until I get another system to setup to get the zfs/lvm
# setup tested. Should only have one disk at a time here but for now its
# enforced so meh.
#
# Testing out this as a layout for the dumb apu4...
# https://github.com/kierdavis/sb-nixpkgs/blob/57707ea2caf1b1898c7f8bec59372052ed7e2146/nixos/tests/installer.nix#L298-L314
for disk in $disks; do
  boot="${disk}-part1"
  swap="${disk}-part2"
  root="${disk}-part3"
  mkswap "${swap}" -L swap
  mkfs.vfat -F 16 "${boot}"
  swapon -L swap
  mkfs.ext3 -L nixos "${root}"

  install -dm755 /mnt
  mount LABEL=nixos /mnt
  install -dm755 /mnt/boot
  mount "${boot}" /mnt/boot
  break
done

nixos-generate-config --root /mnt

hostid="$(printf "00000000%x" "$(cksum /etc/machine-id | cut -d' ' -f1)" | tail -c8)"
install -m644 /etc/machine-id /mnt/etc/machine-id
printf "$hostid\n" | tee /mnt/etc/hostid

# First up, save what the dhcp config got saved with
# Note we ignore the configuration.nix from nixos-generate-config with our
# own, we just use the generated hardware-configuration file for its uuid links.
nixoscfg=/mnt/etc/nixos/configuration.nix
install -D "${configuration}" $nixoscfg
install -D $nixoscfg original-$nixoscfg

# First up insert the hostname and hostid we generated
sed -i '$i  networking.hostName = "'${host}'";' $nixoscfg
sed -i '$i  networking.hostId = "'$hostid'";' $nixoscfg

# Add all networking devices as dhcp in networking
for net in $(ip link | awk '/^[[:digit:]]/ && !/lo/ {print $2}' | tr -d ':'); do
  sed -i '$i networking.interfaces.'"${net}"'.useDHCP = true;' $nixoscfg
done

nixos-install --no-root-password

reboot_into_firmware_or_shutdown
