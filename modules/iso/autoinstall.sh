#!/usr/bin/env sh
#-*-mode: Shell-script; coding: utf-8;-*-
# SPDX-License-Identifier: BlueOak-1.0.0
# Description:
_base=$(basename "$0")
_dir=$(cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P || exit 126)
_script="${_dir}/${_base}"
export _base _dir

set "${SETOPTS:--eux}"

# This is filled in at runtime, if not exit
#shellcheck disable=SC1090
for x in $(echo "${LIBSH}" | tr ':' ' '); do
  . "${x}"
done

seed_shell_history

# Make sure everything is defined as an env var
disks="${disks?}"
wipe="${wipe?}"
zero="${zero?}"
flavor="${flavor?}"
debug="${debug?}"
bootsize="${bootsize?}"
swapsize="${swapsize?}"
ossize="${ossize?}"
hostid="${hostid?}"
host="${host?}"
configuration="${configuration?}"

# Pause until /tmp/okgo is found otherwise just keep looping waiting for the
# file.
pause() {
  go=/tmp/okgo
  while ! [ -e "${go}" ]; do
    printf "pause()\n" >&2
    rs=$(randint 30)
    printf "sleep(%d)\n" "${rs}" >&2
    sleep "${rs}"
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
    bootsize=${bootsize}
    swapsize=${swapsize}
    hostid=${hostid}
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
      printf "fatal: Could not find a /dev/disk/by- symlink for %s\n" "$disk" >&2
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
  printf "Wiping disk lvm \n" >&2
  wipe_lvm

  if [ 1 = "${zero}" ]; then
    printf "Zeroing disks\n" >&2
    zero_disks "${disks}"
  fi

  clear_partition_table_reboot "${disks}"
fi

device_settle "${disks}"

idx=0
for disk in $disks; do
  if [ 1 = "${wipe}" ]; then
    sgdisk -z "${disk}"
    sgdisk -og "${disk}"
  fi

  # New setup is we create only:
  # efi partition
  # swap (md raid paritition even with zfs)
  # boot (for zfs or lvm)
  # slop (if any)
  for part in 1 2 3; do
    case "${part}" in
      1)
        sgdisk --new ${part}::+"${bootsize}" --typecode=${part}:ef00 --change-name=${part}:"ESP${idx}" "${disk}"
        ;;
      2)
        sgdisk --new ${part}::+"${swapsize}" --typecode=${part}:8200 --change-name=${part}:"SWAP${idx}" "${disk}"
        ;;
      3)
        sgdisk --new ${part}::+"${ossize}" --typecode=${part}:bf01 --change-name=${part}:"ROOT${idx}" "${disk}"
        ;;
    esac
  done

  # Ensure we have the partitions just written to the device
  #shellcheck disable=SC2046
  partprobe $(readlink -f "${disk}")
  idx=$((idx + 1))
done

device_settle "${disks}"

devlabel() {
  printf "/dev/disk/by-partlabel/%s" "${1}"
}

# Works off part labels only now
setup_efi() {
  idx="${1?need an index number}"
  esp="ESP${idx}"
  # ^^^^^ its a non issue
  #shellcheck disable=SC2086
  mkfs.vfat -F 32 -n "${esp}" "$(devlabel ${esp})"
}

mount_efi() {
  idx="${1?need an index number}"
  shift
  prefix="${1:-/mnt}"
  src="/dev/disk/by-partlabel/ESP${idx}"
  dst="${prefix}/efiboot/efi${idx}"
  install -dm755 "${dst}"
  mount -t vfat -o iocharset=iso8859-1 "${src}" "${dst}"
}

partition_single() {
  disk="${1?need a disk to setup}"
  shift
  swap="${disk}-part2"
  root="${disk}-part3"

  mkswap -L SWAP0 "${swap}"
  setup_efi 0

  mkfs.xfs -L ROOT0 "${root}"

  install -dm755 /mnt
  mount LABEL=ROOT0 /mnt
  mount_efi 0
}

setup_single() {
  for disk in $disks; do
    partition_single "${disk}"
    break
  done
}

