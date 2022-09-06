{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.mitchty;
  fake = lib.fakeSha256;

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
    version = "28.0.1";

    sourceRoot = ".";
    phases = [ "installPhase" ];
    installPhase = ''
      install -dm755 "$out/Applications"
      VOLUME=`/usr/bin/hdiutil attach $src | grep Volumes | awk '{print $3}'`
      cp -rf $VOLUME/${aname}.app $out/Applications/${aname}.app
      /usr/bin/hdiutil detach $VOLUME
    '';

    src = fetchurl {
      name = "${aname}.dmg";
      # As of obs 28.0.0 this disk image is now APFS and not HFS, so undmg no worky
      url = "https://github.com/${uname}/${name}/releases/download/${version}/obs-studio-${version}-macos-x86_64.dmg";
      sha256 = "sha256-JG4bF0rz9hUT5OAE6UijJRSQkbUWW3AFORVw9tM07j4=";
    };
  };

  stats = with pkgs; stdenv.mkDerivation rec {
    name = "stats";
    uname = "exelban";
    aname = "Stats";
    version = "2.7.32";

    buildInputs = [ undmg ];
    sourceRoot = ".";
    phases = [ "unpackPhase" "installPhase" ];
    installPhase = ''
      install -dm755 "$out/Applications"
      cp -r ${aname}.app "$out/Applications/${aname}.app"
    '';

    src = fetchurl {
      url = "https://github.com/${uname}/${name}/releases/download/v${version}/${aname}.dmg";
      sha256 = "sha256-8XnjkC5pSNOTqcjP87cwbdN+5VyJb1ened9ROa2n60E=";
    };
  };

  stretchly = with pkgs; stdenv.mkDerivation rec {
    name = "stretchly";
    uname = "hovancik";
    aname = "Stretchly";
    version = "1.11.0";

    buildInputs = [ undmg ];
    sourceRoot = ".";
    phases = [ "unpackPhase" "installPhase" ];
    installPhase = ''
      install -dm755 "$out/Applications"
      cp -r ${aname}.app "$out/Applications/${aname}.app"
    '';

    src = fetchurl {
      # https://github.com/hovancik/stretchly/releases/download/v1.10.0/Stretchly-1.10.0.dmg
      url = "https://github.com/${uname}/${name}/releases/download/v${version}/${aname}-${version}.dmg";
      sha256 = "sha256-Bq/Os5jrR52SITM/bxxSGIRFZTQ+ZT3ZoBuHTAzRO7c=";
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
    version = "3.6.7";

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
      sha256 = "sha256-kw/UGM9LlmsSmc6s2Ijr0HBc9EJpAnzzdazJTLevSeg=";
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
      stretchly
      swiftbar
      wtf
      vlc
      obs-studio
      wireshark
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
