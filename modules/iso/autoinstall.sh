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
host="${host?}"
configuration="${configuration?}"

# This is filled in at runtime, if not exit
#shellcheck disable=SC1090
for x in $(echo "${LIBSH}" | tr ':' ' '); do
  . "${x}"
done

# Pause until /tmp/okgo is found otherwise just keep looping waiting for the
# file.
pause() {
  go=/tmp/okgo
  while ! [ -e "${go}" ]; do
    printf "pause()\n" >&2
    if [ 1 = "${debug}" ]; then
      blimit=3
      breaker=10
      printf "backoff(%d %s)\n" "${blimit}" "${breaker}" >&2
      backoff ${blimit} ${breaker}
    else
      rs=$(randint 30)
      printf "sleep(%d)\n" "${rs}" >&2
      sleep "${rs}"
    fi
  done
  printf "rm -f %s\n" "${go}" >&2
  rm -f "${go}"
}

trap pause EXIT

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
    if [[ "" = "$byuuid" ]]; then
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

# Don't just keep appending to .bash_history...
if ! grep sysrq-trigger ~nixos/.bash_history > /dev/null 2>&1; then
  cat >> ~nixos/.bash_history << FIN
sudo sh -c "echo b > /proc/sysrq-trigger"
systemctl restart autoinstall
systemctl status autoinstall
journalctl -fb -n100 -uautoinstall
FIN
fi

pause

# Iff wipe is set, and we find *any* lvm *or* md devices, nuke em all from
# orbit before we do anything.
#
# Logic here is if anythings important, it shouldn't be plugged in. For
# home thats perfectly fine uncomplicated logic.
if [ 1 = "$wipe" ]; then
  # Have lvm activate anything that might be around
  vgchange -ay

  # TODO: hack for now, udevadm settle somehow? WHATEVER future me problem...
  sleep 10

  printf "Wiping all lvm+md setup\n" >&2
  # Nuke lv's first
  for lv in $(ls -d /dev/mapper/*-*); do
    printf "removing lv $lv\n"  >&2
    wipefs --all --force $lv
    lvremove -f $lv
  done

  # Then vg's
  for vg in $(vgs --noheadings | awk '{print $1}'); do
    printf "removing vg $vg\n" >&2
    vgremove $vgn
  done

  # Then pv's
  for pv in $(pvs --noheadings | awk '{print $1}'); do
    printf "removing pv $pv\n" >&2
    pvremove $pv
  done

  # Finally stop any md devices and zero the md superblocks if any
  if [[ -e /proc/mdstat ]]; then
    mdstat=/tmp/mdstat.$$
    cp /proc/mdstat $mdstat
    for md in $(cat $mdstat | awk '/md/ {print $1}'); do
      wipefs --all --force /dev/$md
      mdadm --stop /dev/$md
    done

    # Could be better done... but fits for the specific use case of
    # rebuilding for home.
    #
    # Only tested/valdiated against this specific setup/raid layout. If a
    # dev is sdc1 not sure what would happen.
    for dev in $(cat $mdstat | awk '/active/{print $0}' | sed -e 's/.*raid1 //' | tr -d "[01]"); do
      mdadm --zero-superblock --force /dev/$dev || :
      mdadm --zero-superblock --metadata 1.0 --force /dev/$dev || :
    done
  fi

  for disk in $disks; do
    if [[ 1 = "$zero" ]]; then
      dd if=/dev/zero of="$disk" bs=1M status=progress &
    fi
  done

  # Iff zero is set wait for dd's to finish
  if [[ 1 = "$zero" ]]; then
    printf "\nwaiting for dd's to finish\n" >&2
    wait
  fi
fi

# If partprobe fails, probably due to in use stuff, so just reboot,
# should clear it up on next install run, easier than trying to be
# cute with in use devices.
if ! partprobe --summary $disks; then
  debug
  echo b > /proc/sysrq-trigger
fi

# wait for each device to complete initialization/settle
for disk in $disks; do
  dev=$(readlink -f $disk)
  udevadm settle $dev
  for part in "$dev"-part*; do
    udevadm settle $part
  done
done

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
partprobe $disks

# wait for each device to complete initialization/settle
for disk in $disks; do
  dev=$(readlink -f $disk)
  udevadm settle $dev
  for part in "$dev"-part*; do
    udevadm settle $part
  done
done

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

# Add all networking devices as dhcp in networking
for net in $(ip link | awk '/^[[:digit:]]/ && !/lo/ {print $2}' | tr -d ':'); do
  sed -i '$i networking.interfaces.'"${net}"'.useDHCP = true;' $nixoscfg
done

nixos-install --system $(nix-build -I nixos-config=$nixoscfg '<nixpkgs/nixos>' -A system --no-out-link) --no-root-passwd --cores 0

if [ "zfs" = $flavor ]; then
  for mnt in $(awk '/\/mnt\// {print $1}' /proc/mounts); do
    umount $mnt
  done

  umount /mnt

  # Export as per instructions
  zpool export zroot
fi

# pause

# If we can reboot into firmware-setup via efi do that, otherwise poweroff so
# the usb stick/iso can be yeeted out.
if ! systemctl reboot --firmware-setup ; then
  shutdown now
fi
