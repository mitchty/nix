{ config, pkgs, ... }:
{
  programs.home-manager.enable = true;
  home.username = "mitch";
  home.homeDirectory = "/home/mitch";
  # home.stateVersion = "21.05";

  home.packages = with pkgs; [
    jq
    git
  ];

#  home.file = ...
}
