{ config, ... }: {
  imports =
    [
      ./..
      ./hardware-configuration.nix
      ../virtualization.nix
      ../binfmt.nix
      ../zfs-grub.nix
      ../userscompat.nix
    ];
  # Due to ^^^ we're setting our ip statically
  config = {
    system.stateVersion = "22.05";
    services = {
      zfs.autoScrub.enable = true;
    };
    boot.loader.grub.mirroredBoots = [
      { devices = [ "nodev" ]; path = "/boot"; }
      { devices = [ "nodev" ]; path = "/boot1"; }
    ];
    networking = {
      hostName = "sys1";
      hostId = "76650d70";

      interfaces = {
        enp1s0.useDHCP = true;
        enp2s0.useDHCP = true;
      };
    };
  };
}
