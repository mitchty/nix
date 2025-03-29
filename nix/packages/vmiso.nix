{
  stdenv,
  lib,
  pkgs,
  makeWrapper,
  inputs,
  config,
  ...
}:
let
  inherit (inputs) self;
in
inputs.nixos-generators.nixosGenerate {
  inherit pkgs;
  format = "install-iso";
  modules = [
    inputs.disko.nixosModules.default
    ./../nixosConfigurations/vm/disko.nix
    ./../nixosConfigurations/vm/configuration-disko.nix
    # default.nix is setup for a nixosSystem derivation
    ./../nixosConfigurations/vm/configuration.nix
    ./../installer
    {
      system.stateVersion = "24.11";
      networking.hostName = "vmisotest";
      # for normal (smaller)
      #      isoImage.squashfsCompression = "zstd";
      # for testing (faster)
      isoImage.squashfsCompression = "lz4";
    }
  ];
}
