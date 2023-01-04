{ config, lib, pkgs, inputs, ... }:

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

  yeet = (pkgs.writeScriptBin "yeet" (builtins.readFile ../../src/yeet.sh)).overrideAttrs (old: {
    buildCommand = "${old.buildCommand}\n patchShebangs $out";
  });

  ugde = (pkgs.writeScriptBin "ugde" (builtins.readFile ../../static/src/ugde.sh)).overrideAttrs (old: {
    buildCommand = "${old.buildCommand}\n patchShebangs $out";
  });
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
      # TODO: Gotta make my nixos flake an overlay, future me problem.
      inputs.mitchty.packages.${pkgs.system}.nheko
      inputs.mitchty.packages.${pkgs.system}.obs-studio
      inputs.mitchty.packages.${pkgs.system}.stats
      inputs.mitchty.packages.${pkgs.system}.stretchly
      inputs.mitchty.packages.${pkgs.system}.swiftbar
      inputs.mitchty.packages.${pkgs.system}.vlc
      inputs.mitchty.packages.${pkgs.system}.wireshark
      close
      gohome
      notify
      wtf
      yeet
      ugde
    ];

    system.activationScripts.postActivation.text = ''
      printf "modules/darwin/mitchty.nix: macos shenanigans\n" >&2
      $DRY_RUN_CMD install -dm755 $VERBOSE_ARG ~/.cache/swiftbar
      $DRY_RUN_CMD close stats
      $DRY_RUN_CMD pkill nettop || :
      $DRY_RUN_CMD open -a /Applications/Nix\ Apps/Stats.app
    '';
  };
}
