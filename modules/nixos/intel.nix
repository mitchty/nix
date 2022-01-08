{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.role.intel;
in {
  options.services.role.intel = {
    enable = mkEnableOption "Designate if the system is intel";
  };

  # If we're intel, should always update the firmware and microcode
  config = mkIf cfg.enable {
    hardware.enableRedistributableFirmware = true;
    hardware.cpu.intel.updateMicrocode = true;
  };
}
