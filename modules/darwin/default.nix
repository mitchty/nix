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
        trackpad.TrackpadRightClick = true;
        dock = {
          autohide = true;
          autohide-delay = "0.0";
          mineffect = "suck";
          orientation = "bottom";
        };
        finder = {
          AppleShowAllExtensions = true;
          _FXShowPosixPathInTitle = true;
          FXEnableExtensionChangeWarning = false;
        };
      };
    };
  };
}
