{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.mitchty;

  # Scripts I wrote that are macos only.
  close = (pkgs.writeScriptBin "close" (builtins.readFile ../../static/src/close)).overrideAttrs (old: {
    buildCommand = "${old.buildCommand}\n patchShebangs $out";
  });

  notify = (pkgs.writeScriptBin "notify" (builtins.readFile ../../static/src/notify)).overrideAttrs (old: {
    buildCommand = "${old.buildCommand}\n patchShebangs $out";
  });

  gohome = (pkgs.writeScriptBin "gohome" (builtins.readFile ../../static/src/gohome)).overrideAttrs (old: {
    buildCommand = "${old.buildCommand}\n patchShebangs $out";
  });

  stats = pkgs.stdenv.mkDerivation rec {
    pname = "stats";
    version = "2.7.17";

    buildInputs = [ pkgs.undmg ];
    sourceRoot = ".";
    phases = [ "unpackPhase" "installPhase" ];
    installPhase = ''
      mkdir -p "$out/Applications"
      cp -r Stats.app "$out/Applications/Stats.app"
    '';

    src = pkgs.fetchurl {
      name = "Stats.dmg";
      url = "https://github.com/exelban/stats/releases/download/v${version}/Stats.dmg";
      sha256 = "sha256-N4RiI8OtdtIhiYo/grg77UzTcQY8+nLphtyUyP3n1g8=";
    };
  };
in
{
  options = {
    services.mitchty = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          My custom crap for macos.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      close
      gohome
      notify
      stats
    ];
  };
}