setup_zfs() {
  count=0
  pooldevs=
  mirrorboots=
  swapmd=

  install -dm755 /mnt

  idx=0
  for disk in $disks; do
    boot="${disk}-part1"
    swap="${disk}-part2"
    root="${disk}-part3"
    setup_efi "${idx}"

    pooldevs="${pooldevs} ${root}"
    mirrorboots="${mirrorboots} ${boot}"
    swapmd="${swapmd} ${swap}"
    count=$((count + 1))
    idx=$((idx + 1))
  done

  # metadata 1.0 at the end so we don't conflict with lvm stuff
  # iff we only have 1 device, fake the $count to 2 and add a missing device
  rcount=$count
  if [ "$count" = 1 ]; then
    rcount=$((count + 1))
    swapmd="${swapmd} missing"
  fi

  device_settle "${disks}"

  # Need to do this or we can get errors because "device is in use" by
  # frigging udev.... grr
  # http://dev.bizo.com/2012/07/mdadm-device-or-resource-busy.html
  udevadm control --stop-exec-queue

  md=md0

  # EVEN WITH ^^^ I am getting part2 Device or resource busy still aaaaaaa, but
  # it does eventually assemble? Just sometimes as /dev/md127 not what I said of
  # /dev/md0, but only in the autoinstall setup. After reboot its md0 as
  # expected.
  #shellcheck disable=SC2086
  if ! mdadm --create /dev/${md} --run --level=1 --raid-devices=$rcount --metadata=1.0 --name=SWAPMD --homehost=${host} ${swapmd}; then
    # We'll give ^^^ a max of 30 seconds to work/fight with udev.
    lim=30
    until [ ${lim} -eq 0 ]; do
      if grep -q active /proc/mdstat; then
        md=$(awk '/active raid1/ {print $1}' /proc/mdstat)
        lim=0
      else
        sleep 1
        lim=$((lim - 1))
      fi
    done
  fi
  udevadm control --start-exec-queue

  # Get our swap going and use it so the installer picks it up, not very useful
  # during install though.
  mkswap /dev/${md} -L SWAPMD
  swapon -L SWAPMD

  # Have to invert logic here, need the pool mounted and setup then we can mount
  # all the mirrored /boot partitions.

  # Strategy here is:
  # If count > 2 raidz
  # count == 2 mirror
  # else n/a
  strategy=""
  if [ "${count}" -gt 2 ]; then
    strategy="raidz"
  elif [ "${count}" -eq 2 ]; then
    strategy="mirror"
  fi

  zpool create -f \
    -o ashift=12 \
    -O acltype=posixacl \
    -O atime=off \
    -O compression=zstd \
    -O dnodesize=auto \
    -O mountpoint=none \
    -O xattr=sa \
    zroot ${strategy} ${pooldevs}

  # Lay out the zfs pool with os and user data in different top level layouts
  zfs create -o mountpoint=none zroot/os
  zfs create -o mountpoint=none zroot/user

  # Separating out os related and non datasets
  zfs create -o mountpoint=legacy zroot/os/root
  zfs create -o mountpoint=legacy zroot/os/nix
  zfs create -o mountpoint=legacy zroot/os/var

  # This can cover other "user" data like maybe vm's or whatever for now /home really
  zfs create -o mountpoint=legacy zroot/user/home

  mount -t zfs zroot/os/root /mnt

  install -dm755 /mnt/var /mnt/nix /mnt/home

  for dir in nix var; do
    mount -t zfs zroot/os/${dir} /mnt/${dir}
  done

  mount -t zfs zroot/user/home /mnt/home

  idx=0
  for disk in $disks; do
    mount_efi ${idx}
    idx=$((idx + 1))
  done
  df -h
}

# * here in case things are ran manually
case "${flavor}" in
  single | zfs | lvm)
    setup_${flavor}
    ;;
  *)
    printf "Invalid flavor detected %s\n" "${flavor}" >&2
    ;;
esac

# TODO: nixos-generate-config --show-hardware-config --no-filesystems
# and populate configuration.nix myself with fs data.
nixos-generate-config --root /mnt

# Generate the hostid by default off machine-id otherwise set it to what was provided.
if [ "${hostid}" = "auto" ]; then
  hostid="$(printf "00000000%x" "$(cksum /etc/machine-id | cut -d' ' -f1)" | tail -c8)"
fi
install -m644 /etc/machine-id /mnt/etc/machine-id
printf "%s\n" "${hostid}" | tee /mnt/etc/hostid

