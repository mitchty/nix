{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
{
  # imports = [
  #   ./../../homeModules/emacs.nix
  # ];

  home = rec {
    username = "mitch";
    homeDirectory = "/home/${username}";
    stateVersion = "24.11";
    packages = [
      pkgs.jq
      #      pkgs.myEmacs
      pkgs.home-manager
    ];
  };

  programs.home-manager.enable = true;
}
