{ config, pkgs, lib, inputs, age, role, ... }:
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
    if pkgs.hostPlatform.isDarwin then
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

  systemd.user = lib.mkIf pkgs.hostPlatform.isLinux { startServices = "sd-switch"; };
  programs.home-manager.enable = true;

  # Common packages across all os's
  #
  # TODO: should have a grouping or module setup where I can turn stuff on/off
  # aka have something to control: is this a box for streaming? if so add
  # obs-studio etc.. something akin to roles in ansible.
  home.packages = with nixpkgs.${pkgs.system}; [
    act
    gcc11
    aspell
    aspellDicts.de
    aspellDicts.en
    aspellDicts.en-computers
    aspellDicts.fr
    aspellDicts.la
    aspellDicts.pt_PT
    bind
    bitwarden-cli
    (pkgs.hiPrio clang)
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
    git-absorb
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
    inputs.deploy-rs.packages.${pkgs.system}.deploy-rs
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
    tldr
    unzip
    vim
    wget
    xz
    yt-dlp
    # Non gui linux stuff
  ] ++ lib.optionals pkgs.hostPlatform.isLinux [
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
  ] ++ lib.optionals (role.gui.enable && pkgs.hostPlatform.isLinux) [
    xsel
  ] ++ lib.optionals (pkgs.hostPlatform.isLinux) [
    # macos specific stuff
  ] ++ lib.optionals pkgs.hostPlatform.isDarwin [
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

  programs.emacs = lib.mkIf role.gui.enable {
    enable = true;
    package = pkgs.emacsWithConfig;
  };

  home.file = {
    # Note: mkoutofstoresymlink is here cause I don't want the age decrypted
    # secret in /nix/store, /nix/store/... can simply symlink to the file in /run.
    ".config/mitchty/.canary".source = config.lib.file.mkOutOfStoreSymlink age.secrets.canary.path;

    # Make everything in my lib.sh available for all .envrc files
    ".config/direnv/lib/mycrap.sh" = {
      source = ../../static/src/lib.sh;
      recursive = true;
    };
    # Setup the default mutagen ignore list/config
    ".mutagen.yml".source = ../../static/home/mutagen.yaml;
  } // (lib.mkIf role.gui.enable
    {
      ".emacs.d/early-init.el" = {
        source = ../../static/emacs/early-init.el;
        recursive = true;
      };
      ".emacs.d/init.org" = {
        source = ../../static/emacs/init.org;
        recursive = true;
      };
    }) # role.gui home.files
  // (lib.mkIf pkgs.hostPlatform.isDarwin {
    "Library/Scripts/force-paste.scpt" = {
      source = ../../static/src/force-paste.scpt;
      recursive = true;
    };
  }); # darwin home.files

  # Add to home managers dag to make sure the activation fails if emacs can't
  # parse the init files and nuke any temp dirs we don't need/want to stick
  # around if present. Most of these are just caches though init.el(c) need to
  # get yeeted into the nix store somehow.
  home.activation.freshEmacs = lib.mkIf role.gui.enable (lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    printf "modules/home-manager/default.nix: clean ~/.emacs.d\n" >&2
    $DRY_RUN_CMD rm -rf $VERBOSE_ARG ~/.emacs.d/init.el ~/.emacs.d/init.elc ~/.emacs.d/custom.el ~/.emacs.d/elpa ~/.emacs.d/eln-cache ~/.cache/org-persist
  '');

  # TODO: how the hell do I move this into a flake check instead?
  # Note this has to happen after linkGeneration in the dag, otherwise the new
  # setups not in place to be used by emacs yet and things might have diverged
  # package wise.
  home.activation.testEmacs = lib.mkIf role.gui.enable (lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    printf "modules/home-manager/default.nix: test emacs\n" >&2
    $DRY_RUN_CMD ${pkgs.emacsWithConfig}/bin/emacs --debug-init --batch --user $USER
  '');

  # Ensure that certain defaults are set, note need to restart SystemUIServer
  # for menu bar changes to get picked up.
  #
  # TODO: didn't check if these are possible in nix-darwin future me task
  home.activation.defaults = lib.mkIf pkgs.hostPlatform.isDarwin (lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    printf "modules/home-manager/default.nix: defaults\n" >&2
    $DRY_RUN_CMD defaults write com.apple.scriptmenu ScriptMenuEnabled -bool true
    $DRY_RUN_CMD defaults write com.apple.scriptmenu ShowLibraryScripts -bool false
    $DRY_RUN_CMD defaults write com.apple.systemuiserver "NSStatusItem Visible Siri" -bool false
    $DRY_RUN_CMD defaults write com.apple.systemuiserver menuExtras -array-add "/System/Library/CoreServices/Menu Extras/Bluetooth.menu"
    $DRY_RUN_CMD defaults write com.apple.systemuiserver menuExtras -array-add "/System/Library/CoreServices/Menu Extras/Clock.menu"

    $DRY_RUN_CMD defaults write com.apple.finder ShowPathbar -bool true

    # I sometimes run without finder running, no sense having pkill fail if its not running anyway.
    if pgrep Finder > /dev/null 2>&1; then
      $DRY_RUN_CMD pkill Finder
    fi

    # This can't get shut off so nbd
    $DRY_RUN_CMD killall -KILL SystemUIServer
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
