{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.role.lowmem;
in
{
  options.services.role.lowmem = {
    enable = mkEnableOption "Designate the system has low memory.";
  };

  # Other stuff uses this to indicate if things should(n't) be installed
  config = mkIf cfg.enable {
    # As much as I hate zram, with 2GiB of memory, it helps.
    zramSwap.enable = true;
  };
}
