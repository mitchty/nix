{ config, pkgs, ... }: {
  imports = [
    ./mutagen.nix
    ./syncthing.nix
  ];
}
