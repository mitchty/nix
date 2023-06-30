{ pkgs, ... }: {
  boot = {
    # Be nice to have crash dumps if things go sideways, which they are with
    # dm-integrity, dm-cache, dm-etc....
    crashDump.enable = true;

    kernelPatches = pkgs.lib.singleton {
      name = "I like to customize my kernel config and patch it at times if a CVE comes out.";
      # Patch finally upstream
      patch = null;
      # patch = [
      #   ../patches/CVE-2022-0435.patch
      # ];
      # TODO: Validate all these CONFIG_ options make sense
      # The default nixpkgs kernel has these as modules, but whatever just
      # compile them in statically
      extraConfig = ''
        TASK_DELAY_ACCT y
        ZSWAP_COMPRESSOR_DEFAULT zstd
        ZSWAP_COMPRESSOR_DEFAULT_LZO n
        ZSWAP_COMPRESSOR_DEFAULT_ZSTD y
      '';
    };

    # Always clean out /tmp
    tmp.cleanOnBoot = true;

    # always want sysrq keys in case I need to middle finger things to reboot
    kernel.sysctl = {
      "kernel.sysrq" = 1;
    };

    # For iotop
    kernelParams = [ "delayacct" "boot.shell_on_fail" ];
  };
}
