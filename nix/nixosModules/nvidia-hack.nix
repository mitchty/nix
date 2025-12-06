{ pkgs, lib, ... }:
{
  # 6.18 won't build current nvidia driver shim.
  # https://github.com/nixos/nixpkgs/issues/467814
  # https://github.com/NVIDIA/open-gpu-kernel-modules/pull/951
  boot.kernelPackages = lib.mkForce pkgs.linuxPackages_6_17;
  #  hardware.nvidia.package = pkgs.unstable.kernelPackages.nvidiaPackages.beta;
}
