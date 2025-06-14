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
        BatteryShowPercentage = true;
        Sound = true;
        Bluetooth = false;
      };
    };
  };
}
