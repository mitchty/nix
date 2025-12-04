{
  inputs,
  config,
  pkgs,
  lib,
  ...
}:
{
  # Intel specific power management
  hardware.intel-gpu-tools.enable = true;
}
