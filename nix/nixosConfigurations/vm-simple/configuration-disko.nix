{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  disko = pkgs.writeShellScriptBin "disko" "${config.system.build.diskoScript}";
  disko-mount = pkgs.writeShellScriptBin "disko-mount" "${config.system.build.mountScript}";
  disko-format = pkgs.writeShellScriptBin "disko-format" "${config.system.build.formatScript}";
in
{
  environment.systemPackages = [
    disko
    disko-mount
    disko-format
  ];

  disko.enableConfig = lib.mkDefault false;
}
