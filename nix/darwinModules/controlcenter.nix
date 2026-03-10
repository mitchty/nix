{
  inputs,
  lib,
  pkgs,
  ...
}:
{
  system = {
    defaults = {
      controlcenter = {
        # Keep this around only as its the easy way to charge the battery to
        # full on demand.
        BatteryShowPercentage = false;
        # This all crowds out stats display, set to false then nuke these
        # entirely as the control center widget lets me get at em kinda like
        # barsaver.
        Sound = false;
        Bluetooth = false;
      };
    };
  };
}
