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
  inherit (builtins) mapAttrs substring hashString;
in
{
  imports = [
    #    inputs.impermanence.nixosModules.impermanence
    #    inputs.lanzaboote.nixosModules.lanzaboote
    # self.nixosModules.lix
    # self.nixosModules.kernel
    # self.nixosModules.disks
    # self.nixosModules.tailscale
  ];

  system.configurationRevision = self.rev or null;
}