# First up, save what the dhcp config got saved with
# Note we ignore the configuration.nix from nixos-generate-config with our
# own, we just use the generated hardware-configuration file for its uuid links.
nixoscfg=/mnt/etc/nixos/configuration.nix

# Save off the generated configuration.nix file just in case
install -D $nixoscfg $nixoscfg.generated
install -D "${configuration}" $nixoscfg

# Ensure we're dumping out to the serial console in default kernel params not
# aligned cause nix-fmt can do that for us later.
sed -i '/kernelParams/a "console=ttyS0,115200n8"' ${nixoscfg}

# First up insert the hostname and hostid we generated
sed -i '$i  networking.hostName = "'"${host}"'";' $nixoscfg
sed -i '$i  networking.hostId = "'"${hostid}"'";' $nixoscfg

# Setup the boot loader setup in configuration.nix
#
# Since everything I own is EFI now, ditching grub entirely in lieu of just
# using systemd-boot + efi partitions. No need to insert a bootloader into this
# mess.
#
# The kernel/initrd is in the efi partition(s) and can just import the zpool
# directly no need for efi+/bootN+pool partitions.
sed -i "\$i  boot.loader.systemd-boot.extraInstallCommands = ''" $nixoscfg

idx=0
for disk in $disks; do
  if [ "${idx}" -gt 0 ]; then
    # sed -i '$i  echo syncing /efiboot/efi0/ ->  /efiboot/efi'"${idx}" $nixoscfg
    sed -i '$i  \$\{pkgs.rsync\}/bin/rsync -Ha --delete /efiboot/efi0/ /efiboot/efi'"${idx}" $nixoscfg
  fi
  idx=$((idx + 1))
done
sed -i "\$i                                     '';" $nixoscfg

if [ "zfs" = "${flavor}" ]; then
  sed -i '$i  boot.swraid.enable = true;' $nixoscfg
  sed -i "\$i boot.swraid.mdadmConf = ''\n'';" $nixoscfg

  mdadmconf=/mnt/etc/nixos/mdadm.conf
  printf "PROGRAM \$\{pkgs.coreutils\}/bin/true\n" > ${mdadmconf}

  mdadm --detail --scan --verbose >> ${mdadmconf}

  # Remove the uuid entry I only want md to use the named version of things
  sed -i 's/UUID.*//g' ${mdadmconf}

  # As well as stable device names, using partlabels instead of say /dev/sdN or
  # /dev/nvmeblah which depend on drivers behaving sanely which they don't.
  for device in $(grep devices=/dev ${mdadmconf} | awk -F= '{print $2}' | tr ',' ' '); do
    stable=$(find -L /dev -xdev -samefile ${device} -o -path '/dev/fd/*' -prune | awk '/by-partlabel/')
    sed -i "s|${device}|${stable}|g" ${mdadmconf}
  done

  # mds=$(find -L /dev -xdev -samefile /dev/${md} -o -path '/dev/fd/*' -prune)
  #  mdlabel=$(echo ${mds} | awk '/md-name/ {print $0}')

  sed -i "/mdadmConf/r${mdadmconf}" $nixoscfg
  sed -i '$i  boot.kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;' $nixoscfg
  sed -i '$i  boot.initrd.kernelModules = [ "zfs" ];' $nixoscfg
  sed -i '$i  boot.initrd.postDeviceCommands = "zpool import -lf zpool";' $nixoscfg
  sed -i '$i  boot.zfs.devNodes = "/dev/disk/by-partlabel";' $nixoscfg
fi
idx=0

# Add all networking devices as dhcp in networking
for net in $(ip link | awk '/^[[:digit:]]/ && !/lo/ {print $2}' | tr -d ':'); do
  sed -i '$i networking.interfaces.'"${net}"'.useDHCP = true;' $nixoscfg
done

# pause

for f in configuration.nix hardware-configuration.nix; do
  nixpkgs-fmt /mnt/etc/nixos/${f}
done

nixos-install --no-root-password

# pause

if [ "zfs" = $flavor ]; then
  for mnt in $(awk '/\/mnt\// {print $1}' /proc/mounts); do
    umount $mnt
  done

  umount /mnt

  # Export as per instructions on the wiki
  zpool export zroot
fi

# Make it easier to debug if things go sideways with a tempfile I can create
until [ ! -e /tmp/wait ]; do
  sleep 5
done

reboot_into_firmware_or_shutdown
