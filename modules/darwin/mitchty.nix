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

  ugde = (pkgs.writeScriptBin "ugde" (builtins.readFile ../../static/src/ugde.sh)).overrideAttrs (old: {
    buildCommand = "${old.buildCommand}\n patchShebangs $out";
  });

  reopen = (pkgs.writeScriptBin "reopen" (builtins.readFile ../../static/src/reopen)).overrideAttrs (old: {
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
      inputs.mitchty.packages.${pkgs.system}.clocker
      inputs.mitchty.packages.${pkgs.system}.hidden
      inputs.mitchty.packages.${pkgs.system}.maccy
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
      reopen
      ugde
    ];

    system.activationScripts.postActivation.text = ''
      printf "modules/darwin/mitchty.nix: macos app shenanigans\n" >&2
      $DRY_RUN_CMD reopen Stats Stretchly Maccy 'Hidden Bar'
    '';
  };
}
