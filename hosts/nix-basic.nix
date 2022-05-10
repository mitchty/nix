{ inputs, pkgs, ... }: {
  nix = {
    package = inputs.unstable.legacyPackages.${pkgs.system}.nixFlakes;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };
}
