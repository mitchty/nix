{ config, pkgs, ... }:
{
  programs.home-manager.enable = true;
  home.username = "mitch";
  home.homeDirectory = "/home/mitch";
  # home.stateVersion = "21.05";

  home.packages = with pkgs; [
    ag
    bind
    curl
    docker
    docker-compose
    dstat
    git
    git-lfs
    gitAndTools.transcrypt
    glances
    htop
    iotop
    jq
    niv
    syncthing
    tcpdump
    tmux
    wget
    xorg.xauth
    xrdp
  ];

  # TODO: convert zsh config to this
  programs.zsh = {
    enable = true;
    enableCompletion = true;
  };

  # TODO: convert emacs config to this setup and make the emacs overlay work...
  programs.emacs = {
    enable = true;
    package = pkgs.emacs;
    # package = unstable.emacsGcc;
    # extraPackages = (epkgs: [ epkgs.vterm] );
  };

  #  home.file = ...
}
