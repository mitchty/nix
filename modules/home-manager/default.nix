{ config
, pkgs
, lib
, inputs
, age
, roles
, ...
}:
with lib;

let
  # TODO: maybe yeet this into the gui role itself as a default?
  gooey = (pkgs.hostPlatform.isDarwin || (roles.gui.enable or false) || (roles.gui-new.enable or false));

  # Default font size based off display size in role, basically big or else...
  fontSize = if roles.gui-new.displaySize == "big" then 12 else 10;
  fontName = "Comic Code Bold";

  notify = (pkgs.writeScriptBin "notify" (builtins.readFile ../../static/src/notify)).overrideAttrs (old: {
    buildCommand = "${old.buildCommand}\n patchShebangs $out";
  });

  ugde = (pkgs.writeScriptBin "ugde" (builtins.readFile ../../static/src/ugde.sh)).overrideAttrs (old: {
    buildCommand = "${old.buildCommand}\n patchShebangs $out";
  });

  nb = (pkgs.writeScriptBin "nb" (builtins.readFile ../../static/src/nb.sh)).overrideAttrs (old: {
    buildCommand = "${old.buildCommand}\n patchShebangs $out";
  });

  nba = (pkgs.writeScriptBin "nba" (builtins.readFile ../../static/src/nba.sh)).overrideAttrs (old: {
    buildCommand = "${old.buildCommand}\n patchShebangs $out";
  });

  nixgc = (pkgs.writeScriptBin "nixgc" (builtins.readFile ../../bin/nixgc.sh)).overrideAttrs (old: {
    buildCommand = "${old.buildCommand}\n patchShebangs $out";
  });

  mystatus = (pkgs.writeScriptBin "mystatus" (builtins.readFile ../../static/src/mystatus.sh)).overrideAttrs (old: {
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
    ./kopia.nix
  ];

  programs.home-manager.enable = true;

  # Common packages across all os's
  #
  # TODO: should have a grouping or module setup where I can turn stuff on/off
  # aka have something to control: is this a box for streaming? if so add
  # obs-studio etc.. something akin to roles in ansible.
  home.packages = with pkgs; [
    notify
    ugde
    nb
    nba
    nixgc
  ] ++ [
    # pkgs.agenix.${pkgs.system}.agenix
    inputs.agenix.packages.${pkgs.system}.agenix
    inputs.deploy-rs.packages.${pkgs.system}.deploy-rs
    # pkgs.mitchty.x86_64_linux.altshfmt
    #    pkgs.mitchty.altshfmt
    inputs.mitchty.packages.${pkgs.system}.altshfmt
    inputs.mitchty.packages.${pkgs.system}.hatools
    inputs.mitchty.packages.${pkgs.system}.hwatch
    inputs.mitchty.packages.${pkgs.system}.no-more-secrets
    #    inputs.mitchty.packages.${pkgs.system}.transcrypt
    #    pkgs.morerust.rust
    inputs.rust.packages.${pkgs.system}.rust
    # inputs.nixinit.packages.${pkgs.system}.default
  ] ++ [
    transcrypt
    xq
    (pkgs.hiPrio clang)
    (pkgs.hiPrio go) # Ensure this is the go to use in case of collision
    act
    asm-lsp
    aspell
    aspellDicts.de
    aspellDicts.en
    aspellDicts.en-computers
    aspellDicts.fr
    aspellDicts.la
    aspellDicts.pt_PT
    bind
    bitwarden-cli
    bonnie
    bwcli # this is my wrapper for ^^^
    ccls
    clang-tools
    coreutils
    curl
    dasel
    dateutils
    deadnix
    diffoscopeMinimal
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
    ipcalc
    ipinfo
    ispell
    jid
    jless
    kopia
    libqalculate
    less
    ltex-ls
    manix
    mapcidr
    mercurial
    mermaid-cli
    minio-client
    monolith
    moreutils
    nasm
    nix-prefetch-github
    nix-prefetch-scripts
    nix-tree
    nixpkgs-fmt
    nodePackages.bash-language-server
    nom
    nvd
    openssl
    p7zip
    passh
    pbzip2
    pigz
    procps
    pssh
    pup
    pv
    pyright
    python3Full # For emacs python-mode
    rage
    rclone
    ripgrep
    rq
    pkgs.unstable.rust-analyzer
    s3cmd
    shellcheck
    shellspec
    shfmt
    silver-searcher
    sipcalc
    sshpass
    tldr
    tmuxp
    unzip
    vim
    wget
    xz
    yaml-language-server
    yt-dlp
    zstd
    # General gui stuff
  ] ++ lib.optionals gooey [
    comic-code
    pragmata-pro
    # Non gui linux stuff
  ] ++ lib.optionals pkgs.hostPlatform.isLinux [
    #    hponcfg
    bpftrace
    docker
    docker-compose
    flamegraph
    inotify-tools
    linuxPackages.bcc
    lshw
    podman
    podman-compose
    sysstat
    tcpdump
    tio
    traitor
    usbutils
    pkgs.unstable.webex
    # Gui linux stuff
  ] ++ lib.optionals (gooey && pkgs.hostPlatform.isLinux) [
    mystatus
    obs-studio
    ffmpeg
    bitwarden-desktop
    pulseaudio-ctl
    noto-fonts
    freetube
    kdialog
    xclip
    xsel
    xorg.xauth
    inputs.mitchty.packages.${pkgs.system}.ytdl-sub
  ] ++ lib.optionals (pkgs.hostPlatform.isLinux) [
    efibootmgr
    # macos specific stuff
  ] ++ lib.optionals pkgs.hostPlatform.isDarwin [
    pngpaste
    #   inputs.nixpkgs-darwin.legacyPackages.${pkgs.system}.podman
  ] ++ [
    # TODO: old scripts in my overlay I should review if they're worth retaining.
    cidr
    diskhog
    gecos
    ifinfo
    whoson
  ];

  # Let home-manager setup fonts on macos/linux the same way.
  fonts.fontconfig.enable = gooey;

  programs.emacs = {
    enable = gooey;
    #    package = pkgs.wrappedEmacs;
    package = pkgs.myEmacs;
  };

  programs.kitty = {
    enable = (pkgs.hostPlatform.isLinux && gooey);
    font = {
      name = fontName;
      package = pkgs.comic-code;
      size = fontSize;
    };
    shellIntegration.enableZshIntegration = true;
    #    theme = "Spring";
    extraConfig = ''
      enable_audio_bell no
      visual_bell_duration 0.5
    '';
  };

  home.file = {
    # Note: mkoutofstoresymlink is here cause I don't want the age decrypted
    # secret in /nix/store, /nix/store/... can simply symlink to the file in /run.
    ".config/mitchty/.canary".source = config.lib.file.mkOutOfStoreSymlink age.secrets.canary.path;

    # Make everything in my lib.sh available for all .envrc files
    ".config/direnv/lib/mycrap.sh".source = ../../static/src/lib.sh;
    # TODO: programs.ssh instead? Eh for now this is fine...
    ".ssh/config".source = ../../static/home/sshconfig;
    # Setup the default mutagen ignore list/config
    ".mutagen.yml".source = ../../static/home/mutagen.yaml;
  } // lib.optionalAttrs (gooey && pkgs.hostPlatform.isLinux) {
    # Setup ~/.config as needed for gui stuff
    ".config/i3/config" = {
      text = pkgs.lib.strings.concatStringsSep "\n" ([
        (pkgs.lib.strings.fileContents ../../static/xorg/i3/config)
      ] ++ [
        ''
          # Font for window titles and bar.
          font pango:${fontName} ${builtins.toString fontSize}
        ''
      ]);
      force = true; # I can't get why I need to set force for ~/.config/i3* stuff
    };
    ".config/i3status/config" = {
      source = ../../static/xorg/i3status/config;
      force = true;
    };
  } // lib.optionalAttrs pkgs.hostPlatform.isDarwin {
    "Library/Scripts/force-paste.scpt".source = ../../static/src/force-paste.scpt;
  }; # darwin home.files

  home.activation.dirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    printf "modules/home-manager/default.nix: dirs\n" >&2
    $DRY_RUN_CMD install -dm700 ~/.ssh
    $DRY_RUN_CMD install -dm700 ~/.ssh/.control
  '';

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
    extensions = [
      pkgs.gh-dash
      pkgs.gh-cal
    ] ++ [ inputs.mitchty.packages.${pkgs.system}.gh-actions-status ];
  };
  programs.fzf.enable = true;
  programs.go.enable = true;
  programs.jq.enable = true;

  # stdlib is here to replace .config/direnv/direnvrc in home.file now that
  # home-manager wants to own the file
  # TODO future mitch is this a common sh lib I can abuse for my common lib.sh?

  programs.direnv = {
    enable = true;
    stdlib = pkgs.lib.readFile ../../static/src/direnvrc;
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
  programs.firefox = mkIf gooey (mkMerge [
    (optionalAttrs pkgs.hostPlatform.isDarwin (mkIf (pkgs.hostPlatform.isDarwin) { }))
    (optionalAttrs pkgs.hostPlatform.isLinux (mkIf (pkgs.hostPlatform.isLinux) {
      enable = true;
      package = pkgs.unstable.firefox;
      policies = {
        CaptivePortal = true;
        DisableFirefoxStudies = true;
        DisableFormHistory = true;
        DisablePocket = true;
        DisableTelemetry = true;
        DNSOverHTTPS = { Enabled = false; };
        EncryptedMediaExtensions = { Enabled = false; };
        FirefoxHome = {
          Pocket = false;
          SponsoredPocket = false;
          SponsoredTopSites = false;
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
        # PopupBlocking = { Default = false; };
        PromptForDownloadLocation = true;
        SanitizeOnShutdown = false;
        SearchSuggestEnabled = false;
        ShowHomeButton = true;
        UserMessaging = {
          WhatsNew = false;
          SkipOnboarding = true;
        };
      };
      profiles = {
        default =
          let
            hidetabstoolbar = (pkgs.fetchurl {
              url = "https://raw.githubusercontent.com/MrOtherGuy/firefox-csshacks/master/chrome/hide_tabs_toolbar.css";
              sha256 = "sha256-R8MB1Y389WLRf52bTaulBePmP3zR14fw6+49fimjkQw=";
            });
          in
          {
            id = 0;
            name = "default";
            isDefault = true;
            userChrome = ''
              @import url(${hidetabstoolbar});

              :root {
              	--navbar-height: 48px;
              	--wc-height: 16px;
              	--wc-left-margin: 10px;
              	--wc-red: hsl(-10, 90%, 60%);
              	--wc-yellow: hsl(50, 90%, 60%);
              	--wc-green: hsl(160, 90%, 40%);
              	--sidebar-collapsed-width: var(--navbar-height);
              	--sidebar-width: 250px;
              	--transition-duration: 0.2s;
              	--transition-ease: ease-out;
              }

              #nav-bar {
              	margin-right: calc(var(--wc-height) * 6 + var(--wc-left-margin));
              	padding: calc((var(--navbar-height) - 40px) / 2) 0;
              }
            '';
            extensions = with pkgs.nur.repos.rycee.firefox-addons; [
              auto-tab-discard
              bitwarden
              cookies-txt
              greasemonkey
              i-dont-care-about-cookies
              sidebery
              ublacklist
              ublock-origin
              user-agent-string-switcher
            ] ++ lib.optionals pkgs.hostPlatform.isLinux [
              plasma-integration
            ];
            settings = {
              "apz.allow_double_tap_zooming" = false;
              "apz.allow_zooming" = true;
              "apz.gtk.touchpad_pinch.enabled" = true;
              "browser.aboutConfig.showWarning" = false;
              "browser.startup.page" = 3;
              "browser.tabs.loadInBackground" = true;
              "browser.tabs.warnOnClose" = false;
              "browser.urlbar.shortcuts.bookmarks" = false;
              "browser.urlbar.shortcuts.history" = false;
              "browser.urlbar.shortcuts.tabs" = false;
              "browser.urlbar.update2" = false;
              "dom.w3c.touch_events.enabled" = true;
              "dom.w3c_touch_events.legacy_apis.enabled" = true;
              "privacy.clearOnShutdown.history" = false;
              "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
            };
          };
      };
    }))
  ]);
}
