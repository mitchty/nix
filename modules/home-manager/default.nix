{ config, pkgs, lib, inputs, age, ... }:
with lib;

let
  # TODO: figure out a way to import based on this...
  # sys = pkgs.lib.last (pkgs.lib.splitString "-" pkgs.system);
  emacsWithConfig = (pkgs.emacsWithPackagesFromUsePackage {
    config = ../../static/emacs/readme.org;
    package = pkgs.emacsNativeComp;
    alwaysEnsure = true;
    extraEmacsPackages = epkgs: [
      epkgs.use-package
      epkgs.org
    ];
  });

  # Old scripts I have laying around future me purge as appropriate
  cidr = (pkgs.writeScriptBin "cidr" (builtins.readFile ../../static/src/cidr)).overrideAttrs (old: {
    buildCommand = "${old.buildCommand}\n patchShebangs $out";
  });

  diskhog = (pkgs.writeScriptBin "diskhog" (builtins.readFile ../../static/src/diskhog)).overrideAttrs (old: {
    buildCommand = "${old.buildCommand}\n patchShebangs $out";
  });

  gecos = (pkgs.writeScriptBin "gecos" (builtins.readFile ../../static/src/gecos)).overrideAttrs (old: {
    buildCommand = "${old.buildCommand}\n patchShebangs $out";
  });

  ifinfo = (pkgs.writeScriptBin "ifinfo" (builtins.readFile ../../static/src/ifinfo)).overrideAttrs (old: {
    buildCommand = "${old.buildCommand}\n patchShebangs $out";
  });

  whoson = (pkgs.writeScriptBin "whoson" (builtins.readFile ../../static/src/whoson)).overrideAttrs (old: {
    buildCommand = "${old.buildCommand}\n patchShebangs $out";
  });
in
{
  imports = [
    # ./${sys}
    ./bin.nix
    ./registry.nix
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
    (pkgs.hiPrio gcc11) # Both this and clang provide c++ executable, so prefer gcc's for no reason than because
    act
    avahi
    bind
    clang
    clang-tools
    coreutils
    curl
    dasel
    dateutils
    deadnix
    dive
    du-dust
    entr
    file
    gist
    git
    git-lfs
    gnumake
    gron
    htop
    inputs.agenix.packages.${pkgs.system}.agenix
    inputs.mitchty.packages.${pkgs.system}.hatools
    inputs.mitchty.packages.${pkgs.system}.hwatch
    inputs.nixpkgs.legacyPackages.${pkgs.system}.tmuxp
    inputs.rust.packages.${pkgs.system}.rust
    jless
    less
    manix
    mapcidr
    mercurial
    minio-client
    moreutils
    ncdu
    nix-prefetch-github
    nix-prefetch-scripts
    nixpkgs-fmt
    nvd
    openssl
    p7zip
    pbzip2
    pigz
    pv
    rage
    rclone
    restic
    ripgrep
    rust-analyzer
    s3cmd
    shellcheck
    shellspec
    shfmt
    silver-searcher
    sipcalc
    syncthing
    tldr
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

    docker
    docker-compose
    firefox
    lshw
    podman
    podman-compose
    tcpdump
    xorg.xauth
    # Gui linux stuff
    # TODO: how do I get at the nixos config setup...?
    # ] ++ lib.optional (stdenv.isLinux && config.services.role.gui.enable) [

    # macos only stuff (until I find something only macos empty...)
    # ] ++ lib.optionals stdenv.isDarwin [
  ] ++ [
    cidr
    diskhog
    gecos
    ifinfo
    whoson
    inputs.nixpkgs-darwin.legacyPackages.${pkgs.system}.podman
    # testing nursery...
  ] ++ [
    ccls
    gopls
    pyright
    rust-analyzer
    rnix-lsp
    yaml-language-server
  ];

  # TODO: Finish porting emacs config over future me fix
  programs.emacs = {
    enable = true;
    package = emacsWithConfig;
  };
  home.file = {
    ".emacs.d/init.el" = {
      source = ../../static/emacs/init.el;
      recursive = true;
    };
    ".emacs.d/readme.org" = {
      source = ../../static/emacs/readme.org;
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
      enableFlakes = true;
    };
  };
}
