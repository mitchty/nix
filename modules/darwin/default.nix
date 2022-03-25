{ config, pkgs, lib, ... }: {
  imports = [
    ./bootstrap.nix
    ../../hosts/nix-basic.nix
    ./restic.nix
    ./nix-index.nix
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
          "com.apple.sound.beep.volume" = "0.0";
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
          autohide-delay = "0.0";
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
  };
}
