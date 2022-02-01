{ config, pkgs, ... }: {
  # Use latest kernel rev (don't use on zfs...)
  boot.kernelPackages = pkgs.linuxPackages_latest;
}
