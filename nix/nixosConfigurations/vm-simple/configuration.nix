{
  inputs,
  lib,
  pkgs,
  self,
  ...
}:
{
  imports = [
    inputs.disko.nixosModules.disko
    (import ./disko.nix { })
  ];
  environment.variables.EDITOR = "vi";

  # for normal (smaller)
  #      isoImage.squashfsCompression = "zstd";
  # for testing (faster)
  #  isoImage.squashfsCompression = "lz4";
}
