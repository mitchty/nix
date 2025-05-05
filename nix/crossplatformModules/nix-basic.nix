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
      "experimental-features" = [
        "nix-command"
        "flakes"
      ];
      "fallback" = true;
      "binary-caches-parallel-connections" = 4;
      "auto-optimise-store" = false;
    };
  };
}
