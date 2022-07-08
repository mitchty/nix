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

  vlc = with pkgs; stdenv.mkDerivation rec {
    name = "vlc";
    uname = "videolan";
    aname = "VLC";
    version = "3.0.17.3";

    buildInputs = [ undmg ];
    sourceRoot = ".";
    phases = [ "unpackPhase" "installPhase" ];
    installPhase = ''
      install -dm755 "$out/Applications"
      cp -r ${aname}.app "$out/Applications/${aname}.app"
    '';

    src = fetchurl {
      name = "${aname}.dmg";
      url = "http://get.videolan.org/${name}/${version}/macosx/${name}-${version}-intel64.dmg";
      sha256 = "sha256-zKJn8sUa5WjgLztNimrbqHsr3l8BGiuHxZXBAtifEdg=";
    };
  };

  obs-studio = with pkgs; stdenv.mkDerivation rec {
    name = "obs-studio";
    uname = "obsproject";
    aname = "OBS";
    version = "27.2.4";

    buildInputs = [ undmg ];
    sourceRoot = ".";
    phases = [ "unpackPhase" "installPhase" ];
    installPhase = ''
      install -dm755 "$out/Applications"
      cp -r ${aname}.app "$out/Applications/${aname}.app"
    '';

    src = fetchurl {
      name = "${aname}.dmg";
      url = "https://github.com/${uname}/${name}/releases/download/${version}/obs-mac-${version}.dmg";
      sha256 = "sha256-mu7ZKBbyP9tIGesbDJicFYqqskbgvQJJM0KWFLBkNfI=";
    };
  };

  stats = with pkgs; stdenv.mkDerivation rec {
    name = "stats";
    uname = "exelban";
    aname = "Stats";
    version = "2.7.24";

    buildInputs = [ undmg ];
    sourceRoot = ".";
    phases = [ "unpackPhase" "installPhase" ];
    installPhase = ''
      install -dm755 "$out/Applications"
      cp -r ${aname}.app "$out/Applications/${aname}.app"
    '';

    src = fetchurl {
      url = "https://github.com/${uname}/${name}/releases/download/v${version}/${aname}.dmg";
      sha256 = "sha256-9D0/geCEzI2E/lLE+5ZmdfbtXPc6pMxc2fwHN79/GEk=";
    };
  };

  swiftbar = with pkgs; stdenv.mkDerivation rec {
    name = "swiftbar";
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
      name = "${gname}.zip";
      url = "https://github.com/${name}/${gname}/releases/download/v${version}/${gname}.zip";
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
      vlc
      obs-studio
    ];

    system.activationScripts.postActivation.text = ''
      printf "modules:darwin:mitchty: macos shenanigans\n" >&2
      install -dm755 ~/.cache/swiftbar
    '';
  };
}
