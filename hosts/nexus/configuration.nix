{ config, pkgs, lib, ... }: {
  imports =
    [
      # Ordering of imports is for understanding not alphanumeric sorted
      ./hardware-configuration.nix
      ../sysrq.nix
      ../nix.nix
      ../network.nix
      ../pipewire.nix
      ../virtualization.nix
      ../console.nix
      ../users.nix
      ../ssh.nix
      ../root.nix
      ../pkgs.nix
      ../binfmt.nix
      ../shell.nix
      ../desktop.nix
      ../zfs.nix
      ../hosts.nix
    ];

  # For zfs
  config.networking.hostId = "30d18215";

  # Non dhcp hostname
  config.networking.hostName = "nexus";

  # This config is for nixos release 21.11
  config.system.stateVersion = "21.11";

  # This is an intel system, do "intel" stuff to it
  config.services.role.intel.enable = true;

  # We want gui stuff here
  config.services.role.gui.enable = true;
}
