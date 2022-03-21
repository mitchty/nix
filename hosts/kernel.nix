{ config, pkgs, ... }: {
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
        CAN n
        FIREWIRE n
        FPGA n
        INFINIBAND n
        INPUT_JOYSTICK n
        INPUT_TOUCHSCREEN n
        IWLWIFI n
        GAMEPORT n
        GREYBUS n
        NET_VENDOR_NVIDIA n
        NFC n
        CXL_BUS n
        STAGING y
        STAGING_MEDIA y
        ZSWAP_COMPRESSOR_DEFAULT_LZO n
        ZSWAP_COMPRESSOR_DEFAULT_ZSTD y
        ZSWAP_COMPRESSOR_DEFAULT zstd
      '';
      #    DM_CACHE m
      #    DM_INTEGRITY m
      #    DM_VERITY m
      #    DM_THIN_PROVISIONING m
      #    CRYPTO_AEGIS128_SIMD n
      #    BT n
      #    FB_NVIDIA n
      #    FB_NVIDIA_BACKLIGHT n
      #    FB_NVIDIA_I2C n
      #    RTC_DRV_RK808 y
      #    SND n
      #    SOUND n
    };

    # Always clean out /tmp
    cleanTmpDir = true;

    # always want sysrq keys in case I need to middle finger things to reboot
    kernel.sysctl = {
      "kernel.sysrq" = 1;
    };

    # For iotop
    kernelParams = [ "delayacct" "boot.shell_on_fail" ];
  };
}
