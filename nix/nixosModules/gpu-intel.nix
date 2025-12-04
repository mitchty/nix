{ pkgs, ... }:
{
  boot.kernelParams = [ "i915.enable_guc=3" ];
  hardware = {
    enableAllFirmware = true;
    intel-gpu-tools.enable = true;
    graphics = {
      enable = true;
      extraPackages = with pkgs; [
        intel-media-driver
        libva-vdpau-driver
        intel-compute-runtime
        intel-ocl
        vpl-gpu-rt
      ];
      # extraPackages32 = with pkgs.pkgsi686Linux; [
      #   intel-media-driver
      # ];
    };
  };
}
