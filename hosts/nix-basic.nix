{ pkgs, ... }: {
  # Until nix 2.4 is shipped in a version of nixos, bit of hacks to get things
  # to work.
  nix = {
    package = pkgs.nix_2_4;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };
}
