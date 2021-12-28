{ config, pkgs, lib, ... }: {
  imports =
    [
      # Ordering of imports is for understanding not alphanumeric sorted
      ./hardware-configuration.nix
      ../nix.nix
      ../network.nix
      ../pipewire.nix
      ../graphics.nix
      ../virtualization.nix
      ../console.nix
      ../users.nix
      ../ssh.nix
      ../root.nix
      ../pkgs.nix
      ../binfmt.nix
      ../shell.nix
      ../laptop.nix
      ./host.nix
      ../hosts.nix
    ];

  # Non dhcp hostname
  networking.hostName = "slaptop";

  # This config is for nixos release 21.11
  system.stateVersion = "21.11";
}
