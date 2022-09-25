{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.mitchty;
  fake = lib.fakeSha256;

  obs-studio = pkgs.callPackage ./pkgs/obs.nix { };
  stats = pkgs.callPackage ./pkgs/stats.nix { };
  stretchly = pkgs.callPackage ./pkgs/stretchly.nix { };

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

  yeet = (pkgs.writeScriptBin "yeet" (builtins.readFile ../../src/yeet.sh)).overrideAttrs (old: {
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

  wireshark = with pkgs; stdenv.mkDerivation rec {
    name = "wireshark";
    gname = "Wireshark";
    version = "3.6.8";

    buildInputs = [ undmg ];
    sourceRoot = ".";
    phases = [ "unpackPhase" "installPhase" ];
    installPhase = ''
      install -dm755 "$out/Applications"
      cp -r ${gname}.app "$out/Applications/${gname}.app"
    '';

    src = fetchurl {
      name = "${gname}.dmg";
      url = "https://2.na.dl.wireshark.org/osx/Wireshark%20${version}%20Intel%2064.dmg";
      sha256 = "sha256-weVPGvkzSGrGDalLsaNm31EllZ70FuGpPCovud5476A=";
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
      obs-studio
      stats
      stretchly
      swiftbar
      vlc
      wireshark
      wtf
      yeet
    ];

    system.activationScripts.postActivation.text = ''
      printf "modules/darwin/mitchty.nix: macos shenanigans\n" >&2
      $DRY_RUN_CMD install -dm755 $VERBOSE_ARG ~/.cache/swiftbar
      $DRY_RUN_CMD close stats
      $DRY_RUN_CMD pkill nettop || :
      $DRY_RUN_CMD open -a ~/Applications/Nix\ Apps/Stats.app
    '';
  };
}
