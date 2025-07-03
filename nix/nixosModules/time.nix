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
      servers = [
        "pool.ntp.org"
        "pool.ntp.org"
        "pool.ntp.org"
        "time.apple.com"
      ];
    };
  };
}
