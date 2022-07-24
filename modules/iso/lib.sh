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
  ossize=${1-6GiB}

if [ "gpt" = "${label}" ]; then
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

# Wipe out all md/lv/vg/partition info/data
wipe_disks() {
  # Have lvm activate anything that might be around
  vgchange -ay

  # TODO: hack for now, udevadm settle somehow? WHATEVER future me problem...
  sleep 10

  printf "Wiping all lvm+md setup\n" >&2
  # Nuke lv's first
  for lv in /dev/mapper/*-*; do
    printf "removing lv %s\n" "%{lv}"  >&2
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
  for disk in "$@"; do
    dd if=/dev/zero of="${disk}" bs=4M status=progress &
  done

  # Iff zero is set wait for dd's to finish before returning to caller
  printf "\nwaiting for dd's to finish\n" >&2
  wait
}

# If partprobe fails, probably due to in use stuff, so just reboot,
# should clear it up on next install run, easier than trying to be
# cute with in use devices.
clear_partition_table_reboot() {
  for disk in "$@"; do
    if ! partprobe --summary ${disk}; then
      debug
      echo b > /proc/sysrq-trigger
    fi
  done
}

# wait for each device to complete initialization/settle
device_settle() {
  for disk in $@; do
    dev=$(readlink -f ${disk})
    udevadm settle "${dev}"
    for part in "${dev}"-part*; do
      udevadm settle "${part}"
    done
  done
}

# If we can reboot into firmware-setup via efi do that, otherwise poweroff so
# the usb stick/iso can be yeeted out.
reboot_into_firmware_or_shutdown() {
  if ! systemctl reboot --firmware-setup ; then
    printf "reboot into efi firmware setup failed will shutdown in 30 seconds\n" >&2
    sleep 30
    shutdown now
  fi
}

seed_shell_history() {
  # Don't just keep appending to .bash_history...
  if ! grep sysrq-trigger /root/.bash_history > /dev/null 2>&1; then
    cat >> /root/.bash_history << FIN
echo b > /proc/sysrq-trigger
systemctl restart autoinstall
systemctl status autoinstall
touch /tmp/okgo
journalctl -fb -n100 -uautoinstall
FIN
  fi
}

return
# TODO: Stuff that needs to be ported/tdd'd n stuff
# If anything is leftover, activate it now so we can fail later due to
# open filehandles from lvm to lower block devices in md/sd/nvme layer.
[ "lvm" = $flavor ] && vgchange -a n

# Partition setup efi only
#
# Layout:
# 1 = efi /boot (only partition on dedicatedBoot device)
# 2 = md0 raid partition for swap
# 3 = md1 raid partition for lvm iff lvm else used for zfs
# 4 = rest/other usage
#
# gpt guid list https://en.wikipedia.org/wiki/GUID_Partition_Table
# BC13C2FF-59E6-4262-A352-B275FD6F7172 /boot (uefi basically)
# 0FC63DAF-8483-4772-8E79-3D69D8477DE4 linux filesystem data
# A19D880F-05FC-4D3B-A006-743F0F84911E linux software raid guid
#
# Note on swap, why a swap partition and not say a zvol or file?
# Long story: cause zfs allocates memory for some structs
# leading to a deadlock when you're swapping, which is the last
# thing you want in a memory low situation ref:
# https://github.com/openzfs/zfs/issues/7734
#
# Just avoid it entirely and use a mirror ye olde swap device.

idx=0
for disk in $disks; do
  if [ 1 -eq "${wipe}" ]; then
     wipeit="yep"
  fi
  sfdisklabel gpt ${idx} "${dedicatedboot}" "${bootsize}" "${swapsize}" 50GiB | sfdisk --force ${wipeit+--wipe always --wipe-partitions always} "${disk}"
  idx=$((idx+1))
done

# Do not reboot in this instance
partprobe "${disks}"

# wait for each device to complete initialization/settle
device_settle "${disks}"

# md devices md0 and md1 (md1 iff flavor = lvm)
idx=0
count=0
md0=""
md1=""
for disk in $disks; do
  # dedicatedBoot is only for /boot, has no other partitions, don't
  # add it to the md setups
  if [ "${dedicatedboot}" != "" ] && [ "$idx" = "0" ]; then
    printf "skipping dedicated boot device\n" >&2
  else
    count=$((count+1))

    swappart="$disk-part2"
    ospart="$disk-part3"

    md0="$md0 $swappart"
    md1="$md1 $ospart"
  fi
  idx=$((idx+1))
done

# Need to do this or we can get errors because "device is in use" by
# frigging udev.... grr
# http://dev.bizo.com/2012/07/mdadm-device-or-resource-busy.html
udevadm control --stop-exec-queue
# metadata 1.0 at the end so we don't conflict with lvm stuff
# iff we only have 1 device, fake the $count to 2 and add a missing device
rcount=$count
if [ "$count" = 1 ]; then
  rcount=$(( count + 1 ))
  mdextra=" missing"
fi
mdadm --create /dev/md0 --run --level=1 --raid-devices=$rcount --metadata=1.0 $md0 missing
if [[ "lvm" = $flavor ]]; then
  mdadm --create /dev/md1 --run --level=1 --raid-devices=$rcount --metadata=1.0 $md1 missing
fi
udevadm control --start-exec-queue

# Sync of raid array(s) can happen after reboot/boot, lets not have
# it take iops away from the install
echo 0 > /proc/sys/dev/raid/speed_limit_max

# Get our swap going
mkswap /dev/md0
swapon /dev/md0

if [ "lvm" = $flavor ]; then
  # Setup lvm with xfs
  pvcreate /dev/md1
  vgcreate vgroot /dev/md1

  lvcreate --size 64G vgroot --name lvroot
  lvcreate --size 16G vgroot --name lvvar
  lvcreate --extents '+100%FREE' vgroot --name lvhome

  for lv in lvroot lvvar lvhome; do
    mkfs.xfs /dev/mapper/vgroot-$lv
  done

  mount /dev/mapper/vgroot-lvroot /mnt
  install -dm755 /mnt/var /mnt/home
  mount /dev/mapper/vgroot-lvvar /mnt/var
  mount /dev/mapper/vgroot-lvhome /mnt/home
elif [[ "zfs" = $flavor ]]; then
  # lz4 for everything in this pool, and what would be md1 in lvm is
  # where the zpool resides

  zpool create -f -O xattr=sa -O acltype=posixacl -O compression=lz4 -O atime=off -O mountpoint=legacy zroot $md1
  # TODO: add zpool attach existing-dev new-dev
  zfs create -o mountpoint=none zroot/os
  zfs create -o mountpoint=none zroot/user

  # Separating out os related and non datasets
  zfs create -o mountpoint=legacy zroot/os/root
  zfs create -o mountpoint=legacy zroot/os/nix
  zfs create -o mountpoint=legacy zroot/os/var

  # This can cover other "user" data like maybe vm's or whatever
  zfs create -o mountpoint=legacy zroot/user/home

  mount -t zfs zroot/os/root /mnt

  install -dm755 /mnt/var /mnt/nix /mnt/home
  mount -t zfs zroot/os/nix /mnt/nix
  mount -t zfs zroot/os/var /mnt/var

  mount -t zfs zroot/user/home /mnt/home
fi

idx=0
mirrorboots=""
for disk in $disks; do
  dev="$disk-part1"
  mkfs.vfat $dev
  mntpt=/mnt/boot
  if [[ "0" != "$idx" ]]; then
    mirrorboots="$mirrorboots $disk"
    mntpt="$mntpt$idx"
  fi
  install -dm755 $mntpt
  mount $dev $mntpt
  idx=$((idx+1))
done

# and finally setup the mirrored boot devices
idx=0
sed -i '$i  boot.loader.grub.mirroredBoots = [' $nixoscfg
for disk in $disks; do
  path="/boot"

  if [ "0" = "$idx" ]; then
    out="$path"
  else
    out="$path$idx"
  fi

  sed -i '$i    { devices = [ "nodev" ]; path = "'$out'"; }' $nixoscfg

  idx=$((idx+1))
done
sed -i '$i  ];' $nixoscfg

if [ "zfs" = $flavor ]; then
  for mnt in $(awk '/\/mnt\// {print $1}' /proc/mounts); do
    umount $mnt
  done

  umount /mnt

  # Export as per instructions
  zpool export zroot
fi
