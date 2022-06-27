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

  wtf = (pkgs.writeScriptBin "wtf" (builtins.readFile ../../static/src/wtf.sh)).overrideAttrs (old: {
    buildCommand = "${old.buildCommand}\n patchShebangs $out";
  });

  stats = with pkgs; stdenv.mkDerivation rec {
    pname = "stats";
    uname = "exelban";
    version = "2.7.22";

    buildInputs = [ undmg ];
    sourceRoot = ".";
    phases = [ "unpackPhase" "installPhase" ];
    installPhase = ''
      install -dm755 "$out/Applications"
      cp -r Stats.app "$out/Applications/Stats.app"
    '';

    src = fetchurl {
      name = "Stats.dmg";
      url = "https://github.com/${uname}/${pname}/releases/download/v${version}/Stats.dmg";
      sha256 = "sha256-lWaQbuG29FXvizf5xItnJ80OSt2pBw7F4mQS6y+7NMI=";
    };
  };

  swiftbar = with pkgs; stdenv.mkDerivation rec {
    pname = "swiftbar";
    gname = "SwiftBar";
    version = "1.4.3";

    buildInputs = [ unzip ];
    sourceRoot = ".";
    phases = [ "unpackPhase" "installPhase" ];
    installPhase = ''
      install -dm755 "$out/Applications"
      cp -r ${gname}.app "$out/Applications/${gname}.app"
    '';

    src = fetchurl {
      name = "SwiftBar.zip";
      url = "https://github.com/${pname}/${gname}/releases/download/v${version}/${gname}.zip";
      sha256 = "sha256-IP/lWahb0ouG912XvaWR3nDL1T3HrBZ2E8pp/WbHGgQ=";
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
      swiftbar
      wtf
    ];

    system.activationScripts.postActivation.text = ''
      printf "modules:darwin:mitchty: macos shenanigans\n" >&2
      install -dm755 ~/.cache/swiftbar
    '';
  };
}
