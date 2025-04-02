{
  stdenv,
  lib,
  pkgs,
  makeWrapper,
  inputs,
  system ? "x86_64-linux",
  ...
}:
let
  inherit (inputs) self;
in
inputs.nixos-generators.nixosGenerate {
  inherit pkgs;
  format = "install-iso";
  modules = [
    # default.nix is setup for a nixosSystem derivation
    ./../nixosConfigurations/iso/configuration.nix
    ./../installer

    {
      system.stateVersion = "24.11";
      networking.hostName = "isotest";
      # for normal (smaller)
      #      isoImage.squashfsCompression = "zstd";
      # for testing (faster)
      isoImage.squashfsCompression = "lz4";
    }
  ];
}
