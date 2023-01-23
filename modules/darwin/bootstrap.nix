{ pkgs, ... }: {
  nix = {
    settings = {
      trusted-users = [
        "@admin"
      ];
      substituters = [
        "http://cache.cluster.home.arpa"
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };
    configureBuildUsers = true;
    extraOptions = ''
      auto-optimise-store = true
      experimental-features = nix-command flakes
    '';
  };

  services.nix-daemon.enable = true;
  # TODO: look into this a bit more
  # environment.shells = with pkgs; [
  #   bashInteractive
  #   zsh
  # ];

  programs.zsh.enable = true;
  environment.variables.SHELL = "${pkgs.zsh}/bin/zsh";
  system.stateVersion = 4;
}
