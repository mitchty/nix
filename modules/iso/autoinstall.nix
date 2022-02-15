{ config, pkgs, lib, ... }:
with lib;

let
  modules = [ "dm-thin-pool" "dm-cache" ];
in
{
  config = {
    # BIG TODO: merge the runtime config and this autoinstall setup
    boot.initrd.kernelModules = modules;
    boot.initrd.availableKernelModules = modules;
    boot.kernelModules = modules;

    services.lvm.boot.thin.enable = true;

    boot.kernelParams = [ "delayacct" ];

    # boot.kernelPackages = pkgs.linuxPackages_latest;

    # kernelPatches = pkgs.lib.singleton {
    #   name = "Custom extra kernel config + maybe patches at some point";
    #   patch = null;
    #   # The default nixpkgs kernel has these as modules, but whatever just
    #   # compile them in statically
    #   extraConfig = ''
    #      DM_CACHE m
    #      DM_INTEGRITY m
    #      DM_VERITY m
    #      DM_THIN_PROVISIONING m
    #   '';
    # };

    # No docs on the install iso
    documentation.enable = false;
    documentation.nixos.enable = false;

    # Make the default password blank for installing
    users.users.nixos = {
      isNormalUser = true;
      initialHashedPassword = "";
    };

    # Same as root
    users.users.root.initialHashedPassword = "";

    # Autologin to the nixos install user on getty
    services.getty.autologinUser = "nixos";

    # Let me ssh in by default
    services.openssh = {
      enable = true;
      permitRootLogin = "yes";
    };

    # Don't flush to the backing store
    environment.etc."systemd/pstore.conf".text = ''
      [PStore]
      Unlink=no
    '';

    # Don't log failed connections
    networking.firewall.logRefusedConnections = mkDefault false;

    # I want my magic sysrq triggers to work
    boot.kernel.sysctl = {
      "kernel.sysrq" = 1;
    };

    # Give our installer a bit more by default to be more useful.
    system.extraDependencies = with pkgs; [
      btop
      busybox
      curl
      dropwatch
      iotop
      jq
      linuxPackages.cpupower
      linuxPackages.perf
      lvm2
      lvm2.bin
      mdadm
      parted
      powertop
      stdenv
      stdenvNoCC
      strace
      tcpdump
      thin-provisioning-tools
      utillinux
      vim
    ];
  };

  options = {
    autoinstall = {
      debug = mkOption {
        type = types.bool;
        default = false;
        description = "If we should exit before installing or not to let debugging occur";
      };
      hostName = mkOption {
        type = types.str;
        default = "changeme";
        description = "the hostname the system will be known as";
      };
      rootDevices = mkOption {
        type = types.listOf types.str;
        default = "/dev/sda";
        description = "the root block device that justdoit will nuke from orbit and force nixos onto";
      };
      bootSize = mkOption {
        type = types.str;
        default = "1GiB";
        description = "/boot size";
      };
      swapSize = mkOption {
        type = types.str;
        default = "2GiB";
        description = "swap size";
      };
      wipe = mkOption {
        type = types.bool;
        default = false;
        description = "run wipefs on devices prior to install";
      };
      zero = mkOption {
        type = types.bool;
        default = false;
        description = "zero out devices prior to install (time consuming)";
      };
      dedicatedBoot = mkOption {
        type = types.str;
        default = "";
        description = "If there should be a dedicated /boot device fill this in with the device name.";
      };
      # nop for now, well untested at best
      flavor = mkOption {
        type = types.enum [ "zfs" "lvm" ];
        default = "zfs";
        description = "Specify the disk layout type";
      };
    };
  };
  config.systemd.services.autoinstall = {
    description = "Bootstrap a NixOS installation";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" "polkit.service" ];
    path = [ "/run/current-system/sw/" ];
    script = with pkgs; ''
            #!${pkgs.stdenv.shell}
            _base=$(basename "$0")
            _dir=$(cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P || exit 126)
            _iam="$_dir/$_base"
            export _base _dir _iam

            printf 'systemctl status autoinstall\njournalctl -fb -n100 -uautoinstall\n' >>~nixos/.bash_history

            set -eux

            disks="${config.autoinstall.dedicatedBoot} ${toString config.autoinstall.rootDevices}"
            wipe=${toString config.autoinstall.wipe}
            zero=${toString config.autoinstall.zero}
            flavor=${toString config.autoinstall.flavor}

            wack=0
            disksbyid=""
            for $disk in $disks; do
              # See if we got passed in something like /dev/sda /dev/nvme... If
              # so use a /dev/disk/by-uuid link if we see the string /dev/disk/by- presume
              # its ok/right, we just need the links to get at the -part entries
              # so the logic in the script is simple and can presume -part
              # instead of care about the silliness difference between partition
              # suffixes of sd and nvme etc...
              if [[ $(echo $disk | grep '/dev/disk/by-') ]]; then
                disksbyid="$disksbyid $disk"
              else
                byuuid=$(find -L /dev/disk -samefile $disk | grep uuid)
                if [[ "" = "$byuuid" ]]; then
                  printf "fatal: Could not find a /dev/disk/by-uuid symlink for %s\n" "$disk"
                  wack=1
                else
                  disksbyid="$disksbyid $byuuid"
                fi
              fi
            done

            if [[ $wack -gt 0 ]]; then
              exit 2
            fi

            if [ 1 = ${toString config.autoinstall.debug} ]; then
              printf "Debug set vars are:\n"
              printf "disks=%s\n" "$disks"
              printf "diskbyid=%s\n" "$disksbyid"
              printf "wipe=%s\n" "$wipe"
              printf "zero=%s\n" "$zero"
              printf "flavor=%s\n" "$flavor"
              if [ ! -f /tmp/okgo ]; then
                printf "Not installing automatically as debug is set and /tmp/okgo not present\n"
                printf "iam: %s\n" "$_iam"
                exit 1
              fi
            fi

            # Iff wipe is set, and we find *any* lvm *or* md devices, nuke em all from
            # orbit before we do anything.
            #
            # Logic here is if anythings important, it shouldn't be plugged in. For
            # home thats perfectly fine uncomplicated logic.
            if [[ 1 = "$wipe" ]]; then
              # Have lvm activate anything that might be around
              vgchange -ay

              # TODO: hack for now, udevadm settle somehow? WHATEVER
              sleep 10

              printf "Wiping all lvm+md setup\n"
              # Nuke lv's first
              for lv in $(ls -d /dev/mapper/*-*); do
                printf "removing lv $lv\n"
                wipefs --all --force $lv
                lvremove -f $lv
              done

              # Then vg's
              for vg in $(vgs --noheadings | awk '{print $1}'); do
                printf "removing vg $vg\n"
                vgremove $vg
              done

              # Then pv's
              for pv in $(pvs --noheadings | awk '{print $1}'); do
                printf "removing pv $pv\n"
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
                printf "\nwaiting for dd's to finish\n"
                wait
              fi
            fi

            # If partprobe fails, probably due to in use stuff, so just reboot, should
            # clear it up on next install run.
            partprobe || systemctl reboot

            # wait for each device to complete initialization/settle
            for disk in $disks; do
              udevadm settle --timeout=10 $(readlink -f $disk)
              for part in "$disk"-part*; do
                udevadm settle --timeout=10 $($part -f $part)
              done
            done

            # If anything is leftover, activate it now so we can fail later due to
            # open filehandles from lvm to lower block devices in md/sd/nvme layer.
            [[ $flavor = "lvm" ]] && vgchange -a n

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
              # --force as the ioctl sfdisk sends thinks unpartitioned is "in-use" which is dumb
              if [[ "${config.autoinstall.dedicatedBoot}" != "" ]] && [[ "$idx" = "0" ]] ; then
                sfdisk --force $disk <<FIN
      label: gpt

      1:               type= uefi, bootable
      FIN
              else
                sfdisk --force $disk <<FIN
      label: gpt

      1: size=   ${config.autoinstall.bootSize}, type= uefi, bootable
      2: size=   ${config.autoinstall.swapSize}, type= 0657FD6D-A4AB-43C4-84E5-0933C84B4F4F
      3: size= 256GiB, type= E6D6D379-F507-44C2-A23C-238F2A3DF928
      4:               type= 0FC63DAF-8483-4772-8E79-3D69D8477DE4
      FIN
              fi
              idx=$((idx+1))
            done

            # Do not reboot in this instance
            partprobe

            # wait for each device to complete initialization/settle
            for disk in $disks; do
              dev=$(readlink -f $disk)
              udevadm settle --timeout=10 $dev
              for part in "$disk"-part*; do
                dev=$(readlink -f $part)
                udevadm settle --timeout=10 $
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
              if [[ "${config.autoinstall.dedicatedBoot}" != "" ]] && [[ "$idx" = "0" ]]; then
                printf "skipping dedicated boot device\n"
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
            mdadm --create /dev/md0 --run --level=1 --raid-devices=$count --metadata=1.0 $md0
            if [[ "lvm" = $flavor ]]; then
              mdadm --create /dev/md1 --run --level=1 --raid-devices=$count --metadata=1.0 $md1
            fi
            udevadm control --start-exec-queue

            # Sync of raid array(s) can happen after reboot/boot, lets not have
            # it take iops away from the install
            echo 0 > /proc/sys/dev/raid/speed_limit_max

            # Get our swap going
            mkswap /dev/md0
            swapon /dev/md0

            if [[ "lvm" = $flavor ]]; then
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

              zpool create -f -O xattr=sa -O acltype=posixacl -O compression=lz4 -O atime=off -O mountpoint=legacy zroot mirror $md1
              zfs create -o mountpoint=none zroot/os
              zfs create -o mountpoint=none zroot/user

              # Separating out os related and non datasets
              zfs create -o mountpoint=legacy zroot/os/root
              zfs create -o mountpoint=legacy zroot/os/nix
              zfs create -o mountpoint=legacy zroot/os/var

              # This can cover other "user" data like maybe vm's or whatever
              zfs create -o mountpoint=legacy zroot/user/home

              mount -t zfs zroot/os/root /mnt

              install -dm755 /mnt/var /mnt/home /mnt/nix
              mount -t zfs zroot/os/nix /mnt/nix
              mount -t zfs zroot/os/nix /mnt/var

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
            install -D ${./configuration.nix} $nixoscfg
            install -D $nixoscfg original-$nixoscfg

            # First up insert the hostname and hostid we generated
            sed -i '$i  networking.hostName = "'${config.autoinstall.hostName}'";' $nixoscfg
            sed -i '$i  networking.hostId = "'$hostid'";' $nixoscfg

            # and finally setup the mirrored boot devices
            idx=0
            sed -i '$i  boot.loader.grub.mirroredBoots = [' $nixoscfg
            for disk in $disks; do
              path="/boot"

              if [[ "0" = "$idx" ]]; then
                out="$path"
              else
                out="$path$idx"
              fi

              sed -i '$i    { devices = [ "nodev" ]; path = "'$out'"; }' $nixoscfg

              idx=$((idx+1))
            done
            sed -i '$i  ];' $nixoscfg

            /run/current-system/sw/bin/nixos-install --system $(nix-build -I nixos-config=$nixoscfg '<nixpkgs/nixos>' -A system --no-out-link) --no-root-passwd --cores 0

            if [[ "zfs" = $flavor ]]; then
              for mnt in $(awk '/\/mnt\// {print $1}' /proc/mounts); do
                umount $mnt
              done

              umount /mnt

              # Export as per instructions
              zpool export zroot
            fi

            # If efi booted reboot into firmware setup, otherwise power off
            ${systemd}/bin/systemctl reboot --firmware-setup || ${systemd}/bin/shutdown now
    '';
    environment = config.nix.envVars // {
      inherit (config.environment.sessionVariables) NIX_PATH;
      HOME = "/root";
    };
    serviceConfig = { Type = "oneshot"; };
  };
}
