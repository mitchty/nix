{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
let
  inherit (builtins) mapAttrs;
  inherit (inputs) self;
in
{
  imports = with self.homeModules; [ common ];

  home = {
    stateVersion = "24.11";
  };

  # programs = mapAttrs (_: v: v // { enable = true; }) {
  # };
}
