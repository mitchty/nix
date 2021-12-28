{ config, pkgs, lib, ... }:

with pkgs;
{
  imports = [
    ./sh.nix
    ./zsh.nix
    ./git.nix
    ./tmux.nix
    ./syncthing.nix
  ];

  programs.home-manager.enable = true;
  home.username = "mitch";

  # Common packages across all os's
  #
  # TODO: should have a grouping or module setup where I can turn stuff on/off
  # aka have something to control: is this a box for streaming? if so add
  # obs-studio etc.. something akin to roles in ansible.
  home.packages = [
    ag
    age
    bind
    curl
    docker
    docker-compose
    du-dust
    emacs
    file
    git
    git-lfs
    gitAndTools.transcrypt
    glances
    # TODO: Figure out allowfreepredicate for home-manager
    # google-chrome
    htop
    mercurial
    niv
    openssl
    podman
    pv
    syncthing
    tcpdump
    tmux
    vim
    wget
    xorg.xauth
    xz
  ] ++ (if stdenv.isLinux then [
    dstat
    firefox
    iotop
    podman-compose
    powertop
    obs-studio
    xrdp
  ] else [ ]) ++ (if stdenv.isDarwin then [
    yt-dlp
  ] else [ ]);

  # TODO: Finish porting emacs config over also the overlay isn't working via
  # home-manager switch for some reason future me fix
  # programs.emacs = {
  #   enable = true;
  #   package = pkgs.emacsGcc;
  # };

  # Stuff not worthy of its own .nix file
  programs.jq.enable = true;
  programs.nix-index.enable = true;
}
