{ config, pkgs, lib, inputs, age, ... }:
with lib;

let
  # TODO: figure out a way to import based on this...
  # sys = pkgs.lib.last (pkgs.lib.splitString "-" pkgs.system);
  emacsWithConfig = (pkgs.emacsWithPackagesFromUsePackage {
    config = ../../static/emacs/init.org;
    package = pkgs.emacsNativeComp;
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
    aspell
    aspellDicts.de
    aspellDicts.en
    aspellDicts.en-computers
    aspellDicts.fr
    aspellDicts.la
    aspellDicts.pt_PT
    bind
    clang
    clang-tools
    coreutils
    curl
    dasel
    dateutils
    deadnix
    difftastic
    du-dust
    entr
    file
    fio
    gh
    (pkgs.hiPrio go) # Ensure this is the go to use in the case of collision
    gist
    git-extras
    git-lfs
    git-quick-stats
    git-recent
    git-sizer
    gitFull
    gnumake
    gron
    htop
    hyperfine
    iftop
    inputs.agenix.packages.${pkgs.system}.agenix
    inputs.mitchty.packages.${pkgs.system}.hatools
    inputs.mitchty.packages.${pkgs.system}.hwatch
    inputs.mitchty.packages.${pkgs.system}.transcrypt
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
    procps
    pv
    # For emacs python-mode, not sure if Full is needed or if Minimal would work
    # and don't care much.
    python3Full
    rage
    rclone
    restic
    ripgrep
    rq
    rust-analyzer
    s3cmd
    shellcheck
    shellspec
    shfmt
    silver-searcher
    sipcalc
    sshpass
    syncthing
    tldr
    unzip
    vim
    wget
    xz
    yt-dlp
    # Non gui linux stuff
  ] ++ lib.optionals stdenv.isLinux [
    usbutils
    # Testing packages that I may/not upstream any changes to nixpkgs
    inputs.mitchty.packages.${pkgs.system}.seaweedfs
    docker
    docker-compose
    firefox
    lshw
    podman
    podman-compose
    tcpdump
    tio
    traitor
    xorg.xauth
    # Gui linux stuff
    # TODO: how do I get at the nixos config setup...?
    # ] ++ lib.optional (stdenv.isLinux && config.services.role.gui.enable) [
    # macos specific stuff
    # ] ++ lib.optionals stdenv.isDarwin [
    #   inputs.nixpkgs-darwin.legacyPackages.${pkgs.system}.podman
  ] ++ [
    cidr
    diskhog
    gecos
    ifinfo
    whoson
    # testing nursery...
  ] ++ [
    ccls
    gopls
    pyright
    rnix-lsp
    rust-analyzer
    yaml-language-server
  ];

  # TODO: Finish porting emacs config over future me fix
  programs.emacs = {
    enable = true;
    package = emacsWithConfig;
  };
  home.file = {
    ".emacs.d/early-init.el" = {
      source = ../../static/emacs/early-init.el;
      recursive = true;
    };
    ".emacs.d/init.org" = {
      source = ../../static/emacs/init.org;
      recursive = true;
    };
  };

  # Remove the quelpa nonsense was only there for the modeline module
  home.activation.freshEmacs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    printf "modules/home-manager/default.nix: clean ~/.emacs.d\n" >&2
    $DRY_RUN_CMD rm -rf $VERBOSE_ARG ~/.emacs.d/init.elc ~/.emacs.d/elpa
  '';

  # Programs not (yet) worthy of their own .nix setup... so far
  programs.fzf.enable = true;
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
