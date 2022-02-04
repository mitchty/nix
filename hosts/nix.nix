{ pkgs, ... }: {
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
    # Cleanup old generations we likely don't need, only on nixos though
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };
  };
}
