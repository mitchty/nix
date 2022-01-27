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
    bind
    curl
    docker
    docker-compose
    du-dust
    file
    git
    git-lfs
    gitAndTools.transcrypt
    glances
    htop
    mercurial
    nixpkgs-fmt
    openssl
    podman
    pv
    syncthing
    tcpdump
    tmux
    vim
    wget
    xz
    restic
    # Non gui linux stuff
  ] ++ lib.optionals stdenv.isLinux [
    dstat
    btop
    tmuxp
    iotop
    podman-compose
    powertop
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
}
