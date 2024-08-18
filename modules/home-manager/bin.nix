# This is just a bunch of scripts to put into the /nix store that used to reside
# in ~/bin or ~/.local/bin. It made no sense to continue doing that with nix.
#
# The scripts are still kept as-is mostly and just read into the store at flake
# build time.
{ pkgs, ... }:

let
  dns = (pkgs.writeScriptBin "dns" (builtins.readFile ../../static/src/dns)).overrideAttrs (old: {
    buildCommand = "${old.buildCommand}\n patchShebangs $out";
  });
  iso8601 = (pkgs.writeScriptBin "iso8601" (builtins.readFile ../../static/src/iso8601)).overrideAttrs (old: {
    buildCommand = "${old.buildCommand}\n patchShebangs $out";
  });
  portchk = (pkgs.writeScriptBin "portchk" (builtins.readFile ../../static/src/portchk)).overrideAttrs (old: {
    buildCommand = "${old.buildCommand}\n patchShebangs $out";
  });
in
{
  home.packages = [
    dns
    iso8601
    portchk
  ];
}
