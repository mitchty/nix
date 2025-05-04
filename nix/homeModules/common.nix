{
  pkgs,
  lib,
  inputs,
  config,
  ...
}:
let
  inherit (lib) mkOption types;
in
{
  #  imports = with inputs.self.homeModules; [ emacs ];

  programs.home-manager.enable = true;

  home-manager = {
    enable = true;
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs pkgs; };
  };

  # config = {
  #   home = {
  #     packages = with pkgs; [
  #       man-pages
  #       man-pages-posix
  #       glibcInfo
  #       git
  #       git-absorb
  #       git-lfs
  #       ripgrep
  #       fd
  #       tree
  #       file
  #       moreutils
  #       jq
  #       gnutar
  #       strace
  #       parted
  #       zile
  #       podman
  #       gocryptfs
  #       awscli2
  #       bind.dnsutils
  #       bubblewrap
  #     ];
  #   };

  #   fonts.fontconfig.enable = true;

  #   # xdg.configFile."direnv/direnvrc".text =
  #   #   "source ${pkgs.nix-direnv}/share/nix-direnv/direnvrc";

  #   programs = builtins.mapAttrs (_: v: { enable = true; } // v) {
  #     man.generateCaches = true;
  #   };
  # };
}
