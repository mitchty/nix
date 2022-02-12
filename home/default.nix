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

  systemd.user = lib.mkIf stdenv.isLinux { startServices = "sd-switch"; };
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
    avahi
    bind
    btop
    coreutils
    curl
    docker
    docker-compose
    du-dust
    file
    git
    git-lfs
    gitAndTools.transcrypt
    gist
    glances
    htop
    mercurial
    ncdu
    nix-prefetch-git
    nixpkgs-fmt
    openssl
    podman
    pv
    restic
    ripgrep
    syncthing
    tcpdump
    tldr
    tmux
    tmuxp
    vim
    wget
    xz
    unzip
    # Non gui linux stuff
  ] ++ lib.optionals stdenv.isLinux [
    podman-compose
    # Gui linux stuff
    # TODO: how do I get at the nixos config setup...?
    # ] ++ lib.optional (stdenv.isLinux && config.services.role.gui.enable) [
    emacs
    firefox
    obs-studio
    xrdp
    xorg.xauth
    # macos only stuff
  ] ++ lib.optionals stdenv.isDarwin [
    yt-dlp
  ];

  # TODO: Finish porting emacs config over also the overlay isn't working via
  # home-manager switch for some reason future me fix
  # programs.emacs = {
  #   enable = true;
  #   package = pkgs.emacsGcc;
  # };

  # Stuff not worthy of its own .nix file
  programs.jq.enable = true;
  programs.nix-index.enable = true;
  programs.direnv = {
    enable = true;
    enableBashIntegration = true;
    enableFishIntegration = false;
    enableZshIntegration = true;
    nix-direnv = {
      enable = true;
    };
  };
}
