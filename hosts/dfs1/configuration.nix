{ config, pkgs, ... }: {
  imports =
    [
      ./..
      ../kernel.nix
      # Ordering of imports is for understanding not alphanumeric sorted
      ./hardware-configuration.nix
      # Samba is ASS it constantly coredumps on me when I try to use it
      # ../samba.nix
      ../zfs-grub.nix
    ];

  system.stateVersion = "21.11";

  # Generated stuff goes here...
  networking.hostName = "dfs1";
  networking.hostId = "133320cd";
  boot.loader.grub.mirroredBoots = [
    { devices = [ "nodev" ]; path = "/boot"; }
    { devices = [ "nodev" ]; path = "/boot1"; }
    { devices = [ "nodev" ]; path = "/boot2"; }
  ];

  # This is an intel system, do "intel" stuff to it
  config.services.role.intel.enable = true;

  # Tag this system as a low memory system
  config.services.role.lowmem.enable = true;
}
