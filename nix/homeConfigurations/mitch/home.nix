{
  config,
  pkgs,
  lib,
  ...
}:
{
  home = rec {
    username = "mitch";
    homeDirectory = "/home/${username}";
    stateVersion = "24.11";
  };

  programs.home-manager.enable = true;
}
