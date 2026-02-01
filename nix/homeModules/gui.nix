{
  pkgs,
  lib,
  inputs,
  config,
  ...
}:
let
  enableFullBuild = import ../../hacks/flake-check.nix pkgs.stdenv.hostPlatform.system;
in
{
  # Fonts trigger builds on the destination platform if cross checking but normally we want them
  home.packages = lib.optionalAttrs enableFullBuild [
    pkgs.comic-code
    pkgs.pragmata-pro
    pkgs.noto-fonts-cjk-sans
    pkgs.noto-fonts-cjk-serif
  ];

  fonts.fontconfig.enable = enableFullBuild;
}
