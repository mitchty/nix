{ config, lib, ... }:

with lib;

let
  cfg = config.services.role.mosh;
in
{
  options.services.role.mosh = {
    enable = mkEnableOption "Setup as a mosh enabled system";
  };

  config = mkIf cfg.enable {
    networking.firewall.allowedUDPPortRanges = [
      { from = 60000; to = 60010; }
    ];
  };
}
