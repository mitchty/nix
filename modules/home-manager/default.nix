{ config, pkgs, lib, inputs, age, ... }:
with lib;

let
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

  # Non old af crap that might be better off in mitchty/nixos, future me figure it out.
  bwcli = (pkgs.writeScriptBin "b" (builtins.readFile ../../static/src/b.sh)).overrideAttrs (old: {
    buildCommand = "${old.buildCommand}\n patchShebangs $out";
  });

  # Having issues with the unstable build of util-linux building on macos, so
  # call "nixpkgs" the darwin package set. nixos can stay on bleeding edge
  # stuff.
  nixpkgs =
    if pkgs.stdenv.isDarwin then
      inputs.nixpkgs-darwin.legacyPackages
    else
      inputs.latest.legacyPackages;
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
  home.packages = with nixpkgs.${pkgs.system}; [
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
    bitwarden-cli
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
    (pkgs.hiPrio go) # Ensure this is the go to use in case of collision
    gist
    git-extras
    git-lfs
    git-quick-stats
    git-recent
    git-sizer
    git-vendor
    gitFull
    gnumake
    graphviz
    gron
    gnupg1
    htop
    hyperfine
    iftop
    inputs.agenix.packages.${pkgs.system}.agenix
    inputs.mitchty.packages.${pkgs.system}.altshfmt
    inputs.mitchty.packages.${pkgs.system}.hatools
    inputs.mitchty.packages.${pkgs.system}.hwatch
    inputs.mitchty.packages.${pkgs.system}.no-more-secrets
    inputs.mitchty.packages.${pkgs.system}.transcrypt
    inputs.nixpkgs.legacyPackages.${pkgs.system}.diffoscopeMinimal
    inputs.nixpkgs.legacyPackages.${pkgs.system}.tmuxp
    inputs.rust.packages.${pkgs.system}.rust
    inputs.nixinit.packages.${pkgs.system}.default
    ipcalc
    ipinfo
    ispell
    jid
    jless
    less
    ltex-ls
    manix
    mapcidr
    mercurial
    minio-client
    moreutils
    nix-prefetch-github
    nix-prefetch-scripts
    nix-tree
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
    docker
    docker-compose
    firefox
    lshw
    podman
    podman-compose
    tcpdump
    tio
    traitor
    usbutils
    xorg.xauth
    # Gui linux stuff
    # TODO: how do I get at the nixos config setup...?
    # ] ++ lib.optional (stdenv.isLinux && config.services.role.gui.enable) [
    # macos specific stuff
  ] ++ lib.optionals pkgs.stdenv.isDarwin [
    pngpaste
    #   inputs.nixpkgs-darwin.legacyPackages.${pkgs.system}.podman
  ] ++ [
    cidr
    diskhog
    gecos
    ifinfo
    whoson

    bwcli
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
  programs.emacs = lib.mkIf pkgs.stdenv.isDarwin {
    enable = true;
    package = pkgs.emacsWithConfig;
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
    # Make everything in my lib.sh available for all .envrc files
    ".config/direnv/lib/mycrap.sh" = {
      source = ../../static/src/lib.sh;
      recursive = true;
    };
  };

  # Todo: have a mkmerge mkIf section for macos only stuff in general?
  home.file."Library/Scripts/force-paste.scpt" = lib.mkIf pkgs.stdenv.isDarwin
    {
      source = ../../static/src/force-paste.scpt;
      recursive = true;
    };

  # Add to home managers dag to make sure the activation fails if emacs can't
  # parse the init files and nuke any temp dirs we don't need/want to stick
  # around if present.
  home.activation.freshEmacs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    printf "modules/home-manager/default.nix: clean ~/.emacs.d\n" >&2
    $DRY_RUN_CMD rm -rf $VERBOSE_ARG ~/.emacs.d/init.el ~/.emacs.d/init.elc ~/.emacs.d/elpa ~/.emacs.d/eln-cache
  '';

  # Only test emacs config on macos for now
  home.activation.testEmacs = lib.mkIf pkgs.stdenv.isDarwin (lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    printf "modules/home-manager/default.nix: test emacs\n" >&2
    $DRY_RUN_CMD ${pkgs.emacsWithConfig}/bin/emacs --debug-init --batch -u $USER
  '');

  # Ensure that certain defaults are set, note need to restart SystemUIServer
  # for menu bar changes to get picked up.
  #
  # TODO: didn't check if these are possible in nix-darwin future me task
  home.activation.defaults = lib.mkIf pkgs.stdenv.isDarwin (lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    printf "modules/home-manager/default.nix: defaults\n" >&2
    $DRY_RUN_CMD defaults write com.apple.scriptmenu ScriptMenuEnabled -bool true
    $DRY_RUN_CMD defaults write com.apple.scriptmenu ShowLibraryScripts -bool false
    $DRY_RUN_CMD defaults write com.apple.systemuiserver "NSStatusItem Visible Siri" -bool false
    $DRY_RUN_CMD defaults write com.apple.systemuiserver menuExtras -array-add "/System/Library/CoreServices/Menu Extras/Bluetooth.menu"
    $DRY_RUN_CMD defaults write com.apple.systemuiserver menuExtras -array-add "/System/Library/CoreServices/Menu Extras/Clock.menu"

    $DRY_RUN_CMD defaults write com.apple.finder ShowPathbar -bool true

    # I sometimes run without finder running
    if pgrep Finder > /dev/null 2>&1; then
      $DRY_RUN_CMD pkill Finder
    fi

    # This can't get shut off so nbd
    $DRY_RUN_CMD killall -KILL SystemUIServer

    # Prevent bluetooth headphones from opening or mess with itunes
    $DRY_RUN_CMD launchctl stop com.apple.rcd || :
    $DRY_RUN_CMD launchctl unload -w /System/Library/LaunchAgents/com.apple.rcd.plist || :
  '');

  # Programs not (yet) worthy of their own .nix setup... so far who knows what
  # the future holds.
  programs.gh = {
    enable = true;
    package = nixpkgs.${pkgs.system}.gh;
    extensions = with nixpkgs.${pkgs.system}; [
      gh-dash
      gh-cal
      inputs.mitchty.packages.${pkgs.system}.gh-actions-status
    ];
  };
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
