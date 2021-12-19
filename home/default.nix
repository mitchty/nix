{ config, pkgs, lib, ... }: {
  imports = [
    ./sh.nix
    ./zsh.nix
    ./git.nix
    ./tmux.nix
    ./syncthing.nix
  ];

  programs.home-manager.enable = true;
  home.username = "mitch";

  # Common packages across all
  home.packages = with pkgs; [
    ag
    age
    bind
    curl
    docker
    docker-compose
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
    podman
    syncthing
    tcpdump
    tmux
    vim
    wget
    xorg.xauth
    # ] ++ lib.optional pkgs.stdenv.isDarwin [
    #   # Stuff only macos needs (future)
  ] ++ lib.optional pkgs.stdenv.isLinux [
    # Stuff that might only build/install/work on linux
    dstat
    firefox
    iotop
    podman-compose
    xrdp
  ];

  # TODO: Finish porting emacs config over also the overlay isn't working via
  # home-manager switch for some reason future me fix
  # programs.emacs = {
  #   enable = true;
  #   package = pkgs.emacsGcc;
  # };

  # Stuff not worthy of its own .nix file
  programs.jq.enable = true;
}
