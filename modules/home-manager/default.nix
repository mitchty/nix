{ pkgs, lib, ... }:

with lib;

let
  sys = pkgs.lib.last (pkgs.lib.splitString "-" pkgs.system);
in
rec {
  # TODO: Migrate configuration/setup out of hosts/*.nix to a module setup
  imports = [
    # ./${sys}
    # ./nix-index.nix
  ];
}
