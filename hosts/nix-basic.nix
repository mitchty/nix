{ pkgs, ... }: {
  nix = {
    package = pkgs.nix;
    # Lets things download in parallel but not too parallel
    #
    # Also enable nix flake and repl on flakes
    extraOptions = ''
      fallback = true
      binary-caches-parallel-connections = 10
      auto-optimise-store = false
      experimental-features = nix-command flakes
    '';
  };
}
