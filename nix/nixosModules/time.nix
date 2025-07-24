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
        "pool.ntp.org"
        "pool.ntp.org"
        "pool.ntp.org"
        "time.apple.com"
      ];
    };
  };
}
