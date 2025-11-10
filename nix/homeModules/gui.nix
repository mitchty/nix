{
  pkgs,
  lib,
  inputs,
  config,
  ...
}:
let
  enableFullBuild = import ../../hacks/flake-check.nix;
in
{

  fonts.fontconfig.enable = enableFullBuild;
}
