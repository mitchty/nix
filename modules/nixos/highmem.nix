{ config, lib, ... }:

with lib;

let
  cfg = config.services.role.highmem;
in
{
  options.services.role.highmem = {
    enable = mkEnableOption "Designate the system has too much memory.";
  };

  config = mkIf cfg.enable {
    boot = {
      cleanTmpDir = true;
      tmpOnTmpfs = true;
      tmpOnTmpfsSize = "25%";
    };
  };
}
