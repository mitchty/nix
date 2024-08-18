{ config, pkgs, ... }:
let
  pubKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCl1r2eksJXO02QkuGbjVly38MhG9MpDfvQRPABWJLGfFIBQFNkCvvJffV1UEUpcRNNaAmle1DFS1CtvATZSr/UpTgzsAYu9X+gd0/5OB/WlWHJaC/j0H2LahtiUPKZ2d4/cLkKPQqP6HZdmOXrsHZR1I9bxjhqyNWhwxNLMCK/8995hKNWOYamMagJloHUTRLFQaor/WoFDqjfW8EKo09OxKnXtFFcj6CmXwsu1RWfFY/P/wsADL+8B2/P4CmqqwuLxQknbA0WZ2zWSj13tf24H7BORAkMAeK5249GuLd5SlnnvmHJLiF1OCIkSOZJMcyrNCCvBRavGLcPoKQbtHw7";
in
{
  imports = [
    ./hardware-configuration.nix
  ];

  boot = {
    kernelParams = [
      "console=ttyS0,115200n8"
      "boot.shell_on_fail"
      "iomem=relaxed"
      "intel-spi.writeable=1"
    ];
    supportedFilesystems = [
      "zfs"
      "xfs"
      "ext4"
    ];
    loader = {
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/efiboot/efi0";
      };
      systemd-boot = {
        enable = true;
        configurationLimit = 10;
        memtest86.enable = true;
      };
      generationsDir.copyKernels = true;
    };
    kernel.sysctl = {
      # We want sysrq functions to work if there is an issue
      "kernel.sysrq" = 1;
      # Be kind(er) to low memory systems
      "vm.overcommit_memory" = "1";
    };
    extraModulePackages = with config.boot.kernelPackages; [ acpi_call chipsec zfs ];
  };

  networking.firewall.enable = false;

  environment = {
    variables = {
      # Since we have no swap, have the heap be a bit less extreme
      GC_INITIAL_HEAP_SIZE = "1M";
    };
  };

  services.openssh = {
    enable = true;
    permitRootLogin = "yes";
  };

  users.users.root.openssh.authorizedKeys.keys = [ pubKey ];

  users.mutableUsers = false;

  nix = {
    package = pkgs.nixFlakes;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  system.stateVersion = "23.11";

  # Generated stuff goes under here...
  networking.hostName = "chonkyboi";
  networking.hostId = "126688e2";
  boot.loader.systemd-boot.extraInstallCommands = ''
    ${pkgs.rsync}/bin/rsync -Ha --delete /efiboot/efi0/ /efiboot/efi1
  '';
  boot.swraid.enable = true;
  boot.swraid.mdadmConf = ''
    PROGRAM $\{pkgs.coreutils\}/bin/true
    ARRAY /dev/md/chonkyboi:SWAPMD level=raid1 num-devices=2 metadata=1.0 
       devices=/dev/disk/by-partlabel/SWAP0,/dev/disk/by-partlabel/SWAP1
  '';
  boot.kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;
  boot.initrd.kernelModules = [ "zfs" ];
  boot.initrd.postDeviceCommands = "zpool import -lf zpool";
  boot.zfs.devNodes = "/dev/disk/by-partlabel";
  networking.interfaces.enp6s0.useDHCP = true;
}
