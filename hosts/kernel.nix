{ config, pkgs, ... }: {
  boot = {
    # Be nice to have crash dumps if things go sideways, which they are with
    # dm-integrity, dm-cache, dm-etc....
    crashDump.enable = true;

    kernelPatches = pkgs.lib.singleton {
      name = "Custom extra kernel config + maybe patches at some point";
      patch = [
        ../patches/CVE-2022-0435.patch
      ];
      # TODO: Validate all these CONFIG_ options make sense
      # The default nixpkgs kernel has these as modules, but whatever just
      # compile them in statically
      # extraConfig = ''
      #    DM_CACHE m
      #    DM_INTEGRITY m
      #    DM_VERITY m
      #    DM_THIN_PROVISIONING m
      #    AX25 n
      #    CRYPTO_AEGIS128_SIMD n
      #    CAN n
      #    BT n
      #    FB_NVIDIA n
      #    FB_NVIDIA_BACKLIGHT n
      #    FB_NVIDIA_I2C n
      #    FIREWIRE n
      #    FPGA n
      #    INFINIBAND n
      #    INPUT_JOYSTICK n
      #    INPUT_TOUCHSCREEN n
      #    IWLWIFI n
      #    GAMEPORT n
      #    GREYBUS n
      #    NET_VENDOR_NVIDIA n
      #    NFC n
      #    RTC_DRV_RK808 y
      #    PCCARD n
      #    PCMCIA n
      #    PCMCIA_LOAD_CIS n
      #    CARDBUS n
      #    CXL_BUS n
      #    CXL_PMEM n
      #    CXL_ACPI n
      #    SND n
      #    SOUND n
      #    STAGING y
      #    STAGING_MEDIA y
      #    ZSWAP_COMPRESSOR_DEFAULT_LZO n
      #    ZSWAP_COMPRESSOR_DEFAULT_ZSTD y
      #    ZSWAP_COMPRESSOR_DEFAULT zstd
      #  '';
    };

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
