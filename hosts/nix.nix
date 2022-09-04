{ ... }:
let
  mkCache = url: key: { inherit url key; };
  caches =
    let
      nixos = mkCache "https://cache.nixos.org" "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=";
      nix-community = mkCache "https://nix-community.cachix.org" "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=";
      nix-cache = mkCache "http://nixcache.home.arpa" "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=";
    in
    [ nix-cache nixos nix-community ];

  customCaches = map (x: x.url) caches;
in
{
  imports = [
    ./nix-basic.nix
  ];
  # TODO: no worky in a flake, why?
  # Copy configuration.nix file into the system config derivation in case I
  # might need it.
  # system.copySystemConfiguration = true;

  # Until nix 2.4 is shipped in a version of nixos, bit of hacks to get things
  # to work.
  nix = {
    # Cleanup old generations we likely don't need, only on nixos though
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };

    binaryCaches = customCaches;

    # Lets things download in parallel
    extraOptions = ''
      binary-caches-parallel-connections = 100
    '';
  };
}
