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
    inputs.disko.nixosModules.disko
    inputs.agenix.nixosModules.default
  ]
  ++ (with inputs.self.nixosModules; [
    kernel
    boot
    ssh
    sudo
    user-root
    time
    mitchty-secrets
  ]);
}
