{ pkgs, ... }: {
  boot = {
    # Be nice to have crash dumps if things go sideways, which they are with
    # dm-integrity, dm-cache, dm-etc....
    crashDump.enable = true;

    kernelPatches = pkgs.lib.singleton {
      name = "I like to customize my kernel config and patch it at times if a CVE comes out.";
      patch = [
        # TODO figure out a good way to keep this stuff working
        # (pkgs.fetchpatch {
        #   name = "add-tcp-collapse-sysctl";
        #   url = "https://raw.githubusercontent.com/cloudflare/linux/master/patches/0014-add-a-sysctl-to-enable-disable-tcp_collapse-logic.patch";
        #   sha256 = "sha256-H4zefPF60CIE31wlnbFXAzHmtGnX7drVLyYiau4sHGk=";
        # })
        # (pkgs.fetchpatch {
        #   name = "add-tcp-window-shrink-sysctl";
        #   url = "https://raw.githubusercontent.com/cloudflare/linux/master/patches/0020-Add-a-sysctl-to-allow-TCP-window-shrinking-in-order-.patch";
        #   sha256 = "sha256-XuYvLbEzrGXcDM+h6Bb8rmIrIWOMVW1ExBvnYNTjduw=";
        # })
      ];

      # Patch finally upstream no need for now...
      # patch = null;
      # patch = [
      #   ../patches/CVE-2022-0435.patch
      # ];
      # TODO: Validate all these CONFIG_ options make sense The
      # default nixpkgs kernel has these as modules, but whatever just
      # compile them in statically cause I'm weird. Need to find more
      # stuff I can change around to make a more minimal kconfig for
      # my usage.
      extraConfig = ''
        # PERF_EVENTS y
        # KALLSYMS y
        # TRACEPOINTS y
        # FTRACE y
        # KPROBES y
        # KPROBE_EVENTS y
        # UPROBES y
        # UPROBE_EVENTS y
        # LOCKDEP y
        # LOCK_STAT y
        DEBUG_INFO y
        SCHEDSTATS y
        LATENCYTOP y
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
