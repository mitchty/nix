{ pkgs, ... }: {
  imports = [
    ../../hosts/nix.nix
  ];
  nix = {
    settings = {
      trusted-users = [
        "@admin"
      ];
    };
    configureBuildUsers = true;
  };

  services.nix-daemon.enable = true;
  programs.zsh.enable = true;
  environment.variables.SHELL = "${pkgs.zsh}/bin/zsh";
  system.stateVersion = 4;
}
