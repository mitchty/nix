{
  inputs,
  lib,
  pkgs,
  self,
  ...
}:
let
  pubKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCl1r2eksJXO02QkuGbjVly38MhG9MpDfvQRPABWJLGfFIBQFNkCvvJffV1UEUpcRNNaAmle1DFS1CtvATZSr/UpTgzsAYu9X+gd0/5OB/WlWHJaC/j0H2LahtiUPKZ2d4/cLkKPQqP6HZdmOXrsHZR1I9bxjhqyNWhwxNLMCK/8995hKNWOYamMagJloHUTRLFQaor/WoFDqjfW8EKo09OxKnXtFFcj6CmXwsu1RWfFY/P/wsADL+8B2/P4CmqqwuLxQknbA0WZ2zWSj13tf24H7BORAkMAeK5249GuLd5SlnnvmHJLiF1OCIkSOZJMcyrNCCvBRavGLcPoKQbtHw7";
in
{
  imports = [
    inputs.disko.nixosModules.disko
    (import ./disko.nix { })
    ./../../nixosModules/kernel.nix
  ];

  environment.variables.EDITOR = "vi";
  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
        "ca-derivations"
      ];
    };
  };

  boot = {
    tmp = {
      cleanOnBoot = true;
      useTmpfs = true;
      tmpfsSize = "10%";
    };

    kernelPackages = pkgs.linuxPackages_latest;
    # I want my magic sysrq triggers to work
    kernel.sysctl = {
      "vm.overcommit_memory" = lib.mkForce 1;
    };
    kernelParams = [
      "boot.shell_on_fail"
      "console=ttyS0,115200n8"
      #              "console=tty0" # fallback somehow if serial no work somehow?
      "delayacct"
      "intel-spi.writeable=1"
      "iomem=relaxed"
    ];
    loader = {
      efi = {
        canTouchEfiVariables = true;
      };
      # iso uses grub installed system uses systemd-boot
      systemd-boot.memtest86.enable = true;
    };
  };

  users = {
    mutableUsers = false;
    users.mitch = {
      isNormalUser = true;
      description = "mitch user";
      extraGroups = [
        "wheel"
        "networkmanager"
      ];

      # This is a test vm only used to test out disk/install automation. Its not
      # getting out/exposed to the outside world ever.
      # echo nixos | openssl passwd -6 -stdin -salt vmtestsalt
      hashedPassword = "$6$vmtestsalt$RU13pQq.NolDt0ZFHiLVzYNjIdTY1aj43jklM/6hrge1NAIosvc.W16.dLf5CwsSaSlbCg0pqupZdkLQdf0/z0";
    };
    extraUsers = {
      root.openssh.authorizedKeys.keys = [ pubKey ];
      mitch.openssh.authorizedKeys.keys = [ pubKey ];
    };
  };

  # Let me ssh in by default
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "yes";
    };
  };
}
