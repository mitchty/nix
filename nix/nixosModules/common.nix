{
  config,
  options,
  pkgs,
  lib,
  inputs,
  hostname,
  ...
}:
let
  inherit (inputs) self;
in
{
  # Common imports for nixos
  imports = [
    inputs.home-manager.nixosModules.home-manager
    inputs.disko.nixosModules.disko
    inputs.self.nixosModules.kernel
    inputs.self.nixosModules.boot
    inputs.self.nixosModules.ssh
    inputs.self.nixosModules.sudo
    inputs.self.nixosModules.nix-common
    inputs.self.nixosModules.user-root
  ];
}
