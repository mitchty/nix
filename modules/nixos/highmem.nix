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
      tmp = {
        cleanOnBoot = true;
        useTmpfs = true;
        tmpfsSize = "25%";
      };
    };
  };
}
