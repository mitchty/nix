{
  inputs,
  config,
  pkgs,
  lib,
  ...
}:
{
  config = {
    time.timeZone = "America/Chicago";
    services.chrony = {
      enable = true;
      # For prometheus node_exporter so the sync status goes to 1
      extraConfig = ''
        rtcsync
      '';
      enableRTCTrimming = false;
      servers = [
        "0.north-america.pool.ntp.org"
        "1.north-america.pool.ntp.org"
        "2.north-america.pool.ntp.org"
        "3.north-america.pool.ntp.org"
      ];
    };
  };
}
