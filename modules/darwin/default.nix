{ config, pkgs, ... }: {
  imports = [
    ./bootstrap.nix
    ../../hosts/nix-basic.nix
    ./restic.nix
    ./nix-index.nix
    ./mitchty.nix
    ./home.nix
    ./work.nix
  ];

  config = {
    # Minimal setup of what we want installed outside of home-manager
    environment.systemPackages = with pkgs; [
      vim
      mosh
      git
      tmux
      jq
    ];

    # Sets up /etc/pam/sudo to use touchid for sudo
    security.pam.enableSudoTouchIdAuth = true;

    # Keyboard shenanigans
    system = {
      keyboard = {
        enableKeyMapping = true;
        remapCapsLockToControl = true;
      };
      defaults = {
        NSGlobalDomain = {
          "com.apple.mouse.tapBehavior" = 1;
          "com.apple.sound.beep.feedback" = 0;
          "com.apple.sound.beep.volume" = 0.0;
          AppleKeyboardUIMode = 3;
          ApplePressAndHoldEnabled = false;
          AppleShowAllExtensions = true;
          NSAutomaticCapitalizationEnabled = false;
          NSAutomaticDashSubstitutionEnabled = false;
          NSAutomaticPeriodSubstitutionEnabled = false;
          NSAutomaticQuoteSubstitutionEnabled = false;
          NSAutomaticSpellingCorrectionEnabled = false;
        };
        trackpad = {
          Clicking = true;
          Dragging = true;
          TrackpadRightClick = true;
        };
        dock = {
          autohide = true;
          autohide-delay = 0.0;
          mineffect = "suck";
          orientation = "bottom";
          showhidden = true;
          show-recents = false;
        };
        finder = {
          AppleShowAllFiles = true;
          ShowPathbar = true;
          QuitMenuItem = true;
          AppleShowAllExtensions = true;
          FXEnableExtensionChangeWarning = false;
          _FXShowPosixPathInTitle = true;
        };
      };
    };

    # (Ab)use /etc/resolver for home.arpa so dns lookups are sent to the right nameserver.
    #
    # TODO: maybe make a module for /etc/resolver setups? Also need to figure
    # out an uninstall form for this.
    system.activationScripts.postActivation.text = ''
      printf "modules/darwin/default.nix: /etc/resolve home.arpa dns setup\n" >&2
      $DRY_RUN_CMD sudo install -dm755 $VERBOSE_ARG /etc/resolver
      $DRY_RUN_CMD printf "domain home.arpa\nsearch home.arpa\nnameserver 10.10.10.1\n" | sudo tee /etc/resolver/home.arpa
      $DRY_RUN_CMD sudo killall -HUP mDNSResponder

      printf "modules/darwin/default.nix: defaults not in nix-darwin\n" >&2
      $DRY_RUN_CMD defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
      $DRY_RUN_CMD defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true
    '';
  };
}
