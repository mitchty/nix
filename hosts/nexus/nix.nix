{ ... }: {
  # Clean /tmp at boot time
  boot.cleanTmpDir = true;

  # Save space not enabling docs
  documentation.nixos.enable = false;

  # gc old generations
  nix.gc.automatic = true;
  nix.gc.options = "--delete-older-than 60d";
}
