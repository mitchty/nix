{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.role.gaming;
in
{
  options.services.role.gaming = {
    enable = mkEnableOption "Designate the system is for gaming.";
  };

  # Other stuff uses this to indicate if things should(n't) be installed
  config = mkIf cfg.enable {
    programs.steam.enable = true;
    hardware.opengl.driSupport32Bit = true;
    nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
      "steam"
      "steam-original"
      "steam-run"
    ];

    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      jack.enable = true;
      pulse.enable = true;
      socketActivation = true;
    };
    programs.dconf.enable = true;

    #environment.systemPackages = [ pkgs.steam ];
  };
}
