{
  pkgs,
  ...
}:

{
  nix = {
    package = pkgs.nix;
    # Lets things download in parallel but not too parallel
    #
    # Also enable nix flake and repl on flakes
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
        "ca-derivations"
      ];
      fallback = true;
      binary-caches-parallel-connections = 4;
      auto-optimise-store = false;
      substituters = [
        "https://nix-community.cachix.org/"
        "https://cache.nixos.org/"
      ];
      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      ];
    };
  };
}
