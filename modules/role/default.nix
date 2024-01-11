{ config, pkgs, ... }: {
  imports = [
    ./gui.nix
  ];
}

# Note: Roles are and can be shared across nixos/darwin All module definitions
# should ensure they function across both when applicable.
