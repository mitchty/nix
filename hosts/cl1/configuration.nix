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
      hostName = "cl1";
      hostId = "c38b5592";

      interfaces = {
        enp1s0.useDHCP = true;
        enp2s0.useDHCP = true;
      };
    };
  };
}