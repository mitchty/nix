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
  imports =
    [
      inputs.disko.nixosModules.disko
    ]
    ++ (with inputs.self.nixosModules; [
      kernel
      boot
      ssh
      sudo
      nix-common
      user-root
      time
    ]);
}
