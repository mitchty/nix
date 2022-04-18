{ config, pkgs, lib, inputs, age, ... }:
let
  emacsWithConfig = (pkgs.emacsWithPackagesFromUsePackage {
    config = ../static/emacs/readme.org;
    package = pkgs.emacsNativeComp;
    alwaysEnsure = true;
    extraEmacsPackages = epkgs: [
      epkgs.use-package
      epkgs.org
    ];
  });
in
{
  imports = [
    ./sh.nix
    ./zsh.nix
    ./git.nix
    ./tmux.nix
    ./btop.nix
    ./syncthing.nix
  ];

  # Note: mkoutofstoresymlink is here cause I don't want the age decrypted
  # secret in /nix/store, /nix/store/... can simply symlink to the file in /run.
  home.file.".canary".source = config.lib.file.mkOutOfStoreSymlink age.secrets.canary.path;

  systemd.user = lib.mkIf pkgs.stdenv.isLinux { startServices = "sd-switch"; };
  programs.home-manager.enable = true;

  # Common packages across all os's
  #
  # TODO: should have a grouping or module setup where I can turn stuff on/off
  # aka have something to control: is this a box for streaming? if so add
  # obs-studio etc.. something akin to roles in ansible.
  home.packages = with inputs.unstable.legacyPackages.${pkgs.system}; [
    avahi
    bind
    coreutils
    curl
    docker
    du-dust
    entr
    file
    gcc11
    gist
    git
    git-lfs
    gnumake
    gron
    htop
    inputs.mitchty.packages.${pkgs.system}.hwatch # TODO: Keep or no?
    jless
    less
    mercurial
    minio-client
    ncdu
    nix-prefetch-scripts
    nix-prefetch-github
    nixpkgs-fmt
    openssl
    p7zip
    pbzip2
    pigz
    podman
    pv
    rage
    rclone
    restic
    ripgrep
    s3cmd
    silver-searcher
    syncthing
    tldr
    tmuxp
    transcrypt
    unzip
    vim
    wget
    xz
    yt-dlp
    # Non gui linux stuff
  ] ++ lib.optionals stdenv.isLinux [
    # Testing packages that I may/not upstream any changes to nixpkgs
    inputs.mitchty.packages.${pkgs.system}.seaweedfs
    traitor

    docker-compose
    firefox
    lshw
    podman-compose
    tcpdump
    xorg.xauth
    # Gui linux stuff
    # TODO: how do I get at the nixos config setup...?
    # ] ++ lib.optional (stdenv.isLinux && config.services.role.gui.enable) [

    # macos only stuff (until I find something only macos empty...)
    # ] ++ lib.optionals stdenv.isDarwin [
  ];

  # TODO: Finish porting emacs config over future me fix
  programs.emacs = {
    enable = true;
    package = emacsWithConfig;
  };
  home.file = {
    ".emacs.d/init.el" = {
      source = ../static/emacs/init.el;
      recursive = true;
    };
    ".emacs.d/readme.org" = {
      source = ../static/emacs/readme.org;
      recursive = true;
    };
  };

  # Programs not (yet) worthy of their own .nix setup
  programs.go.enable = true;
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
