{
  pkgs,
  lib,
  ...
}:
{
  # TODO: is there a programs.chrome in home-manager?
  home = {
    packages = with pkgs; [
      google-chrome
    ];
  };
}
