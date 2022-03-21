{ config, pkgs, lib, inputs, ... }: {
  imports = [
    ./sh.nix
    ./zsh.nix
    ./git.nix
    ./tmux.nix
    ./btop.nix
    ./syncthing.nix
  ];

  systemd.user = lib.mkIf pkgs.stdenv.isLinux { startServices = "sd-switch"; };
  programs.home-manager.enable = true;

  # Common packages across all os's
  #
  # TODO: should have a grouping or module setup where I can turn stuff on/off
  # aka have something to control: is this a box for streaming? if so add
  # obs-studio etc.. something akin to roles in ansible.
  home.packages = with pkgs; [
    avahi
    bind
    coreutils
    curl
    docker
    du-dust
    entr
    file
    gist
    git
    git-lfs
    gnumake
    htop
    inputs.mitchty.packages.${pkgs.system}.hwatch # TODO: Keep or no?
    inputs.unstable.legacyPackages.${pkgs.system}.jless
    less
    mercurial
    minio-client
    ncdu
    nix-prefetch-git
    nixpkgs-fmt
    openssl
    podman
    pv
    rclone
    restic
    ripgrep
    sops
    s3cmd
    silver-searcher
    syncthing
    tldr
    tmux
    tmuxp
    transcrypt
    unzip
    vim
    wget
    xz
    # Non gui linux stuff
  ] ++ lib.optionals stdenv.isLinux [
    tcpdump

    # Testing packages that I may/not upstream any changes to nixpkgs
    inputs.mitchty.packages.${pkgs.system}.seaweedfs

    inputs.unstable.legacyPackages.${pkgs.system}.traitor

    # Normal nixpkgs stuff
    podman-compose

    lshw
    # Gui linux stuff
    # TODO: how do I get at the nixos config setup...?
    # ] ++ lib.optional (stdenv.isLinux && config.services.role.gui.enable) [
    docker-compose
    firefox
    xorg.xauth
    # macos only stuff
  ] ++ lib.optionals stdenv.isDarwin [
    yt-dlp
  ];

  # TODO: Finish porting emacs config over future me fix
  programs.emacs = {
    enable = true;
    package = pkgs.emacsGcc;
  };

  # Stuff not worthy of its own .nix file
  programs.jq.enable = true;
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
