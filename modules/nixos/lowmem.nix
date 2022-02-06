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
    boot = {
      cleanTmpDir = true;
      kernel.sysctl = {
        # Be a bit (too) aggressive with swapping old pages
        "vm.swappiness" = 10;

        # The rest here is sus, needs to be brained through a skosh.
        # # Reclaim cache/vm/fs pages sooner
        # "vm.vfs_cache_pressure" = 500;
        # # Let kswap start caring sooner with a tiny background ratio
        # "vm.dirty_background_ratio" = 1;
        # # Don't force sync io until we're at 50% dirty_ratio
        # "vm.dirty_ratio" = 50;
        # # Don't scan task list when in oom, just kill the thing that used crazy mem
        # "vm.oom_kill_allocating_task" = 1;
      };
    };

    # TODO: testing out just using plaine olde swap instead
    # As much as I hate zram, with 2GiB of memory, it helps.
    zramSwap.enable = true;

    # Help out low memory systems by garbage collecting earlier
    environment.variables.GC_INITIAL_HEAP_SIZE = "1M";
  };
}
