{ config, pkgs, lib, ... }: {
  systemd.services.install = {
    description = "Bootstrap a NixOS installation";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" "polkit.service" ];
    path = [ "/run/current-system/sw/" ];
    script = with pkgs; ''
      echo 'journalctl -fb -n100 -uinstall' >>~nixos/.bash_history
      set -eux
      disk0=/dev/sda
      disk0p1=$disk0'1'
      disk0p2=$disk0'2'
      parted -s $disk0 -- mklabel gpt
      parted -s $disk0 -- mkpart ESP fat32 1MiB 512MiB
      parted -s $disk0 -- set 1 esp on
      parted -s $disk0 -- mkpart primary 512MiB -2M

      sync

      hostid="$(printf "00000000%x" "$(cksum /etc/machine-id | cut -d' ' -f1)" | tail -c8)"

      # zfs
      zpool create -f -O xattr=sa -O acltype=posixacl -O compression=zstd -O atime=off zroot $disk0p2
      zfs create -o mountpoint=none zroot/local
      zfs create -o mountpoint=none zroot/safe
      zfs create -o mountpoint=legacy zroot/local/nix
      zfs create -o mountpoint=legacy zroot/safe/root
      zfs create -o mountpoint=legacy zroot/safe/home
      # zfs create -o mountpoint=none zroot/vms
      sync

      # efi nonsense
      mkfs.vfat $disk0p1

      # mount all the crap
      mount -t zfs zroot/safe/root /mnt
      mkdir /mnt/boot /mnt/etc /mnt/home /mnt/nix
      mount -t vfat $disk0p1 /mnt/boot
      mount -t zfs zroot/safe/home /mnt/home
      mount -t zfs zroot/local/nix /mnt/nix

      install -D ${./configuration.nix} /mnt/etc/nixos/configuration.nix
      install -D ${./hardware-configuration.nix} /mnt/etc/nixos/hardware-configuration.nix
      sed -i -E 's/(\w*)#installer-only /\1/' /mnt/etc/nixos/*
      sed -i -E 's/007f0100/'$hostid'/' /mnt/etc/nixos/hardware-configuration.nix
      cp /etc/machine-id /mnt/etc/machine-id
      echo "$hostid" | tee /mnt/etc/hostid
      ${config.system.build.nixos-install}/bin/nixos-install \
        --system ${
          (import <nixpkgs/nixos/lib/eval-config.nix> {
            system = "x86_64-linux";
            modules = [ ./configuration.nix ./hardware-configuration.nix ];
          }).config.system.build.toplevel
        } \
        --no-root-passwd \
        --cores 0
      echo 'Shutting off...'
      ${systemd}/bin/systemctl reboot --firmware-setup || ${systemd}/bin/shutdown now
    '';
    environment = config.nix.envVars // {
      inherit (config.environment.sessionVariables) NIX_PATH;
      HOME = "/root";
    };
    serviceConfig = { Type = "oneshot"; };
  };
}
