{ pkgs, ... }: {
  # Clean /tmp at boot time
  boot.cleanTmpDir = true;

  # Save space not enabling docs
  documentation.nixos.enable = false;

  # gc old generations
  nix.gc.automatic = true;
  nix.gc.options = "--delete-older-than 60d";

  # Until nix 2.4 is shipped in a version of nixos, bit of hacks to get things
  # to work.
  nix = {
    package = pkgs.nix_2_4;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };
}
