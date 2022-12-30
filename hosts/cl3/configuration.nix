{ config, ... }: {
  imports =
    [
      ./..
      ./hardware-configuration.nix
      ../kernel.nix
      ../virtualization.nix
      ../zfs-grub.nix
      ../userscompat.nix
    ];
  config = {
    system.stateVersion = "22.11";
    services = {
      zfs.autoScrub.enable = true;
    };
    boot.loader.grub.mirroredBoots = [
      { devices = [ "nodev" ]; path = "/boot"; }
      { devices = [ "nodev" ]; path = "/boot1"; }
    ];
    networking = {
      hostName = "cl3";
      hostId = "3d2578c6";

      interfaces = {
        enp1s0.useDHCP = true;
        enp2s0.useDHCP = true;
      };
    };
  };
}
