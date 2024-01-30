{ lib, inputs, ... }: {
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
    # Cleanup old generations we likely don't need, only on nixos though on hold
    # gc = {
    #   automatic = true;
    #   dates = "weekly";
    #   options = "--delete-older-than 14d";
    # };

    settings = {
      substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
        # Abuse boolean input to control if this should exist or not for this
        # generation being built.
      ] ++ lib.optionals inputs.with-homecache.value [
        "http://cache.cluster.home.arpa"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };

    # Lets things download in parallel
    extraOptions = ''
      fallback = true
      binary-caches-parallel-connections = 10
      auto-optimise-store = false
      experimental-features = nix-command flakes
    '';
  };
}
