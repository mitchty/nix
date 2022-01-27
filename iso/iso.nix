{ config, pkgs, lib, ... }: with lib; {
  # I want my magic sysrq triggers to work
  config.boot.kernel.sysctl = {
    "kernel.sysrq" = 1;
  };

  # Packages
  config.environment.systemPackages = with pkgs; [
    pkgs.ed
  ];

  options = {
    autoinstall = {
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
      # TODO: A Flavor option of sorts if I want to bring back the zfs setup?
    };
  };
  config.systemd.services.autoinstall = {
    description = "Bootstrap a NixOS installation";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" "polkit.service" ];
    path = [ "/run/current-system/sw/" ];
    script = with pkgs; ''
            #!${pkgs.stdenv.shell}
            printf 'systemctl status autoinstall\n' >>~nixos/.bash_history
            printf 'journalctl -fb -n100 -uautoinstall\n' >>~nixos/.bash_history
            set -eux

            disks="${config.autoinstall.dedicatedBoot} ${toString config.autoinstall.rootDevices}"
            wipe=${toString config.autoinstall.wipe}
            zero=${toString config.autoinstall.zero}

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
            # clear it up.
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
            vgchange -a n

            # Partition setup efi only
            #
            # Layout:
            # 1 = silly efi bootable crap/padding
            # 2 = efi /boot
            # 3 = md0 raid partition for swap
            # 4 = md1 raid partition for lvm
            # 5 = rest/other usage
            #
            # gpt guid list https://en.wikipedia.org/wiki/GUID_Partition_Table
            # BC13C2FF-59E6-4262-A352-B275FD6F7172 /boot (uefi basically)
            # 0FC63DAF-8483-4772-8E79-3D69D8477DE4 linux filesystem data
            # A19D880F-05FC-4D3B-A006-743F0F84911E linux software raid guid
            idx=0
            for disk in $disks; do
              # --force as the ioctl sfdisk sends thinks unpartitioned is "in-use" which is dumb
              if [[ "${config.autoinstall.dedicatedBoot}" != "" ]] && [[ "$idx" = "0" ]] ; then
                sfdisk --force $disk <<FIN
      label: gpt

      1: size=   1MiB, type= 21686148-6449-6E6F-744E-656564454649
      2:               type= uefi, bootable
      FIN
              else
                sfdisk --force $disk <<FIN
      label: gpt

      1: size=   1MiB, type= 21686148-6449-6E6F-744E-656564454649
      2: size=   ${config.autoinstall.bootSize}, type= uefi, bootable
      3: size=   ${config.autoinstall.swapSize}, type= 0657FD6D-A4AB-43C4-84E5-0933C84B4F4F
      4: size= 256GiB, type= E6D6D379-F507-44C2-A23C-238F2A3DF928
      5:               type= 0FC63DAF-8483-4772-8E79-3D69D8477DE4
      FIN
              fi
              idx=$((idx+1))
            done

            # Do not reboot in this instance
            partprobe

            # wait for each device to complete initialization/settle
            for disk in $disks; do
              udevadm settle --timeout=10 $disk
              for part in "$disk"-part*; do
                udevadm settle --timeout=10 $part
              done
            done

            # md devices md0 and md1
            idx=0
            count=0
            md0=""
            md1=""
            for disk in $disks; do
              # dedicatedBoot is only for /boot, has no other partitions, don't add it to the md setups
              if [[ "${config.autoinstall.dedicatedBoot}" != "" ]] && [[ "$idx" = "0" ]]; then
                printf "skipping dedicated boot device\n"
              else
                count=$((count+1))

                part3="$disk-part3"
                part4="$disk-part4"

                md0="$md0 $part3"
                md1="$md1 $part4"
              fi
              idx=$((idx+1))
            done

            # Need to do this or we can get errors because "device is in use" by frigging udev.... grr
            # http://dev.bizo.com/2012/07/mdadm-device-or-resource-busy.html
            udevadm control --stop-exec-queue
            # metadata 1.0 at the end so we don't conflict with lvm stuff
            mdadm --create /dev/md0 --run --level=1 --raid-devices=$count --metadata=1.0 $md0
            mdadm --create /dev/md1 --run --level=1 --raid-devices=$count --metadata=1.0 $md1
            udevadm control --start-exec-queue

            # Sync of raid array can happen after reboot/boot, lets not have it take
            # iops from the install
            echo 0 > /proc/sys/dev/raid/speed_limit_max

            # Get our swap going
            mkswap /dev/md0
            swapon /dev/md0

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

            idx=0
            mirrorboots=""
            for disk in $disks; do
              # dev=$(readlink -f "$disk-part2")
              dev="$disk-part2"
              mkfs.vfat $dev
              mntpt=/mnt/boot
              if [[ "$idx" != "0" ]]; then
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
            install -D ${./configuration.nix} /mnt/etc/nixos/configuration.nix
            install -D ${./configuration.nix} /tmp

            # First up insert the hostname and hostid we generated
            sed -i '$i  networking.hostName = "'${config.autoinstall.hostName}'";' /mnt/etc/nixos/configuration.nix
            sed -i '$i  networking.hostId = "'$hostid'";' /mnt/etc/nixos/configuration.nix

            # and finally setup the mirrored boot devices
            idx=0
            sed -i '$i  boot.loader.grub.mirroredBoots = [' /mnt/etc/nixos/configuration.nix
            for disk in $disks; do
              path="/boot"
              if [[ "$idx" = "0" ]]; then
                sed -i '$i    { devices = [ "nodev" ]; path = "'$path'"; }' /mnt/etc/nixos/configuration.nix
              else
                sed -i '$i    { devices = [ "nodev" ]; path = "'$path$idx'"; }' /mnt/etc/nixos/configuration.nix
              fi
              idx=$((idx+1))
            done
            sed -i '$i  ];' /mnt/etc/nixos/configuration.nix

            /run/current-system/sw/bin/nixos-install --system $(nix-build -I nixos-config=/mnt/etc/nixos/configuration.nix '<nixpkgs/nixos>' -A system --no-out-link) --no-root-passwd --cores 0
            echo 10 > /proc/sys/dev/raid/speed_limit_max

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
