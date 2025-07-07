{
  inputs,
  config,
  pkgs,
  lib,
  ...
}:
{
  # Intel specific power management
  config = {
    hardware.intel-gpu-tools.enable = true;
  };
}
