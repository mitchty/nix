{ config, pkgs, ... }: {
  boot = {
    # Use latest kernel rev (don't use on zfs...)
    kernelPackages = pkgs.linuxPackages_latest;

    # Always clean out /tmp
    cleanTmpDir = true;

    # always want sysrq keys in case I need to middle finger things to reboot
    kernel.sysctl = {
      "kernel.sysrq" = 1;
    };

    # For iotop
    kernelParams = [ "delayacct" ];
  };
}
