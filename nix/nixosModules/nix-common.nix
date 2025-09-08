# Common settings for nix command itself.
{
  config,
  pkgs,
  lib,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    cachix
    nix-output-monitor
  ];

  nix = {
    settings.experimental-features = [
      "nix-command"
      "flakes"
      "ca-derivations"
    ];
    settings = {
      # https://github.com/NixOS/nix/issues/11728
      download-buffer-size = 64 * 024 * 1024; # 64MiB from 1MiB
      substituters = [
        "https://cache.nixos.org/"
        "https://nix-community.cachix.org/"
      ];
      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      ];
      trusted-users = [
        "root"
        "@wheel"
      ];
    };
  };
}
