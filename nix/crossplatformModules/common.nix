{
  pkgs,
  lib,
  inputs,
  config,
  ...
}:
{
  imports = with inputs.self.crossplatformModules; [
    nix-basic
    debug
  ];
}
