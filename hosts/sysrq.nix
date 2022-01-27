{ ... }: {
  # General sysctl stuff
  boot.kernel.sysctl = {
    "kernel.sysrq" = 1;
  };

  # For iotop
  boot.kernelParams = [ "delayacct" ];
}
