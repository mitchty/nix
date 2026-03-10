{ pkgs, lib, ... }:
{
  # 6.19 won't build current nvidia driver shim driver
  # https://github.com/NixOS/nixpkgs/issues/489947
  boot.kernelPackages = lib.mkForce pkgs.linuxPackages_6_18;
  #hardware.nvidia.package = pkgs.unstable.kernelPackages.nvidiaPackages.beta;
}
