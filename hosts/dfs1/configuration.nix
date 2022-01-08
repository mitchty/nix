{ config, pkgs, lib, ... }: {
  imports =
    [
      # Ordering of imports is for understanding not alphanumeric sorted
      ./hardware-configuration.nix
      ../nix.nix
      ../network.nix
      ../console.nix
      ../users.nix
      ../ssh.nix
      ../root.nix
      ../pkgs.nix
      ../shell.nix
      ../zfs.nix
      ../hosts.nix
    ];

  # For zfs
  networking.hostId = "96a61137";

  # non dhcp hostname
  networking.hostName = "dfs1";

  # This config is for nixos release 21.11
  system.stateVersion = "21.11";
}
