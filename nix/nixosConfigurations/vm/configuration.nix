{
  inputs,
  lib,
  pkgs,
  ...
}:
# let
#   inherit (inputs) disko;
# in
{
  #  imports = [
  #   # infinite recursion...
  #   #    inputs.disko.nixosModules.disko

  #    (import ./disko.nix { })
  #  ];
  environment.variables.EDITOR = "vi";
}
