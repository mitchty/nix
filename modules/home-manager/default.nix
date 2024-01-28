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

  # Note these are encrypted on disk in git as they are paid so don't look at
  # this to work for you unless you buy them too, pay the font designers to do
  # their thing.
  comic-code = pkgs.stdenv.mkDerivation rec {
    pname = "comiccode";
    version = "0.0.0";
    nativeBuildInputs = [ pkgs.unzip ];
    src = ../../secrets/crypt/comic-code.zip;
    sourceRoot = ".";
    buildPhase = ''
      find -name \*.otf
    '';
    installPhase = ''
      install -dm755 $out/share/fonts/opentype/ComicCode
      find -name \*.otf -exec mv {} $out/share/fonts/opentype/ComicCode \;
    '';
  };
  pragmata-pro = pkgs.stdenv.mkDerivation rec {
    pname = "pragmatapro";
    version = "0.0.0";
    nativeBuildInputs = [ pkgs.unzip ];
    src = ../../secrets/crypt/pragmata-pro.zip;
    sourceRoot = ".";
    buildPhase = ''
      find -name \*.ttf
    '';
    installPhase = ''
      install -dm755 $out/share/fonts/truetype/PragmataPro
      find -name \*.ttf -exec mv {} $out/share/fonts/truetype/PragmataPro \;
    '';
  };


  # TODO: maybe yeet this into the gui role itself?
  gooey = (pkgs.hostPlatform.isDarwin || (role.gui.enable or false));
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
  ];

  systemd.user = lib.mkIf pkgs.hostPlatform.isLinux { startServices = "sd-switch"; };
  programs.home-manager.enable = true;

  # Common packages across all os's
  #
  # TODO: should have a grouping or module setup where I can turn stuff on/off
  # aka have something to control: is this a box for streaming? if so add
  # obs-studio etc.. something akin to roles in ansible.
  home.packages = with nixpkgs.${pkgs.system}; [
    (pkgs.hiPrio clang)
    (pkgs.hiPrio go) # Ensure this is the go to use in case of collision
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
    ccls
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
    gcc11
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
    gnupg1
    gopls
    graphviz
    gron
    htop
    hyperfine
    iftop
    inputs.agenix.packages.${pkgs.system}.agenix
    inputs.deploy-rs.packages.${pkgs.system}.deploy-rs
    inputs.mitchty.packages.${pkgs.system}.altshfmt
    inputs.mitchty.packages.${pkgs.system}.hatools
    inputs.mitchty.packages.${pkgs.system}.hwatch
    inputs.mitchty.packages.${pkgs.system}.no-more-secrets
    inputs.mitchty.packages.${pkgs.system}.transcrypt
    # inputs.nixinit.packages.${pkgs.system}.default
    inputs.nixpkgs.legacyPackages.${pkgs.system}.diffoscopeMinimal
    inputs.nixpkgs.legacyPackages.${pkgs.system}.tmuxp
    inputs.rust.packages.${pkgs.system}.rust
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
    monolith
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
    pup
    pv
    pyright
    python3Full # For emacs python-mode
    rage
    rclone
    restic
    ripgrep
    rnix-lsp
    rq
    rust-analyzer
    rust-analyzer
    s3cmd
    shellcheck
    shellspec
    shfmt
    silver-searcher
    sipcalc
    sshpass
    tldr
    #    transcrypt
    unzip
    vim
    wget
    xz
    yaml-language-server
    yt-dlp
    # General gui stuff
  ] ++ lib.optionals role.gui.enable [
    comic-code
    pragmata-pro
    # Non gui linux stuff
  ] ++ lib.optionals pkgs.hostPlatform.isLinux [
    docker
    docker-compose
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
    freetube
    kdialog
    xsel
  ] ++ lib.optionals (pkgs.hostPlatform.isLinux) [
    # macos specific stuff
  ] ++ lib.optionals pkgs.hostPlatform.isDarwin [
    pngpaste
    #   inputs.nixpkgs-darwin.legacyPackages.${pkgs.system}.podman
  ] ++ [
    bwcli
    cidr
    diskhog
    gecos
    ifinfo
    whoson
  ];

  # Let home-manager setup fonts on macos/linux the same way.
  fonts.fontconfig.enable = true;

  programs.emacs = {
    enable = gooey;
    package = pkgs.emacsMt;
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
    # TODO: programs.ssh instead? Eh for now this is fine...
    ".ssh/config" = {
      source = ../../static/home/sshconfig;
    };
    # Setup the default mutagen ignore list/config
    ".mutagen.yml".source = ../../static/home/mutagen.yaml;
    # } // lib.optionalAttrs gooey
    #   {
    # This is where gui only files would go if I had anymore at this point.
  } # role.gui home.files
  // lib.optionalAttrs pkgs.hostPlatform.isDarwin {
    "Library/Scripts/force-paste.scpt" = {
      source = ../../static/src/force-paste.scpt;
      recursive = true;
    };
  }; # darwin home.files

  # Add to home managers dag to make sure the activation fails if emacs can't
  # parse the init files and nuke any temp dirs we don't need/want to stick
  # around if present. Most of these are just caches though init.el(c) need to
  # get yeeted into the nix store somehow.
  home.activation.freshEmacs = lib.mkIf gooey (lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    printf "modules/home-manager/default.nix: clean ~/.emacs.d\n" >&2
    $DRY_RUN_CMD rm -rf $VERBOSE_ARG ~/.emacs.d/init.elc ~/.emacs.d/custom.el ~/.emacs.d/elpa ~/.emacs.d/eln-cache ~/.cache/org-persist
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
    extensions = (lib.attrVals [
      "gh-dash"
      "gh-cal"
    ]
      nixpkgs.${pkgs.system}) ++ [ inputs.mitchty.packages.${pkgs.system}.gh-actions-status ];
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

  # Mostly yeeted from here https://gitlab.com/usmcamp0811/dotfiles/-/blob/fb584a888680ff909319efdcbf33d863d0c00eaa/modules/home/apps/firefox/default.nix
  #
  # TODO: get this working on macos, this only works on linux
  #
  # ALso problematic is this firefox module is 23.11 only, need to debug the hokey segfault in emacs with 23.11 setups with treesitter.
  programs.firefox = mkIf (role.gui.enable or false) (mkMerge [
    (optionalAttrs pkgs.hostPlatform.isDarwin (mkIf (pkgs.hostPlatform.isDarwin) { }))
    (optionalAttrs pkgs.hostPlatform.isLinux (mkIf (pkgs.hostPlatform.isLinux) {
      enable = true;
      policies = {
        CaptivePortal = true;
        DisableFirefoxAccounts = true;
        DisableFirefoxStudies = true;
        DisableFormHistory = true;
        DisablePocket = true;
        DisableTelemetry = true;
        DNSOverHTTPS = { Enabled = false; };
        EncryptedMediaExtensions = { Enabled = false; };
        FirefoxHome = {
          SponsoredTopSites = false;
          Pocket = false;
          SponsoredPocket = false;
        };
        HardwareAcceleration = true;
        Homepage = { StartPage = "none"; };
        NetworkPrediction = false;
        NewTabPage = false;
        NoDefaultBookmarks = false;
        OfferToSaveLogins = false;
        OfferToSaveLoginsDefault = false;
        OverrideFirstRunPage = "";
        OverridePostUpdatePage = "";
        PasswordManagerEnabled = false;
        Permissions = {
          Location = { BlockNewRequests = true; };
          Notifications = { BlockNewRequests = true; };
        };
        #          PopupBlocking = { Default = false; };
        PromptForDownloadLocation = true;
        SanitizeOnShutdown = true;
        SearchSuggestEnabled = false;
        ShowHomeButton = true;
        UserMessaging = {
          WhatsNew = false;
          SkipOnboarding = true;
        };
      };
      profiles = {
        default = {
          id = 0;
          name = "default";
          isDefault = true;
          extensions = (lib.attrVals [
            "auto-tab-discard"
            "bitwarden"
            "cookies-txt"
            "greasemonkey"
            "i-dont-care-about-cookies"
            "sidebery"
            "ublacklist"
            "ublock-origin"
          ]
            pkgs.nur.repos.rycee.firefox-addons) ++ lib.optionals pkgs.hostPlatform.isLinux (lib.attrVals [ "plasma-integration" ]);
          settings = {
            "apz.allow_double_tap_zooming" = false;
            "apz.allow_zooming" = true;
            "apz.gtk.touchpad_pinch.enabled" = true;
            "browser.aboutConfig.showWarning" = false;
            "browser.startup.page" = 3;
            "browser.tabs.loadInBackground" = false;
            "browser.tabs.warnOnClose" = false;
            "browser.urlbar.shortcuts.bookmarks" = false;
            "browser.urlbar.shortcuts.history" = false;
            "browser.urlbar.shortcuts.tabs" = false;
            "browser.urlbar.update2" = false;
            "dom.w3c.touch_events.enabled" = true;
            "dom.w3c_touch_events.legacy_apis.enabled" = true;
            "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
          };
        };
      };
    }))
  ]);
}
