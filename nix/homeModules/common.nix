{
  pkgs,
  lib,
  inputs,
  config,
  ...
}:
{
  imports = with inputs.self.homeModules; [
    git
    sh
    tmux
  ];

  nix = {
    nixPath = [
      "nixpkgs=flake:nixpkgs"
    ];
  };

  home = {
    packages = with pkgs; [
      btop
      curl
      du-dust
      file
      gron
      htop
      hwatch
      less
      libqalculate
      moreutils
      mosh
      ripgrep
      tree
      wget
    ];
  };

  home = {
    file = {
      ".config/btop/btop.conf".source = ../../static/btop/btop.conf;
      ".canary".text = "ok";
    };
  };

  programs.direnv = {
    enable = true;
    stdlib = lib.readFile ../../static/home/direnvrc;
    enableBashIntegration = true;
    enableFishIntegration = false;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  # TODO: need to brain how to tack this into my direnvrc setup
  #   # xdg.configFile."direnv/direnvrc".text =
  #   #   "source ${pkgs.nix-direnv}/share/nix-direnv/direnvrc";

  #   programs = builtins.mapAttrs (_: v: { enable = true; } // v) {
  #     man.generateCaches = true;
  #   };
}
