{
  pkgs,
  lib,
  inputs,
  config,
  ...
}:
{
  # All me gui related junk goes here
  home.packages = with pkgs; [
    paid-fonts
  ];

  # This should go in a gooey module
  fonts.fontconfig.enable = true;
}
