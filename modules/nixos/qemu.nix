{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.role.qemu;
  qemux64efiwrapper =
    pkgs.writeShellScriptBin "qemu-system-x86_64-uefi" '' qemu-system-x86_64 -bios ${ pkgs.OVMF.fd}/FV/OVMF.fd "$@"
'';
in
{
  options.services.role.qemu = {
    enable = mkEnableOption "If there should be qemu related shenanigans done on this node or not";
  };

  config = mkIf cfg.enable {
    nixpkgs.config.packageOverrides = pkgs: {
      qemu = pkgs.qemu.override { gtkSupport = true; };
    };

    environment = {
      systemPackages = (lib.attrVals [
        "qemu"
        "qemux64efiwrapper"
      ]
        pkgs);
    };
  };
}
