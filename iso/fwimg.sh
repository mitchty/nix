#!/usr/bin/env nix-shell
#-*-mode: Shell-script; coding: utf-8;-*-
#!nix-shell -i bash -p bash grub2_efi gptfdisk util-linux libarchive dosfstools parted
# File: fwboot.sh
_base=$(basename "$0")
_dir=$(cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P || exit 126)
export _base _dir

set -x
cd "${_dir}" || exit 126

loopdev=""
mountdir="$(mktemp --directory $0-XXXXXX)"

cleanup() {
    cd /
    if [[ -e "${mountdir}" ]]; then
        umount "${mountdir}" || :
        rmdir "${mountdir}" || :
    fi
    if [[ -e "${loopdev}" ]]; then
        losetup -d "${loopdev}" || :
    fi
}

trap cleanup EXIT

set -eu
img=/var/tmp/arch.img
fallocate -l 1G "${img}"
loopdev=$(losetup --find "${img}" --show)
udevadm settle

sgdisk --zap-all "${loopdev}"
sgdisk --clear --mbrtogpt "${loopdev}"
sgdisk --new 1:2048:0 --change-name 1:"ARCH_202112" "${loopdev}"

# sgdisk --new 1:2048:4095 --change-name 1:"GRUB" --typecode 1:ef02 "${loopdev}"
# sgdisk --new 2:4096:1050623 --change-name 2:"EFI" --typecdoe 2:ef00 --attributes "2:set:2" "${loopdev}"
sgdisk --print "${loopdev}"
partprobe "${loopdev}"
sleep 3
install -dm755 "${mountdir}"

ls -dal ${loopdev}*
loopdevp1="${loopdev}p1"
mkfs.fat -F 32 -h 4096 -n "ARCH_202112" "${loopdevp1}"
mountdir="/var/tmp/fw-"$$
install -dm755 "${mountdir}"
mount "${loopdevp1}" "${mountdir}"
bsdtar -x --exclude=syslinux/ -f /home/mitch/Downloads/archlinux-2021.12.01-x86_64.iso -C "${mountdir}"
fatlabel "${loopdevp1}" "ARCH_202112"
find "${mountdir}"
exit $?


find $(dirname $(which grub-mkimage))/..

#---

rm -f "$ROOT/$IMAGE"
fallocate -l 1G "$ROOT/$IMAGE"
sleep 1
sgdisk --zap-all "$LOOPDEV"
sgdisk --clear --mbrtogpt "$LOOPDEV"
# 1M
sgdisk --new 1:2048:4095 --change-name 1:"GRUB" --typecode 1:ef02 "$LOOPDEV"
# 512M
sgdisk --new 2:4096:1050623 --change-name 2:"EFI" --typecode 2:ef00 --attributes "2:set:2" "$LOOPDEV"

mkdir -p "$ROOT"/bootpart
mkfs.fat -F 32 -h 4096 -n "EFI" "$LOOPDEV"p2
mount -t vfat "$LOOPDEV"p2 "$ROOT"/bootpart

# install kernel & initramfs
mkdir -p "$ROOT"/bootpart/boot
cp -v "$ROOT"/boot/{vmlinuz,initrd.img}* "$ROOT"/bootpart/boot

# install rootfs
mkdir -p "$ROOT"/bootpart/system
cp "$ROOT"/rootfs.squashfs "$ROOT"/bootpart/system/rootfs.squashfs

# install GRUB2 CSM
# The plain old method that is device-specific doesn't work on every device:
#grub-install --force --skip-fs-probe --target=i386-pc --boot-directory="$ROOT"/bootpart/boot "$LOOPDEV"
# Override core.img to insert gpt modules:
# http://www.dolda2000.com/~fredrik/doc/grub2
cp -r /usr/lib/grub "$ROOT"/grub
grub-mkimage -O i386-pc -o "$ROOT"/grub/i386-pc/core.img -c grub/earlyconfig.cfg --prefix "" $GRUB_MODULES
# we cannot install grub-pc on Ubuntu 16.04 because of a dependency hell so a symlink is missing
# we have to use the original absolute path
/usr/lib/grub/i386-pc/grub-bios-setup --force --skip-fs-probe --directory="$ROOT"/grub/i386-pc "$LOOPDEV"

# install GRUB2 UEFI
grub-install --force --skip-fs-probe --target=x86_64-efi --boot-directory="$ROOT"/bootpart/boot --efi-directory="$ROOT"/bootpart --bootloader-id=GRUB --uefi-secure-boot --removable --no-nvram

# populate GRUB2 config
KERNEL_FILENAME=$(basename `ls "$ROOT"/boot/vmlinuz-* | head -n 1 `)
INITRD_FILENAME=$(basename `ls "$ROOT"/boot/initrd.img* | head -n 1 `)
echo "kernel: $KERNEL_FILENAME"
echo "initrd: $INITRD_FILENAME"
cat > "$ROOT"/bootpart/boot/grub/grub.cfg <<EOF
timeout=3

insmod part_gpt
insmod part_msdos
insmod fat
insmod acpi
insmod loadenv
insmod test

insmod linux
insmod gzio
insmod xzio
insmod lzopio

menuentry 'UEFI firmware setup' {
    fwsetup
}

menuentry 'Reboot' {
    insmod reboot
    reboot
}

menuentry 'Poweroff' {
    insmod halt
    halt
}
EOF

cp grub/earlyconfig.cfg "$ROOT"/bootpart/EFI/BOOT/grub.cfg
# workaround GRUB2 legacy modules missing
cp -r /usr/lib/grub/i386-pc "$ROOT"/bootpart/boot/grub/i386-pc
# Unicode font
cp /usr/share/grub/unicode.pf2 "$ROOT"/bootpart/boot/grub/unicode.pf2

# calculate checksums
pushd "$ROOT"/bootpart
rm -f md5sum.txt
find . ! -name 'md5sum.txt' ! -name 'grubenv' -exec md5sum {} \; 2>/dev/null | tee md5sum.txt
popd

# clean up
umount "$ROOT"/bootpart
losetup -d "$LOOPDEV"

ls -alh "$ROOT"/"$IMAGE"
