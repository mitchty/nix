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
        # "vm.swappiness" = 50;
        # The rest here is sus, needs to be brained through a skosh.
        # # Reclaim cache/vm/fs pages sooner
        # "vm.vfs_cache_pressure" = 500;
        # 100MiB of bytes % is 10% by default
        # "vm.dirty_background_bytes" = 104857600;
        # 200MiB of bytes % is 20% by default will slow dirtying of pages till caught up
        # "vm.dirty_bytes" = 209715200;
        # # Don't scan task list when in oom, just kill the thing that used crazy mem
        # "vm.oom_kill_allocating_task" = 1;
      };
    };

    # TODO: testing out just using plaine olde swap instead
    # As much as I hate zram, with 2GiB of memory, it helps.
    # zramSwap.enable = true;

    # Help out low memory systems by garbage collecting earlier
    environment.variables.GC_INITIAL_HEAP_SIZE = "1M";
  };
}
