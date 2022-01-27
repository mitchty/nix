{ config, pkgs, ... }: {
  imports = [
    ./hardware-configuration.nix
  ];

  boot.loader.grub.efiInstallAsRemovable = true;
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.device = "nodev";

  # networking.hostName = "changeme";
  networking.firewall.enable = false;

  boot.kernelParams = [ "boot.shell_on_fail" ];
  boot.supportedFilesystems = [ "zfs" "bcachefs" ];

  # We want sysrq functions to work if there is an issue
  boot.kernel.sysctl = {
    "kernel.sysrq" = 1;
  };

  users.users.root.initialPassword = "changeme";

  services.openssh = {
    enable = true;
    permitRootLogin = "yes";
  };

  users.mutableUsers = false;

  nix = {
    package = pkgs.nix_2_4;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  system.stateVersion = "21.11";

  # Generated stuff goes here...
}
