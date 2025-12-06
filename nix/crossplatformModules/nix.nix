# Common settings for nix command itself between darwin/nixos
{
  pkgs,
  lib,
  ...
}:
let
  enableHomeCache = import ../../hacks/home-nix-cache.nix;
in
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
      # Default is 0 which means 5 minutes before it declares a substituter DOA
      connect-timeout = 10;

      # If binary substition fails build from source is ok I guess
      fallback = true;

      # I'm sick of these messages I knowwwwwwww the checkout has changes. I did
      # the changes.
      warn-dirty = false;

      # Saves on rebuilds a bit, can probably turn this off back to default if
      # issues arise.
      keep-outputs = true;

      # Fixes some weird channel related behavior
      extra-nix-path = "nixpkgs=flake:nixpkgs";

      # https://github.com/NixOS/nix/issues/11728
      # 128MiB from 1MiB default, increase further if the buffer fills up (again,
      # with my nginx proxy cache things fill up fast even on the slower 2.5g
      # link compared to 10g ...)
      #
      # Had this fill up on another system so doubling it to 128MiB. How gihugic
      # do I need this to be on a 10g/2.5g network?
      download-buffer-size = 256 * 1024 * 1024;

      # Keys I'm willing to accept as kosher
      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      ];

      # OK so I have a thought here... setup a ncps instance locally, point THAT
      # here and let ncps handle if something is down or not.
      #
      # Then I can ignore this feature flag kinda crap and just let ncps cache
      # to internal ncps when on local network and/or wireguard when I get that
      # working but always through the local ncps daemon and I don't gotta do
      # anything with editing files or whatever.
      extra-substituters = lib.mkIf enableHomeCache [ "http://nix.cache.home.arpa:8080?priority=10" ];
    };
  };
}
