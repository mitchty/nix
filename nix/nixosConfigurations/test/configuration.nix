{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  # disko = pkgs.writeShellScriptBin "disko" ''${config.system.build.diskoScript}'';
  # disko-mount = pkgs.writeShellScriptBin "disko-mount" "${config.system.build.mountScript}";
  # disko-format = pkgs.writeShellScriptBin "disko-format" "${config.system.build.formatScript}";

in
{

  # TODO: do I want to constrain disko stuff only to the installer system derivations? "to be safe(r)"
  # imports = [
  #   ./disko.nix
  # ];
  # environment.systemPackages = [
  #   disko
  #   disko-mount
  #   disko-format
  # ];

  environment.variables.EDITOR = "vi";

  #  disko.enableConfig = lib.mkDefault false;
}
